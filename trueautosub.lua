function table.append(t1, t2)
	for _,v in next,t2 do table.insert(t1, v) end
end

-- requires subliminal, version 1.0 or newer
-- default keybinding: b
local o = {
	subliminal = "/usr/bin/subliminal", -- path to subliminal
	single = false, -- Save subtitle without language code in the file name.
	auto = 10, -- Initial delay before auto-download. A negative value disables it.
	addic7ed_username = "", legendastv_username = "", opensubtitles_username = "",
	addic7ed_password = "", legendastv_password = "", opensubtitles_password = "",
	omdb_api = ""
}
(require "mp.options").read_options(o)
o.single = o.single and "-s" or ""

-- setup constant args
local args = { o.subliminal }
for _,v in next,{"addic7ed", "legendastv", "opensubtitles"} do
	local username, password = o[v.."_username"], o[v.."_password"]
	if username ~= "" and password ~= "" then
		table.append(args, {"--"..v, username, password})
	end
end
if o.omdb_api ~= "" then
	table.append(args, {"--omdb", o.omdb_api})
end
table.append(args, { "download", o.single, "-l", "en", "", "" })


local function msg(s, level)
	mp.msg[level or "info"](s)
	mp.osd_message(s)
end

-- download the subtitle
local function load_sub_fn(force)
	msg("Searching subtitle")
	args[#args - 1] = force and "-f" or ""
	args[#args] = mp.get_property("path")
	if mp.command_native({ name = "subprocess", args = args }).status == 0 then
		mp.commandv("rescan_external_files", "reselect")
		msg("Subtitle download succeeded")
	else
		msg("Subtitle download failed", "warn")
	end
end

mp.add_key_binding("b", "auto_load_subs", function() load_sub_fn(true) end)
if o.auto >= 0 then -- auto search and download if not present, the way god intended :P
	mp.register_event("file-loaded", function() mp.add_timeout(o.auto, load_sub_fn) end)
end
