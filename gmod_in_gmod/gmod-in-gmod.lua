lokaCSModelTable = lokaCSModelTable or {}
lokaCSModelTableCreated = lokaCSModelTableCreated or {}

local POffset = Vector(-2996, -1348, -38)

-- helper func to make a lot of csmodels easily
local function addCSModel(id, mdl, pos, ang)
	local tabl = {
		mdl = mdl,
		pos = pos,
		ang = ang
	}

	lokaCSModelTable[id] = tabl
end

addCSModel(1,
	"models/props_c17/FurnitureTable002a.mdl",
	Vector(-2.974609375, -37.39501953125, -38.359031677246),
	Angle(0, 90, 0)
)


addCSModel(2,
	"models/props_c17/FurnitureChair001a.mdl",
	Vector(-3.970947265625, -6.644287109375, -36.55110168457),
	Angle(0, -90, 0)
)

addCSModel(3,
	"models/props_lab/monitor02.mdl",
	Vector(-1.4365234375, -41.57861328125, -20.205154418945),
	Angle(0, 90.027465820313, 0)
)

addCSModel(4,
	"models/props_lab/harddrive02.mdl",
	Vector(-21.1923828125, -35.580200195313, -10.295738220215),
	Angle(0, 90.016479492188, 0)
)

addCSModel(5,
	"models/props_c17/computer01_keyboard.mdl",
	Vector(-1.488525390625, -24.153076171875, -20.8125),
	Angle(-0.10986328125, 90.005493164063, 0)
)




for k, v in pairs(lokaCSModelTable) do
	if IsValid(lokaCSModelTableCreated[k]) then
		lokaCSModelTableCreated[k]:Remove()
	end

	lokaCSModelTableCreated[k] = ClientsideModel(v.mdl)
	lokaCSModelTableCreated[k]:SetPos(POffset + v.pos)
	lokaCSModelTableCreated[k]:SetAngles(v.ang)
	lokaCSModelTableCreated[k]:Spawn()
end




local rtRenderView = GetRenderTarget("lokaRtRenderViewTest1", 512, 512, false)
local rtMat = CreateMaterial("lokaRtRenderViewTestMaterial1", "UnlitGeneric", {
	["$basetexture"] = rtRenderView:GetName()
})

hook.Add("PostRender", "PostRenderLokaRenderViewTest", function()
	render.PushRenderTarget(rtRenderView)
	cam.Start2D()
		surface.SetDrawColor(255, 255, 255, 255)
		render.RenderView({
			origin = LocalPlayer():EyePos(),
			angles = LocalPlayer():EyeAngles(),
			fov = LocalPlayer():GetFOV(),
			drawhud = true,
			viewmodelfov = math.Clamp(LocalPlayer():GetFOV() - 48, 0, 120),
			drawviewmodel = true,
			aspect = 1,
			w = 512,
			h = 512
		})

		surface.SetDrawColor(255, 255, 255)

		surface.DrawRect(256, 256, 1, 1)

		local crspacing = 8

		surface.DrawRect(256, 256 + crspacing, 1, 1)
		surface.DrawRect(256 + crspacing, 256, 1, 1)
		surface.DrawRect(256, 256 - crspacing, 1, 1)
		surface.DrawRect(256 - crspacing, 256, 1, 1)

		hook.Run("HUDPaintBackground")
		hook.Run("HUDPaint")
		hook.Run("HUDDrawTargetID")
		hook.Run("HUDDrawPickupHistory")

		hook.Run("PostDrawHUD")
		hook.Run("DrawOverlay")
		--hook.Run("DrawDeathNotice")

		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetTexture(surface.GetTextureID("effects/flicker_128"))
		surface.DrawTexturedRect(0, 0, 512, 512)

		draw.NoTexture()
		surface.SetDrawColor(0, 0, 0, 40)
		surface.DrawRect(0, 0, 512, 512)








	cam.End2D()
	render.PopRenderTarget()
end)


hook.Add("Think", "LokaRenderViewTestResetDSP", function()
	LocalPlayer():SetDSP(59)
end)

hook.Add("HUDPaint", "LokaHudPaintRenderViewTest", function()
	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(rtMat)
	--surface.DrawTexturedRect(0, 0, 512, 512)
end)

hook.Add("CalcView", "ForceViewAtAScreenRenderViewTest", function(ply, pos, ang, fov)
	local swa1 = (math.sin(CurTime() * 0.75) * 0.5) * 0.25
	local swa2 = (math.cos(CurTime()) * 0.3536) * 0.25
	local swa3 = math.sin(CurTime() * 0.816) * 0.25

	--local vec = Vector(-2996.105225, -1348.221924, -38.968750)
	--print("Vector("..vec.x - POffset.x..", "..vec.y - POffset.y..", "..vec.z - POffset.z..")")

	local newView = {
		origin = POffset + Vector(-0.105224609375, -0.221923828125, -0.96875),
		angles = Angle(12.618141 + swa1, -90.863808 + swa2, swa3),
		fov = 75,
		drawviewer = false
	}

	return newView
end)

hook.Add("CalcViewModelView", "HideViewModelLokaRenderViewTest", function(wep, vm, oldpos, oldang, newpos, newang)
end)


local ScrPos = (POffset + Vector(7.75, -31.5, 2.25))
local ScrAng = Angle(0, 180, 82)

hook.Add("PreDrawTranslucentRenderables", "RenderComputerMonitor", function()
	cam.Start3D2D(ScrPos, ScrAng, 0.030)
		draw.NoTexture()
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(rtMat)
		surface.DrawTexturedRect(0, 0, 512 + 64 + 32, 512 - 22)
	cam.End3D2D()
end)

local toHide = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudCrosshair"] = true,
	["CHudGMod"] = true
}

hook.Add("HUDShouldDraw", "HideTheHUD", function(name)
	if toHide[name] then
		return false
	end
end)


hook.Add("EntityEmitSound", "OverrideSoundPosToComputerLoka", function(sdata)
	sdata.Pos = POffset + Vector(0, 0, 16)
	return true
end)

