-- optimized mandlebrot renderer
-- q to quit
-- mouse to select zoom area
-- z to zoom out
local component=require("component")
local event=require("event")
local term=require("term")
local unicode=require("unicode")
local oci=require("oci")
local s=require("serialization")
local gpu=component.gpu
local oldw,oldh=gpu.getResolution()
local w,h=gpu.maxResolution()
local x0=-2
local y0=-1
local x1=0.5
local y1=1
local err,res=pcall(function()
	gpu.setResolution(w,h)
	local depth=32
	local zoom={}
	while true do
		local dx=x1-x0
		local dy=y1-y0
		local palette={}
		for l1=0,depth do
			palette[l1]={
				r=math.min(math.max(math.floor(l1/depth*1024),0),255),
				g=math.min(math.max(math.floor((l1-depth/3)/depth*1024),0),255),
				b=math.min(math.max(math.floor((l1-depth/3*2)/depth*1024),0),255),
			}
		end
		palette[depth-1]={r=0,g=0,b=0}
		local map={}
		local mu={}
		for y=0,h-1 do
			map[y+1]={}
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
				local c=(((p.r*256)+p.g)*256)+p.b
				mu[c]=(mu[c] or 0)+1
				map[y+1][x+1]=c
			end
		end
		local dat=oci.encode(map,"yx24","oci")
		oci.render(dat)
		local ax
		local ay
		local bx
		local by
		while true do
			local p={event.pull()}
			if p[1]=="touch" then
				ax=p[3]
				ay=p[4]
			elseif p[1]=="drag" then
				bx=p[3]
				by=p[4]
			elseif p[1]=="key_down" then
				if p[4]==44 and zoom[1] then
					x0,x1,y0,y1=table.unpack(zoom[1])
					table.remove(zoom,1)
					break
				elseif p[4]==28 and ax and bx then
					table.insert(zoom,1,{x0,x1,y0,y1})
					x0=(((ax-1)/(w-1))*(x1-x0))+x0
					x1=(((bx-1)/(w-1))*(x1-x0))+x0
					y0=(((ay-1)/(h-1))*(y1-y0))+y0
					y1=(((by-1)/(h-1))*(y1-y0))+y0
					break
				elseif p[4]==16 then
					os.exit()
				end
			end
		end
	end
end)
gpu.setBackground(0x000000)
term.clear()
gpu.setResolution(oldw,oldh)
print("zoom:",x0,y0,x1,y1)
if not err and type(res)~="table" then
	print(res)
end
