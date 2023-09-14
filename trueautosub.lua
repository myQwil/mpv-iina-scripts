-- requires subliminal, version 1.0 or newer
-- default keybinding: b

local function msg(s, level)
    mp.msg[level or "info"](s)
    mp.osd_message(s)
end

-- download the subtitle
local function load_sub_fn(force)
    subl = "/usr/local/bin/subliminal" -- use 'which subliminal' to find the path
    msg("Searching subtitle")

    force = force and "-f" or ""
    args = {subl, "download", "-s", force, "-l", "en", mp.get_property("path")}
    if mp.command_native({ name = "subprocess", args = args }).status == 0 then
        mp.commandv("rescan_external_files", "reselect")
        msg("Subtitle download succeeded")
    else
        msg("Subtitle download failed", "warn")
    end
end

mp.add_key_binding("b", "auto_load_subs", function() load_sub_fn(true) end)

-- auto search for subs and download if not present, the way god intended :P
mp.register_event("file-loaded", function() mp.add_timeout(10, load_sub_fn) end)
