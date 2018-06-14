pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	_lt_plt={}
	for i=0,15 do
		_lt_plt[i]={}
		for j=0,7 do
			_lt_plt[i][j]=0
		end
	end
	
	_fd_plt={}
	for i=0,15 do
		_fd_plt[i]={}
		for j=0,7 do
			_fd_plt[i][j]=0
		end
	end
	
	_lt_dst2={10*42,18*42,26*42,34*42,42*42}

	local baseaddr=0x800
	for x=0,3 do
		for y=0,15 do
			local addr=baseaddr+y*64+x
			local v=peek(addr)
			local l=band(v,0x0f)
			local r=shr(band(v,0xf0),4)
			_lt_plt[y][x*2+0]=l
			_lt_plt[y][x*2+1]=r
		end
	end
	
	_lt_plt_addr=0x4500
	for lt=0,0 do
		for r=0,15 do
			for l=0,15 do
				local a=_lt_plt_addr+r*16+l+lt*0x100
				local v=shl(_lt_plt[r][lt],4)+_lt_plt[l][lt]
				poke(a,v)
			end
		end
	end
	
	for x=4,7 do
		for y=0,15 do
			local addr=baseaddr+y*64+x
			local v=peek(addr)
			local l=band(v,0x0f)
			local r=shr(band(v,0xf0),4)
			_fd_plt[y][(x-4)*2+0]=l
			_fd_plt[y][(x-4)*2+1]=r
		end
	end

	showplt=false
	
	px=64
	py=64
end

prev=false
function _update()
	if btn(4) and not prev then
		showplt=not showplt
	end
	prev=btn(4)
	
	if(btn(0))px-=1
	if(btn(1))px+=1
	if(btn(2))py-=1
	if(btn(3))py+=1
end

function _draw()
	cls()
	map(0,0,0,0,16,16)

	local scrstr=0x6000
	local scrend=0x6000//0x7fff
	for scraddr=scrstr,scrend do
//		poke(scraddr,0)
		poke(scraddr,
			peek(
				bor(_lt_plt_addr,peek(scraddr))))
		print(peek(scraddr),0,80,7)
		print(peek(0x4555),0,86,7)
	end
--[[
	for y=0,127 do
		light_hline(y,0,127)
	end]]
	
	if showplt then
 	rectfill(0,0,120,80,0)
 	for c=0,15 do
 		print(c..":",0,c*6,7)
 		for r=0,7 do
 			print(_lt_plt[c][r],18+r*12,c*6,7)
 		end
 	end
	end
end

function fast_getp(x,y)
	local addr=0x6000+y*64+flr(x/2)
	local v=peek(addr)
	if x%2==0 then
		return shr(band(v,0xf0),4)
	else
		return band(v,0xf)
	end
end

function fast_setp(x,y,c)
	if(x%2==1)x-=1
	local addr=0x6000+y*64+flr(x/2)
	
end	

function light_hline(y,x1,x2)
	for x=x1,x2 do
		local lt=light_level(x,y)
		local c=fast_getp(x,y)
		local ltbl=_lt_plt[c]
		fast_setp(x,y,ltbl[6-lt])
	end
end

function light_level(x,y)
	local dx,dy=px-x,py-y
	local d=dx*dx+dy*dy
	for i=1,#_lt_dst2 do
		if d<=_lt_dst2[i] then
			return 7-i
		end
	end
	return 0
end
__gfx__
0000000055555555d565565d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000767775765566665500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700666765766655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700067666566565dd56500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700055555555565dd56500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700757677676655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000657667665566665500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000065666676d565565d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11100000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22110000211000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33311000331100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42211000442210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55111000551100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66d5100066dd51000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
776d100077776d510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88221000888421000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
94221000999421000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a9421000aa9942100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb331000bbb331000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccd51000ccdd51000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dd511000dd5110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee421000ee4442100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f9421000fff942100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11100000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22110000211000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33311000331100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42211000442210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55111000551100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66d5100066dd51000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
776d100077776d510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88221000888421000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
94221000999421000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a9421000aa9942100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb331000bbb331000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccd51000ccdd51000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dd511000dd5110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee421000ee4442100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f9421000fff942100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
