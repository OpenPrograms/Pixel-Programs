-- brainfuck by PixelToast
-- infinite tape and 8 bit cells
local program="++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."
assert(loadstring(
	"local s,p={},0"..program
	:gsub("[^%[%]%+%-+.%,<>]","\n")
	:gsub("%]","\nend")
	:gsub("%[","\nwhile (s[p] or 0)~=0 do")
	:gsub("[%+%-]+",function(txt)
		return "\ns[p]=((s[p] or 0)"..txt:sub(1,1)..#txt..")%256"
	end)
	:gsub("[<>]+",function(txt)
		return "\np=p"..(txt:sub(1,1)==">" and "+" or "-")..#txt
	end)
	:gsub("%.","\nio.write(string.char(s[p] or 0))")
	:gsub(",","\ns[p]=string.byte(io.read(1))")
,"=brainfuck"))()