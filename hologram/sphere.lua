local component=require("component")
local holo=component.hologram
holo.setScale(2)
holo.clear()
local function dist(ax,ay,az,bx,by,bz)
	return math.abs(math.sqrt((bx-ax)^2+(by-ay)^2+(bz-az)^2))
end
local function combine(bits)
	local o=0
	for k,v in pairs(bits) do
		o=o+((2^(k-1))*(v and 1 or 0))
	end
	return o
end
for cx=1,32 do
	for cz=1,32 do
		local bits={}
		for cy=1,32 do
			bits[cy]=dist(cx,cy,cz,16,16,16)<16
		end
		os.sleep(0)
		holo.set(cx+11,cz+11,combine(bits))
	end
end