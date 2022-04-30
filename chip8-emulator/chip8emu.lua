-- a chip8 emulator written for gmod lua
-- coded by lokachop, based on this wondeful guide https://tobiasvl.github.io/blog/write-a-chip-8-emulator/

file.CreateDir("chip8")
local ROMPath = "chip8/ibmlogo.ch8"
-- rom is actual chip8 rom
local ips = 700 -- how many instructions to run per second
local doWrap = true
local legacy_shift = false -- toggle shifting legacy way

local nextCall = CurTime()
local nextDec = CurTime()
local active = false


local SzMul = 4
local memdumpw = 64 * SzMul
local memdumph = 64 * SzMul




local screenRT = GetRenderTarget("chip8_screen", 64, 32)
local screenRTMat = CreateMaterial("chip8_screen_mat", "UnlitGeneric", {
    ["$basetexture"] = screenRT:GetName()
})


local function hex(num)
    return string.format("%X", num)
end



local beep_sound = "synth/square.wav"

local ROM = file.Open(ROMPath, "rb", "DATA")
if ROM == nil then
    print("ROM invalid!")
    return
end

local screen = {} -- 64 x 32
local memory = {} -- 4kb mem
local keyboard = {} -- 16 keys

local pc = 0x200 -- program counter
local regI = 0x0 -- register i, points at mem

local stack = {} -- holds 16 bit addresses
local dtimer = 0 -- decreases from 60 - 0 in 1s
local stimer = 0 -- sound timer, same as dtimer but plays sound if not 0

local sound_active = false


local screen_updated = false

 -- 8 bit registers
local regs = {
    [0x0] = 0x0, -- v0
    [0x1] = 0x0, -- v1
    [0x2] = 0x0, -- v2
    [0x3] = 0x0, -- v3
    [0x4] = 0x0, -- v4
    [0x5] = 0x0, -- v5
    [0x6] = 0x0, -- v6
    [0x7] = 0x0, -- v7
    [0x8] = 0x0, -- v8
    [0x9] = 0x0, -- v9
    [0xA] = 0x0, -- va
    [0xB] = 0x0, -- vb
    [0xC] = 0x0, -- vc
    [0xD] = 0x0, -- vd
    [0xE] = 0x0, -- ve
    [0xF] = 0x0, -- vf
}

local function debugPrintRegs()
    print("------BEGIN DUMP------")
    print("    ----REGS----")
    for k, v in pairs(regs) do
        print("        0x" .. hex(k) .. ": 0x" .. hex(v) .. ":" .. v)
    end

    print("    ----STACK----")
    for k, v in pairs(stack) do
        print("        0x" .. hex(k) .. ": 0x" .. hex(v) .. ":" .. v)
    end

    print("    ----IREG----")
    print("        0x" .. hex(regI) .. ":" .. regI)
    print("------END DUMP------")
end


local font = {
    0xF0, 0x90, 0x90, 0x90, 0xF0, -- 0
    0x20, 0x60, 0x20, 0x20, 0x70, -- 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, -- 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, -- 3
    0x90, 0x90, 0xF0, 0x10, 0x10, -- 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, -- 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, -- 6
    0xF0, 0x10, 0x20, 0x40, 0x40, -- 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, -- 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, -- 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, -- A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, -- B
    0xF0, 0x80, 0x80, 0x80, 0xF0, -- C
    0xE0, 0x90, 0x90, 0x90, 0xE0, -- D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, -- E
    0xF0, 0x80, 0xF0, 0x80, 0x80  -- F
}


local function wipeScreen()
    for x = 0, 63 do
        if not screen[x] then
            screen[x] = {}
        end

        for y = 0, 31 do
            screen[x][y] = false
        end
    end
end


local function updateKeyRegs()
    keyboard = {
        [0x0] = input.IsKeyDown(KEY_X) and 1 or 0, -- 0
        [0x1] = input.IsKeyDown(KEY_1) and 1 or 0, -- 1
        [0x2] = input.IsKeyDown(KEY_2) and 1 or 0, -- 2
        [0x3] = input.IsKeyDown(KEY_3) and 1 or 0, -- 3
        [0x4] = input.IsKeyDown(KEY_Q) and 1 or 0, -- 4
        [0x5] = input.IsKeyDown(KEY_W) and 1 or 0, -- 5
        [0x6] = input.IsKeyDown(KEY_E) and 1 or 0, -- 6
        [0x7] = input.IsKeyDown(KEY_A) and 1 or 0, -- 7
        [0x8] = input.IsKeyDown(KEY_S) and 1 or 0, -- 8
        [0x9] = input.IsKeyDown(KEY_D) and 1 or 0, -- 9
        [0xA] = input.IsKeyDown(KEY_Z) and 1 or 0, -- A
        [0xB] = input.IsKeyDown(KEY_C) and 1 or 0, -- B
        [0xC] = input.IsKeyDown(KEY_4) and 1 or 0, -- C
        [0xD] = input.IsKeyDown(KEY_R) and 1 or 0, -- D
        [0xE] = input.IsKeyDown(KEY_F) and 1 or 0, -- E
        [0xF] = input.IsKeyDown(KEY_V) and 1 or 0, -- F
    }
    --PrintTable(keyboard)
end


local function pushToStack(v)
    stack[#stack + 1] = v
end

local function popFromStack()
    local g = stack[#stack]
    stack[#stack] = nil
    return g
end


local prevRegs = table.Copy(regs)
local function checkForRegChanges()
    --local diff = false
    for k, v in pairs(regs) do
        if prevRegs[k] ~= v then
            --diff = true
            print("DIFF; V0x" .. hex(k) .. ": " .. hex(v) .. ":" .. v .. "(prev " .. hex(prevRegs[k]) .. ":" .. prevRegs[k] .. ")")
        end
    end
    --if diff then
    --    debugPrintRegs()
    --end

    prevRegs = table.Copy(regs)
end




local function decTimers()
    if dtimer > 0 then
        dtimer = dtimer - 1
    end

    if stimer > 0 then
        if not sound_active then
            sound_active = true
            LocalPlayer():EmitSound(beep_sound)
        end
        stimer = stimer - 1
    elseif sound_active then
        sound_active = false
        LocalPlayer():StopSound(beep_sound)
    end
end


local function pushFontToMemory()
    for i = 0, 0xF do
        memory[i] = font[i]
    end
end

local function pushRomToMemory()
    for i = 0, ROM:Size() - 1 do
        local read = ROM:ReadByte()
        print("hex; " .. hex(read))
        memory[i + 0x200] = read
    end

    print("----mem dump----")
    PrintTable(memory)
end



local function drawScreen()
    if not screen_updated then
        return
    end

    render.PushRenderTarget(screenRT)
    cam.Start2D()
        for x = 0, 63 do
            for y = 0, 31 do
                local mul = (screen[x][y] and 1 or 0) * 255
                surface.SetDrawColor(mul, mul, mul, 255)
                surface.DrawRect(x, y, 1, 1)
            end
        end
    cam.End2D()
    render.PopRenderTarget()
    screen_updated = false
end


local opcode_descriptors = { -- debug descriptions
    [0x0] = "CLR or POP",
    [0x1] = "JMP",
    [0x2] = "CALL",
    [0x3] = "SE",
    [0x4] = "SNE",
    [0x5] = "SER",
    [0x6] = "MOV",
    [0x7] = "ADD",
    [0x8] = "MATH",
    [0x9] = "SNER",
    [0xA] = "MOV I",
    [0xB] = "JMP V0",
    [0xC] = "RND",
    [0xD] = "DRW",
    [0xE] = "KEY",
    [0xF] = "MANP",
}




local math_opcodes = {
    [0x0] = function(x, y)
        return math.floor(regs[y] or 0) % 256
    end,
    [0x1] = function(x, y)
        return bit.bor(regs[x], regs[y] or 0)
    end,
    [0x2] = function(x, y)
        return bit.band(regs[x], regs[y] or 0)
    end,
    [0x3] = function(x, y)
        return bit.bxor(regs[x], regs[y] or 0)
    end,
    [0x4] = function(x, y)
        local c = regs[x] + regs[y] or 0
        if c > 255 then
            regs[0xF] = 1
        else
            regs[0xF] = 0
        end

        return c
    end,
    [0x5] = function(x, y)
        local c = (regs[x] or 0) - (regs[y] or 0)

        if c < 0 then
            regs[0xF] = 0
        else
            regs[0xF] = 1
        end

        return c
    end,
    [0x6] = function(x, y)
        if legacy_shift then
            regs[x] = regs[y]
        end

        local preshft = regs[x]
        regs[0xF] = preshft > 0 and 1 or 0
        return bit.rshift(regs[x], 1)
    end,
    [0x7] = function(x, y)
        local c = regs[y] - regs[x]

        if c < 0 then
            regs[0xF] = 0
        else
            regs[0xF] = 1
        end

        return c
    end,
    [0xE] = function(x, y)
        if legacy_shift then
            regs[x] = regs[y]
        end

        local preshft = regs[x]
        regs[0xF] = preshft > 0 and 1 or 0
        return bit.lshift(regs[x], 1)
    end,
}

local opcode_calls = {
    [0x0] = function(x, y, n, nn, nnn)
        if n == 0xE0 then
            wipeScreen()
        elseif nn == 0xEE then
            pc = math.floor(popFromStack() or 0x200)
        end
    end,
    [0x1] = function(x, y, n, nn, nnn)
        pc = math.floor(nnn % 4097)
    end,
    [0x2] = function(x, y, n, nn, nnn)
        pushToStack(pc)
        pc = math.floor(nnn % 4097)
    end,
    [0x3] = function(x, y, n, nn, nnn)
        pc = (regs[x] == nn and pc + 2 or pc)
    end,
    [0x4] = function(x, y, n, nn, nnn)
        pc = (regs[x] ~= nn and pc + 2 or pc)
    end,
    [0x5] = function(x, y, n, nn, nnn)
        pc = (regs[x] == regs[y] and pc + 2 or pc)
    end,
    [0x6] = function(x, y, n, nn, nnn)
        regs[x] = math.floor(nn) % 256
    end,
    [0x7] = function(x, y, n, nn, nnn)
        regs[x] = (regs[x] + nn) % 256
    end,
    [0x8] = function(x, y, n, nn, nnn)
        print("math; " .. hex(n))
        regs[x] = math.floor(math_opcodes[n](x, y) % 256)
    end,
    [0x9] = function(x, y, n, nn, nnn)
        pc = math.floor(regs[x] ~= regs[y] and pc + 2 or pc)
    end,
    [0xA] = function(x, y, n, nn, nnn)
        regI = math.floor(nnn % 4097)
    end,
    [0xB] = function(x, y, n, nn, nnn)
        pc = math.floor((regs[0] + nnn) % 4097)
    end,
    [0xC] = function(x, y, n, nn, nnn)
        regs[x] = math.floor(bit.band(math.random(0, 255) % 256, nn))
    end,
    [0xD] = function(x, y, n, nn, nnn)
        regs[0xF] = 0
        local regx = doWrap and regs[x] % 64 or regs[x]
        local regy = doWrap and regs[y] % 32 or regs[y]

        for i = 0, n - 1 do
            local byte = memory[regI + i]

            for b = 0, 7 do
                local tb = 7 - b

                local bitg = bit.band(byte or 0, bit.lshift(1, tb))
                local valid = bitg > 0

                if valid then
                    local screenstate = screen[regx + b][regy + i]

                    screen[regx + b][regy + i] = not screenstate

                    regs[0xF] = screenstate and 1 or regs[0xF]
                end
            end

        end

        screen_updated = true
    end,
    [0xE] = function(x, y, n, nn, nnn)
        if nn == 0x9E then
            pc = (keyboard[regs[x]] > 0 and pc + 2 or pc)
        elseif nn == 0xA1 then
            pc = (keyboard[regs[x]] <= 0 and pc + 2 or pc)
        end
    end,
    [0xF] = function(x, y, n, nn, nnn)
        if nn == 0x07 then
            regs[x] = math.floor(dtimer % 256)
        elseif nn == 0x15 then
            dtimer = regs[x]
        elseif nn == 0x18 then
            stimer = regs[x]
        elseif nn == 0x1E then
            local c = regI + regs[x]
            regs[0xF] = c > 255 and 1 or 0
            regI = math.floor(c % 256)
        elseif nn == 0x0A then
            for k, v in pairs(keyboard) do
                if v >= 1 then
                    regs[x] = k
                    return
                end
            end

            pc = pc - 2
        elseif nn == 0x29 then
            regI = regs[x] * 5
        elseif nn == 0x33 then
            local num = regs[x]
            local d1 = math.floor(num / 100)
            local d2 = math.floor((num % 100) / 10)
            local d3 = math.floor(num % 10)

            memory[regI] = d1
            memory[regI + 1] = d2
            memory[regI + 2] = d3
        elseif nn == 0x55 then
            local itrs = math.Clamp(x, 0x0, 0xF)
            for i = 0, itrs do
                memory[regI + i] = regs[i] or 0
            end
        elseif nn == 0x65 then
            local itrs = math.Clamp(x, 0x0, 0xF)
            for i = 0, itrs do
                regs[i] = memory[regI + i] or 0
            end
        end
    end,
}




local function fetch()
    local opcodetop = memory[pc]
    local opcodebot = memory[pc + 1]

    local opcode = bit.lshift(opcodetop, 8) + opcodebot

    print("pc; " .. pc .. " opcode; " .. hex(opcode))
    pc = pc + 2
    return opcode
end

local function dump_nibble(nibble)
    print("NIBBLE; (" .. nibble .. ")[" .. hex(nibble) .. "]")
end

local function exec(opcode)
    local optype = bit.band(opcode, 0xF000)
    optype = bit.rshift(optype, 12)

    --dump_nibble(optype)

    local nibblex = bit.band(opcode, 0x0F00)
    nibblex = bit.rshift(nibblex, 8)
    --dump_nibble(nibblex)

    local nibbley = bit.band(opcode, 0x00F0)
    nibbley = bit.rshift(nibbley, 4)
    --dump_nibble(nibbley)

    local nibblen = bit.band(opcode, 0x000F)
    --dump_nibble(nibblen)

    local nibblenn = bit.band(opcode, 0x00FF)
    --dump_nibble(nibblenn)

    local nibblennn = bit.band(opcode, 0x0FFF)
    --dump_nibble(nibblennn)


    local fine, ret = pcall(opcode_calls[optype], nibblex % 256, nibbley % 256, nibblen % 16, nibblenn % 256, nibblennn % 4097)
    print(opcode_descriptors[optype])

    if not fine then
        print("error calling opcode; " .. hex(opcode))
        print("optype; " .. hex(optype))
        print("luaerror;")
        print(ret)
    end
end

wipeScreen()
pushFontToMemory()
pushRomToMemory()

hook.Add("HUDPaint", "Chip8Emu", function()
    if not active then
        return
    end
    updateKeyRegs()

    if nextDec < CurTime() then
        decTimers()
        nextDec = CurTime() + 1 / 60
    end


    if CurTime() < nextCall then
        return
    end
    local op = fetch()
    exec(op)
    drawScreen()

    checkForRegChanges()

    nextCall = CurTime() + (1 / ips)

    if regs[0x10] ~= nil then
        print("EMULATOR CRASHED!; invalid reg made")
        hook.Remove("HUDPaint", "Chip8Emu")
    end
end)



hook.Add("HUDPaint", "DrawChip8TL", function()
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(screenRTMat)
    surface.DrawTexturedRect(0, 0, 64 * 4, 32 * 4)

    for k, v in pairs(regs) do
        draw.SimpleText("[0x" .. hex(k) .. "]: " .. hex(v) .. "(" .. v .. ")", "BudgetLabel", ScrW() / 2, k * 16, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
    end
end)


concommand.Add("chip8_vismem", function()
    local frame = vgui.Create("DFrame")
    frame:SetSize(memdumpw + 96, memdumph + 24)
    frame:MakePopup()
    frame:SetTitle("Memory Viewer")
    frame:Center()

    local panelvw = vgui.Create("DPanel", frame)
    panelvw:SetSize(memdumpw + 96, memdumph)
    panelvw:SetPos(0, 24)

    function panelvw:Paint(w, h)
        for x = 0, (w - 96) / SzMul do
            for y = 0, h / SzMul do
                local memp = memory[x + y * (w / SzMul)] or 0

                surface.SetDrawColor(memp, memp, memp, 255)
                surface.DrawRect(x * SzMul, y * SzMul, SzMul, SzMul)
            end
        end


        surface.SetDrawColor(255, 0, 0, 200)

        local cx = pc % 64
        local cy = math.floor(pc / 64)
        surface.DrawRect(cx * SzMul, cy * SzMul, SzMul, SzMul)


        surface.SetDrawColor(0, 255, 0, 200)

        cx = regI % 64
        cy = math.floor(regI / 64)
        surface.DrawRect(cx * SzMul, cy * SzMul, SzMul, SzMul)

        for i = 0, 15 do
            draw.SimpleText("[0x" .. hex(i) .. "]:" .. hex(regs[i]) .. "(" .. regs[i] .. ")", "BudgetLabel", w - 94, i * 16, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
        end
    end
end)

concommand.Add("chip8_toggle", function()
    active = not active
    print("now; " .. (active and "On" or "Off"))
end)
