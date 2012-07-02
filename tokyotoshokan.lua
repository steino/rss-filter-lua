local before = clock()
local r = require'redis'
local client = r:connect()

if not client:ping() then return end

local mp = require'msgpack'

header("Content-Type", "application/rss+xml")

print"<rss version=\"2.0\" xmlns:atom=\"http://www.w3.org/2005/Atom\">\n"
print"<channel>\n"
print"<atom:link href=\"http://tokyotosho.info/rss.php\" rel=\"self\" type=\"application/rss+xml\" />\n"
print("<title>Tokyo Toshokan - Filtered</title>\n")
print("<link>http://tokyotosho.info</link>\n")
print("<description>Torrent Listing</description>\n")

local matches = client:lrange("rss:matches", 0, -1)

for _, v in next, matches do
	r = mp.unpack(v)
	print"<item>\n"
	print("<title>" .. r.release .. "</title>\n")
	print("<link><![CDATA[" .. r.link .. "]]></link>\n")
	print"</item>\n"
end

print"</channel>\n"
print"</rss>"

local after = clock()
local diff = after.seconds * 1e9 + after.nanoseconds - (before.seconds * 1e9 + before.nanoseconds)

print('\n\n<!-- ', diff / 1e6, ' ms', ' | ', collectgarbage'count', ' kB', ' -->')

client:quit()
