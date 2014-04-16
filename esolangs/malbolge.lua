-- Malbolge in Lua by PixelToast
 
local program=...
--program="(=<`#9]~6ZY32Vx/4Rs+0No-&Jk)\"Fh}|Bcy?`=*z]Kw%oG4UUS0/@-ejc(:'8dc"
 
assert(program,"No program.")
assert(#program>=2,"Minimum program is 2 chars.")
 
local enc={
	[0]=57 ,109,60 ,46 ,84 ,86 ,97 ,99 ,96 ,117,89 ,42 ,77 ,75 ,39 ,88 ,126,120,68 ,
	108,125,82 ,69 ,111,107,78 ,58 ,35 ,63 ,71 ,34 ,105,64 ,53 ,122,93 ,38 ,103,
	113,116,121,102,114,36 ,40 ,119,101,52 ,123,87 ,80 ,41 ,72 ,45 ,90 ,110,44 ,
	91 ,37 ,92 ,51 ,100,76 ,43 ,81 ,59 ,62 ,85 ,33 ,112,74 ,83 ,55 ,50 ,70 ,104,
	79 ,65 ,49 ,67 ,66 ,54 ,118,94 ,61 ,73 ,95 ,48 ,47 ,56 ,124,106,115,98 ,
}
 
local out={} -- remember output so initializing ram doesnt take years
-- crazy function
local function crz(a,b)
	local ot=out[a..","..b]
	if ot then
		return ot
	end
	local cr={[0]={[0]=1,0,0},{[0]=1,0,2},{[0]=2,2,1}}
	local o,bs=0
	for l1=0,9 do
		bs=3^l1
		o=o+(bs*cr[math.floor(a/bs)%3][math.floor(b/bs)%3])
	end
	out[a..","..b]=o
	return o
end
 
local a,c,d,bse,ins,mem=0,0,0,3^10,0,{}
-- load program into memory
for l1=1,#program do
	mem[l1-1]=string.byte(program,l1,l1)
end
-- fill in rest of memory
-- TODO: make precomputed table to make this faster
for l1=#mem+1,bse-1 do
	mem[l1]=crz(mem[l1-1],mem[l1-2])
end
 
while true do
	local op=(mem[c]+c)%94
	if op==4 then
		c=mem[d]
	elseif op==5 then
		io.write(string.char(a%256))
	elseif op==23 then
		a=string.byte(io.read(1))
	elseif op==39 then
		a=((mem[d]%3)*3^9)+math.floor(mem[d]/3)
		mem[d]=a
	elseif op==40 then
		d=mem[d]
	elseif op==62 then
		a=crz(mem[d],a)
		mem[d]=a
	elseif op==81 then
		return
	end
	mem[c]=enc[mem[c]%94] or mem[c]
	c=(c+1)%bse
	d=(d+1)%bse
	ins=ins+1
	-- just encase there is a infinite loop
	if ins>10000 then
		print("Time limit exeeded.")
		return
	end
end