-- Agony in lua by PixelToast

-- text to Agony
local text="Hello, World!\r\n"
local program
do
	local agony={
		[0]="$","}","{",">","<","@","~","+","-",".",",","(",")","[","]","*"
	}
	program="<[.<]$$"..text:reverse():gsub(".",function(t)
		t=t:byte()
		return agony[math.floor(t/16)]..agony[t%16]
	end)
end

assert(program=="<[.<]$$$,$[{}~<~)+{~*@+{${)~*~)~)~@<-")

program=program:gsub("[^%$}{><@~%+%-%.,%(%)%[%]%*]","")
local bt={
	["$"]=0x0,["}"]=0x1,["{"]=0x2,[">"]=0x3,
	["<"]=0x4,["@"]=0x5,["~"]=0x6,["+"]=0x7,
	["-"]=0x8,["."]=0x9,[","]=0xA,["("]=0xB,
	[")"]=0xC,["["]=0xD,["]"]=0xE,["*"]=0xF,
}
local mxval=0
local mnval=0
local mem=setmetatable({},{
	__newindex=function(s,n,d)
		mxval=math.max(mxval,n)
		mnval=math.min(mnval,n)
		rawset(s,n,d)
	end,
	__index=function()
		return 0
	end
})
for l1=1,#program do
	mem[l1-1]=bt[program:sub(l1,l1)]
end
local eip=0
local ptr=#program+1
local function lc(dt,a,b,cmp,tf)
	local mrm=(mem[ptr-1]*16)+mem[ptr]
	if tf then
		mrm=mem[ptr]
	end
	if (mrm==0 and cmp==1) or (mrm~=0 and cmp==0) then
		local cn=0
		local cnt=0
		local ins
		repeat
			cnt=cnt+dt
			ins=mem[eip+cnt]
			if ins==a then
				cn=cn+1
			elseif ins==b then
				cn=cn-1
			end
		until eip==mnval or eip==mxval or cn==-1
		if eip==mnval or eip==mxval then
			error("Syntax error "..eip)
		end
		eip=eip+cnt
	end
end
while true do
	local ins=mem[eip]
	if ins==0 then
		return
	elseif ins==1 then
		ptr=ptr+1
	elseif ins==2 then
		ptr=ptr-1
	elseif ins==3 then
		ptr=ptr+2
	elseif ins==4 then
		ptr=ptr-2
	elseif ins==5 then
		mem[ptr]=(mem[ptr]+1)%16
	elseif ins==6 then
		mem[ptr]=(mem[ptr]-1)%16
	elseif ins==7 then
		mem[ptr]=mem[ptr]+1
		mem[ptr-1]=(mem[ptr-1]+math.floor(mem[ptr]/16))%16
		mem[ptr]=mem[ptr]%16
	elseif ins==8 then
		mem[ptr]=mem[ptr]-1
		mem[ptr-1]=(mem[ptr-1]+math.floor(mem[ptr]/16))%16
		mem[ptr]=mem[ptr]%16
	elseif ins==9 then
		io.write(string.char((mem[ptr-1]*16)+mem[ptr]))
	elseif ins==10 then
		mem[ptr]=string.byte(io.read(1))
	elseif ins==11 then
		lc(1,0xB,0xC,1,true)
	elseif ins==12 then
		lc(-1,0xC,0xB,0,true)
	elseif ins==13 then
		lc(1,0xD,0xE,1)
	elseif ins==14 then
		lc(-1,0xE,0xD,0)
	elseif ins==15 then
		mem[ptr-1],mem[ptr],buff[1],buff[2]=buff[1],buff[2],mem[ptr-1],mem[ptr]
	end
	eip=eip+1
end
