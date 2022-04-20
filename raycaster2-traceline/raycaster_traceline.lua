--[[
	raycaster_traceline.lua

	another dumb raycaster by lokachop, this time using traceLine to make it fast, also textured too
]]--

LkRc = {}

LkRc.CamPos = LocalPlayer():EyePos()
LkRc.CamDir = LocalPlayer():EyeAngles():Forward()

LkRc.ResDiv = ScrW() / 240 -- ensure all screensizes use same traces
LkRc.FOV = LocalPlayer():GetFOV() * 1

LkRc.WallHeight = 128


LkRc.DivW = ScrW() / LkRc.ResDiv
LkRc.DivWH = LkRc.DivW / 2


LkRc.MatTable = LkRc.MatTable or {}




local function parseMapTex(mat)

	local smat = mat
	if string.sub(smat, 0, 4) == "maps" then
		smat = string.gsub(mat, "_[?%-%d]+_[?%-%d]+_[?%-%d]+$", "") -- horrid but needed
	end
	if smat ~= nil then
		smat = string.gsub(smat, "maps%b//", "")
	end

	return smat
end


-- get a fullbright texture that doesnt fuck up when rendering to screen
local function GetFBMaterial(mat)
	if LkRc.MatTable[mat] == nil then
		print("Capturing material " .. mat)
		local matData = {
			["$basetexture"] = mat,
			["$nodecal"] = 1,
			["$model"] = 1,
			["$nocull"] = 1,
			["$vertexcolor"] = 1,
		}


		LkRc.MatTable[mat] = CreateMaterial("LKRCC_" .. mat, "UnlitGeneric", matData)

		LkRc.MatTable[mat].SetInt(LkRc.MatTable[mat], "$flags", bit.bor(LkRc.MatTable[mat]:GetInt("$flags"), 32768))
		LkRc.MatTable[mat].Recompute(LkRc.MatTable[mat])


		if (LkRc.MatTable[mat].GetString(LkRc.MatTable[mat], "$basetexture") ~= mat) then
			local m = Material(mat)
			LkRc.MatTable[mat].SetTexture(LkRc.MatTable[mat], "$basetexture", m.GetTexture(m, "$basetexture"))
		end

	end

	return LkRc.MatTable[mat]

end


LkRc.SkyMat = GetFBMaterial("composite/buildingset056a")

function LkRc.RaycastAtDir(dir)
	local tr = util.TraceLine({
		start = LkRc.CamPos,
		endpos = LkRc.CamPos + dir * 10000,
		filter = LocalPlayer()
	})

	return tr
end

function LkRc.GetCorrectedDist(relative, tr)
	local distrcorrect = math.cos(math.rad(relative * LkRc.FOV))
	local dcalc = tr.StartPos:Distance(tr.HitPos) / 2
	dcalc = dcalc + (distrcorrect * dcalc / 8)

	return dcalc
end



hook.Add("HUDPaint", "LkRcRaycast", function()
	LkRc.CamPos = LocalPlayer():EyePos()
	LkRc.CamDir = LocalPlayer():EyeAngles():Forward()

	draw.NoTexture()
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, ScrH() / 2, ScrW(), ScrH() / 2)


	surface.SetTexture(surface.GetTextureID("gui/gradient_up"))
	surface.SetDrawColor(64, 64, 64, 255)
	surface.DrawTexturedRect(0, ScrH() / 2, ScrW(), ScrH() / 2)

	surface.SetMaterial(LkRc.SkyMat)
	surface.SetDrawColor(255, 255, 255, 255)

	local dir = ((LkRc.CamDir:Angle()[2] + 180) * (ScrW() / 90)) % ScrW()
	local wdiv = ScrW()



	surface.DrawTexturedRectUV(dir, 0, ScrW(), ScrH() / 2, 0, 0, 1, 1)
	surface.DrawTexturedRectUV(dir + wdiv, 0, ScrW(), ScrH() / 2, 0, 0, 1, 1)
	surface.DrawTexturedRectUV(dir - wdiv, 0, ScrW(), ScrH() / 2, 0, 0, 1, 1)

	surface.SetTexture(surface.GetTextureID("gui/gradient_up"))
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawTexturedRect(0, 0, ScrW(), ScrH() / 2)



	for i = 0, LkRc.DivW do
		local relative = (i - LkRc.DivWH) / LkRc.DivWH

		local dircpy = Vector(LkRc.CamDir[1], LkRc.CamDir[2], 0) -- do this to copy vector so :Rotate() doesnt break it
		dircpy:Rotate(Angle(0, -relative * (LkRc.FOV / 2), 0))

		local tr = LkRc.RaycastAtDir(dircpy)
		local dcalc = LkRc.GetCorrectedDist(relative, tr)



		local wh = ((LkRc.WallHeight * (ScrH() / 2)) / dcalc)

		local lcol = math.Clamp(tr.HitNormal:Dot(Vector(.25, .75, 0)), .2, 1) * 255

		local coldcalc = math.Clamp(dcalc / 256, 1, 1000)

		surface.SetDrawColor(lcol / coldcalc, lcol / coldcalc, lcol / coldcalc)


		local hpos = tr.HitPos
		hpos = hpos / 128

		local uang = tr.HitNormal:Angle():Right()
		local fx = (hpos * uang):Length() % 2

		surface.SetMaterial(GetFBMaterial(parseMapTex(tr.HitTexture)))
		surface.DrawTexturedRectUV(i * LkRc.ResDiv, (ScrH() / 2) - (wh / 2), LkRc.ResDiv, wh,
			fx, 0,
			fx + LkRc.ResDiv / 4096, 1
		)
	end
end)
