-- text renderer, supports all capital letters, space, < and 3
-- edit line 86

local component=require("component")
local unicode=require("unicode")
local term=require("term")
term.clear()
local gpu=component.gpu
local holo=component.hologram
holo.setScale(2)
holo.clear()
local function bpack(bits)
	local o=0
	for k,v in pairs(bits) do
		o=o+((2^(k-1))*v)
	end
	return o
end
local function bunpack(num)
	local o={}
	for l1=1,32 do
		o[l1]=math.floor(num/2^(l1-1))%2
	end
	return o
end
local txt={
	A={" ### ","#   #","#####","#   #","#   #"},
	B={"#### ","#   #","#### ","#   #","#### "},
	C={" ####","#    ","#    ","#    "," ####"},
	D={"#### ","#   #","#   #","#   #","#### "},
	E={"#####","#    ","#####","#    ","#####"},
	F={"#####","#    ","#####","#    ","#    "},
	G={" ####","#    ","# ###","#   #"," ####"},
	H={"#   #","#   #","#####","#   #","#   #"},
	I={"#####","  #  ","  #  ","  #  ","#####"},
	J={" ####","    #","    #","#   #"," ### "},
	K={"#   #","#  # ","###  ","#  # ","#   #"},
	L={"#    ","#    ","#    ","#    ","#####"},
	M={" # # ","# # #","# # #","#   #","#   #"},
	N={"#   #","##  #","# # #","#  ##","#   #"},
	O={" ### ","#   #","#   #","#   #"," ### "},
	P={"#### ","#   #","#### ","#    ","#    "},
	Q={" ### ","#   #","# # #","#   #"," ####"},
	R={"#### ","#   #","#### ","#   #","#   #"},
	S={" ####","#    "," ### ","    #","#### "},
	T={"#####","  #  ","  #  ","  #  ","  #  "},
	U={"#   #","#   #","#   #","#   #"," ### "},
	V={"#   #","#   #","#   #"," # # ","  #  "},
	W={"#   #","#   #","# # #","# # #"," # # "},
	X={"#   #"," # # ","  #  "," # # ","#   #"},
	Y={"#   #","#   #"," # # ","  #  ","  #  "},
	Z={"#####","   # ","  #  "," #   ","#####"},
	[" "]={"     ","     ","     ","     ","     "},
	["<"]={"   # ","  #  "," #   ","  #  ","   # "},
	["3"]={"#### ","    #"," ### ","    #","#### "},
}
local dat={}
local zd={}
for z=1,32 do
	zd[z]=0
end
local fq={}
for x=1,48 do
	dat[x]={}
	fq[x]={}
	for y=1,48 do
		dat[x][y]={table.unpack(zd)}
		fq[x][y]=false
	end
end
local function set(x,y,z,st)
	fq[x][y]=true
	dat[x][y][z]=st and 1 or 0
end
local function fl()
	for x=1,48 do
		for	y=1,48 do
			if fq[x][y] then
				holo.set(x,y,bpack(dat[x][y]))
				fq[x][y]=nil
			end
		end
	end
end
local b=0
for char in ("<3 KODOS"):gmatch(".") do
	for l1=1,5 do
		for l2=1,5 do
			if txt[char][l1]:sub(l2,l2)~=" " then
				set(24,(l2)+b,(6-l1)+10,true)
				gpu.set(l2+b,l1,unicode.char(0x2588))
			end
		end
	end
	b=b+6
end
fl()
term.read()