-- A befunge emulator that shows stack and IP
-- useful as a debugger or eye candy

local prg='0"!dlroW ,olleH">:#,_@'
-- this supports newlines

local component=require("component")
local gpu=component.gpu
local pt=require("pt")
local mem={}
local width=0
local sy=0
local stack={}
local term=require("term")
local mx,my=gpu.getResolution()
local function supdate()
	gpu.setForeground(0x000000)
	gpu.setBackground(0xFFFFFF)
	gpu.fill(mx-4,1,5,my," ")
	for l1=1,#stack do
		gpu.set(mx-4,l1,((stack[l1]>=32 and stack[l1]<=126) and string.char(stack[l1]) or " ").." "..stack[l1])
	end
	gpu.setForeground(0xFFFFFF)
	gpu.setBackground(0x000000)
end
local function push(val)
	supdate()
	table.insert(stack,1,math.floor(val%256))
end
local function pop(n)
	supdate()
	local v=stack[n or 1]
	table.remove(stack,n or 1)
	return v
end
gpu.setForeground(0xFFFFFF)
gpu.setBackground(0x000000)
term.clear()
supdate()
for line in prg:gmatch("[^\n]+") do
	sy=sy+1
	gpu.set(1,sy,line)
	width=math.max(width,#line)
	mem[sy]={string.byte(line,1,#line)}
end
term.setCursor(1,sy+1)
for ly=1,sy do
	for lx=1,width do
		mem[ly][lx]=mem[ly][lx] or 32
	end
end
local x=1
local y=1
local dir=2
local dirs={
	["^"]=1,
	[">"]=2,
	["v"]=3,
	["<"]=4,
}
local function update(nx,ny)
	if (mem[ny] or {})[nx] then
		local is=x==nx and y==ny
		gpu.setForeground(is and 0x000000 or 0xFFFFFF)
		gpu.setBackground(is and 0xFFFFFF or 0x000000)
		gpu.set(nx,ny,string.char(mem[ny][nx]))
		gpu.setForeground(0xFFFFFF)
		gpu.setBackground(0x000000)
	end
end
local strmode=false
while (mem[y] or {})[x] do
	update(x,y)
	os.sleep(0.25)
	local lastx=x
	local lasty=y
	local ins=string.char(mem[y][x])
	if strmode then
		if ins=="\"" then
			strmode=false
		else
			push(mem[y][x])
		end
	else
		if ins=="+" then
			push(pop()+pop())
		elseif ins=="-" then
			push(pop(2)-pop())
		elseif ins=="*" then
			push(pop(2)*pop())
		elseif ins=="/" then
			push(math.floor(pop(2)/pop()))
		elseif ins=="%" then
			push(pop(2)%pop())
		elseif ins=="!" then
			push(pop()==0 and 1 or 0)
		elseif ins=="`" then
			push(pop()>pop() and 1 or 0)
		elseif dirs[ins] then
			dir=dirs[ins]
		elseif ins=="?" then
			dir=math.random(1,4)
		elseif ins=="_" then
			dir=pop()==0 and 2 or 4
		elseif ins=="|" then
			dir=pop()==0 and 3 or 1
		elseif ins=="\"" then
			strmode=true
		elseif ins==":" then
			push(stack[1])
		elseif ins=="\\" then
			stack[1],stack[2]=stack[2],stack[1]
		elseif ins=="$" then
			pop()
		elseif ins=="." then
			io.write(pop())
		elseif ins=="," then
			io.write(string.char(pop()))
		elseif ins=="#" then
			x=x+(({[4]=-1,[2]=1})[dir] or 0)
			y=y+(({[1]=-1,[3]=1})[dir] or 0)
		elseif ins=="g" then
			push((mem[pop()] or {})[pop()] or 32)
		elseif ins=="p" then
			(mem[pop(2)] or {})[pop(2)]=pop()
		elseif ins=="&" then
			push(tonumber(io.read()))
		elseif ins=="~" then
			push(string.byte(io.read(1)))
		elseif ins=="@" then
			return
		elseif tonumber(ins) then
			push(tonumber(ins))
		end
	end
	x=x+(({[4]=-1,[2]=1})[dir] or 0)
	y=y+(({[1]=-1,[3]=1})[dir] or 0)
	update(lastx,lasty)
end