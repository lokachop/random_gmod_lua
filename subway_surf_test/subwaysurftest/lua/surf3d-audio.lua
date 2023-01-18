Surf3D = Surf3D or {}
Surf3D.Audio = Surf3D.Audio or {}

print("Loading Surf3D-Audio!")



Surf3D.ExistingAudios = Surf3D.ExistingAudios or {}
Surf3D.ExistingSGAudios = Surf3D.ExistingSGAudios or {}
function Surf3D.Audio.G_SoundScript(id, len, callback, pitch)
	pitch = pitch or 100
	local srate = 11025
	-- 11025
	-- 22050

	local idg = id .. "_sg_tg_" .. math.floor(CurTime())
	if not Surf3D.ExistingSGAudios[idg] then
		sound.Generate(idg, srate, len, callback)
	end
	--surface.PlaySound(idg)

	sound.Add({
		name = "surf3d_audio_" .. id .. "_p_" .. pitch,
		channel = CHAN_AUTO,
		volume = 1,
		pitch = pitch,
		sound = idg,
	})

	if not Surf3D.ExistingAudios[id] then
		Surf3D.ExistingAudios[id] = {
			id = id,
			idg = idg,
			len = len,
			callback = callback,
			pitch_ex = {[pitch] = true}
		}
	end
	Surf3D.ExistingAudios[id].pitch_ex[pitch] = true
	return "surf3d_audio_" .. id .. "_p_" .. pitch
end

function Surf3D.Audio.PlaySound(id, pos, pitch, vol)
	vol = vol or 1
	pitch = pitch or 100
	if not Surf3D.ExistingAudios[id] then
		print("attempt to play nonexistent sound: " .. id)
		return
	end

	if not Surf3D.ExistingAudios[id].pitch_ex[pitch] then
		print("attempt to play nonexistent pitch: " .. pitch .. " for sound: " .. id .. ", generating new pitch")
		Surf3D.Audio.G_SoundScript(id, Surf3D.ExistingAudios[id].len, Surf3D.ExistingAudios[id].callback, pitch)
	end


	print(Surf3D.ExistingAudios[id].len)
	debugoverlay.Text(pos, "surf3d_audio_" .. id .. "_p_" .. pitch, Surf3D.ExistingAudios[id].len)
	debugoverlay.Cross(pos, 4, Surf3D.ExistingAudios[id].len, Color(255, 0, 0, 255))

	sound.Play("surf3d_audio_" .. id .. "_p_" .. pitch, pos, 100, pitch, vol)
end




Surf3D.Audio.CFileOpens = {}
function Surf3D.Audio.FileOpenCallback(name, isfloat, rate)
	if not Surf3D.Audio.CFileOpens[name] then
		Surf3D.Audio.CFileOpens[name] = file.Open(name, "rb", "GAME")
	end

	local file_g = Surf3D.Audio.CFileOpens[name]

	if not file_g then
		print("FileOpen_ERROR! " .. name)
		return nil
	end

	local lf = function(t)
		file_g:Seek(math.floor(((t * 2) % (file_g:Size() + 1)) * rate))
		local fread = isfloat and file_g:ReadShort() or file_g:ReadByte()

		return isfloat and fread / 65535 or (fread / 128) - 1
	end

	return lf
end


--local cf = Surf3D.Audio.FileOpenCallback("sound/ambient/music/country_rock_am_radio_loop.wav")
--Surf3D.Audio.G_SoundScript("test2", 32, Surf3D.Audio.FileOpenCallback("sound/ambient/music/cubanmusic1.wav", true, 1))

--Surf3D.Audio.PlaySound("test2", LocalPlayer():EyePos() + (LocalPlayer():EyeAngles():Right() * 32), 99)
--Surf3D.Audio.PlaySound("test2", LocalPlayer():EyePos() - (LocalPlayer():EyeAngles():Right() * 32), 100)


--Surf3D.Audio.G_SoundScript("test2", 10.66, Surf3D.Audio.FileOpenCallback("sound/ambient/music/piano2.wav", true))

concommand.Add("surf3d_audio_soundgen", function(ply, cmd, args)
	PrintTable(args)
	local id = args[1]
	local sample = args[2]
	local len = tonumber(args[3])
	local isfloat = tonumber(args[4] or "0") > 0
	local rate = tonumber(args[5] or "1")

	if not id or not sample or not len then
		print("surf3d_audio_soundgen <id> <sample> <len> <isfloat> <rate>")
		return
	end
	print("GEN: " .. id .. " " .. sample .. " " .. len .. " " .. (isfloat and "true" or "false") .. " " .. rate)
	Surf3D.Audio.G_SoundScript(id, len, Surf3D.Audio.FileOpenCallback(sample, isfloat, rate))

	Surf3D.Audio.PlaySound(id, LocalPlayer():EyePos(), 1, 1)
end)

concommand.Add("surf3d_audio_soundtest", function(ply, cmd, args)
	PrintTable(args)
	local id = args[1]
	local pitch = tonumber(args[2] or "100")
	local vol = tonumber(args[3] or "1")

	if not id then
		print("surf3d_audio_soundtest <id> <pitch> <vol>")
		return
	end

	print("PLAY: " .. id .. " " .. pitch .. " " .. vol)
	Surf3D.Audio.PlaySound(id, LocalPlayer():EyePos(), pitch, vol)
end)



function Surf3D.Audio.PlaySound(snd, pos)
end

function Surf3D.Audio.CloseFiles()
	for k, v in pairs(Surf3D.Audio.CFileOpens) do
		v:Close()
	end
end