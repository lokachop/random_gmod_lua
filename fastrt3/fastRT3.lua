--[[
	fastRT3.lua

	Fast R T 3
		 a r
		 y a
		   c
		   e
		   r

	coded by lokachop 
	contact at Lokachop#5862 or lokachop@gmail.com

	very ""fast"" pure glua raytracer, uses direction table calculation func by mee (Mee#9971)
	use for anything really, do try to credit though
]]--

local o3_opt = {"-fold", "-cse", "-dce", "-loop", "-fwd", "-dse", "-abc", "-sink", "-fuse"}
--local misc_opt = {"maxrecord=8000", "maxtrace=2000", "maxirconst=1000", "hotloop=6", "hotexit=22", "sizemcode=128"}
--jit.opt.start(unpack(misc_opt), unpack(o3_opt))
jit.opt.start(unpack(o3_opt))
collectgarbage("setstepmul", 40) -- fixes over-agressive garbage collector lagspikes
local prev_wait = collectgarbage("setpause", 280)
print("PREVIOUS WAIT; " .. prev_wait)
local resDiv = 12
local itrPerTick = 512 * 3
local texSz = 32

local FOV = 90
local benchMark = true
local sunDir = Vector(3, 2, 5)
sunDir:Normalize()



local ply = LocalPlayer()
local active = true

local math = math
local math_floor = math.floor
local math_tan = math.tan
local math_random = math.random
local math_abs = math.abs
local math_min = math.min
local math_max = math.max
local math_exp = math.exp
local math_Clamp = math.Clamp
local math_pow = math.pow
local math_Round = math.Round

local util = util
local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull

local render = render
local render_SetViewPort = render.SetViewPort
local render_Clear = render.Clear
local render_PushRenderTarget = render.PushRenderTarget
local render_PopRenderTarget = render.PopRenderTarget
local render_CapturePixels = render.CapturePixels
local render_ReadPixel = render.ReadPixel
local render_PushFilterMin = render.PushFilterMin
local render_PushFilterMag = render.PushFilterMag
local render_PopFilterMag = render.PopFilterMag
local render_PopFilterMin = render.PopFilterMin

local string = string
local string_sub = string.sub
local string_gsub = string.gsub

local table = table
local table_remove = table.remove

local surface = surface
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect

local Material = Material
local CreateMaterial = CreateMaterial




local wDiv, hDiv = math_floor(ScrW() / resDiv), math_floor(ScrH() / resDiv)
local muDiv = math_floor(wDiv * hDiv)

local pxW, pxH = math_floor(ScrW() / wDiv), math_floor(ScrH() / hDiv)


local ao_ch_scl = 5
local norm_dec = 2
local fr_ao_count = 0
local max_fr_ao = (wDiv + hDiv) / 2
local do_ao_expire = false
local ao_expire = 4 -- age


local doTex = false


local DirTable = {}
-- from https://www.youtube.com/watch?v=YSOBCp2mito
local function calculateForward()
	local start
	if benchMark then
		start = SysTime()
	end


	for y = 0, hDiv do
		DirTable[y] = {}
		for x = 0, wDiv do
			local coeff = math_tan((FOV / 2) * (3.1416 / 180)) * 2.71828;
			DirTable[y][x] = Vector(
				1,
				((wDiv - x) / (wDiv - 1) - 0.5) * coeff,
				(coeff / wDiv) * (hDiv - y) - 0.5 * (coeff / wDiv) * (hDiv - 1)
			):GetNormalized()
		end
	end

	if benchMark then
		print("it took us " .. (SysTime() - start) * 1000 .. "ms to calc the forward table ")
	end
end
calculateForward()


local function megaCollect()
	local pre
	if benchMark then
		pre = collectgarbage("count")
	end

	for i = 1, 5 do
		collectgarbage("collect")
	end

	print("collected " .. math_floor((pre - collectgarbage("count")) / 1024) .. "mb of garbage!")
end
megaCollect()


local function reflect(I, N) -- Reflects an incidence vector I about the normal N -- from https://github.com/Derpius/VisTrace/blob/master/Examples/StarfallEx/vistrace_laser.txt
	return I - 2 * N.Dot(N, I) * N
end



local pointsToTrace = {}
local totalPoints = 0
local function reCalcPointsToTrace()
	local start
	if benchMark then
		start = SysTime()
	end

	pointsToTrace = {}
	totalPoints = 0

	local takenRandoms = {}
	for i = 1, muDiv + 1 do
		takenRandoms[i] = i
	end

	for i = 0, muDiv do
		local rindex = math_random(1, #takenRandoms)
		pointsToTrace[#pointsToTrace + 1] = takenRandoms[rindex]
		totalPoints = totalPoints + 1
		table_remove(takenRandoms, rindex)
	end

	if benchMark then
		print("it took us " .. (SysTime() - start) * 1000 .. "ms to get " .. totalPoints .. " random points")
	end
end
reCalcPointsToTrace()

local frame = 0
local function nextFrame()
	frame = frame + 1
	fr_ao_count = 0
	--reCalcPointsToTrace()
end

local intern_rtrace_id = 1
local function getRandomTrace()
	local tid = pointsToTrace[intern_rtrace_id]
	intern_rtrace_id = intern_rtrace_id + 1

	if intern_rtrace_id > totalPoints then
		intern_rtrace_id = 1
		nextFrame()
	end

	return tid % wDiv, math_floor(tid / wDiv)
end








local fbTextures = {}
local function mapSafeTex(tex)
	local stex = tex
	if string_sub(tex, 0, 4) == "maps" then
		stex = string_gsub(tex, "_[?%-%d]+_[?%-%d]+_[?%-%d]+$", "") -- horrid but needed
	end
	if stex ~= nil then
		stex = string_gsub(stex, "maps%b//", "")
	end
	return stex
end

local function fbTex(mat)
	local safe = mapSafeTex(mat)
	if fbTextures[safe] then
		return fbTextures[safe]
	end


	local smat = CreateMaterial(safe .. "_fb", "UnlitGeneric", {
		["$basetexture"] = safe,
		["$nodecal"] = 1,
		["$model"] = 1,
		["$nocull"] = 1,
		["$vertexcolor"] = 1
	})


	-- from adv. material stool, idk where the github is though
	if (smat.GetString(smat, "$basetexture") ~= safe) then
		local m = Material(mat)
		smat.SetTexture(smat, "$basetexture", m.GetTexture(m, "$basetexture"))
	end

	fbTextures[safe] = smat
	return fbTextures[safe]
end


local textureAverages = {}
local texturePixels = {}
local rtCapturePx = GetRenderTarget("fastRT3_rtcapt_" .. texSz, texSz, texSz)
local rtCapturePxMat = CreateMaterial("lrrt3_rtcap_" .. texSz .. texSz, "UnlitGeneric", {
	["$basetexture"] = rtCapturePx:GetName()
})


local function calcPxls(tex)
	local safeName = mapSafeTex(tex)
	local mat = fbTex(tex)
	local start
	if benchMark then
		start = SysTime()
	end

	texturePixels[safeName] = {}
	textureAverages[safeName] = {0, 0, 0}


	local ow, oh = ScrW(), ScrH()
	render_SetViewPort(0, 0, texSz, texSz)
	render_PushRenderTarget(rtCapturePx)
		render_Clear(0, 0, 0, 255)
		render_PushFilterMin(TEXFILTER.POINT)
		render_PushFilterMag(TEXFILTER.POINT)
		surface_SetDrawColor(255, 255, 255, 255)
		surface_SetMaterial(mat)
		surface_DrawTexturedRect(-1, 1, 2, -2)
		render_PopFilterMag()
		render_PopFilterMin()

		render_CapturePixels()
		local ar, ag, ab = 0, 0, 0
		local totitr = texSz * texSz
		for i = 0, totitr - 1 do
			local x = i % texSz
			local y = math_floor(i / texSz)

			local r, g, b = render_ReadPixel(x, y)
			ar = ar + r
			ag = ag + g
			ab = ab + b
			texturePixels[safeName][i] = {r, g, b}
		end
		ar = math_floor(ar / totitr)
		ag = math_floor(ag / totitr)
		ab = math_floor(ab / totitr)

		textureAverages[safeName] = {ar, ag, ab}
	render_PopRenderTarget()
	render_SetViewPort(0, 0, ow, oh)


	if benchMark then
		print("it took us " .. (SysTime() - start) * 1000 .. "ms to get the pixels for " .. safeName)
	end
end

local function getAverage(tex)
	local safeName = mapSafeTex(tex)
	if not textureAverages[safeName] then
		calcPxls(tex)
	end

	return textureAverages[safeName]
end

local function getPx(tex, x, y)
	--return {x % 255, y % 255, 0}

	local safeName = mapSafeTex(tex)
	if not textureAverages[safeName] then
		calcPxls(tex)
	end

	return texturePixels[safeName][math_floor(x % texSz) + (math_floor(y % texSz) * texSz)]
end





local function benchmarkTraces()
	if not benchMark then
		return
	end

	local start = SysTime()
	for i = 1, muDiv do
		local _ = getRandomTrace()
	end

	print("it took us " .. (SysTime() - start) * 1000 .. "ms to get " .. muDiv .. " random traces")
end
benchmarkTraces()

local rtRender = GetRenderTarget("lrrt3_target_" .. wDiv .. hDiv, ScrW(), ScrH())
local rtMat = CreateMaterial("lrrt3_mat_" .. wDiv .. hDiv, "UnlitGeneric", {
	["$basetexture"] = rtRender:GetName()
})


local function getDir(tr)
	return (tr.HitPos - tr.StartPos):GetNormalized()
end

local c_top = {8, 16, 64}
local c_bot = {8, 80, 196}
local c_sun = {255, 245, 100}


local function calcSky(tr)
	local dir = getDir(tr)




	local ns = math.random(-3, 0)
	local rc, gc, bc = Lerp(dir[3], c_bot[1], c_top[1]) + ns, Lerp(dir[3], c_bot[2], c_top[2]) + ns, Lerp(dir[3], c_bot[3], c_top[3]) + ns

	local sd = dir:Dot(sunDir)
	if sd > .9975 then
		local res = (sd - .9975) * 500
		return Lerp(res, rc, c_sun[1]), Lerp(res, gc, c_sun[2]), Lerp(res, bc, c_sun[3])
	end

	return rc, gc, bc
end

-- https://github.com/shff/opengl_sky


local function v_n(n)
	return Vector(n, n, n)
end
local function v_pow(v1, v2)
	return Vector(math_pow(v1[1], v2[1]), math_pow(v1[2], v2[2]), math_pow(v1[3], v2[3]))
end

local function v_exp(v)
	return Vector(math_exp(v[1]), math_exp(v[2]), math_exp(v[3]))
end

local function v_cl(v)
	return Vector(math_Clamp(v[1], 0, 255), math_Clamp(v[2], 0, 255), math_Clamp(v[3], 0, 255))
end

local Br = 0.0025
local Bm = 0.0003
local sk_g =  0.9800
local nitrogen = Vector(0.650, 0.570, 0.475)
local Kr = Br / v_pow(nitrogen, v_n(4.0))
local Km = Bm / v_pow(nitrogen, v_n(0.84))

local function calcSkyExp(tr)
	local dir = getDir(tr)
	local y = dir[3]
	local sy = sunDir[3]
	if y < 0 then
		return 64, 64, 64
	end

	local mu = dir:Dot(sunDir)
	local rayleigh = (3 / (8 * 3.14) * (1 + mu * mu))
	local mie = (Kr + Km * (1.0 - sk_g * sk_g) / (2.0 + sk_g * sk_g) / math_pow(1.0 + sk_g * sk_g - 2.0 * sk_g * mu, 1.5)) / (Br + Bm)
	local day_extinction = v_exp(-math_exp(-((y + sy * 4.0) * (math_exp(-y * 16.0) + 0.1) / 80.0) / Br) * (math_exp(-y * 16.0) + 0.1) * Kr / Br) * math_exp(-y * math_exp(-y * 8.0 ) * 4.0) * math_exp(-y * 2.0) * 4.0



	local night_extinction = v_n(1.0 - math_exp(sy)) * 0.2
	local extinction = Lerp(-sy * 0.2 + 0.2, day_extinction, night_extinction)

	local fc = v_cl(rayleigh * mie * -extinction)
	return fc[3], fc[2], fc[1]
end

local ao_ch = {}
local ao_age = {}
local ao_mdist = 15
local ao_itr = 4
local ao_st_delta = 1 / ((ao_itr * ao_itr) - 1)
local ao_itr2 = (ao_itr / 2)
local ao_tr_bother = {}
local ao_tr_main = {}
local function ao_at_pos(pos, norm)
	--local p_idx = Vector(math_floor(pos[1] / ao_ch_scl), math_floor(pos[2] / ao_ch_scl), math_floor(pos[3] / ao_ch_scl))
	--local n_idx = Vector(math_Round(norm[1], norm_dec), math_Round(norm[2], norm_dec), math_Round(norm[3], norm_dec))
	--local n_str = n_idx[1] .. ":" .. n_idx[2] .. ":" .. n_idx[3]
	--local p_str = p_idx[1] .. ":" .. p_idx[2] .. ":" .. p_idx[3]

	local n_str = math_floor(pos[1] / ao_ch_scl) .. ":" .. math_floor(pos[2] / ao_ch_scl) .. ":" .. math_floor(pos[3] / ao_ch_scl)
	local p_str = math_floor(norm[1] * norm_dec) .. ":" .. math_floor(norm[2] * norm_dec) .. ":" .. math_floor(norm[3] * norm_dec)
	if not ao_ch[p_str] then
		ao_ch[p_str] = {}
		ao_age[p_str] = {}
	end

	if (not ao_ch[p_str][n_str]) or (do_ao_expire and ((CurTime() - (ao_age[p_str][n_str] or 0)) > 0)) then
		if fr_ao_count > max_fr_ao then
			return 1
		end
		fr_ao_count = fr_ao_count + .25

		util_TraceHull({
			start = pos + norm * ao_mdist,
			endpos = pos + norm * (ao_mdist + 1),
			mins = Vector(-ao_mdist, -ao_mdist, -ao_mdist),
			maxs = Vector(ao_mdist, ao_mdist, ao_mdist),
			filter = LocalPlayer(),
			output = ao_tr_bother
		})

		if not ao_tr_bother.Hit then -- why even bother?
			ao_ch[p_str][n_str] = 1
			return ao_ch[p_str][n_str]
		end

		fr_ao_count = fr_ao_count + .75





		local sub_var = 0
		local n_a = norm:Angle()
		for i = 0, (ao_itr * ao_itr) - 1 do
			local upc = n_a:Up() * ((math_floor(i / ao_itr) - ao_itr2) / ao_itr2) -- dy
			local ric = n_a:Right() * (((i % ao_itr) - ao_itr2) / ao_itr2) -- dx

			upc:Add(ric)
			--ncopy:Add(ric)
			upc:Normalize()
			--ncopy:Rotate(ac)

			util_TraceLine({
				start = pos + (norm * .5),
				endpos = (pos + (norm * .5)) + upc * ao_mdist,
				filter = LocalPlayer(),
				output = ao_tr_main
			})

			--local dc = n_pos:Distance(pos)
			--if dc < ao_mdist then
				sub_var = sub_var + ((ao_st_delta * math_abs(1 - ao_tr_main.Fraction)) * .35)
			--end
		end
		ao_ch[p_str][n_str] = math_abs(1 - sub_var)
		if do_ao_expire then
			ao_age[p_str][n_str] = CurTime() + ao_expire
		end
	end


	--return (ao_age[p_str][n_str] - CurTime()) / ao_expire
	return ao_ch[p_str][n_str]
end

concommand.Add("fastrt3_wipeao", function()
	ao_ch = {}
end)

local ref_sun_tr = {}
local function calcShadowAndAO(tr)
	local hp = tr.HitPos
	util_TraceLine({
		start = hp,
		endpos = hp + (sunDir * 100000),
		output = ref_sun_tr
	})

	if ref_sun_tr.HitSky then
		return 1
	elseif ref_sun_tr.Hit then
		local aoc = ao_at_pos(hp, tr.HitNormal)
		return math_max(aoc - .5, 0)
		--return .5
	end
	return 1
end



local bclasses = {
	["func_brush"] = true,
	["class C_BaseEntity"] = true,
}

local ShaderTable

local tsz_8 = texSz / 8
local function calcCol(tr)
	if not tr.Hit or tr.HitSky then
		return calcSky(tr)
	end



	local shade = calcShadowAndAO(tr)
	local cdat = nil
	if IsValid(tr.Entity) and (not bclasses[tr.Entity:GetClass()]) then
		if tr.Entity:GetClass() == "func_reflective_glass" then
			cdat = ShaderTable["debug/env_cubemap_model"](tr)
		elseif tr.Entity:GetMaterial() ~= "" and ShaderTable[tr.Entity:GetMaterial()] then
			cdat = ShaderTable[tr.Entity:GetMaterial()](tr)
		else
			cdat = getAverage(tr.Entity:GetMaterials()[1])
		end
	elseif tr.HitTexture ~= "**displacement**" then
		if doTex then
			local hp = tr.HitPos / tsz_8
			local hna = tr.HitNormal:Angle()


			cdat = getPx(tr.HitTexture, (hp * hna:Right()):Length(), (hp * hna:Up()):Length())
		else
			cdat = getAverage(tr.HitTexture)
		end
	else
		local dot = tr.HitNormal:Dot(sunDir) * 1
		cdat = {64 * dot, 196 * dot, 64 * dot}
	end

	return cdat[1] * shade, cdat[2] * shade, cdat[3] * shade
end

local CurrRefl = 0
local MaxRefl = 2
local ref_tr_refl = {}

local CurrRefr = 0
local MaxRefr = 3
local Refr_Filt_Tbl = {}
local ref_tr_refr = {}
ShaderTable = {
	["debug/env_cubemap_model"] = function(tr)
		CurrRefl = CurrRefl + 1
		if CurrRefl > MaxRefl then
			CurrRefl = 0
			return {128, 128, 128}
		end


		util_TraceLine({
			start = tr.HitPos + (tr.HitNormal * .25),
			endpos = (tr.HitPos + (tr.HitNormal * .25)) + (reflect(getDir(tr), tr.HitNormal) * 100000),
			output = ref_tr_refl
		})

		local cr, cg, cb = calcCol(ref_tr_refl)
		local ecm = Color(1, 1, 1)

		if IsValid(tr.Entity) then
			ecm = tr.Entity:GetColor()
			ecm.r = math_max(ecm.r / 255, .25)
			ecm.g = math_max(ecm.g / 255, .25)
			ecm.b = math_max(ecm.b / 255, .25)
		end

		CurrRefl = 0
		return {(cr * ecm.r) * .95, (cg * ecm.g) * .95, (cb * ecm.b) * .95}
	end,
	-- refract, https://bheisler.github.io/post/writing-raytracer-in-rust-part-3/
	["models/shadertest/shader3"] = function(tr)
		CurrRefr = CurrRefr + 1
		if CurrRefr > MaxRefr then
			CurrRefr = 0
			Refr_Filt_Tbl = {}
			return calcSky(tr)
		end

		Refr_Filt_Tbl[#Refr_Filt_Tbl + 1] = tr.Entity
		local ior = 2.49

		local hp = tr.HitPos
		local ref_n = tr.HitNormal
		local eta_t = ior -- index of refraction
		local eta_i = 1
		local i_dot_n = hp:Dot(tr.HitNormal)

		if i_dot_n < 0 then
			-- inside, invert
			i_dot_n = -i_dot_n
		else
			ref_n = -tr.HitNormal;
			eta_t = 1;
			eta_i = ior;
		end

		local eta = eta_i / eta_t
		local k = 1 - ((eta * eta) * (1 - (i_dot_n * i_dot_n)))
		if k < 0 then
			return {255, 0, 0}
		else
			local dir = (((tr.Entity:GetPos() - hp) + i_dot_n * ref_n) * eta - ref_n * math.sqrt(k))
			dir:Normalize()
			util_TraceLine({
				start = hp + (tr.HitNormal * .25),
				endpos = (hp + (tr.HitNormal * .25)) + (dir * 100000),
				filter = Refr_Filt_Tbl,
				output = ref_tr_refr,
			})
			local cr, cg, cb = calcCol(ref_tr_refr)
			local ecm = Color(1, 1, 1)

			if IsValid(tr.Entity) then
				ecm = tr.Entity:GetColor()
				ecm.r = math_max(ecm.r / 255, .25)
				ecm.g = math_max(ecm.g / 255, .25)
				ecm.b = math_max(ecm.b / 255, .25)
			end

			CurrRefr = 0
			Refr_Filt_Tbl = {}
			return {(cr * ecm.r) * .95, (cg * ecm.g) * .95, (cb * ecm.b) * .95}
		end
	end
}


concommand.Add("fastrt3_dotex", function()
	doTex = not doTex
	print("Texturing " .. (doTex and "Activated" or "Deactivated"))
end)

local main_tr = {}
local function raytrace(x, y)
	local dcopy = DirTable[y][x]:GetNormalized()
	dcopy:Rotate(LocalPlayer():EyeAngles())
	dcopy:Mul(1000000)

	local ep = ply:EyePos()
	util_TraceLine({
		start = ep,
		endpos = ep + dcopy,
		filter = ply,
		output = main_tr
	})

	return calcCol(main_tr)
end

hook.Add("Think", "lrrt3RenderRT", function()
	if not active then
		return
	end

	local ow, oh = ScrW(), ScrH()
	render_PushRenderTarget(rtRender)
		for i = 1, itrPerTick do
			local x, y = getRandomTrace()
			if ((x + y + frame) % 2) == 1 then
				continue
			end

			local r, g, b = raytrace(x, y)

			render_SetViewPort(x * pxW, y * pxH, pxW, pxH)
			render_Clear(r, g, b, 255)
			render_SetViewPort(0, 0, ow, oh)
		end
	render_PopRenderTarget()
end)


hook.Add("HUDPaint", "lrrt3RenderCanvas", function()
	if not active then
		return
	end

	surface_SetDrawColor(255, 255, 255, 255)
	surface_SetMaterial(rtMat)
	surface_DrawTexturedRect(0, 0, ScrW(), ScrH())

	surface_SetMaterial(rtCapturePxMat)
	surface_DrawTexturedRect(0, 0, texSz, texSz)

	draw.SimpleText(math_floor(collectgarbage("count") / 1024) .. "mb", "DermaLarge", 0, 0, Color(255, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end)

concommand.Add("fastrt3_toggle", function()
	active = not active
	print("lrrt: set to " .. (active and "enabled" or "false"))
end)
