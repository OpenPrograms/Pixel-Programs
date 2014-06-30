-----------------------------------------------------------------------------------------------------------------------------
-- crypto library by PixelToast
-- functions:
--   bit64:
--     to64(...) converts numbers to 64 bit
--     band(...)
--     bor(...)
--     bnot(x)
--     bxor(...)
--     lshift(x,n)
--     rshift(x,n)
--     rrotate(x,n) ror(x,n)
--     lrotate(x,n) rol(x,n)
--     add(...)
--   hash:
--     sha256(txt[,nohex])
--     sha512(txt[,nohex])
--   checksum:
--     crc32(txt[,nohex])
--     crc64(txt[,nohex])
--   encrypt:
--     rc4(key[,state]) returns function to encrypt and the state table
--   decrypt:
--     rc4(key[,state]) returns function to encrypt and the state table
--   encode:
--     b64(txt)
--     hex(txt)
--   decode (no error checking, so watch out):
--     b64(txt)
--     hex(txt)
-- todo:
--   signatures
--   DH
--   network protocol
-----------------------------------------------------------------------------------------------------------------------------

local band=bit32.band
local bor=bit32.bor
local bnot=bit32.bnot
local bxor=bit32.bxor
local lshift=bit32.lshift
local rshift=bit32.rshift
local rrotate=bit32.rrotate
local lrotate=bit32.lrotate
local byte=string.byte
local char=string.char
local format=string.format
local floor=math.floor

local function chars2num(txt)
	return (txt:byte(1)*16777216)+(txt:byte(2)*65536)+(txt:byte(3)*256)+(txt:byte(4))
end

local function limit(num)
	return band(num)
end

local function num2chars(num,l)
	local out=""
	for l1=1,l or 4 do
		out=char(floor(num/(256^(l1-1)))%256)..out
	end
	return out
end

local _num2hex={}
for l1=0,255 do
	hr[l1]=format("%02x",l1)
end

local function num2hex(num)
	return _num2hex[floor(num/16777216)%256].._num2hex[floor(num/65536)%256].._num2hex[floor(num/256)%256].._num2hex[num%256]
end

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

local function band64(...)
	local p={...}
	local a,b=0,0
	for i=1,#p do
		a=band(a,p[i][1])
		b=band(b,p[i][2])
	end
	return {a,b}
end

local function bor64(...)
	local p={...}
	local a,b=0,0
	for i=1,#p do
		a=bor(a,p[i][1])
		b=bor(b,p[i][2])
	end
	return {a,b}
end

local function bnot64(a)
	return {bnot(a[1]),bnot(a[2])}
end

local function bxor64(...)
	local p={...}
	local a,b=0,0
	for i=1,#p do
		a=bxor(a,p[i][1])
		b=bxor(b,p[i][2])
	end
	return {a,b}
end

local function lshift64(a,b)
	local sh=b[2]%64
	if sh>=32 then
		return {lshift(a[2],sh%32),0}
	else
		return {bor(lshift(a[1],sh),rshift(a[2],32-sh)),lshift(a[2],sh)}
	end
end

local function rshift64(a,b)
	local sh=b[2]%64
	if sh>=32 then
		return {0,rshift(a[1],sh%32)}
	else
		return {rshift(a[1],sh),bor(rshift(a[2],sh),lshift(a[1],32-sh))}
	end
end

local function lrotate64(a,b)
	return bor64(rshift64(a,64-b[2]),lshift64(a,b))
end

local function rrotate64(a,b)
	return bor64(lshift64(a,{0,64-b[2]}),rshift64(a,b))
end

local function add64(...)
	local p={...}
	local c={0,0}
	for k,v in pairs(p) do
		c[2]=c[2]+v[2]
		c[1]=band(v[1]+c[1]+floor(c[2]/0x100000000))
		c[2]=band(c[2])
	end
	return c
end

local function chars2num64(txt)
	return {
		(txt:byte(1)*16777216)+(txt:byte(2)*65536)+(txt:byte(3)*256)+(txt:byte(4)),
		(txt:byte(5)*16777216)+(txt:byte(6)*65536)+(txt:byte(7)*256)+(txt:byte(8))
	}
end

local function num2chars64(num)
	if type(num)=="number" then
		return char((num/16777216)%256,(num/65536)%256,(num/256)%256,num%256)
	else
		return char(
			(num[1]/16777216)%256,(num[1]/65536)%256,(num[1]/256)%256,num[1]%256,
			(num[2]/16777216)%256,(num[2]/65536)%256,(num[2]/256)%256,num[2]%256
		)
	end
end

local function num2hex64(num)
	return string.format("%08x",num[1])..string.format("%08x",num[2])
end

-----------------------------------------------------------------------------------------------------------------------------
-- hashes                                                                                                                  --
-----------------------------------------------------------------------------------------------------------------------------

local sha256
do
	local k={[0]=
		0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
		0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
		0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
		0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
		0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
		0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
		0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
		0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2,
	}
	local ha,len,w,rawchunk,a,b,c,d,e,f,g,h,temp1,cnv
	function sha256(txt,nohex)
		ha={[0]=
			0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,
			0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19,
		}
		len=#txt
		txt=txt.."\128"..("\0"):rep(64-((len+9)%64))..num2chars(8*len,8)
		w={}
		for chunkind=1,#txt,64 do
			rawchunk=txt:sub(chunkind,chunkind+63)
			for i=1,64,4 do
				w[floor(i/4)]=chars2num(rawchunk:sub(i))
			end
			for i=16,63 do
				w[i]=w[i-16]+bxor(rrotate(w[i-15],7),rrotate(w[i-15],18),rshift(w[i-15],3))+w[i-7]+bxor(rrotate(w[i-2],17),rrotate(w[i-2],19),rshift(w[i-2],10))
			end
			a,b,c,d,e,f,g,h=ha[0],ha[1],ha[2],ha[3],ha[4],ha[5],ha[6],ha[7]
			for i=0,63 do
				temp1=limit(limit(h+bxor(rrotate(e,6),rrotate(e,11),rrotate(e,25)))+limit(bxor(band(e,f),band(bnot(e),g))+k[i]+w[i]))
				a,b,c,d,e,f,g,h=limit(temp1+bxor(rrotate(a,2),rrotate(a,13),rrotate(a,22))+bxor(band(a,b),band(a,c),band(b,c))),a,b,c,limit(d+temp1),e,f,g
			end
			ha[0],ha[1],ha[2],ha[3],ha[4],ha[5],ha[6],ha[7]=limit(ha[0]+a),limit(ha[1]+b),limit(ha[2]+c),limit(ha[3]+d),limit(ha[4]+e),limit(ha[5]+f),limit(ha[6]+g),limit(ha[7]+h)
		end
		cnv=nohex and num2chars or num2hex
		return
			cnv(ha[0])..cnv(ha[1])..cnv(ha[2])..cnv(ha[3])..
			cnv(ha[4])..cnv(ha[5])..cnv(ha[6])..cnv(ha[7])
	end
end

local sha512
do
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
	
	local ha,len,w,rawchunk,a,b,c,d,e,f,g,h,temp1,cnv
	local c1={0,1}
	local c6={0,6}
	local c7={0,7}
	local c8={0,8}
	local c14={0,14}
	local c18={0,18}
	local c19={0,19}
	local c28={0,28}
	local c34={0,34}
	local c39={0,39}
	local c41={0,41}
	local c61={0,61}
	function sha512(txt,nohex)
		ha={[0]=
			{0x6a09e667,0xf3bcc908},{0xbb67ae85,0x84caa73b},{0x3c6ef372,0xfe94f82b},{0xa54ff53a,0x5f1d36f1},
			{0x510e527f,0xade682d1},{0x9b05688c,0x2b3e6c1f},{0x1f83d9ab,0xfb41bd6b},{0x5be0cd19,0x137e2179}
		}
		len=#txt
		txt=txt.."\128"..("\0"):rep(132-((len+9)%128))..num2chars64(8*len)
		w={}
		for chunkind=1,#txt,128 do
			rawchunk=txt:sub(chunkind,chunkind+127)
			for i=1,128,8 do
				w[floor(i/8)]=chars2num64(rawchunk:sub(i))
			end
			for i=16,79 do
				w[i]=add64(
					w[i-16],
					bxor64(
						rrotate64(w[i-15],c1),
						rrotate64(w[i-15],c8),
						rshift64(w[i-15],c7)
					),
					w[i-7],
					bxor64(
						rrotate64(w[i-2],c19),
						rrotate64(w[i-2],c61),
						rshift64(w[i-2],c6)
					)
				)
			end
			a,b,c,d,e,f,g,h=ha[0],ha[1],ha[2],ha[3],ha[4],ha[5],ha[6],ha[7]
			for i=0,79 do
				temp1=add64(h,bxor64(rrotate64(e,c14),rrotate64(e,c18),rrotate64(e,c41)),bxor64(band64(e,f),band64(bnot64(e),g)),k[i],w[i])
				a,b,c,d,e,f,g,h=add64(temp1,add64(bxor64(rrotate64(a,c28),rrotate64(a,c34),rrotate64(a,c39)),bxor64(band64(a,b),band64(a,c),band64(b,c)))),a,b,c,add64(d,temp1),e,f,g
			end
			ha[0],ha[1],ha[2],ha[3],ha[4],ha[5],ha[6],ha[7]=add64(ha[0],a),add64(ha[1],b),add64(ha[2],c),add64(ha[3],d),add64(ha[4],e),add64(ha[5],f),add64(ha[6],g),add64(ha[7],h)
		end
		cnv=nohex and num2chars64 or num2hex64
		return
			cnv(ha[0])..cnv(ha[1])..cnv(ha[2])..cnv(ha[3])..
			cnv(ha[4])..cnv(ha[5])..cnv(ha[6])..cnv(ha[7])
	end
end

-----------------------------------------------------------------------------------------------------------------------------
-- checksums                                                                                                               --
-----------------------------------------------------------------------------------------------------------------------------

do
	local crc32dat={
		0x00000000,0x77073096,0xee0e612c,0x990951ba,0x076dc419,0x706af48f,0xe963a535,0x9e6495a3,
		0x0edb8832,0x79dcb8a4,0xe0d5e91e,0x97d2d988,0x09b64c2b,0x7eb17cbd,0xe7b82d07,0x90bf1d91,
		0x1db71064,0x6ab020f2,0xf3b97148,0x84be41de,0x1adad47d,0x6ddde4eb,0xf4d4b551,0x83d385c7,
		0x136c9856,0x646ba8c0,0xfd62f97a,0x8a65c9ec,0x14015c4f,0x63066cd9,0xfa0f3d63,0x8d080df5,
		0x3b6e20c8,0x4c69105e,0xd56041e4,0xa2677172,0x3c03e4d1,0x4b04d447,0xd20d85fd,0xa50ab56b,
		0x35b5a8fa,0x42b2986c,0xdbbbc9d6,0xacbcf940,0x32d86ce3,0x45df5c75,0xdcd60dcf,0xabd13d59,
		0x26d930ac,0x51de003a,0xc8d75180,0xbfd06116,0x21b4f4b5,0x56b3c423,0xcfba9599,0xb8bda50f,
		0x2802b89e,0x5f058808,0xc60cd9b2,0xb10be924,0x2f6f7c87,0x58684c11,0xc1611dab,0xb6662d3d,
		0x76dc4190,0x01db7106,0x98d220bc,0xefd5102a,0x71b18589,0x06b6b51f,0x9fbfe4a5,0xe8b8d433,
		0x7807c9a2,0x0f00f934,0x9609a88e,0xe10e9818,0x7f6a0dbb,0x086d3d2d,0x91646c97,0xe6635c01,
		0x6b6b51f4,0x1c6c6162,0x856530d8,0xf262004e,0x6c0695ed,0x1b01a57b,0x8208f4c1,0xf50fc457,
		0x65b0d9c6,0x12b7e950,0x8bbeb8ea,0xfcb9887c,0x62dd1ddf,0x15da2d49,0x8cd37cf3,0xfbd44c65,
		0x4db26158,0x3ab551ce,0xa3bc0074,0xd4bb30e2,0x4adfa541,0x3dd895d7,0xa4d1c46d,0xd3d6f4fb,
		0x4369e96a,0x346ed9fc,0xad678846,0xda60b8d0,0x44042d73,0x33031de5,0xaa0a4c5f,0xdd0d7cc9,
		0x5005713c,0x270241aa,0xbe0b1010,0xc90c2086,0x5768b525,0x206f85b3,0xb966d409,0xce61e49f,
		0x5edef90e,0x29d9c998,0xb0d09822,0xc7d7a8b4,0x59b33d17,0x2eb40d81,0xb7bd5c3b,0xc0ba6cad,
		0xedb88320,0x9abfb3b6,0x03b6e20c,0x74b1d29a,0xead54739,0x9dd277af,0x04db2615,0x73dc1683,
		0xe3630b12,0x94643b84,0x0d6d6a3e,0x7a6a5aa8,0xe40ecf0b,0x9309ff9d,0x0a00ae27,0x7d079eb1,
		0xf00f9344,0x8708a3d2,0x1e01f268,0x6906c2fe,0xf762575d,0x806567cb,0x196c3671,0x6e6b06e7,
		0xfed41b76,0x89d32be0,0x10da7a5a,0x67dd4acc,0xf9b9df6f,0x8ebeeff9,0x17b7be43,0x60b08ed5,
		0xd6d6a3e8,0xa1d1937e,0x38d8c2c4,0x4fdff252,0xd1bb67f1,0xa6bc5767,0x3fb506dd,0x48b2364b,
		0xd80d2bda,0xaf0a1b4c,0x36034af6,0x41047a60,0xdf60efc3,0xa867df55,0x316e8eef,0x4669be79,
		0xcb61b38c,0xbc66831a,0x256fd2a0,0x5268e236,0xcc0c7795,0xbb0b4703,0x220216b9,0x5505262f,
		0xc5ba3bbe,0xb2bd0b28,0x2bb45a92,0x5cb36a04,0xc2d7ffa7,0xb5d0cf31,0x2cd99e8b,0x5bdeae1d,
		0x9b64c2b0,0xec63f226,0x756aa39c,0x026d930a,0x9c0906a9,0xeb0e363f,0x72076785,0x05005713,
		0x95bf4a82,0xe2b87a14,0x7bb12bae,0x0cb61b38,0x92d28e9b,0xe5d5be0d,0x7cdcefb7,0x0bdbdf21,
		0x86d3d2d4,0xf1d4e242,0x68ddb3f8,0x1fda836e,0x81be16cd,0xf6b9265b,0x6fb077e1,0x18b74777,
		0x88085ae6,0xff0f6a70,0x66063bca,0x11010b5c,0x8f659eff,0xf862ae69,0x616bffd3,0x166ccf45,
		0xa00ae278,0xd70dd2ee,0x4e048354,0x3903b3c2,0xa7672661,0xd06016f7,0x4969474d,0x3e6e77db,
		0xaed16a4a,0xd9d65adc,0x40df0b66,0x37d83bf0,0xa9bcae53,0xdebb9ec5,0x47b2cf7f,0x30b5ffe9,
		0xbdbdf21c,0xcabac28a,0x53b39330,0x24b4a3a6,0xbad03605,0xcdd70693,0x54de5729,0x23d967bf,
		0xb3667a2e,0xc4614ab8,0x5d681b02,0x2a6f2b94,0xb40bbe37,0xc30c8ea1,0x5a05df1b,0x2d02ef8d
	}

	function crc32(txt,nohex)
		local crc=bit.bnot(0)
		for l1=1,#txt do
			crc=bit.bxor(bit.rshift(crc,8),crc32dat[bit.bxor(bit.band(crc,0xFF),txt:byte(l1,l1))+1])
		end
		return nohex and bit.bnot(crc) or 
	end
end

do
	local crc64dat={
		{0x00000000,0x00000000},{0x7ad870c8,0x30358979},{0xf5b0e190,0x606b12f2},{0x8f689158,0x505e9b8b},
		{0xc038e573,0x9841b68f},{0xbae095bb,0xa8743ff6},{0x358804e3,0xf82aa47d},{0x4f50742b,0xc81f2d04},
		{0xab28ecb4,0x6814fe75},{0xd1f09c7c,0x5821770c},{0x5e980d24,0x087fec87},{0x24407dec,0x384a65fe},
		{0x6b1009c7,0xf05548fa},{0x11c8790f,0xc060c183},{0x9ea0e857,0x903e5a08},{0xe478989f,0xa00bd371},
		{0x7d08ff3b,0x88be6f81},{0x07d08ff3,0xb88be6f8},{0x88b81eab,0xe8d57d73},{0xf2606e63,0xd8e0f40a},
		{0xbd301a48,0x10ffd90e},{0xc7e86a80,0x20ca5077},{0x4880fbd8,0x7094cbfc},{0x32588b10,0x40a14285},
		{0xd620138f,0xe0aa91f4},{0xacf86347,0xd09f188d},{0x2390f21f,0x80c18306},{0x594882d7,0xb0f40a7f},
		{0x1618f6fc,0x78eb277b},{0x6cc08634,0x48deae02},{0xe3a8176c,0x18803589},{0x997067a4,0x28b5bcf0},
		{0xfa11fe77,0x117cdf02},{0x80c98ebf,0x2149567b},{0x0fa11fe7,0x7117cdf0},{0x75796f2f,0x41224489},
		{0x3a291b04,0x893d698d},{0x40f16bcc,0xb908e0f4},{0xcf99fa94,0xe9567b7f},{0xb5418a5c,0xd963f206},
		{0x513912c3,0x79682177},{0x2be1620b,0x495da80e},{0xa489f353,0x19033385},{0xde51839b,0x2936bafc},
		{0x9101f7b0,0xe12997f8},{0xebd98778,0xd11c1e81},{0x64b11620,0x8142850a},{0x1e6966e8,0xb1770c73},
		{0x8719014c,0x99c2b083},{0xfdc17184,0xa9f739fa},{0x72a9e0dc,0xf9a9a271},{0x08719014,0xc99c2b08},
		{0x4721e43f,0x0183060c},{0x3df994f7,0x31b68f75},{0xb29105af,0x61e814fe},{0xc8497567,0x51dd9d87},
		{0x2c31edf8,0xf1d64ef6},{0x56e99d30,0xc1e3c78f},{0xd9810c68,0x91bd5c04},{0xa3597ca0,0xa188d57d},
		{0xec09088b,0x6997f879},{0x96d17843,0x59a27100},{0x19b9e91b,0x09fcea8b},{0x636199d3,0x39c963f2},
		{0xdf7adabd,0x7a6e2d6f},{0xa5a2aa75,0x4a5ba416},{0x2aca3b2d,0x1a053f9d},{0x50124be5,0x2a30b6e4},
		{0x1f423fce,0xe22f9be0},{0x659a4f06,0xd21a1299},{0xeaf2de5e,0x82448912},{0x902aae96,0xb271006b},
		{0x74523609,0x127ad31a},{0x0e8a46c1,0x224f5a63},{0x81e2d799,0x7211c1e8},{0xfb3aa751,0x42244891},
		{0xb46ad37a,0x8a3b6595},{0xceb2a3b2,0xba0eecec},{0x41da32ea,0xea507767},{0x3b024222,0xda65fe1e},
		{0xa2722586,0xf2d042ee},{0xd8aa554e,0xc2e5cb97},{0x57c2c416,0x92bb501c},{0x2d1ab4de,0xa28ed965},
		{0x624ac0f5,0x6a91f461},{0x1892b03d,0x5aa47d18},{0x97fa2165,0x0afae693},{0xed2251ad,0x3acf6fea},
		{0x095ac932,0x9ac4bc9b},{0x7382b9fa,0xaaf135e2},{0xfcea28a2,0xfaafae69},{0x8632586a,0xca9a2710},
		{0xc9622c41,0x02850a14},{0xb3ba5c89,0x32b0836d},{0x3cd2cdd1,0x62ee18e6},{0x460abd19,0x52db919f},
		{0x256b24ca,0x6b12f26d},{0x5fb35402,0x5b277b14},{0xd0dbc55a,0x0b79e09f},{0xaa03b592,0x3b4c69e6},
		{0xe553c1b9,0xf35344e2},{0x9f8bb171,0xc366cd9b},{0x10e32029,0x93385610},{0x6a3b50e1,0xa30ddf69},
		{0x8e43c87e,0x03060c18},{0xf49bb8b6,0x33338561},{0x7bf329ee,0x636d1eea},{0x012b5926,0x53589793},
		{0x4e7b2d0d,0x9b47ba97},{0x34a35dc5,0xab7233ee},{0xbbcbcc9d,0xfb2ca865},{0xc113bc55,0xcb19211c},
		{0x5863dbf1,0xe3ac9dec},{0x22bbab39,0xd3991495},{0xadd33a61,0x83c78f1e},{0xd70b4aa9,0xb3f20667},
		{0x985b3e82,0x7bed2b63},{0xe2834e4a,0x4bd8a21a},{0x6debdf12,0x1b863991},{0x1733afda,0x2bb3b0e8},
		{0xf34b3745,0x8bb86399},{0x8993478d,0xbb8deae0},{0x06fbd6d5,0xebd3716b},{0x7c23a61d,0xdbe6f812},
		{0x3373d236,0x13f9d516},{0x49aba2fe,0x23cc5c6f},{0xc6c333a6,0x7392c7e4},{0xbc1b436e,0x43a74e9d},
		{0x95ac9329,0xac4bc9b5},{0xef74e3e1,0x9c7e40cc},{0x601c72b9,0xcc20db47},{0x1ac40271,0xfc15523e},
		{0x5594765a,0x340a7f3a},{0x2f4c0692,0x043ff643},{0xa02497ca,0x54616dc8},{0xdafce702,0x6454e4b1},
		{0x3e847f9d,0xc45f37c0},{0x445c0f55,0xf46abeb9},{0xcb349e0d,0xa4342532},{0xb1eceec5,0x9401ac4b},
		{0xfebc9aee,0x5c1e814f},{0x8464ea26,0x6c2b0836},{0x0b0c7b7e,0x3c7593bd},{0x71d40bb6,0x0c401ac4},
		{0xe8a46c12,0x24f5a634},{0x927c1cda,0x14c02f4d},{0x1d148d82,0x449eb4c6},{0x67ccfd4a,0x74ab3dbf},
		{0x289c8961,0xbcb410bb},{0x5244f9a9,0x8c8199c2},{0xdd2c68f1,0xdcdf0249},{0xa7f41839,0xecea8b30},
		{0x438c80a6,0x4ce15841},{0x3954f06e,0x7cd4d138},{0xb63c6136,0x2c8a4ab3},{0xcce411fe,0x1cbfc3ca},
		{0x83b465d5,0xd4a0eece},{0xf96c151d,0xe49567b7},{0x76048445,0xb4cbfc3c},{0x0cdcf48d,0x84fe7545},
		{0x6fbd6d5e,0xbd3716b7},{0x15651d96,0x8d029fce},{0x9a0d8cce,0xdd5c0445},{0xe0d5fc06,0xed698d3c},
		{0xaf85882d,0x2576a038},{0xd55df8e5,0x15432941},{0x5a3569bd,0x451db2ca},{0x20ed1975,0x75283bb3},
		{0xc49581ea,0xd523e8c2},{0xbe4df122,0xe51661bb},{0x3125607a,0xb548fa30},{0x4bfd10b2,0x857d7349},
		{0x04ad6499,0x4d625e4d},{0x7e751451,0x7d57d734},{0xf11d8509,0x2d094cbf},{0x8bc5f5c1,0x1d3cc5c6},
		{0x12b59265,0x35897936},{0x686de2ad,0x05bcf04f},{0xe70573f5,0x55e26bc4},{0x9ddd033d,0x65d7e2bd},
		{0xd28d7716,0xadc8cfb9},{0xa85507de,0x9dfd46c0},{0x273d9686,0xcda3dd4b},{0x5de5e64e,0xfd965432},
		{0xb99d7ed1,0x5d9d8743},{0xc3450e19,0x6da80e3a},{0x4c2d9f41,0x3df695b1},{0x36f5ef89,0x0dc31cc8},
		{0x79a59ba2,0xc5dc31cc},{0x037deb6a,0xf5e9b8b5},{0x8c157a32,0xa5b7233e},{0xf6cd0afa,0x9582aa47},
		{0x4ad64994,0xd625e4da},{0x300e395c,0xe6106da3},{0xbf66a804,0xb64ef628},{0xc5bed8cc,0x867b7f51},
		{0x8aeeace7,0x4e645255},{0xf036dc2f,0x7e51db2c},{0x7f5e4d77,0x2e0f40a7},{0x05863dbf,0x1e3ac9de},
		{0xe1fea520,0xbe311aaf},{0x9b26d5e8,0x8e0493d6},{0x144e44b0,0xde5a085d},{0x6e963478,0xee6f8124},
		{0x21c64053,0x2670ac20},{0x5b1e309b,0x16452559},{0xd476a1c3,0x461bbed2},{0xaeaed10b,0x762e37ab},
		{0x37deb6af,0x5e9b8b5b},{0x4d06c667,0x6eae0222},{0xc26e573f,0x3ef099a9},{0xb8b627f7,0x0ec510d0},
		{0xf7e653dc,0xc6da3dd4},{0x8d3e2314,0xf6efb4ad},{0x0256b24c,0xa6b12f26},{0x788ec284,0x9684a65f},
		{0x9cf65a1b,0x368f752e},{0xe62e2ad3,0x06bafc57},{0x6946bb8b,0x56e467dc},{0x139ecb43,0x66d1eea5},
		{0x5ccebf68,0xaecec3a1},{0x2616cfa0,0x9efb4ad8},{0xa97e5ef8,0xcea5d153},{0xd3a62e30,0xfe90582a},
		{0xb0c7b7e3,0xc7593bd8},{0xca1fc72b,0xf76cb2a1},{0x45775673,0xa732292a},{0x3faf26bb,0x9707a053},
		{0x70ff5290,0x5f188d57},{0x0a272258,0x6f2d042e},{0x854fb300,0x3f739fa5},{0xff97c3c8,0x0f4616dc},
		{0x1bef5b57,0xaf4dc5ad},{0x61372b9f,0x9f784cd4},{0xee5fbac7,0xcf26d75f},{0x9487ca0f,0xff135e26},
		{0xdbd7be24,0x370c7322},{0xa10fceec,0x0739fa5b},{0x2e675fb4,0x576761d0},{0x54bf2f7c,0x6752e8a9},
		{0xcdcf48d8,0x4fe75459},{0xb7173810,0x7fd2dd20},{0x387fa948,0x2f8c46ab},{0x42a7d980,0x1fb9cfd2},
		{0x0df7adab,0xd7a6e2d6},{0x772fdd63,0xe7936baf},{0xf8474c3b,0xb7cdf024},{0x829f3cf3,0x87f8795d},
		{0x66e7a46c,0x27f3aa2c},{0x1c3fd4a4,0x17c62355},{0x935745fc,0x4798b8de},{0xe98f3534,0x77ad31a7},
		{0xa6df411f,0xbfb21ca3},{0xdc0731d7,0x8f8795da},{0x536fa08f,0xdfd90e51},{0x29b7d047,0xefec8728}
	}
	
	function crc64(txt,nohex)
		local crc=bnot64(0)
		for l1=1,#txt do
			crc=bxor64(crc64dat[bxor64(crc,byte(txt))],rshift64(crc,8))
		end
		return nohex and crc or num2hex64(crc)
	end
end


-----------------------------------------------------------------------------------------------------------------------------
-- encryption                                                                                                              --
-----------------------------------------------------------------------------------------------------------------------------

local rc4
do
	local function crypt(txt,state)
		local len=#txt
		local sch=state.sch
		local k={}
		for i=1,len do
			sch[state.i],sch[state.j]=(state.j+sch[state.i-1])%256,(state.i+1)%256
			k[i]=sch[(sch[state.i-1]+sch[state.j-1]-1)%256]
		end
		local out=""
		for i=1,len do
			out=out..char(bxor(k[i],byte(txt,i)))
		end
		return out
	end
	function rc4(key,state)
		local len=#key
		key={byte(key,1,-1)}
		local sch={}
		for i=0,255 do
			sch[i]=i
		end
		local j=0
		for i=0,255 do
			j=(j+sch[i]+key[(i%len)+1])%256
			sch[i],sch[j]=sch[j],sch[i]
		end
		state=state or {
			i=0,
			j=0,
			sch=sch
		}
		return function(txt)
			return cipher(txt,state)
		end,state
	end
end

-----------------------------------------------------------------------------------------------------------------------------
-- encoding                                                                                                                --
-----------------------------------------------------------------------------------------------------------------------------

local _tob64={
	[0]="A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
	"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
	"0","1","2","3","4","5","6","7","8","9","+","/"
}

local function tob64(txt)
	local d,o,d1,d2,d3={byte(txt,1,#txt)},""
	for l1=1,#txt-2,3 do
		d1,d2,d3=d[l1],d[l1+1],d[l1+2]
		o=o.._tob64[floor(d1/4)].._tob64[((d1%4)*16)+floor(d2/16)].._tob64[((d2%16)*4)+floor(d3/64)].._tob64[d3%64]
	end
	local m=#txt%3
	if m==1 then
		o=o.._tob64[floor(d[#txt]/4)].._tob64[((d[#txt]%4)*16)].."=="
	elseif m==2 then
		o=o.._tob64[floor(d[#txt-1]/4)].._tob64[((d[#txt-1]%4)*16)+floor(d[#txt]/16)].._tob64[(d[#txt]%16)*4].."="
	end
	return o
end

local _unb64={
	["A"]=0,["B"]=1,["C"]=2,["D"]=3,["E"]=4,["F"]=5,["G"]=6,["H"]=7,["I"]=8,["J"]=9,["K"]=10,["L"]=11,["M"]=12,["N"]=13,
	["O"]=14,["P"]=15,["Q"]=16,["R"]=17,["S"]=18,["T"]=19,["U"]=20,["V"]=21,["W"]=22,["X"]=23,["Y"]=24,["Z"]=25,
	["a"]=26,["b"]=27,["c"]=28,["d"]=29,["e"]=30,["f"]=31,["g"]=32,["h"]=33,["i"]=34,["j"]=35,["k"]=36,["l"]=37,["m"]=38,
	["n"]=39,["o"]=40,["p"]=41,["q"]=42,["r"]=43,["s"]=44,["t"]=45,["u"]=46,["v"]=47,["w"]=48,["x"]=49,["y"]=50,["z"]=51,
	["0"]=52,["1"]=53,["2"]=54,["3"]=55,["4"]=56,["5"]=57,["6"]=58,["7"]=59,["8"]=60,["9"]=61,["+"]=62,["/"]=63,
}

local function unb64(txt)
	txt=txt:gsub("=+$","")
	local o,d1,d2=""
	local ln=#txt
	local m=ln%4
	for l1=1,ln-3,4 do
		d1,d2=_unb64[sub(txt,l1+1,l1+1)],_unb64[sub(txt,l1+2,l1+2)]
		o=o..char((_unb64[sub(txt,l1,l1)]*4)+floor(d1/16),((d1%16)*16)+floor(d2/4),((d2%4)*64)+_unb64[sub(txt,l1+3,l1+3)])
	end
	if m==2 then
		o=o..char((_unb64[sub(txt,-2,-2)]*4)+floor(_unb64[sub(txt,-1,-1)]/16))
	elseif m==3 then
		d1=_unb64[sub(txt,-2,-2)]
		o=o..char((_unb64[sub(txt,-3,-3)]*4)+floor(d1/16),((d1%16)*16)+floor(_unb64[sub(txt,-1,-1)]/4))
	end
	return o
end

local tohex,unhex
do
	function tohex(txt)
		local o=""
		for l1=1,#txt do
			o=o.._num2hex[byte(txt,l1,l1)]
		end
		return o
	end
	local hf={}
	for l1=0,255 do
		hf[format("%02x",l1)]=char(l1)
		hf[format("%02X",l1)]=char(l1)
	end
	function unhex(txt)
		local o=""
		for l1=1,#txt,2 do
			o=o..hf[txt:sub(l1,l1+1)]
		end
		return o
	end
end

local rot13,rot47
do
	local ht={}
	for l1=0,255 do
		ht[l1]=char(l1):gsub("%l",function(c)
			return char(((byte(c)-84)%26)+97)
		end):gsub("%u",function(c)
			return char(((byte(c)-52)%26)+65)
		end)
	end
	function rot13(txt)
		local o=""
		for l1=1,#txt do
			o=o..ht[byte(txt,l1,l1)]
		end
		return o
	end
	local hf={}
	for l1=0,255 do
		ht[l1]=char(l1):gsub(".",function(c)
			if c:byte()<127 and c:byte()>32 then
				return string.char(((c:byte()+14)%94)+33)
			end
		end)
	end
	function rot47(txt)
		local o=""
		for l1=1,#txt do
			o=o..ht[byte(txt,l1,l1)]
		end
		return o
	end
end
	
local function rot47(txt)
	txt=txt
	return txt
end

return {
	bit64={
		to64=to64,
		band=band64,
		bor=bor64,
		bnot=bnot64,
		bxor=bxor64,
		lshift=lshift64,
		rshift=rshift64,
		rol=lrotate64,
		ror=rrotate64,
		lrotate=lrotate64,
		rrotate=rrotate64,
		add=add64,
	},
	hash={
		sha512=sha512,
		sha256=sha256,
	},
	checksum={
		crc32=crc32,
	},
	encrypt={
		rc4=function(key,state)
			local encrypt,state=rc4(key,state)
			return function(txt,nohex)
				return nohex and encrypt(txt) or tohex(encrypt(txt))
			end,state
		end,
	},
	decrypt={
		rc4=function(key,state)
			local decrypt,state=rc4(key,state)
			return function(txt,nohex)
				return nohex and encrypt(txt) or tohex(fromhex(txt))
			end,state
		end,
	},
	encode={
		b64=tob64,
		hex=tohex,
		rot13=rot13,
		rot47=rot47,
	}
	decode={
		b64=unb64,
		hex=unhex,
		rot13=rot13,
		rot47=rot47,
	}
}
