local component=require("component")
local unicode=require("unicode")
local holo=component.hologram
holo.setScale(2)
holo.clear()
local function menger(x,y)
	x,y=x-1,y-1
	while x>0 or y>0 do
		if x%3==1 and y%3==1 then
			return false
		end
		x,y=math.floor(x/3),math.floor(y/3)
	end
	return true
end
local function combine(bits)
	local o=0
	for k,v in pairs(bits) do
		o=o+((2^(k-1))*(v and 1 or 0))
	end
	return o
end
local map={}
for cx=1,3^3 do
	map[cx]={}
	for cy=1,3^3 do
		map[cx][cy]=menger(cx,cy)
	end
end
for cx=1,3^3 do
	for cz=1,3^3 do
		local bits={}
		for cy=1,3^3 do
			bits[cy]=map[cx][cy] and map[cx][cz] and map[cy][cz]
		end
		os.sleep(0)
		holo.set(cx+11,cz+11,combine(bits))
	end
end