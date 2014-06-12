local bit64=require("bit64")
local bxor=bit64.bxor
local ror=bit64.ror
local rshift=bit64.rshift
local rol=bit64.rol
local band=bit64.band
local bnot=bit64.bnot
local add=bit64.add

local k={[0]=
	{0x428a2f98,0xd728ae22},{0x71374491,0x23ef65cd},{0xb5c0fbcf,0xec4d3b2f},{0xe9b5dba5,0x8189dbbc},{0x3956c25b,0xf348b538},
	{0x59f111f1,0xb605d019},{0x923f82a4,0xaf194f9b},{0xab1c5ed5,0xda6d8118},{0xd807aa98,0xa3030242},{0x12835b01,0x45706fbe},
	{0x243185be,0x4ee4b28c},{0x550c7dc3,0xd5ffb4e2},{0x72be5d74,0xf27b896f},{0x80deb1fe,0x3b1696b1},{0x9bdc06a7,0x25c71235},
	{0xc19bf174,0xcf692694},{0xe49b69c1,0x9ef14ad2},{0xefbe4786,0x384f25e3},{0x0fc19dc6,0x8b8cd5b5},{0x240ca1cc,0x77ac9c65},
	{0x2de92c6f,0x592b0275},{0x4a7484aa,0x6ea6e483},{0x5cb0a9dc,0xbd41fbd4},{0x76f988da,0x831153b5},{0x983e5152,0xee66dfab},
	{0xa831c66d,0x2db43210},{0xb00327c8,0x98fb213f},{0xbf597fc7,0xbeef0ee4},{0xc6e00bf3,0x3da88fc2},{0xd5a79147,0x930aa725},
	{0x06ca6351,0xe003826f},{0x14292967,0x0a0e6e70},{0x27b70a85,0x46d22ffc},{0x2e1b2138,0x5c26c926},{0x4d2c6dfc,0x5ac42aed},
	{0x53380d13,0x9d95b3df},{0x650a7354,0x8baf63de},{0x766a0abb,0x3c77b2a8},{0x81c2c92e,0x47edaee6},{0x92722c85,0x1482353b},
	{0xa2bfe8a1,0x4cf10364},{0xa81a664b,0xbc423001},{0xc24b8b70,0xd0f89791},{0xc76c51a3,0x0654be30},{0xd192e819,0xd6ef5218},
	{0xd6990624,0x5565a910},{0xf40e3585,0x5771202a},{0x106aa070,0x32bbd1b8},{0x19a4c116,0xb8d2d0c8},{0x1e376c08,0x5141ab53},
	{0x2748774c,0xdf8eeb99},{0x34b0bcb5,0xe19b48a8},{0x391c0cb3,0xc5c95a63},{0x4ed8aa4a,0xe3418acb},{0x5b9cca4f,0x7763e373},
	{0x682e6ff3,0xd6b2b8a3},{0x748f82ee,0x5defb2fc},{0x78a5636f,0x43172f60},{0x84c87814,0xa1f0ab72},{0x8cc70208,0x1a6439ec},
	{0x90befffa,0x23631e28},{0xa4506ceb,0xde82bde9},{0xbef9a3f7,0xb2c67915},{0xc67178f2,0xe372532b},{0xca273ece,0xea26619c},
	{0xd186b8c7,0x21c0c207},{0xeada7dd6,0xcde0eb1e},{0xf57d4f7f,0xee6ed178},{0x06f067aa,0x72176fba},{0x0a637dc5,0xa2c898a6},
	{0x113f9804,0xbef90dae},{0x1b710b35,0x131c471b},{0x28db77f5,0x23047d84},{0x32caab7b,0x40c72493},{0x3c9ebe0a,0x15c9bebc},
	{0x431d67c4,0x9c100d4c},{0x4cc5d4be,0xcb3e42b6},{0x597f299c,0xfc657e2a},{0x5fcb6fab,0x3ad6faec},{0x6c44198c,0x4a475817}
}

local function chars2num(txt)
	return {
		(txt:byte(1)*16777216)+(txt:byte(2)*65536)+(txt:byte(3)*256)+(txt:byte(4)),
		(txt:byte(5)*16777216)+(txt:byte(6)*65536)+(txt:byte(7)*256)+(txt:byte(8))
	}
end

local function num2chars(num)
	if type(num)=="number" then
		return string.char((num/16777216)%256,(num/65536)%256,(num/256)%256,num%256)
	else
		return string.char(
			(num[1]/16777216)%256,(num[1]/65536)%256,(num[1]/256)%256,num[1]%256,
			(num[2]/16777216)%256,(num[2]/65536)%256,(num[2]/256)%256,num[2]%256
		)
	end
end

local function num2hex(num)
	return string.format("%08x",num[1])..string.format("%08x",num[2])
end

local function sha512(txt,nohex)
	local ha={[0]=
		{0x6a09e667,0xf3bcc908},{0xbb67ae85,0x84caa73b},{0x3c6ef372,0xfe94f82b},{0xa54ff53a,0x5f1d36f1},
		{0x510e527f,0xade682d1},{0x9b05688c,0x2b3e6c1f},{0x1f83d9ab,0xfb41bd6b},{0x5be0cd19,0x137e2179}
	}
	local len=#txt
	txt=txt.."\128"..("\0"):rep(132-((len+9)%128))..num2chars(8*len)
	assert(#txt%128==0,#txt)
	assert(#txt>0)
	local w={}
	for chunkind=1,#txt,128 do
		local rawchunk=txt:sub(chunkind,chunkind+127)
		local chunk={}
		for i=1,128,8 do
			chunk[math.floor(i/8)]=chars2num(rawchunk:sub(i))
		end
		for i=0,15 do
			w[i]=chunk[i]
		end
		for i=16,79 do
			local s0=bxor(ror(w[i-15],1),ror(w[i-15],8),rshift(w[i-15],7))
			local s1=bxor(ror(w[i-2],19),ror(w[i-2],61),rshift(w[i-2],6))
			w[i]=add(w[i-16],s0,w[i-7],s1)
		end
		local a,b,c,d,e,f,g,h=ha[0],ha[1],ha[2],ha[3],ha[4],ha[5],ha[6],ha[7]
		for i=0,79 do
			local S1=bxor(ror(e,14),ror(e,18),ror(e,41))
			local ch=bxor(band(e,f),band(bnot(e),g))
			local temp1=add(h,S1,ch,k[i],w[i])
			local S0=bxor(ror(a,28),ror(a,34),ror(a,39))
			local maj=bxor(band(a,b),band(a,c),band(b,c))
			local temp2=add(S0,maj)
			a,b,c,d,e,f,g,h=add(temp1,temp2),a,b,c,add(d,temp1),e,f,g
		end
		ha[0],ha[1],ha[2],ha[3],ha[4],ha[5],ha[6],ha[7]=add(ha[0],a),add(ha[1],b),add(ha[2],c),add(ha[3],d),add(ha[4],e),add(ha[5],f),add(ha[6],g),add(ha[7],h)
	end
	local cnv=nohex and num2chars or num2hex
	return
		cnv(ha[0])..cnv(ha[1])..cnv(ha[2])..cnv(ha[3])..
		cnv(ha[4])..cnv(ha[5])..cnv(ha[6])..cnv(ha[7])
end

return sha512
