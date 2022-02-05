--[[
	Simple raycaster ver 0.5
	Coded by lokachop

	share if you want to i guess

	Comments cleaned (flag 0)
]]--


local plyPos = Vector(-22, 0, 0)
local plyDir = Vector(-1, 0, 0)
local objects = {}
local objectInitPos = {}
local speedMod = 16
local resDiv = 4
local rotSpeed = 64
local FOV = 90
local FogDist = 1024

local doDebug = true
local alpha = 255
local WallHeight = 32

--"gui/noicon.png"
--"skybox/sky_day01_09ft"
local skyTex = "composite/buildingset056a"

local PlacedStuff = false
local PlaceID = 7

RCMaterials = RCMaterials or {}
--skybox/sky_day01_05_hdrlf
function makePaintSafeMat(mat)
	if RCMaterials[mat] == nil then
		print("initializing material: " .. mat)
		local matData = {
			["$basetexture"] = mat,
			["$nodecal"] = 1,
			["$model"] = 1,
			["$nocull"] = 1,
			["$noclamp"]  = 1
		}

		RCMaterials[mat] = CreateMaterial("LKRC_T_" .. mat, "UnlitGeneric", matData)

		RCMaterials[mat]:SetInt( "$flags", bit.bor(RCMaterials[mat]:GetInt("$flags"), 32768))
		RCMaterials[mat]:Recompute()
	end
end


makePaintSafeMat(skyTex)

function makeBox(id, pos, col, size, ang)
	local objTabl = {}
	objTabl["obj"] = {
		pos,
		size,
		ang,
		"CUBE"
	}
	objectInitPos[id] = pos

	objTabl["r"] = col.r
	objTabl["g"] = col.g
	objTabl["b"] = col.b

	print("--==made box==--")
	PrintTable(objTabl)
	table.insert(objects, objTabl)
end


function makePlane(id, pos, col, size, ang)
	local objTabl = {}
	objTabl["obj"] = {
		pos,
		size,
		ang,
		"PLANE"
	}
	objectInitPos[id] = pos

	objTabl["r"] = col.r
	objTabl["g"] = col.g
	objTabl["b"] = col.b

	print("--==made box==--")
	PrintTable(objTabl)
	table.insert(objects, objTabl)
end

makeBox(1, Vector(0, 0, 0), Color(255, 0, 0, 255), Vector(16, 16, 16), Angle(0, 0, 0))
makeBox(2, Vector(-13, 25, 0), Color(0, 255, 0, 255), Vector(16, 32, 16), Angle(0, 45, 0))
makeBox(3, Vector(-23, -15, 0), Color(0, 0, 255, 255), Vector(16, 32, 16), Angle(0, 90, 0))

makeBox(4, Vector(-64, 0, 0), Color(0, 255, 255, 255), Vector(16, 16, 16), Angle(0, 0, 0))

makeBox(5, Vector(-64, 32, 8), Color(0, 255, 255, 255), Vector(16, 16, 16), Angle(0, 0, 0))
makeBox(6, Vector(-64, 64, 12), Color(255, 255, 0, 255), Vector(16, 16, 16), Angle(45, 45, 45))

function sortObjects()
	table.sort(objects, function(a, b)
		return a["obj"][1]:DistToSqr(plyPos) > b["obj"][1]:DistToSqr(plyPos)
	end)

end

--for i = 6, 160 do
--	makeBox(i, Vector(-64, 64 + (i * 0.25), 0), HSVToColor(i * 16, 1, 1), Vector(0.25, 0.25, 0.25), Angle(0, 0, 0))
--end


function raycastDir(pos, dir, dist)
	local currShortestDist = math.huge

	local tablToReturn = {}
	for k, v in ipairs(objects) do
		local bPos = v["obj"][1]
		local bMins = -v["obj"][2] / 2
		local bMaxs = v["obj"][2] / 2
		local bAng = v["obj"][3]

		local r = v["r"]
		local g = v["g"]
		local b = v["b"]
		local col = Color(r, g, b)

		if doDebug then
			debugoverlay.Cross(pos,  2, FrameTime() * 2, Color(255, 0, 0))
			debugoverlay.BoxAngles(bPos, bMins, bMaxs, bAng, FrameTime() * 2, Color(r, g, b, 1))
		end

		local hpos, normal, fraction = util.IntersectRayWithOBB(pos, dir * dist, bPos, bAng, bMins, bMaxs)

		if hpos ~= nil and hpos:Distance(pos) < currShortestDist and hpos:Distance(pos) ~= 0 then
			currShortestDist = pos:Distance(hpos)
			tablToReturn.dist = pos:Distance(hpos)
			tablToReturn.hpos = hpos
			tablToReturn.normal = normal
			tablToReturn.fraction = fraction
			tablToReturn.col = col
		end
	end
	if doDebug then
		debugoverlay.Line(pos, tablToReturn.hpos or (pos + (dir * dist)), FrameTime() * 2, Color(255, 255, 0))
	end
	return tablToReturn
end

function drawWall(col, tex, raycast, height, i)


end

hook.Add("HUDPaint", "RenderRaycastLoka", function()
	surface.SetDrawColor(0, 0, 0, alpha)
	surface.DrawRect(0, 0, ScrW(), ScrH() / 2)

	surface.SetDrawColor(255, 255, 255, alpha)
	surface.SetMaterial(RCMaterials[skyTex])
	local wadd = ((plyDir:Angle()[2] + 180) * (ScrW() / 90)) % (ScrW())

	surface.DrawTexturedRect(wadd, 0, ScrW(), ScrH() / 2)

	surface.DrawTexturedRect(wadd + (ScrW()), 0, ScrW(), ScrH() / 2)

	surface.DrawTexturedRect(wadd - (ScrW()), 0, ScrW(), ScrH() / 2)
	draw.NoTexture()


	surface.SetDrawColor(0, 0, 0, alpha)
	surface.DrawRect(0, ScrH() / 2, ScrW(), ScrH() / 2)


	surface.SetTexture(surface.GetTextureID("gui/gradient_up"))
	surface.SetDrawColor(64, 64, 64, alpha)
	surface.DrawTexturedRect(0, ScrH() / 2, ScrW(), ScrH() / 2)
	surface.SetTexture(surface.GetTextureID(""))


	for i = 0, (ScrW() / resDiv) do
		local iRel = -(i - ((ScrW() / resDiv) / 2))
		local dirCopy = Vector(plyDir[1], plyDir[2], plyDir[3]) -- weird ass shit because of glua
		local rotCalc = (iRel / (ScrW() / resDiv)) * FOV


		dirCopy:Rotate(Angle(0, rotCalc, 0))

		local raycast = raycastDir(plyPos, dirCopy, 5000)
		local mult = (ScrW() / resDiv)

		local cosCalc = (-plyDir) - (-plyDir - Vector(0, iRel / mult, 0))
		local distCalc = raycast.dist or 0
		distCalc = distCalc  * (math.cos(cosCalc[2]))
		distCalc = (WallHeight * (ScrH() / 2)) / distCalc
		local hcalc = distCalc

		if raycast.normal ~= nil then
			local absCalc = math.Clamp(math.abs(raycast.normal[2]), 0.5, 1)
			local col = raycast.col
			col.r = col.r * absCalc
			col.g = col.g * absCalc
			col.b = col.b * absCalc

			local colDistCalc = distCalc
			colDistCalc = colDistCalc / FogDist
			col.r = col.r * math.Clamp(colDistCalc, 0, 1)
			col.g = col.g * math.Clamp(colDistCalc, 0, 1)
			col.b = col.b * math.Clamp(colDistCalc, 0, 1)
			col.a = alpha

			surface.SetDrawColor(col)
		else
			surface.SetDrawColor(64, 64, 64, alpha)
		end

		surface.DrawRect(i * resDiv, (ScrH() / 2) - (hcalc / 2), resDiv, hcalc)
	end


	draw.SimpleText("plypos:" .. tostring(plyPos), "BudgetLabel", ScrW(), 0, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	draw.SimpleText("plyDir:" .. tostring(plyDir), "BudgetLabel", ScrW(), 16, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
end)

local function moveObject(id, dir)
	objects[id]["obj"][1] = objects[id]["obj"][1] + dir
end

local function setObjectPos(id, pos)
	objects[id]["obj"][1] = pos
end

local function setAngleObject(id, ang)
	objects[id]["obj"][3] = ang
end

local function addAngleObject(id, ang)
	objects[id]["obj"][3] = objects[id]["obj"][3] + ang
end

local function setColourObject(id, col)
	local r = col.r
	local g = col.g
	local b = col.b

	objects[id]["r"] = r
	objects[id]["g"] = g
	objects[id]["b"] = b
end

local function setScaleObject(id, scale)
	objects[id]["obj"][2] = scale
end

local function updateObjects()
	setObjectPos(1, objectInitPos[1] + Vector(0, math.sin(CurTime() / 2) * 16, 0))

	--[[
	for i = 6, 60 do
		if i % 2 == 1 then
			setObjectPos(i, objectInitPos[i] + Vector(math.sin(CurTime() / 2) * 16, 0, 0))
		else
			setObjectPos(i, objectInitPos[i] - Vector(math.sin(CurTime() / 2) * 16, 0, 0))
		end
	end
	]]--

	setColourObject(4, HSVToColor(CurTime() * 32, 0.5, 1))
	setScaleObject(4,  Vector(math.abs(math.cos(CurTime() / 1) * 16), math.abs(math.sin(CurTime() / 1) * 16), 16))


	setAngleObject(5, Angle(-CurTime() * 45, -CurTime() * 65, -CurTime() * 25))
end



hook.Add("Think", "LokaRaycastMovePlayer", function()
	updateObjects()
	local ply = LocalPlayer()

	if input.IsKeyDown(KEY_PAD_8) then
		plyPos = plyPos + (plyDir * (speedMod * FrameTime()))
	end

	if input.IsKeyDown(KEY_PAD_7) then
		plyPos = plyPos - (plyDir:Angle():Right() * (speedMod * FrameTime()))
	end

	if input.IsKeyDown(KEY_PAD_9) then
		plyPos = plyPos + (plyDir:Angle():Right() * (speedMod * FrameTime()))
	end

	if input.IsKeyDown(KEY_PAD_5) then
		plyPos = plyPos - (plyDir * (speedMod * FrameTime()))
	end

	if input.IsKeyDown(KEY_PAD_4) then
		plyDir:Rotate(Angle(0, rotSpeed * FrameTime(), 0))
	end

	if input.IsKeyDown(KEY_PAD_6) then
		plyDir:Rotate(Angle(0, -rotSpeed * FrameTime(), 0))
	end

	if input.IsKeyDown(KEY_PAD_1) then
		if PlacedStuff == false then

			makeBox(6, plyPos + (plyDir * 8), HSVToColor(PlaceID * 16, 1, 1), Vector(2, 2, 2), Angle(0, 0, 0))
			PlaceID = PlaceID + 1
			PlacedStuff = true
		end
	else
		if PlacedStuff then
			PlacedStuff = false
		end
	end
end)
