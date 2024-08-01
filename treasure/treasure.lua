file.CreateDir("lktools")


-- get the sound from trays github
-- thank you ArtificialBakingTrays

if not file.Exists("lktools/treasure.mp3", "DATA") then
    -- get from github
    http.Fetch("https://raw.githubusercontent.com/ArtificialBakingTrays/Music-Storage/main/treasure.mp3", function(body)
        -- success!!
        -- write us the file

        file.Write("lktools/treasure.mp3", body)
    end, function(err)
        print("LKTOOLS fail downloading treasure sound")
    end)
end

if not file.Exists("lktools/coin.png", "DATA") then
    -- Write coin
    local coin_mat = "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"
    file.Write("lktools/coin.png", util.Decompress(util.Base64Decode(coin_mat)))
end

local coinScale = 128 + 32
local _h_coinScale = coinScale * .5

local colHigh = 255
local colDark = 100

local meshCoin = Mesh()
mesh.Begin(meshCoin, MATERIAL_QUADS, 1)
    -- #-o
    -- | |
    -- o-o
    mesh.Position(Vector(-_h_coinScale, -_h_coinScale, 0))
    mesh.TexCoord(0, 0, 0)
    mesh.Color(colHigh, colHigh, colHigh, 255)
    mesh.AdvanceVertex()

    -- o-#
    -- | |
    -- o-o
    mesh.Position(Vector(_h_coinScale, -_h_coinScale, 0))
    mesh.TexCoord(0, 1, 0)
    mesh.Color(colHigh, colHigh, colHigh, 255)
    mesh.AdvanceVertex()

    -- o-o
    -- | |
    -- o-#
    mesh.Position(Vector(_h_coinScale, _h_coinScale, 0))
    mesh.TexCoord(0, 1, 1)
    mesh.Color(colDark, colDark, colDark, 255)
    mesh.AdvanceVertex()

    -- o-o
    -- | |
    -- #-o
    mesh.Position(Vector(-_h_coinScale, _h_coinScale, 0))
    mesh.TexCoord(0, 0, 1)
    mesh.Color(colDark, colDark, colDark, 255)
    mesh.AdvanceVertex()
mesh.End()


local function doSong()
    sound.PlayFile("data/lktools/treasure.mp3", "mono noblock", function(snd, errID, errName)
        if not snd then
            print("LKTOOLS treasure song play fail [" .. errID .. "] -> " .. errName)
            return
        end

        snd:SetVolume(4)
        snd:Play()
    end)

end


local matCoin = Material("../data/lktools/coin.png", "ignorez nocull smooth")

local spawnedCoins = {}
local function addCoin()
    spawnedCoins[#spawnedCoins + 1] = {
        vel = Vector(0, 1.5 + math.random() * 3),
        pos = Vector(math.random(0, ScrW() + _h_coinScale), -_h_coinScale),
        life = math.random() * 556.6544,
        realLife = 0,
        idx = math.random(0, 4096 * 16)
    }
end

local function updateCoins()
    local toRemove = {}
    for i = 1, #spawnedCoins do
        local coin = spawnedCoins[i]

        local velAddExpo = (coin.vel * FrameTime() * 96 * ((coin.realLife + 1) * 2))

        coin.pos = coin.pos + velAddExpo
        coin.life = coin.life + FrameTime()
        coin.realLife = coin.realLife + FrameTime()


        if coin.pos[2] > (ScrH() + coinScale) then
            toRemove[#toRemove + 1] = i
        end
    end

    if #toRemove <= 0 then
        return
    end

    for i = #toRemove, 1, -1 do
        local coinToRM = toRemove[i]

        table.remove(spawnedCoins, coinToRM)
    end
end


local debugWhite = Material("color/white")
local function renderCoinFX()
    local matrixCoins = Matrix()
    local angRot = Angle()

    render.SetMaterial(matCoin)
    --render.SetColorMaterial()
    for i = 1, #spawnedCoins do
        local coin = spawnedCoins[i]

        local pos = coin.pos
        local life = coin.life
        local idx = coin.idx

        --local bright = 200 + ((math.sin(idx) + 1) * 27.5)
        local rot = (life * 512) * math.sin(idx * .5235235)
        angRot.y = rot

        matrixCoins:SetTranslation(pos)
        matrixCoins:SetAngles(angRot)

        cam.PushModelMatrix(matrixCoins)
            meshCoin:Draw()
        cam.PopModelMatrix()

        --surface.SetDrawColor(bright, bright, bright)
        --surface.SetMaterial(matCoin)
        --surface.DrawTexturedRect(pos[1] - _h_coinScale, pos[2] - _h_coinScale, coinScale, coinScale, rot)
    end


    render.SetColorModulation(1, 1, 1)
end

local coinCurseActive = false
local coinCurseAddEnd = 0
local coinCurseAddCount = 0

local _nextAdd = 0
local function addCoins()
    if CurTime() > coinCurseAddEnd then
        return
    end

    if CurTime() < _nextAdd then
        return
    end

    _nextAdd = CurTime() + 0.1


    for i = 1, coinCurseAddCount do
        addCoin()
    end
end


hook.Add("Think", "LKTools_CoinThink", function()
    if not coinCurseActive then
        return
    end


    addCoins()
    updateCoins()
end)

hook.Add("DrawOverlay", "LKTools_CoinCurse", function()
    if not coinCurseActive then
        return
    end

    renderCoinFX()
end)


function TreasureSelfFast()
    coinCurseActive = true
    coinCurseAddEnd = CurTime() + 19
    coinCurseAddCount = 16

    doSong()
end
