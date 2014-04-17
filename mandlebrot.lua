-- optimized mandlebrot renderer
-- http://puu.sh/8cs0i
local component=require("component")
local event=require("event")
local term=require("term")
local s=require("serialization")
local gpu=component.gpu
local oldw,oldh=gpu.getResolution()
gpu.setBackground(0xFF0000)
term.clear()
local w,h=gpu.maxResolution()
gpu.setResolution(w,h)
local depth=32
local x0=-0.65
local y0=-0.7
local x1=-0.5
local y1=-0.6
local dx=x1-x0
local dy=y1-y0
local palette={}
for l1=0,depth do
	palette[l1] = {
		r=math.min(math.max(math.floor(l1/depth*1024),0),255),
		g=math.min(math.max(math.floor((l1-depth/3)/depth*1024),0),255),
		b=math.min(math.max(math.floor((l1-depth/3*2)/depth*1024),0),255),
	}
end
palette[depth-1]={r=0,g=0,b=0}
local file=io.open("hdd/out.txt","w")
file:write(s.serialize(pallette))
file:close()
for y=0,h-1 do
	local lx=0
	local lcolor=0
	local function app(x)
		if x~=1 and lcolor~=0xFF0000 then
			gpu.setBackground(lcolor)
			gpu.set(lx,y+1,(" "):rep(x-lx))
		end
		lx=x
	end
	for x=0,w-1 do
		local r=0
		local n=0
		local b=x/w*dx+x0
		local e=y/h*dy+y0
		local i=0
		while i<depth-1 and r*r<4 do
			local d=r
			r=r*r-n*n+b
			n=2*d*n+e
			i=i+1
		end
		local p=palette[i]
		local ccolor=(((p.r*256)+p.g)*256)+p.b
		if ccolor~=lcolor then
			app(x+1)
			lcolor=ccolor
		end
	end
	gpu.setBackground(lcolor)
	gpu.set(lx,y+1,(" "):rep((w-lx)+1))
end
event.pull("key_down")
gpu.setResolution(oldw,oldh)
