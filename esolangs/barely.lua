-- Barely in OC by PixelToast
local program="xjhhhhxooooooooxooooooxjjjxhhoohhhhxjjjjjjjjhxooooooooooooxjhhhhxjjjxxjjjjjjjxjjjhhhhhhxjjjjjjjjjjjjjjhhhh~"
if program:match("[^%]%^bfghijklmnopqstx~]") or not program:match("~$") then
	return "Invalid program."
end
local cell=setmetatable({},{__index=function() return 0 end})
local mp=0
local jmp=0
local acc=126
local ip=#program
local se
while ip>0 and ip<#program+1 do
	local ins=se or program:sub(ip,ip)
	se=nil
	if ins=="]" then
		return o
	elseif ins=="^" then
		if acc==0 then
			se="b"
		end
	elseif ins=="b" then
		ip=ip+jmp
	elseif ins=="g" then
		acc=cell[mp]
		se="i"
	elseif ins=="h" then
		acc=(acc+47)%256
		se="k"
	elseif ins=="i" then
		mp=mp+1
		se="j"
	elseif ins=="j" then
		acc=(acc+1)%256
	elseif ins=="k" then
		jmp=jmp-1
	elseif ins=="m" then
		cell[mp]=acc
		se="o"
	elseif ins=="n" then
		mp=mp-1
		se="o"
	elseif ins=="o" then
		acc=(acc-1)%256
		se="p"
	elseif ins=="p" then
		jmp=jmp+10
	elseif ins=="t" then
		acc=io.read(1):byte()
	elseif ins=="x" then
		io.write(string.char(acc))
	end
	if not se then
		ip=ip-1
	end
end
return o