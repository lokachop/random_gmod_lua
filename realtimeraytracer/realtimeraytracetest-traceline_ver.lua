local ply = LocalPlayer()
local w = ScrW()
local h = ScrH()
local resDiv = 16

local wDiv = w / resDiv
local hDiv = h / resDiv

local tracesPerThink = 512 * 1.5
local FOV = LocalPlayer():GetFOV() * 0.97
local SunDir = Vector(-0.4, 0.4, 0.8)


local CurrReflect = 0





----------CONFIG----------
local DoRenderUpdateGraph = true -- graph that shows renders per second over time

local DoAO = false -- fake ambient occlusion, very laggy but cool
local DoExpensiveAO = false -- uses a super expensive ao table (6 traces for cheap, 26 traces for expensive)
local AOBrightMult = 1.5 -- higher = darker ao

local DoSkyBoxTraces = true -- trace into skyboxes too, make sure you get your map's skybox in the table

local MaxReflects = 2 -- max. number of reflections to render

local LUTSize = 64 -- 64 x 64 textures, higher leadds to exponentially more mem usage

local WorldDrawFlat = true -- draw the world as the average colour of x texture, not actual texture, slightly faster as it lets the renderer skip more pixels
----------------------------







local AOtr = {
	Vector(0, 1, 0),
	Vector(0, -1, 0),
	Vector(1, 0, 0),
	Vector(-1, 0, 0),
	Vector(0, 0, 1),
	Vector(0, 0, -1)
}

local AOtrExp = {
	[1] = Vector(1, 0, 0),
	[2] = Vector(-1, 0, 0),
	[3] = Vector(1, 1, 0),
	[4] = Vector(1, -1, 0),
	[5] = Vector(-1, -1, 0),
	[6] = Vector(-1, 1, 0),
	[7] = Vector(0, 1, 0),
	[8] = Vector(0, -1, 0),
	[9] = Vector(0, 1, 1),
	[10] = Vector(0, -1, 1),
	[11] = Vector(0, -1, -1),
	[12] = Vector(0, 1, -1),
	[13] = Vector(0, 0, 1),
	[14] = Vector(0, 0, -1),
	[15] = Vector(1, 0, 1),
	[16] = Vector(1, 0, -1),
	[17] = Vector(-1, 0, 1),
	[18] = Vector(-1, 0, -1),
	[19] = Vector(1, 1, 1),
	[20] = Vector(1, 1, -1),
	[21] = Vector(1, -1, 1),
	[22] = Vector(1, -1, -1),
	[23] = Vector(-1, 1, 1),
	[24] = Vector(-1, 1, -1),
	[25] = Vector(-1, -1, 1),
	[26] = Vector(-1, -1, -1)
}


local TgtAO = DoExpensiveAO and AOtrExp or AOtr

local AOL = 24
local stdv = (255 * AOBrightMult) / #TgtAO


local function RefreshAOConf()
	TgtAO = DoExpensiveAO and AOtrExp or AOtr
	stdv = (255 * AOBrightMult) / #TgtAO
end







concommand.Add("realtime_raytrace_toggle", function()
	RealtimeRaytraceActive = not RealtimeRaytraceActive
	print("Realtime raytracing is now; " .. (RealtimeRaytraceActive and "on" or "off"))
end)


concommand.Add("realtime_raytrace_ao_toggle", function()
	DoAO = not DoAO
	print("AO is now; " .. (DoAO and "on" or "off"))
end)

concommand.Add("realtime_raytrace_ao_toggleexp", function()
	DoExpensiveAO = not DoExpensiveAO
	RefreshAOConf()
	print("AO dirtable is now; " .. (DoExpensiveAO and "expensive" or "cheap"))
end)

concommand.Add("realtime_raytrace_skybox_toggletraces", function()
	DoSkyBoxTraces = not DoSkyBoxTraces
	print("Skybox traces are now; " .. (DoSkyBoxTraces and "on" or "off"))
end)

concommand.Add("realtime_raytrace_toggledrawflat", function()
	WorldDrawFlat = not WorldDrawFlat
	print("flat world texturing is now now; " .. (WorldDrawFlat and "on" or "off"))
end)





-- use lua_run print(ents.FindByClass("sky_camera")[1]:GetPos())
-- OR local pos = ents.FindByClass("sky_camera")[1]:GetPos() print("[\"" .. game.GetMap() .. "\"] = Vector(" .. pos.x .. ", " .. pos.y .. ", " .. pos.z .. ")")

local skyPosTable = {
	["gm_construct"] = Vector(-1428.000000, 1645.000000, 10991.200195),
	["gm_bigcity"] = Vector(0, 0.00048828098806553, 5112),
	["gm_bluehills_test3"] = Vector(9216, 9216, 14250.5)
}
local skyPos = skyPosTable[game.GetMap() or Vector(0, 0, 0)]


local HasSky = false


RealtimeRaytraceActive = RealtimeRaytraceActive or true

local CurrX, CurrY


local rtRender = GetRenderTarget("LokaRealtimeRaytrace_W" .. w .. "_H" .. h .. "_RD" .. resDiv, w, h)
local rtRenderMaterial = CreateMaterial("LokaRealtimeRaytrace_W" .. w .. "_H" .. h .. "_RD" .. resDiv .. "_MAT", "UnlitGeneric",
	{
		["$basetexture"] = rtRender:GetName()
	})


ResFwrdTbl = {}
ResFwrdTbl[resDiv] = ResFwrdTbl[resDiv] or {}
ValidTraces = {}

ColTable = ColTable or {}
ColTable[resDiv] = {}

for x = 0, wDiv do
	ColTable[resDiv][x] = {}
end

local Frame = 0


local SkippedDrawCalls = 0
local CalcSkippedDrawCalls = 0

local AvgPixels = 0
local CalcAvgPixels = 0

local DrawnPixels = 0
local CalcDrawnPixels = 0



local UpdateCalc = 0
local UpdateTable = {}
local PrevSec = math.floor(CurTime())
local UpdateAvg = 0
local UpdateChecks = 15




MatTable = {}
MatLUTTable = {}
MatAverageTable = {}
local MatCaptureRT = GetRenderTarget("LokaRealTimeRTCapture", LUTSize, LUTSize)




local math_abs = math.abs
local math_random = math.random
local util_TraceLine = util.TraceLine
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local render_ReadPixel = render.ReadPixel




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
	if MatTable[mat] == nil then
		print("Building FBMaterial for " .. mat)
		local matData = {
			["$basetexture"] = mat,
			["$nodecal"] = 1,
			["$model"] = 1,
			["$nocull"] = 1,
			["$vertexcolor"] = 1
		}


		MatTable[mat] = CreateMaterial("LKRCC_" .. mat, "UnlitGeneric", matData)

		MatTable[mat].SetInt(MatTable[mat], "$flags", bit.bor(MatTable[mat]:GetInt("$flags"), 32768))
		MatTable[mat].Recompute(MatTable[mat])


		-- from adv. material stool, idk where the github is though
		if (MatTable[mat].GetString(MatTable[mat], "$basetexture") ~= mat) then
			local m = Material(mat)
			MatTable[mat].SetTexture(MatTable[mat], "$basetexture", m.GetTexture(m, "$basetexture"))
		end

	end

	return MatTable[mat]
end


local function BuildMaterialLUT(mat)
	if MatTable[mat] == nil then
		GetFBMaterial(mat)
	end

	if MatLUTTable[mat] ~= nil then
		return
	end

	print("Building LUT for " .. mat)
	render.PushRenderTarget(MatCaptureRT)
		cam.Start2D()
			surface_SetDrawColor(255, 255, 255)
			surface.SetMaterial(MatTable[mat])
			surface.DrawTexturedRect(0, 0, LUTSize, LUTSize)
		cam.End2D()
		render.CapturePixels()
	render.PopRenderTarget()



	MatLUTTable[mat] = {}
	for x = 0, LUTSize do
		MatLUTTable[mat][x] = {}
		for y = 0, LUTSize do
			local r, g, b = render_ReadPixel(x % LUTSize, y % LUTSize)
			MatLUTTable[mat][x][y] = {r, g, b}
		end
	end

end


function GetMaterialAverageCol(mat)
	if MatTable[mat] == nil then
		GetFBMaterial(mat)
	end

	if MatAverageTable[mat] ~= nil then
		return MatAverageTable[mat][1], MatAverageTable[mat][2], MatAverageTable[mat][3]
	end


	print("Building average for " .. mat)
	render.PushRenderTarget(MatCaptureRT)
		cam.Start2D()
			surface_SetDrawColor(255, 255, 255)
			surface.SetMaterial(MatTable[mat])
			surface.DrawTexturedRect(0, 0, LUTSize, LUTSize)
		cam.End2D()
		render.CapturePixels()
	render.PopRenderTarget()


	local avg = Vector(0, 0, 0)
	local cnt = 0

	for x = 0, LUTSize do
		for y = 0, LUTSize do
			local r, g, b = render_ReadPixel(x % LUTSize, y % LUTSize)
			avg = avg + Vector(r, g, b)
			cnt = cnt + 1
		end
	end

	avg = avg / cnt
	MatAverageTable[mat] = {avg[1], avg[2], avg[3]}

	return MatAverageTable[mat][1], MatAverageTable[mat][2], MatAverageTable[mat][3]
end


local function GetPixelColour(mat, x, y)
	if MatLUTTable[mat] == nil then
		BuildMaterialLUT(mat)
	end

	return MatLUTTable[mat][math.floor(x) % LUTSize][math.floor(y) % LUTSize]
end



local function RefreshValidTraces()
	print("refreshing traces; F:" .. Frame)
	Frame = Frame + 1
	CalcSkippedDrawCalls = SkippedDrawCalls
	SkippedDrawCalls = 0

	CalcAvgPixels = AvgPixels
	AvgPixels = 0

	CalcDrawnPixels = DrawnPixels
	DrawnPixels = 0

	UpdateCalc = UpdateCalc + 1
	if math.floor(CurTime()) ~= PrevSec then
		table.insert(UpdateTable, 1, UpdateCalc)
		local Total = 0
		for k, v in ipairs(UpdateTable) do
			UpdateAvg = UpdateAvg + v
			Total = Total + 1
		end

		UpdateAvg = UpdateAvg / Total
		UpdateCalc = 0
		PrevSec = math.floor(CurTime())
	end

	UpdateTable[UpdateChecks] = nil

	for y = 0, hDiv do
		for x = 0, wDiv do

			if (((x + y % 2) + (Frame % 2)) % 2) ~= 1 then -- checkerboarding
				table.insert(ValidTraces, {x, y})
			end
		end
	end
end

RefreshValidTraces()

local function reflect(I, N) -- Reflects an incidence vector I about the normal N -- from https://github.com/Derpius/VisTrace/blob/master/Examples/StarfallEx/vistrace_laser.txt
	return I - 2 * N.Dot(N, I) * N
end

local function getDir(tr)
	return (tr.HitPos - tr.StartPos):GetNormalized()
end

local function fresnel(tr)
	local dot = getDir(tr):Dot(tr.HitNormal)
	local fnorm = (1 - math_abs(dot))
	return fnorm
end

local function mix(...)
	args = {...}
	local r, g, b = 0, 0, 0
	local total = 0

	for i = 1, #args, 3 do
		r = r + args[i]
		g = g + args[i + 1]
		b = b + args[i + 2]
		total = total + 1
	end

	return r / total, g / total, b / total
end

local bayer = {
	{0,  8,  2, 10},
	{12,  4, 14,  6},
	{3, 11,  1,  9},
	{15,  7, 13,  5},
}



local function dither(r, g, b, x, y)
	local intensity = (r / 255 + g / 255 + b / 255) / 3
	local rx = (x % 4) + 1
	local ry = (y % 4) + 1
	local threshold = bayer[rx][ry]

	local sub = math_abs(1 - intensity) * 8
	local finr = r - sub
	local fing = g - sub
	local finb = b - sub


	if (intensity * 16) > threshold then
		finr = r
		fing = g
		finb = b
	end


	return finr, fing, finb
end


local function GetRandomValidTrace()
	if #ValidTraces <= 0 then
		RefreshValidTraces()
	end

	local k = math_random(#ValidTraces)
	local tbl = ValidTraces[k]
	local x, y = tbl[1], tbl[2]
	table.remove(ValidTraces, k)

	return x, y
end


-- from https://www.youtube.com/watch?v=YSOBCp2mito
local function calculateForward()

	if ResFwrdTbl[resDiv] == nil then
		ResFwrdTbl[resDiv] = {}
	end

	if ResFwrdTbl[resDiv][0] ~= nil then
		return
	end

	print("calculating forward table for resDiv " .. resDiv .. "...")

	for y = 0, hDiv do
		ResFwrdTbl[resDiv][y] = {}
		for x = 0, wDiv do
			local coeff = math.tan((FOV / 2) * (3.1416 / 180)) * 2.71828;
			ResFwrdTbl[resDiv][y][x] = Vector(
				1,
				((wDiv - x) / (wDiv - 1) - 0.5) * coeff,
				(coeff / wDiv) * (hDiv - y) - 0.5 * (coeff / wDiv) * (hDiv - 1)
			):GetNormalized()
		end
	end
end

calculateForward()

local function CalcColCopy()
end



local function shadeSky(tr, x, y)
	if not HasSky and DoSkyBoxTraces then
		HasSky = true

		local pos = skyPos + (tr.HitPos / 16)
		local newTrace = util_TraceLine({
			start = pos,
			endpos = pos + getDir(tr) * 1000000
		})


		return CalcColCopy(newTrace)
	end

	local dir = getDir(tr)
	local d1 = dir.Dot(dir, Vector(0, 0, 1))
	local d2 = dir.Dot(dir, Vector(0, 0, -1))

	local sdc = dir.Dot(dir, SunDir)

	if sdc < 0.97 then
		sdc = 0
	end

	local fsuncolr = sdc / 2
	local fsuncolg = sdc / 2

	local fd = (math.max(d1, d2))

	local fcolr = (fd / 2) + fsuncolr
	local fcolg = (fd / 2) + fsuncolg
	local fcolb = fd

	return dither(fcolr * 255, fcolg * 255, fcolb * 255, x, y)
end


local function CheckForShadows(tr)
	local trNew = util_TraceLine({
		start = tr.HitPos,
		endpos = tr.HitPos + (SunDir * 1000000)
	})


	return not trNew.HitSky
end

--[[
local function GetLighting(tr)

end
]]--


local function GetReflection(tr)
	CurrReflect = CurrReflect + 1

	if CurrReflect > MaxReflects then
		CurrReflect = 0
		return 0, 0, 0
	end

	local dir = getDir(tr)
	local refl = reflect(dir, tr.HitNormal)
	local trNew = util_TraceLine({
		start = tr.HitPos,
		endpos = tr.HitPos + (refl * 1000000)
	})


	CurrReflect = 0
	local rt, gt, bt = CalcColCopy(trNew)
	local rc, gc, bc = tr.Entity:GetColor():Unpack()
	return mix(rt, gt, bt, rc, gc, bc)
end



local ShaderTable = {
	["debug/env_cubemap_model"] = function(tr)
		return GetReflection(tr)
	end,
	["models/shiny"] = function(tr)
		local rr, rg, rb = GetReflection(tr)
		local er, eg, eb = tr.Entity:GetColor():Unpack()
		local fresnelr = fresnel(tr)

		local r = ((er * math_abs(1 - fresnelr)) + (rr * fresnelr)) / 2
		local g = ((eg * math_abs(1 - fresnelr)) + (rg * fresnelr)) / 2
		local b = ((eb * math_abs(1 - fresnelr)) + (rb * fresnelr)) / 2

		return r, g, b
	end,
	["models/screenspace"] = function(tr)
		local rr, rg, rb = GetReflection(tr)
		local er, eg, eb = tr.Entity:GetColor():Unpack()
		local fresnelr = fresnel(tr)

		local r = ((rr * math_abs(1 - fresnelr)) + (er * fresnelr)) / 2
		local g = ((rg * math_abs(1 - fresnelr)) + (eg * fresnelr)) / 2
		local b = ((rb * math_abs(1 - fresnelr)) + (eb * fresnelr)) / 2

		return r, g, b
	end,
	["models/props_combine/tprings_globe"] = function(tr)
		local er, eg, eb = tr.Entity:GetColor():Unpack()
		local fresnelr = fresnel(tr)

		local r = er * fresnelr
		local g = eg * fresnelr
		local b = eb * fresnelr

		return r, g, b
	end,
}


local function BadAO(tr)
	local fs = 255


	for i = 1, #TgtAO do
		local trAO = util_TraceLine({
			start = tr.HitPos + tr.HitNormal * .5,
			endpos = (tr.HitPos + tr.HitNormal * .5) + TgtAO[i] * AOL
		})

		fs = fs - (math_abs(1 - trAO.Fraction) * stdv)
	end

	return fs / 255
end


local function CalcEntCol(tr)
	local albr, albg, albb = GetMaterialAverageCol(tr.Entity:GetMaterials()[1])


	-- props are quite dark so lets brighten up
	albr = albr * 1.5
	albg = albg * 1.5
	albb = albb * 1.5


	local r, g, b = tr.Entity:GetColor():Unpack()

	local dc = math.Clamp(tr.HitNormal:Dot(SunDir), 0.5, 1)

	r = albr * (r / 255)
	g = albg * (g / 255)
	b = albb * (b / 255)


	r = r * dc
	g = g * dc
	b = b * dc

	return r, g, b

end


local function CalcCol(tr)
	local shadowed = CheckForShadows(tr)


	local r, g, b


	if IsValid(tr.Entity) and ShaderTable[tr.Entity:GetMaterial()] ~= nil then
		local fine
		fine, r, g, b = pcall(ShaderTable[tr.Entity:GetMaterial()], tr)

		if not fine then
			print("Error with shader \"" .. tr.Entity:GetMaterial() .. "\"!; " .. r)
			r, g, b = 0, 0, 0
		end
	elseif IsValid(tr.Entity) then
		r, g, b = CalcEntCol(tr)
	elseif tr.HitSky then
		r, g, b = shadeSky(tr, CurrX, CurrY)
	else

		if tr.HitTexture ~= "**displacement**" then
			local col = {}
			if not WorldDrawFlat then
				local hpos = tr.HitPos
				hpos = hpos / 2

				local udir = tr.HitNormal:Angle():Right()
				local u = (hpos * udir):Length()

				local vdir = tr.HitNormal:Angle():Up()
				local v = (hpos * vdir):Length()

				col = GetPixelColour(parseMapTex(tr.HitTexture), u, v)
			else
				local rf, gf, bf = GetMaterialAverageCol(parseMapTex(tr.HitTexture))
				col = {rf, gf, bf}
			end

			r, g, b = col[1] or 0, col[2] or 0, col[3] or 0
		else
			r = (tr.HitNormal[1] + 1) * 128
			g = (tr.HitNormal[2] + 1) * 128
			b = (tr.HitNormal[3] + 1) * 128
		end
	end



	--local licol = render.GetLightColor(tr.HitPos)
	--r = r * (licol[1] + 0.1) --shadowed
	--g = g * (licol[2] + 0.1) --shadowed
	--b = b * (licol[3] + 0.1) --shadowed

	if shadowed and (not tr.HitSky) then
		if DoAO then
			local ao = BadAO(tr)
			r = r * ao
			g = g * ao
			b = b * ao
		end

		r = r * 0.5
		g = g * 0.5
		b = b * 0.5
	end


	return r, g, b
end


CalcColCopy = CalcCol


local function hashColour(r, g, b)
	return math.Clamp(math.floor(r), 0, 255) + math.Clamp(math.floor(g), 0, 255) * 256 + math.Clamp(math.floor(b), 0, 255) * 65536
end

local function deHashColour(hash)
	return math.floor(hash) % 256, math.floor(hash / 256) % 256, math.floor(hash / 65536) % 256
end

local function Raytrace(x, y)
	CurrX = x
	CurrY = y

	if ((x + y % 2) + (Frame % 2) % 2) == 1 then --x % SkipModulo == 0 and y % SkipModulo == 0 then
		return 0, 0, 0
	end

	--print("RAYTRACE; ", x, y)
	local dir = Vector(ResFwrdTbl[resDiv][y][x][1], ResFwrdTbl[resDiv][y][x][2], ResFwrdTbl[resDiv][y][x][3])
	dir:Rotate(LocalPlayer():EyeAngles())

	-- needed for realtime

	local tr = util_TraceLine({
		start = ply:EyePos(),
		endpos = ply:EyePos() + (dir * 1000000),
		filter = ply
	})

	return CalcCol(tr)
end


hook.Add("Think", "RealtimeRaytraceLoka", function()
	if not RealtimeRaytraceActive then
		return
	end

	cam.Start2D()
		render.PushRenderTarget(rtRender)
		for i = 1, tracesPerThink do
			local x, y = GetRandomValidTrace()
			local r, g, b = Raytrace(x, y)
			HasSky = false
			--r, g, b = dither(r, g, b, x, y)

			if ColTable[resDiv][x][y] ~= hashColour(r, g, b) then
				if r == 512 then
					r = 0
					local total = 0
					for x2 = -1, 1 do
						for y2 = -1, 1 do
							total = total + 1
							local dr, dg, db = deHashColour((ColTable[resDiv][x + x2] or {})[y + y2] or 0)
							r = r + dr
							g = g + dg
							b = b + db
						end
					end

					r = r / total
					g = g / total
					b = b / total
					AvgPixels = AvgPixels + 1
				end

				--local rd, gd, bd = dither(r, g, b, x, y)

				surface_SetDrawColor(r, g, b, 255)
				surface_DrawRect(x * resDiv, y * resDiv, resDiv, resDiv)
				DrawnPixels = DrawnPixels + 1

				ColTable[resDiv][x][y] = hashColour(r, g, b) -- skip drawing the same thing, just compress the colours and check if its the same!
			else
				SkippedDrawCalls = SkippedDrawCalls + 1
			end
		end
		render.PopRenderTarget()
	cam.End2D()


end)



hook.Add("HUDPaint", "RenderRealtimeRaytraceLoka", function()
	if not RealtimeRaytraceActive then
		return
	end

	surface_SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(rtRenderMaterial)
	surface.DrawTexturedRect(0, 0, w, h)

	draw.SimpleText("Skipped pixels: " .. CalcSkippedDrawCalls .. "px" .. " (out of "  .. (wDiv * hDiv) - CalcAvgPixels .. "px)", "BudgetLabel", ScrW() / 2, 0, Color(0, 255, 0), TEXT_ALIGN_CENTER)
	draw.SimpleText("Averaged pixels: " .. CalcAvgPixels .. "px", "BudgetLabel", ScrW() / 2, 16, Color(0, 255, 0), TEXT_ALIGN_CENTER)
	draw.SimpleText("Drawn pixels: " .. CalcDrawnPixels .. "px", "BudgetLabel", ScrW() / 2, 32, Color(0, 255, 0), TEXT_ALIGN_CENTER)
	draw.SimpleText("Updates per second: " .. UpdateAvg, "BudgetLabel", ScrW() / 2, 48, Color(0, 255, 0), TEXT_ALIGN_CENTER)
	draw.SimpleText("Current frame: " .. Frame, "BudgetLabel", ScrW() / 2, 64, Color(0, 255, 0), TEXT_ALIGN_CENTER)


	if DoRenderUpdateGraph then
		local Start = ScrW()
		local HeiStart = ScrH() * 0.55

		for i = 1, #UpdateTable do
			local dpos = Start - i * 32


			local dposnext = Start - (i + 1) * 32

			local currVal = UpdateTable[i]
			local nextVal = UpdateTable[i + 1] or UpdateTable[i]

			surface_SetDrawColor(255, 128, 0)
			surface.DrawLine(dpos, HeiStart - currVal * 16, dposnext, HeiStart - nextVal * 16)

			surface_SetDrawColor(64, 64, 255)
			surface.DrawLine(dpos, HeiStart, dposnext, HeiStart)

			draw.SimpleText(currVal, "BudgetLabel", dpos, HeiStart - currVal * 16, Color(255, 128, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end
	end
end)

