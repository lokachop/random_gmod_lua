local CachedModels = {}
local CachedMats = {}
local FBrightMats = {}
local CachedRTs = {}
local texScale = 256
local fround = 0.0000000001
local uvround = 16
local lod = 1
local devMat = Material("gui/alpha_grid.png")
local ColourUVMatTable = {}
local DoVertColourAndMat = false

function captureMat(mat)
    if CachedMats[mat] == nil then
        print("captturing mat: " .. mat)

        local matData = {
            ["$basetexture"] = mat,
            ["$nodecal"] = 1,
            ["$model"] = 1,
            ["$nocull"] = 1
        }

        FBrightMats[mat] = CreateMaterial("SZ_" .. texScale .. "_LKCLONE_" .. mat, "UnlitGeneric", matData)
        FBrightMats[mat]:SetInt("$flags", bit.bor(FBrightMats[mat]:GetInt("$flags"), 32768))
        FBrightMats[mat]:Recompute()
        CachedRTs[mat] = GetRenderTargetEx("RTRenderOverride_" .. mat .. "_" .. texScale, texScale, texScale, RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_SEPARATE, bit.bor(2, 256), 1, IMAGE_FORMAT_BGRA8888)
        render.PushRenderTarget(CachedRTs[mat])
        cam.Start2D()
        surface.SetDrawColor(64, 64, 64, 32)
        surface.SetMaterial(FBrightMats[mat])
        surface.DrawTexturedRect(0, 0, texScale, texScale)
        cam.End2D()
        render.CapturePixels()
        render.PopRenderTarget()

        CachedMats[mat] = CreateMaterial("RTRenderOverrideMat_" .. mat .. "_" .. texScale .. LocalPlayer():Name(), "UnlitGeneric", {
            ["$basetexture"] = CachedRTs[mat]:GetName(),
            ["$model"] = 1
        })

        ColourUVMatTable[mat] = {}

        for x = 0, texScale do
            ColourUVMatTable[mat][x] = {}

            for y = 0, texScale do
                local r, g, b = render.ReadPixel(x % texScale, y % texScale)

                ColourUVMatTable[mat][x][y] = {
                    [1] = r,
                    [2] = g,
                    [3] = b
                }
            end
        end
    end

    return CachedMats[mat]
end

function getUVColourOffMat(mat, u, v)
    if CachedMats[mat] == nil then
        captureMat(mat)
    end

    local ucalc = math.floor(u * texScale)
    local vcalc = math.floor(v * texScale)

    return ColourUVMatTable[mat][ucalc % texScale][vcalc % texScale]
end

function getVerticesOffEnt(ent)
    if CachedModels[ent:GetModel()] == nil then
        print("caching model: " .. ent:GetModel())
        local tablCopy = {}
        local tabl = util.GetModelMeshes(ent:GetModel(), lod, 8)

        for k, v in pairs(tabl[1]["triangles"]) do
            tablCopy[k] = {
                pos = v["pos"],
                u = v["u"],
                v = v["v"],
                normal = v["normal"]
            }
        end

        CachedModels[ent:GetModel()] = tablCopy
    end

    return CachedModels[ent:GetModel()]
end

hook.Add("Think", "LokaMeshRenderOverrideThink", function() end) --[[
	for k, v in pairs(CachedRTs) do
		render.PushRenderTarget(CachedRTs[k])
		cam.Start2D()
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(FBrightMats[k])
			surface.DrawTexturedRect(0, 0, texScale, texScale)

			local col = HSVToColor(CurTime() * 32, 1, 1)
			local r = col.r
			local g = col.g
			local b = col.b

			surface.SetDrawColor(r, g, b, 255)

			local px = ((math.sin(CurTime()) + 1) / 2) * texScale
			local py = ((math.cos(CurTime() * 1.36) + 1) / 2) * texScale
			surface.DrawRect(px, py, 32, 32)
		cam.End2D()
		render.PopRenderTarget()
	end

	]] --

hook.Add("PostDrawOpaqueRenderables", "RenderMeshOverride", function()
    for k, v in pairs(ents.GetAll()) do
        if v:GetClass() == "prop_physics" then
            v:SetRenderMode(RENDERMODE_TRANSCOLOR)
            v:SetColor(Color(255, 255, 255, 0))
            local vertData = getVerticesOffEnt(v)
            local materialName = v:GetMaterials()[1]
            local mat = captureMat(materialName)

            if DoVertColourAndMat == true then
                render.SetColorMaterial()
            else
                render.SetMaterial(mat)
            end

            --render.SetColorModulation(1, 1, 1)
            if #vertData >= 32767 then
                print("TOO MANY VERTS: RETURNING!")

                return
            end

            mesh.Begin(MATERIAL_TRIANGLES, #vertData)

            for i = 1, #vertData do
                local pcalc = Vector(vertData[i].pos[1], vertData[i].pos[2], vertData[i].pos[3])
                pcalc:Rotate(v:GetAngles())
                local posFullCalc = pcalc + v:GetPos()
                posFullCalc[1] = math.Round(posFullCalc[1], fround)
                posFullCalc[2] = math.Round(posFullCalc[2], fround)
                posFullCalc[3] = math.Round(posFullCalc[3], fround)
                local uRound = math.Round(vertData[i].u, uvround)
                local vRound = math.Round(vertData[i].v, uvround)

                if DoVertColourAndMat == true then
                    local br, bg, bb = render.GetLightColor(posFullCalc):Unpack()
                    local rgbtab = getUVColourOffMat(materialName, uRound, vRound)
                    local r = rgbtab[1] * math.Clamp(br, 0.25, 1)
                    local g = rgbtab[2] * math.Clamp(bg, 0.25, 1)
                    local b = rgbtab[3] * math.Clamp(bb, 0.25, 1)
                    mesh.Color(r, g, b, 255)
                end

                local normRot = Vector(vertData[i].normal[1], vertData[i].normal[2], vertData[i].normal[3])
                normRot:Rotate(v:GetAngles())
                mesh.Position(posFullCalc)
                mesh.TexCoord(0, uRound, vRound)
                mesh.Normal(normRot)
                mesh.AdvanceVertex()
            end

            mesh.End()
        end
    end
end)
