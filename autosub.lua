---@param t1 table
---@param t2 table
function table.append(t1, t2)
	for _,v in next,t2 do table.insert(t1, v) end
end

-- requires subliminal, version 1.0 or newer
local o = {
	subliminal = '/usr/bin/subliminal', -- path to subliminal
	single = false, -- Save subtitle without language code in the file name.
	auto = 10, -- Initial delay before auto-download. A negative value disables it.
	lang = 'en',
	pattern = '(%d+)[xeE%.](%d+) %- (.+)',
	addic7ed_username = '', legendastv_username = '', opensubtitles_username = '',
	addic7ed_password = '', legendastv_password = '', opensubtitles_password = '',
	omdb_api = ''
}
(require 'mp.options').read_options(o)
local ext = (o.single and '' or ('.'..o.lang))..'.srt'
o.single = o.single and '-s' or ''

-- setup constant args
local args = { o.subliminal }
for _,v in next,{'addic7ed', 'legendastv', 'opensubtitles'} do
	local username, password = o[v..'_username'], o[v..'_password']
	if username ~= '' and password ~= '' then
		table.append(args, {'--'..v, username, password})
	end
end
if o.omdb_api ~= '' then
	table.append(args, {'--omdb', o.omdb_api})
end
table.append(args, { 'download', o.single, '-l', o.lang, '' })


---@param s string
---@param level? string
local function msg(s, level)
	mp.msg[level or 'info'](s)
	mp.osd_message(s, 2)
end

---@param s string
---@return string
local function srt(s)
	local dot = s:find('%.[^.]*$')
	return (dot and s:sub(1, dot - 1) or s)..ext
end

---@param s string
---@return string
local function guess(s)
	local season, episode, title = s:match(o.pattern)
	local levels = {} ---@type string[]
	local file = io.popen('realpath "'..s..'"')
	if file then
		local path = file:read('*a'):gsub('\n', '')
		for lvl in path:gmatch('[^/\\]+') do
			table.insert(levels, lvl)
		end
		file:close()
	else
		return s
	end
	local show = ''
	for i = #levels-1, 1, -1 do
		if not levels[i]:lower():match('^season %d') then
			show = levels[i]
			break
		end
	end
	s = string.format('%s season %d episode %d - %s',
		show, tonumber(season), tonumber(episode), title)
	print(s)
	return s
end

---@param force? boolean
local function sub_dl(force)
	local path = mp.get_property('path')
	if not force then -- stop if .srt already exists
		local file = io.open(srt(path), 'r')
		if file then
			io.close(file)
			return
		end
	end

	msg('Searching subtitle')
	args[#args] = guess(path)
	if mp.command_native({ name = 'subprocess', args = args }).status == 0 then
		msg('Subtitle download succeeded')
		local ok, message = os.rename(srt(args[#args]), srt(path))
		if ok then
			mp.commandv('rescan_external_files', 'reselect')
		else
			print(message)
		end
	else
		msg('Subtitle download failed', 'warn')
	end
end

if o.auto >= 0 then -- auto search and download if not present, the way god intended :P
	mp.register_event('file-loaded', function() mp.add_timeout(o.auto, sub_dl) end)
end
mp.register_script_message('sub_dl', function() sub_dl(true) end)
