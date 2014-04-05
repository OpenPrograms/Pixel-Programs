-- Super Stack! in OC by PixelToast
local program="0 33 100 108 114 111 87 32 44 111 108 108 101 72 if outputascii fi"

program=program.." "
local stack={}
local function push(val)
	table.insert(stack,1,math.floor((type(val)=="boolean" and (val and 1 or 0) or val)%256))
end
local function pop(n)
	local v=stack[n or 1]
	table.remove(stack,n or 1)
	return v or 0
end
local sb
local ins={
	["(%d+)"]=function(num)
		sb=#num
		return "push("..num..")"
	end,
	["add"]=function()
		sb=3
		return "push(pop()+pop())"
	end,
	["sub"]=function()
		sb=3
		return "push(pop(2)-pop())"
	end,
	["mul"]=function()
		sb=3
		return "push(pop()*pop())"
	end,
	["div"]=function()
		sb=3
		return "push(pop(2)/pop())"
	end,
	["mod"]=function()
		sb=3
		return "push(pop(2)%pop())"
	end,
	["random"]=function()
		sb=6
		return "push(math.random(0,pop()-1))"
	end,
	["and"]=function()
		sb=3
		return "push(pop()~=0 and pop()~=0)"
	end,
	["or"]=function()
		sb=2
		return "push(pop()~=0 or pop()~=0)"
	end,
	["xor"]=function()
		sb=3
		return "push(pop()~=pop())"
	end,
	["nand"]=function()
		sb=4
		return "push(not (pop()~=0 and pop()~=0))"
	end,
	["not"]=function()
		sb=3
		return "push(pop()==0)"
	end,
	["output"]=function()
		sb=3
		return "o=o..pop()..\" \""
	end,
	["input"]=function()
		sb=5
		return "push(tonumber(io.input()))"
	end,
	["outputascii"]=function()
		sb=11
		return "io.write(string.char(pop()))"
	end,
	["inputascii"]=function()
		sb=10
		return "push(io.input(1):byte)"
	end,
	["pop"]=function()
		sb=3
		return "pop()"
	end,
	["swap"]=function()
		sb=4
		return "stack[1],stack[2]=stack[2],stack[1]"
	end,
	["cycle"]=function()
		sb=5
		return "table.insert(stack,pop())"
	end,
	["rcycle"]=function()
		sb=6
		return "push(table.remove(stack))"
	end,
	["dup"]=function()
		sb=3
		return "push(stack[1])"
	end,
	["rev"]=function()
		sb=3
		return "table.reverse(stack)"
	end,
	["if"]=function()
		sb=2
		return "while stack[1]>0 do"
	end,
	["fi"]=function()
		sb=2
		return "end"
	end,
	["quit"]=function()
		sb=4
		return "error(o,0)"
	end,
	["debug"]=function()
		sb=5
		return "io.write(table.concat(stack,\" | \")..\" \")"
	end,
}
local out=""
while #txt>0 do
	sb=1
	for k,v in pairs(ins) do
		local p={txt:match("^"..k.."%s")}
		if p[1] then
			out=out..v(unpack(p)).." "
		end
	end
	txt=txt:sub(sb+1)
end

local func,err=loadstring(out.."return o")
if not func then
	return err
end
setfenv(func,{
	push=push,
	pop=pop,
	stack=stack,
	string=string,
	math=math,
	table=table,
	io=io
})()