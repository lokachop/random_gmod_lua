--[[
	made by lokachop
	Advdupe2 code by wireteam, taken from https://github.com/wiremod/advdupe2
]]--


local filepath = "advdupe2/encoding/FILE.txt" -- make sure filepath is proper, syntax is "advdupe2/[folder]/[filename].txt !!!"




local Ad2 = Ad2 or {} -- avoid overwriting proper advdupe2, use our own thingy!!! (idk the name :/)

local pairs = pairs
local error = error
local Vector = Vector
local Angle = Angle
local decompress = util.Decompress

local read4, read5

do --Version 4
	local dec = {}
	for i = 1, 255 do dec[i] = error_nodeserializer end

	local function read()
		local tt = buff:ReadByte()
		if not tt then
			error("Expected value, got EOF!")
		end
		if tt == 0 then
			return nil
		end
		return dec[tt]()
	end
	read4 = read

	dec[255] = function() --table
		local t = {}
		local k
		reference = reference + 1
		local ref = reference
		repeat
			k = read()
			if k ~= nil then
				t[k] = read()
			end
		until (k == nil)
		tables[ref] = t
		return t
	end

	dec[254] = function() --array
		local t = {}
		local k = 0
		local v
		reference = reference + 1
		local ref = reference
		repeat
			k = k + 1
			v = read()
			if (v ~= nil) then
				t[k] = v
			end

		until (v == nil)
		tables[ref] = t
		return t
	end

	dec[253] = function()
		return true
	end
	dec[252] = function()
		return false
	end
	dec[251] = function()
		return buff:ReadDouble()
	end
	dec[250] = function()
		return Vector(buff:ReadDouble(),buff:ReadDouble(),buff:ReadDouble())
	end
	dec[249] = function()
		return Angle(buff:ReadDouble(),buff:ReadDouble(),buff:ReadDouble())
	end
	dec[248] = function() --null-terminated string
		local start = buff:Tell()
		local slen = 0

		while buff:ReadByte() ~= 0 do
			slen = slen + 1
		end

		buff:Seek(start)

		local retv = buff:Read(slen)
		if (not retv) then retv = "" end
		buff:ReadByte()

		return retv
	end
	dec[247] = function() --table reference
		reference = reference + 1
		return tables[buff:ReadShort()]
	end

	for i = 1, 246 do dec[i] = function() return buff:Read(i) end end
end

do --Version 5
	local dec = {}
	for i = 1, 255 do dec[i] = error_nodeserializer end

	local function read()
		local tt = buff:ReadByte()
		if not tt then
			error("Expected value, got EOF!")
		end
		return dec[tt]()
	end
	read5 = read

	dec[255] = function() --table
		local t = {}
		reference = reference + 1
		tables[reference] = t

		for k in read do
			t[k] = read()
		end

		return t
	end

	dec[254] = function() --array
		local t = {}
		reference = reference + 1
		tables[reference] = t

		local k = 1
		for v in read do
			t[k] = v
			k = k + 1
		end

		return t
	end

	dec[253] = function()
		return true
	end
	dec[252] = function()
		return false
	end
	dec[251] = function()
		return buff:ReadDouble()
	end
	dec[250] = function()
		return Vector(buff:ReadDouble(),buff:ReadDouble(),buff:ReadDouble())
	end
	dec[249] = function()
		return Angle(buff:ReadDouble(),buff:ReadDouble(),buff:ReadDouble())
	end
	dec[248] = function() -- Length>246 string
		local slen = buff:ReadULong()
		local retv = buff:Read(slen)
		if (not retv) then retv = "" end
		return retv
	end
	dec[247] = function() --table reference
		return tables[buff:ReadShort()]
	end
	dec[246] = function() --nil
		return
	end

	for i = 1, 245 do dec[i] = function() return buff:Read(i) end end

	dec[0] = function() return "" end
end


local function deserialize(str, read)

	if (str == nil) then
		error("File could not be decompressed!")
		return {}
	end

	tables = {}
	reference = 0
	buff = file.Open("ad2temp.txt","wb","DATA")
	buff:Write(str)
	buff:Flush()
	buff:Close()

	buff = file.Open("ad2temp.txt","rb", "DATA")
	local success, tbl = pcall(read)
	buff:Close()

	if success then
		return tbl
	else
		error(tbl)
	end
end


local function getInfo(str)
	local last = str:find("\2")
	if not last then
		error("Attempt to read AD2 file with malformed info block!")
	end
	local info = {}
	local ss = str:sub(1, last - 1)
	for k, v in ss:gmatch("(.-)\1(.-)\1") do
		info[k] = v
	end

	if info.check ~= "\r\n\t\n" then
		if info.check == "\10\9\10" then
			error("Detected AD2 file corrupted in file transfer (newlines homogenized)(when using FTP, transfer AD2 files in image/binary mode, not ASCII/text mode)!")
		else
			error("Attempt to read AD2 file with malformed info block!")
		end
	end
	return info, str:sub(last + 2)
end



--decoders for individual versions go here
local versions = {}

--versions[1] = AdvDupe2.LegacyDecoders[1] hopefully no deprecated dupes!
--versions[2] = AdvDupe2.LegacyDecoders[2]

versions[3] = function(encodedDupe)
	encodedDupe = encodedDupe:Replace("\r\r\n\t\r\n", "\t\t\t\t")
	encodedDupe = encodedDupe:Replace("\r\n\t\n", "\t\t\t\t")
	encodedDupe = encodedDupe:Replace("\r\n", "\n")
	encodedDupe = encodedDupe:Replace("\t\t\t\t", "\r\n\t\n")
	return versions[4](encodedDupe)
end

versions[4] = function(encodedDupe)
	local info, dupestring = getInfo(encodedDupe:sub(7))
	return deserialize(decompress(dupestring), read4), info
end

versions[5] = function(encodedDupe)
	local info, dupestring = getInfo(encodedDupe:sub(7))
	return deserialize(decompress(dupestring), read5), info
end

function Ad2.Decode(encodedDupe)

	local sig, rev = encodedDupe:match("^(....)(.)")

	if not rev then
		return false, "Malformed dupe (wtf <5 chars long)!"
	end

	rev = rev:byte()

	if sig ~= "AD2F" then
		error("not advdupe2 file!")
	else
		local success, tbl, info = pcall(versions[rev], encodedDupe)


		if success then
			info.revision = rev
		end

		return success, tbl, info
	end
end




local readFile = file.Open(filepath, "rb", "DATA")
local readData = readFile:Read(readFile:Size())
readFile:Close()
local _, dupe, _, _ = Ad2.Decode(readData)
print("--==START DUPE DATA==--")
PrintTable(dupe)
print("--==END DUPE DATA==--")

local code = "@name modelExportedAsHolo\nif(first()|dupefinished())\n{\n"

local idc = 0

local AvgPos = Vector(0, 0, 0)
local avgPosCount = 1
for k, v in pairs(dupe["Entities"]) do
	local pos = v["PhysicsObjects"][0]["Pos"]
	AvgPos = AvgPos + Vector(pos.x, pos.y, pos.z)
	avgPosCount = avgPosCount + 1
end

AvgPos = AvgPos / avgPosCount

for k, v in pairs(dupe["Entities"]) do
	--if v["Class"] == "prop_physics" then
		idc = idc + 1
		local pos = v["PhysicsObjects"][0]["Pos"]
		local ang = v["PhysicsObjects"][0]["Angle"]
		local mdl = v["Model"]
		local emods = v["EntityMods"]

		local mat = ""
		local col = {
			a = 255,
			r = 255,
			g = 255,
			b = 255
		}

		if emods ~= nil then
			if emods["material"] ~= nil then
				mat = emods["material"]["MaterialOverride"]
			end

			if emods["colour"] ~= nil then
				col = emods["colour"]["Color"]
			end
		end

		local fp = {
			x = math.Round(pos.x - AvgPos.x, 3),
			y = math.Round(pos.y - AvgPos.y, 3),
			z = math.Round(pos.z - AvgPos.z, 3)
		}

		local fa = {
			math.Round(ang.p, 3),
			math.Round(ang.y, 3),
			math.Round(ang.r, 3)
			}

		code = code .. "    holoCreate(" .. idc .. ")\n"
		code = code .. "    holoModel(" .. idc .. ", \"" .. mdl .. "\")\n"
		code = code .. "    holoParent(" .. idc .. ", entity())\n"
		code = code .. "    holoPos(" .. idc .. ", entity():toWorld(vec(" .. fp.x .. ", " .. fp.y .. ", " .. fp.z .. ")))\n"
		code = code .. "    holoAng(" .. idc .. ", entity():toWorld(ang(" .. fa[1] .. "," .. fa[2] .. ", " .. fa[3] .. ")))\n"
		code = code .. "    holoColor(" .. idc .. ", vec4(" .. col.r .. ", " .. col.g .. ", " .. col.b .. ", " .. col.a .. "))\n"
		code = code .. "    holoMaterial(" .. idc .. ", \"" .. mat .. "\")\n\n"

		if idc % 30 == 0 then
			code = code .. "    # holy shit there's more than 30 models lets wait a bit to avoid hitting holo burst limit\n"
			code = code .. "    timer(\"BURSTID" .. idc .. "\", 10000)\n}\n\n"
			code = code .. "if(clk(\"BURSTID" .. idc .. "\"))\n{\n"
		end
	--end
end

code = code .. "}\n# exported with lokachop's advdupe2 -> holo tool\n# by lokachop, contact at Lokachop#5862"


local saveFile = file.Open("expression2/" .. "lokaHoloExported" .. ".txt", "w", "DATA")
saveFile:Write(code)
saveFile:Close()

print("Success! converted " .. filepath .. " into e2 " .. "expression2/" .. "lokaHoloExported" .. ".txt")
