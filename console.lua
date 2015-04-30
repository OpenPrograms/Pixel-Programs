--[[

	ConsoleUtils by PixelToast, public domain
	
	> console.box("puts a box\naround some text")
	┌────────────────┐
	│puts a box      │
	│around some text│
	└────────────────┘ 

	> console.cat(console.box("cats\nsome\ntext")," with more text")
	┌────┐               
	│cats│               
	│some│ with more text
	│text│               
	└────┘                          

	> console.table({{"first","column"},{"second\ncolumn"},{"foo","potatowalrus","bar"}})
	┌──────┬─────────────┬───┐
	│first │column       │   │
	├──────┼─────────────┼───┤
	│second│             │   │
	│column│             │   │
	├──────┼─────────────┼───┤
	│foo   │potato walrus│bar│
	└──────┴─────────────┴───┘

	> console.serialize({key="value",table={list={1,2,"three"},d="alphabetical order",c=1,b=2,a=3}})
	┌─────────────────────────────────────────┐
	│"key"   = "value"                        │
	│          ┌─────────────────────────────┐│
	│          │"a"    = 3                   ││
	│          │"b"    = 2                   ││
	│          │"c"    = 1                   ││
	│          │"d"    = "alphabetical order"││
	│"table" = │         ┌───────┐           ││
	│          │         │1      │           ││
	│          │"list" = │2      │           ││
	│          │         │"three"│           ││
	│          │         └───────┘           ││
	│          └─────────────────────────────┘│
	└─────────────────────────────────────────┘

]]

local console={}

local box={
	ud="│",
	lr="─",
	ur="└",
	rd="┌",
	ld="┐",
	lu="┘",
	lrd="┬",
	udr="├",
	x="┼",
	lud="┤",
	lur="┴",
	e="[]"
}

--[[local box={
	ud="|",
	lr="-",
	ur="\\",
	rd="/",
	ld="\\",
	lu="/",
	lrd="-",
	udr="|",
	x="+",
	lud="|",
	lur="-",
	e="[]"
}]]

local unicode=require("unicode")

local function txtbl(s,mx)
	mx=mx or 0
	if s=="" and mx>0 then
		s=" "
	end
	local o={}
	for c in s:gmatch("[^\r\n]+") do
		table.insert(o,c)
	end
	for l1=1,#o do
		mx=math.max(mx,unicode.len(o[l1]))
	end
	for l1=1,#o do
		o[l1]=o[l1]..(" "):rep(mx-unicode.len(o[l1]))
	end
	return o,mx
end

function console.box(s)
	local t,l=txtbl(s)
	for l1=1,#t do
		t[l1]=box.ud..t[l1]..box.ud
	end
	table.insert(t,1,box.rd..(box.lr:rep(l))..box.ld)
	table.insert(t,box.ur..(box.lr:rep(l))..box.lu)
	return table.concat(t,"\n")
end

function console.cat(a,b,al,bl)
	local at,al=txtbl(a,al)
	local bt,bl=txtbl(b,bl)
	if #at==#bt then
		for l1=1,#bt do
			bt[l1]=at[l1]..bt[l1]
		end
		return table.concat(bt,"\n")
	end
	if al==0 then
		return table.concat(bt,"\n")
	elseif bl==0 then
		return table.concat(at,"\n")
	end
	local ml=math.max(#at,#bt)
	for l1=1,math.floor((#bt-#at)/2) do
		table.insert(at,1,(" "):rep(al))
	end
	for l1=#at+1,ml do
		table.insert(at,(" "):rep(al))
	end
	for l1=1,math.floor((#at-#bt)/2) do
		table.insert(bt,1,(" "):rep(bl))
	end
	for l1=#bt+1,ml do
		table.insert(bt,(" "):rep(bl))
	end
	for l1=1,ml do
		at[l1]=at[l1]..bt[l1]
	end
	return table.concat(at,"\n")
end

function console.table(t)
	local ncols=0
	local nrows=0
	for k,v in pairs(t) do
		nrows=math.max(nrows,k)
		for n,l in pairs(v) do
			ncols=math.max(ncols,n)
		end
	end
	local wcols={}
	local hrows={}
	for l1=1,nrows do
		for l2=1,ncols do
			local d,mx=txtbl(t[l1][l2] or "")
			wcols[l2]=math.max(wcols[l2] or 0,mx)
			hrows[l1]=math.max(hrows[l1] or 0,#d)
		end
	end
	local sp={}
	for l1=1,ncols do
		table.insert(sp,(box.lr):rep(wcols[l1]))
	end
	local ocols={box.rd..table.concat(sp,box.lrd)..box.ld}
	for l1=1,nrows do
		local orow={}
		for l2=1,ncols do
			table.insert(orow,table.concat(txtbl(t[l1][l2] or "",wcols[l2]),"\n"))
			table.insert(orow,(box.ud.."\n"):rep(hrows[l1]))
		end
		local o=(box.ud.."\n"):rep(hrows[l1])
		for l2=1,#orow do
			o=console.cat(o,orow[l2])
		end
		table.insert(ocols,o)
		table.insert(ocols,l1==nrows and (box.ur..table.concat(sp,box.lur)..box.lu) or (box.udr..table.concat(sp,box.x)..box.lud))
	end
	return table.concat(ocols,"\n")
end

local _serialize
function _serialize(t,r)
	r=r or {}
	if r[t] then
		return tostring(t)
	end
	local tpe=type(t)
	if tpe=="table" then
		if getmetatable(v) and getmetatable(v).__tostring then
			return tostring(v)
		end
		local err,res=pcall(function()
			local ok={}
			local ov={}
			local u={}
			local n=1
			r[t]=true
			while t[n]~=nil do
				u[n]=true
				table.insert(ok," ")
				table.insert(ov,console.cat("   ",_serialize(t[n],r)))
				n=n+1
			end
			local oi={}
			for k,v in pairs(t) do
				if not u[k] then
					table.insert(oi,{k,v})
				end
			end
			if #oi==0 then
				for l1=1,#ov do
					ov[l1]=ov[l1]:sub(4)
				end
			end
			table.sort(oi,function(a,b)
				return tostring(a[1])<tostring(b[1])
			end)
			for k,v in ipairs(oi) do
				table.insert(ok,_serialize(v[1],r))
				table.insert(ov,console.cat(" = ",_serialize(v[2],r)))
			end
			if #ok==0 then
				return box.e
			end
			local _
			local kl=0
			for k,v in pairs(ok) do
				if v~=" " then
					_,kl=txtbl(v,kl)
				end
			end
			if kl==0 then
				return console.box(table.concat(ov,"\n"))
			end
			local vl=0
			for k,v in pairs(ov) do
				_,vl=txtbl(v,vl)
			end
			local o=""
			for l1=1,#ok do
				o=o..console.cat(ok[l1],ov[l1],kl,vl).."\n"
			end
			r[t]=nil
			return console.box(o)
		end)
		return err and res or tostring(t)
	elseif tpe=="number" then
		if t~=t then
			return "nan"
		elseif t==math.huge then
			return "inf"
		elseif t==-math.huge then
			return "-inf"
		end
		return tostring(t)
	elseif tpe=="string" then
		local o=string.format("%q",t):gsub("\\\n","\\n"):gsub("%z","\\z")
		return o
	else
		return tostring(t)
	end
end

function console.serialize(t)
	return _serialize(t)
end

return console
