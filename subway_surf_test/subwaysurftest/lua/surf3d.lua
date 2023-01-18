--[[
    SURF3D

    gmod lua textured 3d engine
    coded by lokachop @@ 01/07/2022
    contact at Lokachop#5862 or lokachop@gmail.com

    last updated: 05/07/2022
]]--

Surf3D = Surf3D or {}
Surf3D.Models = Surf3D.Models or {}

print("loading Surf3D!")

local function r_find(path, prepath)
    print("search; " .. path .. "/*")
    local files, folders = file.Find(path .. "/*",  "GAME")

    for k, v in pairs(files) do
        print("INCLUDE; " .. prepath .. "/" .. v)
        include(prepath .. "/" .. v)
    end

    for k, v in pairs(folders) do
        print("FOLDER; " .. path .. "/" .. v)
        print(v)
        r_find(path .. "/" .. v, v)
    end
end




local root_name = "subwaysurftest"
r_find("addons/" .. root_name .. "/lua/models", "models")


Surf3D.W = 256
Surf3D.H = 256
Surf3D.Debug = true
Surf3D.Wireframe = false
Surf3D.DoBackfaceCulling = true
Surf3D.FullBright = false
Surf3D.ForceGridTex = false
Surf3D.DoPosFuncs = false
Surf3D.DoUpdateWait = false
Surf3D.DoUpdatingTextures = true
Surf3D.UpdateWait = 0


Surf3D.RenderTarget = GetRenderTargetEx("surf3d_canvas_" .. Surf3D.W .. ":" .. Surf3D.H, Surf3D.W, Surf3D.H, RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_SEPARATE, bit.bor(1, 256), 0, IMAGE_FORMAT_ARGB8888)
Surf3D.RenderTargetMat = CreateMaterial("surf3d_canvas_mat", "UnlitGeneric", {
    ["$basetexture"] = Surf3D.RenderTarget:GetName()
})


Surf3D.CamPos = Vector(0, 0, -4)
Surf3D.CamAng = Angle(0, 0, 0)
Surf3D.CamMul = Vector(1, 1, 1)
Surf3D.RenderClearCol = Color(0, 0, 0, 255)
Surf3D.FogCol = Color(0, 0, 0, 255)
Surf3D.AmbientCol = Color(255, 255, 255, 255)
Surf3D.FogDist = 16

Surf3D.DoVertSnapping = true
Surf3D.VertSnappingVar = 1.5


local function lerpColour(t, a, b)
    return Color(
        Lerp(t, a.r, b.r),
        Lerp(t, a.g, b.g),
        Lerp(t, a.b, b.b),
        Lerp(t, a.a, b.a)
    )
end



function Surf3D.VertOffsetFunc(pos) return pos end


Surf3D.Textures = {}
Surf3D.TextureRTs = {}
Surf3D.TextureFuncs = {}
Surf3D.TextureSizes = {}
Surf3D.UpdatingTextures = {}
function Surf3D.CreateTex(name, w, h, func)
    local rt = GetRenderTargetEx(name, w, h, RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_SEPARATE, bit.bor(1, 256), 0, 19)
    local mat = CreateMaterial(name .. "_mat", "UnlitGeneric", {
        ["$basetexture"] = rt:GetName(),
        ["$nodecal"] = 1,
        ["$nocull"] = 1,
        ["$ignorez"] = 1,
        ["$vertexcolor"] = 1,
        ["$vertexalpha"] = 1
    })


    local c_scrw = ScrW()
    local c_scrh = ScrH()

    render.SetViewPort(0, 0, w, h)
    cam.Start2D()
    render.PushRenderTarget(rt)
        render.Clear(0, 0, 0, 0, true, true)
        pcall(func, w, h)
    render.PopRenderTarget()
    cam.End2D()
    render.SetViewPort(0, 0, c_scrw, c_scrh)


    Surf3D.Textures[name] = mat
    Surf3D.TextureRTs[name] = rt
    Surf3D.TextureFuncs[name] = func
    Surf3D.TextureSizes[name] = {w, h}
    return mat, rt
end

function Surf3D.SetUpdatingTex(name, updating)
    Surf3D.UpdatingTextures[name] = updating
end

hook.Add("HUDPaint", "Surf3D_UpdatingTextures", function()
    if Surf3D.DoUpdatingTextures then
        local c_scrw = ScrW()
        local c_scrh = ScrH()

        for k, v in pairs(Surf3D.UpdatingTextures) do
            if not v then
                continue
            end
            local w, h = Surf3D.TextureSizes[k][1], Surf3D.TextureSizes[k][2]
            render.SetViewPort(0, 0, w, h)
            cam.Start2D()
            render.PushRenderTarget(Surf3D.TextureRTs[k])
                pcall(Surf3D.TextureFuncs[k], w, h)
            render.PopRenderTarget()
            cam.End2D()
            render.SetViewPort(0, 0, c_scrw, c_scrh)
        end
    end
end)



function Surf3D.Tex2DFriendly(w, h, matsrc)
    local mat = CreateMaterial(matsrc .. "_2dfriendly", "UnlitGeneric", {
        ["$basetexture"] = matsrc,
        ["$nodecal"] = 1,
        ["$nocull"] = 1,
        ["$ignorez"] = 1,
        ["$vertexcolor"] = 1,
        ["$vertexalpha"] = 1
    })
    return mat
end




function Surf3D.CreateTexFromSourceMat(name, w, h, matsrc, alpha)
    local mat = CreateMaterial(name .. "_mat", "UnlitGeneric", {
        ["$basetexture"] = matsrc,
        ["$nodecal"] = 1,
        ["$nocull"] = 1,
        ["$ignorez"] = 1,
        ["$vertexcolor"] = 1,
        ["$vertexalpha"] = alpha and 1 or 0
    })

    Surf3D.Textures[name] = mat
    return mat
end

Surf3D.Textures["grid"] = Material("gui/alpha_grid.png", "nocull ignorez noclamp")




Surf3D.Scene = {}
function Surf3D.AddToScene(id, mdl)
    Surf3D.Scene[id] = {
        model = mdl,
        pos = Vector(0, 0, 0),
        ang = Angle(0, 0, 0),
        scale = Vector(1, 1, 1),
        texture = "grid",
        ignorecull = false
    }
end

function Surf3D.SetPos(id, pos)
    Surf3D.Scene[id].pos = pos
end

function Surf3D.SetAng(id, ang)
    Surf3D.Scene[id].ang = ang
end

function Surf3D.SetScale(id, scale)
    Surf3D.Scene[id].scale = scale
end

function Surf3D.SetIgnoreCull(id, ignorecull)
    Surf3D.Scene[id].ignorecull = ignorecull
end

function Surf3D.SetTexture(id, texture)
    Surf3D.Scene[id].texture = texture
end

function Surf3D.HookToPanel(panel)
    function panel:Paint(w, h)
    end
end


function Surf3D.WorldToCam(pos)
    return -pos
end

function Surf3D.TransformCamera(vec)
    vec = vec * Surf3D.CamMul
    vec = vec + Surf3D.CamPos

    vec:Rotate(Angle(Surf3D.CamAng.p, 0, 0))
    vec:Rotate(Angle(0, Surf3D.CamAng.y, 0))
    vec:Rotate(Angle(0, 0, Surf3D.CamAng.r))
    return vec
end


Surf3D.CamFar = 100000
Surf3D.CamNear = 0.1

function Surf3D.ProjectToScreen(vec)
    if Surf3D.DoVertSnapping then
        vec[1] = math.Round(vec[1], Surf3D.VertSnappingVar)
        vec[2] = math.Round(vec[2], Surf3D.VertSnappingVar)
        vec[3] = math.Round(vec[3], Surf3D.VertSnappingVar)
    end

    local z = vec[3]

    local xc = ((Surf3D.W / 2) * (vec[1] / z)) + Surf3D.W / 2
    local yc = ((Surf3D.H / 2) * (vec[2] / z)) + Surf3D.H / 2

    return xc, yc
end

--models/flesh

local function t_tri(x1, y1, u1, v1, x2, y2, u2, v2, x3, y3, u3, v3)
    if Surf3D.Wireframe then
        surface.DrawLine(x1, y1, x2, y2)
        surface.DrawLine(x2, y2, x3, y3)
        surface.DrawLine(x3, y3, x1, y1)
        return
    end

    local tri = {
        {x = x1, y = y1, u = u1, v = v1},
        {x = x2, y = y2, u = u2, v = v2},
        {x = x3, y = y3, u = u3, v = v3}
    }

    surface.DrawPoly(tri)
end


Surf3D.PreRenderFunc = function()
end


-- sets prerender before drawing geometry (aka background)
function Surf3D.PreRender(func)
    Surf3D.PreRenderFunc = func
end

local l_update = 0
local l_frametime = SysTime()

-- call with a 2d rendering context
function Surf3D.RenderScene()
    if Surf3D.DoUpdateWait then
        if l_update > SysTime() then
            return
        end

        if Surf3D.UpdateWait then
            l_update = SysTime() + Surf3D.UpdateWait
        end
    end

    local transformedTris = {}
    local vcount = 0

    for k, v in pairs(Surf3D.Scene) do
        local transformedPoints = {}
        local verts = Surf3D.Models[v.model].Verts
        local uvs = Surf3D.Models[v.model].UVs
        local tris = Surf3D.Models[v.model].Indices

        for k2, v2 in ipairs(verts) do
            local v2c = Vector(v2[1], v2[2], v2[3])
            v2c:Rotate(v.ang)
            v2c = v2c * v.scale
            v2c = v2c + v.pos


            transformedPoints[#transformedPoints + 1] = v2c
            vcount = vcount + 1
        end

        for ke2, ve2 in ipairs(tris) do
            local vec1 = transformedPoints[ve2[1][1]]
            local vec2 = transformedPoints[ve2[2][1]]
            local vec3 = transformedPoints[ve2[3][1]]


            vec1 = Surf3D.TransformCamera(vec1)
            vec2 = Surf3D.TransformCamera(vec2)
            vec3 = Surf3D.TransformCamera(vec3)

            if vec1.z > 0.01 or vec2.z > 0.01 or vec3.z > 0.01 then
                continue
            end
            if Surf3D.DoPosFuncs then
                vec1 = Surf3D.VertOffsetFunc(vec1)
                vec2 = Surf3D.VertOffsetFunc(vec2)
                vec3 = Surf3D.VertOffsetFunc(vec3)
            end

            if Surf3D.DoBackfaceCulling and not v.ignorecull then
                local norm = (vec2 - vec1):Cross(vec3 - vec1)
                norm:Normalize()

                local ndot = norm:Dot(Vector(0, 0, 1))

                if ndot < 0 then
                    continue
                end
            end
            --vec1 = Surf3D.ClipVertex(vec1)
            --vec2 = Surf3D.ClipVertex(vec2)
            --vec3 = Surf3D.ClipVertex(vec3)

            local px1, py1 = Surf3D.ProjectToScreen(vec1)
            local px2, py2 = Surf3D.ProjectToScreen(vec2)
            local px3, py3 = Surf3D.ProjectToScreen(vec3)

            local uv1 = uvs[ve2[1][2]]
            local uv2 = uvs[ve2[2][2]]
            local uv3 = uvs[ve2[3][2]]

            local x1 = px1
            local y1 = py1
            local u1 = uv1[1]
            local v1 = math.abs(1 - uv1[2])

            local x2 = px2
            local y2 = py2
            local u2 = uv2[1]
            local v2 = math.abs(1 - uv2[2])

            local x3 = px3
            local y3 = py3
            local u3 = uv3[1]
            local v3 = math.abs(1 - uv3[2])

            local az = (vec1.z + vec2.z + vec3.z) / 3

            transformedTris[#transformedTris + 1] = {x1, y1, u1, v1, x2, y2, u2, v2, x3, y3, u3, v3, z = az, w = az, tex = v.texture}
            if not Surf3D.FullBright then
                local azc = math.abs(az / Surf3D.FogDist)
                local t_col = lerpColour(azc, Surf3D.AmbientCol, Surf3D.FogCol)
                transformedTris[#transformedTris].col = t_col
            end

            if Surf3D.ForceGridTex then
                transformedTris[#transformedTris].tex = "grid"
            end
        end


    end

    table.sort(transformedTris, function(a, b)
        return a.z < b.z
    end)

    local c_scrw = ScrW()
    local c_scrh = ScrH()

    render.SetViewPort(0, 0, Surf3D.W, Surf3D.H)
    render.PushRenderTarget(Surf3D.RenderTarget)
    cam.Start2D()
        render.Clear(Surf3D.RenderClearCol.r, Surf3D.RenderClearCol.g, Surf3D.RenderClearCol.b, Surf3D.RenderClearCol.a)

        draw.NoTexture()
        pcall(Surf3D.PreRenderFunc, Surf3D.W, Surf3D.H)


        draw.NoTexture()
        for k, v in ipairs(transformedTris) do
            if not Surf3D.FullBright then
                surface.SetDrawColor(v.col)
            end
            surface.SetMaterial(Surf3D.Textures[v.tex])
            --    x  |  y  |  u  |  v
            t_tri(
                v[1], v[2], v[3], v[4],
                v[5], v[6], v[7], v[8],
                v[9], v[10], v[11], v[12]
            )
        end

        if Surf3D.Debug then
            draw.SimpleText("Tri Count: " .. #transformedTris, "DebugFixed", 0, 0, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("Vert Count: " .. vcount, "DebugFixed", 0, 14, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("Frametime: " .. math.Round(SysTime() - l_frametime, 4) .. "ms", "DebugFixed", 0, 28, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("FPS: " .. math.floor(1 / (SysTime() - l_frametime)) .. "[CAP " ..  1 / Surf3D.UpdateWait .. "]", "DebugFixed", 0, 42, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

            draw.SimpleText("Objects: " .. table.Count(Surf3D.Scene), "DebugFixed", 0, 56, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

            draw.SimpleText(
                "Pos: " .. math.Round(Surf3D.CamPos.x, 2) .. ", " .. math.Round(Surf3D.CamPos.y, 2) .. ", " .. math.Round(Surf3D.CamPos.z, 2),
                "DebugFixed", 0, 70, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
            )

            draw.SimpleText(
                "Ang: " .. math.Round(Surf3D.CamAng.p, 2) .. ", " .. math.Round(Surf3D.CamAng.y, 2) .. ", " .. math.Round(Surf3D.CamAng.r, 2),
                "DebugFixed", 0, 84, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
            )

            l_frametime = SysTime()
        end
    cam.End2D()
    render.PopRenderTarget()
    render.SetViewPort(0, 0, c_scrw, c_scrh)
end


-- call with 2d rendering context
-- renders the actual RT to the rendering context
function Surf3D.RenderCanvas(x, y, w, h)
    surface.SetMaterial(Surf3D.RenderTargetMat)
    surface.DrawTexturedRect(x, y, w, h)
end


-- call with 2d rendering context
-- dumps all textures to a 2d rendering context
function Surf3D.DumpTextures(ox, oy, rows, columns, sx, sy, spacing, dotext)
    spacing = spacing or 8
    local tox = ox - spacing
    local toy = oy - spacing

    local t_curr = 0
    for k, v in pairs(Surf3D.Textures) do
        local oxc = ((t_curr % columns) * (sx + spacing))
        local oyc = (math.floor(t_curr / columns) * (sy + spacing))

        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(v)
        surface.DrawTexturedRect(tox + oxc, toy + oyc, sx, sy)

        if dotext then
            draw.SimpleText(k, "BudgetLabel", tox + oxc, toy + oyc, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        t_curr = t_curr + 1
    end
end



--include("surf3d-audio.lua")