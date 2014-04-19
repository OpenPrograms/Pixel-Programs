-- optimized mandlebrot renderer
-- http://puu.sh/8cs0i
local component=require("component")
local event=require("event")
local term=require("term")
local s=require("serialization")
local gpu=component.gpu
local oldw,oldh=gpu.getResolution()
local w,h=gpu.maxResolution()
gpu.setResolution(w,h)
local depth=32
local x0=-1.5
local y0=-1
local x1=0.5
local y1=1
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
local muc
local mun
for k,v in pairs(mu) do
	if v>(mun or 0) then
		muc=k
		mun=v
	end
end
gpu.setBackground(muc)
term.clear()
local cmp={}
for y=1,h do
	cmp[y]={}
	local c=map[y]
	for x=1,w do
		local cc=c[x]
		if cc~=muc then
			local mx=y+x
			local ct={y,x}
			local pmn=w
			for cy=y,h do
				if map[cy][x]~=cc then
					break
				end
				local m=x
				for cx=x,pmn do
					if map[cy][cx]~=cc then
						break
					end
					m=cx
				end
				pmn=math.min(pmn,m)
				if m+cy>mx then
					ct={cy,m}
				end
			end
			cmp[y][x]=ct
		end
	end
end
local opt=0
for y=1,h do
	local c=cmp[y]
	for x=1,w do
		local cc=c[x]
		if cc then
			local sz=(cc[1]-y)+(cc[2]-x)
			for sy=y,cc[1] do
				for sx=x,cc[2] do
					local sc=cmp[sy][sx]
					if sc and (sx~=x or sy~=y) and sc[1]<=cc[1] and sc[2]<=cc[2] and (sc[1]-sy)+(sc[2]-sx)<sz then
						cmp[sy][sx]=nil
						opt=opt+1
					end
				end
			end
		end
	end
end
for y=1,h do
	local c=cmp[y]
	for x=1,w do
		local cc=c[x]
		if cc then
			gpu.setBackground(map[y][x])
			gpu.fill(x,y,(cc[2]-x)+1,(cc[1]-y)+1," ")
		end
	end
end
--[====[
for y=1,h do
	local c=map[y]
	local u={}
	local cr=1
	while cr<w+1 do
		local cc=c[cr]
		if not u[cc] then
			u[cc]=true
			local l={}
			for l1=cr,w do
				if c[l1]==cc then
					table.insert(l,l1)
				else
					u[c[l1]]=false
				end
			end
			gpu.setBackground(cc)
			gpu.set(cr,y,(" "):rep((l[#l]-cr)+1))
		end
		cr=cr+1
	end
end
]====]
event.pull("key_down")
gpu.setBackground(0x000000)
term.clear()
gpu.setResolution(oldw,oldh)