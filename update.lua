-- Load redis and test.
local r = require'redis'
local client = r.connect()
if not client:ping() then return end

-- Load the other libs.
local mp = require'msgpack'
local lz = require'zlib'
local http = require'socket.http'

function http.get(u)
	local t = {}
	local r, c, h = http.request{
		url = u,
		sink = ltn12.sink.table(t),
		headers = {
			["Accept-Encoding"] = "gzip, deflate",
		},
	}
	return lz.inflate()(table.concat(t)), r, c, h
end

local function match(release)
	local whitelist = client:lrange("rss:whitelist", 0, -1)
	for _,w in next, whitelist do
		if release:match(w:lower()) then return release end
	end
end

local function duplicate(guid)
	if client:exists("rss:"..guid) then return true end
end

local rss = http.get"http://tokyotosho.se/rss.php?filter=1&zwnj=0&entries=150"

if rss then
	rss = rss:gsub("\226\128\139", "")
	local arr = {}
	for release, link, guid in rss:gmatch".-<item>.-<title>(.-)</title>.-<link>(.-)</link>.-<guid>(.-)</guid>.-</item>" do
		link = link:match"<!%[CDATA%[(.-)%]%]>" or link
		if link:match("page=torrentinfo") then
			local id = link:match("page=torrentinfo&tid=(%d+)")
			link = "http://www.nyaa.eu/?page=download&tid="..id
		end
		release = release:gsub("%s", "_"):lower()
		guid = guid:match("http://tokyotosho.info/details.php%?id%=(%d+)")
	
		table.insert(arr, {release = release, link = link, guid = guid})
	end
	
	for n, v in next, arr do
		local release = match(v.release)
		if release and not duplicate(v.guid) then
			client:lpush("rss:matches", mp.pack(v))
			client:set("rss:"..v.guid, "1")
			print(v.release.." has been added.")
		end
	end
end
