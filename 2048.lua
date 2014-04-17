local component=require("component")
local term=require("term")
local event=require("event")
local gpu=component.gpu
local map={
	{0,0,0,0},
	{0,0,0,0},
	{0,0,0,0},
	{0,0,0,0},
}
local function up()
	local valid=false
	local rep
	local function shift(x)
		for y=2,4 do
			if map[y][x]>0 and map[y-1][x]==0 then
				map[y-1][x]=map[y][x]
				map[y][x]=0
				rep=true
				valid=true
			end
		end
	end
	for x=1,4 do
		rep=true
		while rep do
			rep=false
			shift(x)
		end
		local y=1
		while y<4 do
			if map[y+1][x]==map[y][x] then
				valid=true
				map[y][x]=map[y][x]*2
				map[y+1][x]=0
				shift(x)
			end
			y=y+1
		end
	end
	if not valid then
		os.exit()
	end
end
local function rightrotate(dir)
	local nmap={{},{},{},{}}
	for y,d in pairs(map) do
		for x,n in pairs(d) do
			nmap[x][5-y]=n
		end
	end
	for k,v in pairs(map) do
		map[k]=nmap[k]
	end
end
local function leftrotate(dir)
	local nmap={{},{},{},{}}
	for y,d in pairs(map) do
		for x,n in pairs(d) do
			nmap[5-x][y]=n
		end
	end
	for k,v in pairs(map) do
		map[k]=nmap[k]
	end
end
local function down()
	rightrotate()
	rightrotate()
	up()
	rightrotate()
	rightrotate()
end
local function left()
	rightrotate()
	up()
	leftrotate()
end
local function right()
	leftrotate()
	up()
	rightrotate()
end
local function step()
	term.clear()
	local sp={}
	for y=1,4 do
		for x=1,4 do
			if map[y][x]==0 then
				table.insert(sp,{y,x})
			end
		end
	end
	if #sp==1 then
		local y,x=table.unpack(sp[1])
		map[y][x]=2
	elseif #sp>0 then
		local y,x=table.unpack(sp[math.random(1,#sp)])
		map[y][x]=2
	end
	for y=1,4 do
		for x=1,4 do
			local n=tostring(map[y][x])
			if n~="0" then
				gpu.set(((x*5)-4)+(3-math.floor(#n/2)),(y*5)-2,n)
			end
		end
	end
end
step()
print(xpcall(function()
	while true do
		local _,_,_,key=event.pull("key_down")
		if key==200 then
			up()
			step()
		elseif key==205 then
			right()
			step()
		elseif key==208 then
			down()
			step()
		elseif key==203 then
			left()
			step()
		elseif key==16 then
			break
		end
	end
end,debug.traceback))