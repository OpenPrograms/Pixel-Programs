-- b64 by PixelToast
-- this one is a bit faster than the one on the lua users wiki
local _tob64={
	[0]="A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
	"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
	"0","1","2","3","4","5","6","7","8","9","+","/"
}
local function tob64(stxt)
	local txt=tostring(stxt)
	if not txt then
		error("string expected, got "..type(stxt),2)
	end
	local d,o,d1,d2,d3={string.byte(txt,1,#txt)},""
	for l1=1,#txt-2,3 do
		d1,d2,d3=d[l1],d[l1+1],d[l1+2]
		o=o.._tob64[math.floor(d1/4)].._tob64[((d1%4)*16)+math.floor(d2/16)].._tob64[((d2%16)*4)+math.floor(d3/64)].._tob64[d3%64]
	end
	local m=#txt%3
	if m==1 then
		o=o.._tob64[math.floor(d[#txt]/4)].._tob64[((d[#txt]%4)*16)].."=="
	elseif m==2 then
		o=o.._tob64[math.floor(d[#txt-1]/4)].._tob64[((d[#txt-1]%4)*16)+math.floor(d[#txt]/16)].._tob64[(d[#txt]%16)*4].."="
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
local function unb64(stxt)
	local txt=tostring(stxt)
	if not txt then
		error("string expected, got "..type(stxt),2)
	end
	txt=txt:gsub("[^%a%d/%+]","")
	local m=#txt%4
	if m==1 then
		error("invalid b64",2)
	end
	local o,d1,d2=""
	for l1=1,#txt-3,4 do
		d1,d2=_unb64[txt:sub(l1+1,l1+1)],_unb64[txt:sub(l1+2,l1+2)]
		o=o..string.char((_unb64[txt:sub(l1,l1)]*4)+math.floor(d1/16),((d1%16)*16)+math.floor(d2/4),((d2%4)*64)+_unb64[txt:sub(l1+3,l1+3)])
	end
	if m==2 then
		o=o..string.char((_unb64[txt:sub(-2,-2)]*4)+math.floor(_unb64[txt:sub(-1,-1)]/16))
	elseif m==3 then
		d1=_unb64[txt:sub(-2,-2)]
		o=o..string.char((_unb64[txt:sub(-3,-3)]*4)+math.floor(d1/16),((d1%16)*16)+math.floor(_unb64[txt:sub(-1,-1)]/4))
	end
	return o
end

return { -- because some people complain about the function names
	to=tob64,
	un=unb64,
	from=unb64,
	tob64=tob64,
	unb64=unb64,
	b64=tob64,
	ub64=unb64,
	fromb64=unb64,
}