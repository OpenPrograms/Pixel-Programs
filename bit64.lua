--[[

	bit64 API for OC/Lua 5.2
	by PixelToast
	
	numbers are formatted like {uint32,uint32} in big endian
	all functions accept numbers and hex strings
	
	TODO:
		arshift
		sub
		mult
		div
		mod
		pow
]]

local bit64={}

local band=bit32.band
local bor=bit32.bor
local bnot=bit32.bnot
local bxor=bit32.bxor
local lshift=bit32.lshift
local rshift=bit32.rshift
local ror=bit32.rrotate
local rol=bit32.lrotate

local function to64(...)
	local o={}
	for k,v in pairs({...}) do
		if type(v)=="number" then
			table.insert(o,{0,band(v)})
		elseif type(v)=="string" then
			local hex=v:match("^%x+$")
			if hex then
				hex=(("0"):rep(math.max(0,16-#hex))..hex):sub(1,16)
				table.insert(o,{tonumber("0x"..hex:sub(1,8)),tonumber("0x"..hex:sub(9))})
			else
				error("invalid number")
			end
		elseif type(v)=="table" then
			table.insert(o,{band(v[1]),band(v[2])})
		end
	end
	return table.unpack(o)
end

local function unpackn(t,i)
	local o={}
	for k,v in pairs(t) do
		table.insert(o,v[i])
	end
	return table.unpack(o)
end

function bit64.band(...)
	local p={to64(...)}
	return to64({band(unpackn(p,1)),band(unpackn(p,2))})
end

function bit64.bor(...)
	local p={to64(...)}
	return to64({bor(unpackn(p,1)),bor(unpackn(p,2))})
end

function bit64.bnot(a)
	a=to64(a)
	return to64({bnot(a[1]),bnot(a[2])})
end

function bit64.bxor(...)
	local p={to64(...)}
	return to64({bxor(unpackn(p,1)),bxor(unpackn(p,2))})
end

function bit64.lshift(a,b)
	a,b=to64(a),to64(b)
	local sh=b[2]%64
	if sh>=32 then
		return to64({lshift(a[2],sh%32),0})
	else
		return to64({bor(lshift(a[1],sh),rshift(a[2],32-sh)),lshift(a[2],sh)})
	end
end

function bit64.rshift(a,b)
	a,b=to64(a),to64(b)
	local sh=b[2]%64
	if sh>=32 then
		return to64({0,rshift(a[1],sh%32)})
	else
		return to64({rshift(a[1],sh),bor(rshift(a[2],sh),lshift(a[1],32-sh))})
	end
end

function bit64.rol(a,b)
	a,b=to64(a),to64(b)
	return bit64.bor(bit64.rshift(a,64-b[2]),bit64.lshift(a,b))
end
bit64.lrotate=bit64.rol

function bit64.ror(a,b)
	a,b=to64(a),to64(b)
	return bit64.bor(bit64.lshift(a,64-b[2]),bit64.rshift(a,b))
end
bit64.rrotate=bit64.ror

function bit64.add(...)
	local p={to64(...)}
	local c={0,0}
	for k,v in pairs(p) do
		c[2]=c[2]+v[2]
		c=to64({v[1]+c[1]+math.floor(c[2]/0x100000000),c[2]})
	end
	return c
end

return bit64