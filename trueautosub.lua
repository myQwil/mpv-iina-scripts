-- requires subliminal, version 1.0 or newer
-- default keybinding: b

-- download the subtitle
local function load_sub_fn(force)
    local subl = "/usr/local/bin/subliminal" -- use 'which subliminal' to find the path
    mp.msg.info("Searching subtitle")
    mp.osd_message("Searching subtitle")

    force = force and "-f" or ""
    local args = {subl, "download", "-s", force, "-l", "en", mp.get_property("path")}
    if mp.command_native({ name = "subprocess", args = args }).status == 0 then
        mp.commandv("rescan_external_files", "reselect")
        mp.msg.info("Subtitle download succeeded")
        mp.osd_message("Subtitle download succeeded")
    else
        mp.msg.warn("Subtitle download failed")
        mp.osd_message("Subtitle download failed")
    end
end

mp.add_key_binding("b", "auto_load_subs", function() load_sub_fn(true) end)

-- auto search for subs and download if not present, the way god intended :P
mp.register_event("file-loaded", function() mp.add_timeout(10, load_sub_fn) end)
