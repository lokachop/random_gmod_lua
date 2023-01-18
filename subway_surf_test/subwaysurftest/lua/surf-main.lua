LSCT = LSCT or {}
LSCT.Gritty = true

LSCT.TPrefix = LSCT.Gritty and "_g" or "_o"

include("surf3d.lua")
include("surfplayer.lua")

Surf3D.RenderClearCol = Color(60, 74, 52, 255)
Surf3D.FogCol = Color(60, 74, 52, 255)
Surf3D.DoPosFuncs = true

Surf3D.DoUpdateWait = true
Surf3D.UpdateWait = 1 / 60
Surf3D.Wireframe = false

function Surf3D.VertOffsetFunc(v)
    --return v + Vector(0, 0, math.sin(v.z / 2) * 2)
    return v + Vector(0, -((v.z / 10) ^ 2), 0)

    --return v
end

local f_sky = Surf3D.Tex2DFriendly(64, 64, "composite/buildingset056a")
Surf3D.PreRender(function(w, h)
    local ang = Surf3D.CamAng

    local arcy = (-ang.r * 2.666666) + 64 + 24
    local arcx = -ang.p / 90

    surface.SetDrawColor(60 * 0.50, 74 * 0.50, 52 * 0.50)
    surface.DrawRect(0, arcy + (h / 2.5), w, h * 2)


    local div = 8
    local wdiv = w / div
    local ssize = 1 / wdiv -- needed so it dont look like shit
    local emul = 32

    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(f_sky)

    for i = 0, wdiv do
        local delta = i / wdiv


        local mdelta = -math.sin(math.pi * delta)


        surface.DrawTexturedRectUV(i * div, arcy - (mdelta * (emul / 2)), div, (h / 2) + mdelta * emul, delta + arcx, 0, delta + arcx + ssize, 1)
    end
end)








local f_trainh = Surf3D.Tex2DFriendly(64, 64, "vehicle/metaltrain001a")
local f_trainh2 = Surf3D.Tex2DFriendly(64, 64, "vehicle/metaltrain001c")
Surf3D.CreateTex("train_tex_g", 64, 64, function(w, h)
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(f_trainh)
    surface.DrawTexturedRect(w / 4, h / 4, w, h)

    surface.SetMaterial(f_trainh2)
    surface.DrawTexturedRect(w / 4, 0, w, h / 4)

    surface.SetDrawColor(255, 255, 0)
    surface.DrawRect(0, 0, w / 4, h / 2)

    surface.SetDrawColor(45, 100, 255)
    surface.DrawRect(0, h / 2, w / 4, h / 2)


    for i = 1, 4 do
        surface.SetDrawColor(45 - i * 16, 100 - i * 16, 255)
        surface.DrawRect(i * (w / 20), h / 2, w / 18, h / 2)
    end
end)

Surf3D.CreateTex("train_tex_o", 64, 64, function(w, h)
    surface.SetDrawColor(150, 150, 150)
    surface.DrawRect(w / 4, h / 4, w, h)

    surface.SetDrawColor(50, 50, 50)
    surface.DrawRect(w / 4, 0, w, h / 4)

    surface.SetDrawColor(255, 255, 0)
    surface.DrawRect(0, 0, w / 4, h / 2)

    surface.SetDrawColor(45, 100, 255)
    surface.DrawRect(0, h / 2, w / 4, h / 2)

    for i = 1, 4 do
        surface.SetDrawColor(45 - i * 16, 100 - i * 16, 255)
        surface.DrawRect(i * (w / 20), h / 2, w / 18, h / 2)
    end
end)



Surf3D.CreateTex("ply_tex", 64, 64, function(w, h)
    surface.SetDrawColor(0, 119, 255)
    surface.DrawRect(0, 0, w, h / 4)

    surface.SetDrawColor(92, 92, 92)
    surface.DrawRect(0, h / 4, w, h / 4)

    surface.SetDrawColor(58, 58, 58)
    surface.DrawRect(w / 2, h / 4, w / 2, h / 4)

    surface.SetDrawColor(164, 255, 155)
    surface.DrawRect(0, (h / 4) * 2, w, h / 4)

    surface.SetDrawColor(241, 194, 125)
    surface.DrawRect(0, (h / 4) * 3, w, h / 4)
end)


Surf3D.CreateTex("stopper_tex", 64, 64, function(w, h)
    surface.SetDrawColor(225, 50, 50)
    surface.DrawRect(0, 0, w, h / 4)

    surface.SetDrawColor(225, 225, 225)
    surface.DrawRect(0, h / 4, w, h / 4)

    surface.SetDrawColor(225, 50, 50)
    surface.DrawRect(0, (h / 4) * 2, w, h / 4)

    surface.SetDrawColor(150, 111, 51)
    surface.DrawRect(0, (h / 4) * 3, w, h / 4)
end)


local f_tile = Surf3D.Tex2DFriendly(64, 64, "concrete/concretefloor028c")
local f_rock = Surf3D.Tex2DFriendly(64, 64, "concrete/concretefloor008b")
local f_track = Surf3D.Tex2DFriendly(64, 64, "wood/woodtrack001a")

Surf3D.CreateTex("track_tex_g", 64, 64, function(w, h)
    surface.SetDrawColor(0, 0, 0)
    surface.DrawRect(0, 0, w, h)

    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(f_tile)
    surface.DrawTexturedRectUV(0, 0, w / 2, h, 0, 0, 1, 2)

    surface.SetMaterial(f_rock)
    surface.DrawTexturedRectUV(w / 2, 0, w / 2, h, 0, 0, 1, 2)

    surface.SetMaterial(f_track)
    surface.DrawTexturedRectUV(w / 2 + (w / 16), 0, w / 2 - (w / 8), h, 0, 0, 1, 2)
end)


Surf3D.CreateTex("track_tex_o", 64, 64, function(w, h)
    surface.SetDrawColor(0, 0, 0)
    surface.DrawRect(0, 0, w, h)

    surface.SetDrawColor(128, 128, 128)
    surface.DrawRect(0, 0, w / 2, h)
    surface.SetDrawColor(32, 32, 32)
    surface.DrawOutlinedRect(0, 0, w / 2, h)


    surface.SetDrawColor(131,101,57)
    surface.DrawRect(w / 2, 0, w / 2, h)

    surface.SetDrawColor(54, 38, 27)

    for i = 0, h / 8 do
        surface.DrawRect((w / 2) + w / 32, (i * 8) + 2, (w / 2) - w / 16, 4)
    end
end)


Surf3D.CreateTex("rainbow", 64, 64, function()
    local div = 1

    for i = 0, 64 / div do
        surface.SetDrawColor(HSVToColor((i / (64 / div)) * 360 + (CurTime() * 256), 1, 1))
        surface.DrawRect(i * div, 0, div, 64)
    end
end)

Surf3D.SetUpdatingTex("rainbow", true)

Surf3D.CreateTexFromSourceMat("source-test2", 64, 64, "console/background02", false)
Surf3D.CreateTexFromSourceMat("flesh_tex", 64, 64, "models/flesh", false)
Surf3D.CreateTexFromSourceMat("breen_tex", 64, 64, "models/breen/breen_face", false)

Surf3D.AddToScene("cube1", "cube")
Surf3D.SetPos("cube1", Vector(0, 5, 0))
Surf3D.SetTexture("cube1", "rainbow")


Surf3D.AddToScene("train2", "train")
Surf3D.SetPos("train2", Vector(5, 0, 0))
Surf3D.SetTexture("train2", "train_tex" .. LSCT.TPrefix)

Surf3D.AddToScene("train4", "train")
Surf3D.SetPos("train4", Vector(5 - 2, 0, 0))
Surf3D.SetTexture("train4", "train_tex" .. LSCT.TPrefix)

Surf3D.AddToScene("cube1", "cube")
Surf3D.SetPos("cube1", Vector(0, 5, 0))
Surf3D.SetTexture("cube1", "rainbow")

Surf3D.AddToScene("player1", "player")
Surf3D.SetIgnoreCull("player1", true)
Surf3D.SetPos("player1", Vector(0, 0, -5))
Surf3D.SetScale("player1", Vector(0.35, 0.35, 0.35))
Surf3D.SetTexture("player1", "ply_tex")


for i = 1, 3 do
    Surf3D.AddToScene("track" .. i, "track")
    Surf3D.SetPos("track" .. i, Vector(5, -1, -40 + (i * 20)))
    Surf3D.SetTexture("track" .. i, "track_tex" .. LSCT.TPrefix)
    Surf3D.SetIgnoreCull("track" .. i, true)
end


hook.Add("HUDPaint", "SURF3D_RenderTest", function()
    Surf3D.RenderScene()

    surface.SetDrawColor(255, 255, 255)
    Surf3D.RenderCanvas(128, 128, 512, 512)

    -- for debug
    Surf3D.DumpTextures(ScrW() - (512 + 128), 64, 8, 4, 128, 128, 32, true)
end)

hook.Add("Think", "UpdateSceneTest", function()
    Surf3D.SetAng("cube1", Angle(CurTime() * 32, CurTime() * 16, 0))
    Surf3D.SetPos("train2", Vector(5, 0, -20 + ((CurTime() % 4) * 6)))


    Surf3D.SetPos("train4", Vector(5 - 2, 0, (CurTime() % 16) * 2))

    local e = LocalPlayer():EyePos()
    local a = LocalPlayer():EyeAngles()

    Surf3D.CamAng = Angle(a.y, a.r, a.p)
    Surf3D.CamPos = Vector(-e.y / 128, -e.z / 128, e.x / 128)

    --Surf3D.CamAng = Angle(0, 0, 25)
    --Surf3D.CamPos = Vector(-5 + (math.sin(CurTime() * 2) * 2), -4, -30 + (CurTime() % 8) * 4)
end)
