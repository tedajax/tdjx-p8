pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	heli={
		x=8,y=8,
		dx=0,dy=0,
		r=0,
		dr=0.8,
		mx_spd=8,
		accel=12,
		fric=0.99,
		t0=0,
		t_fire=0,
		fire_rate=0.12,
		vts={
			4,0,
			3,-2,
			3,2,
			-4,-2,
			-4,2,
			-6,1,
			-6,-1,
			-9,0
		},
		ind={
			0,2,4,5,7,6,3,1,0
		}
	}
	
	cam={
		x=0,y=0
	}
	
	bullets={}
	monsters={}
	
	for i=1,20 do
		add_monster(flr(rnd(128)),flr(rnd(64)))
	end
	
--	sfx(16)
end

function _update60()
	dt=1/stat(7)
	
	update_watch()
	
	update_heli(heli)
	update_bullets()
	
	cam.x=mid(0,heli.x*8-64,112*8)
	cam.y=mid(0,heli.y*8-64,48*8)

	watch("pos:"..heli.x..","..heli.y)	
	watch("fps:"..stat(7))
	watch("mem:"..stat(0)/2048)
	watch("cpu:"..stat(1)*100)
end

function _draw()
	cls()

	map(0,0,-cam.x,-cam.y,128,64)
	foreach(monsters,draw_monster)
	draw_bullets()
	draw_heli(heli)

	draw_watch()
end

function update_heli(h)
	h.t0+=dt*4
	if (h.t0>1) h.t0-=1
	
	local ix,iy=0,0
	
	if (btn(0)) ix-=1
	if (btn(1)) ix+=1
	if (btn(3)) iy-=1
	if (btn(2)) iy+=1
	
	h.r+=ix*-h.dr*dt
	h.rr=flr(h.r*32)/32
	
	local ddx,ddy=0,0
	
	if iy~=0 then
		ddx=cos(h.rr)*h.accel*dt*iy
		ddy=sin(h.rr)*h.accel*dt*iy
	end

	h.dx*=h.fric
	h.dy*=h.fric
	
	h.dx+=ddx
	h.dy+=ddy
	
	local mx=h.mx_spd
	if (btn(4)) mx*=4
	
	local l=sqrt(h.dx*h.dx+h.dy*h.dy)
	if l>mx then
		h.dx=h.dx/l*mx
		h.dy=h.dy/l*mx
	end
		
	h.x+=h.dx*dt
	h.y+=h.dy*dt
	
	local border=0.5
	
	if h.x<border then
		h.x=border
		h.dx=max(h.dx,0)
	end
	
	if h.x>128-border then
		h.x=128-border
		h.dx=min(h.dx,0)
	end
	
	if h.y<border then
		h.y=border
		h.dy=max(h.dy,0)
	end
	
	if h.y>64-border then
		h.y=64-border
		h.dy=min(h.dy,0)
	end
	
	h.t_fire-=dt
	if btn(4) and h.t_fire<=0 then
		add_bullet(h.x,h.y,h.rr,
			{spd=25})
		h.t_fire=h.fire_rate
	end
end

function draw_heli(h)
	local cx,cy=h.x*8-cam.x,h.y*8-cam.y
	
	local r=h.rr
	
	for i=1,#h.ind-1 do
		local i1=h.ind[i]
		local i2=h.ind[i+1]
		local x1,y1=h.vts[i1*2+1],h.vts[i1*2+2]
		local x2,y2=h.vts[i2*2+1],h.vts[i2*2+2]
		local t1=cos(r)*x1-sin(r)*y1+cx
		local t2=sin(r)*x1+cos(r)*y1+cy
		local t3=cos(r)*x2-sin(r)*y2+cx
		local t4=sin(r)*x2+cos(r)*y2+cy
		line(t1,t2,t3,t4,11)
	end

	flood_fill(cx,cy,11)

	local rad=6
	local th=-h.t0
	local x1,y1,x2,y2,x3,y3,x4,y4=
		cos(th)*rad,sin(th)*rad,
		cos(th+.5)*rad,sin(th+.5)*rad,
		cos(th+.25)*rad,sin(th+.25)*rad,
		cos(th+.75)*rad,sin(th+.75)*rad
	line(x1+cx,y1+cy,x2+cx,y2+cy,7)
	line(x3+cx,y3+cy,x4+cx,y4+cy,7)
end

function flood_fill(x,y,c)
	if (x>1024 or x<0 or y>512 or y<0) return
	if (px_fill(x,y,c)) pset(x,y,c)
	if (px_fill(x-1,y,c)) flood_fill(x-1,y,c)
	if (px_fill(x+1,y,c)) flood_fill(x+1,y,c)
	if (px_fill(x,y-1,c)) flood_fill(x,y-1,c)
	if (px_fill(x,y+1,c)) flood_fill(x,y+1,c)
end

function px_fill(x,y,c)
	local p=pget(x,y)
	return p~=c and p~=0
end

function add_bullet(x,y,r,props)
	local p=props or {}
	local spd=p.spd or 10
	local t_life=p.lifetime or 1
	return add(bullets,{
		destroy=false,
		x=x or 0,y=y or 0,
		r=r or 0,
		spd=spd,t_life=t_life,
	})
end

function update_bullet(b)
	b.t_life-=dt
	if b.t_life<=0 then
		b.destroy=true
	end

	local vx,vy=cos(b.r)*b.spd,
		sin(b.r)*b.spd
	
	b.x+=vx*dt
	b.y+=vy*dt
end

function draw_bullet(b)
	circ(b.x*8-cam.x,b.y*8-cam.y,1,10)
end


function update_bullets()
	foreach(bullets,update_bullet)
	
	local n=#bullets
	for i=1,n do
		if bullets[i].destroy then
			bullets[i]=nil
		end
	end
	compress(bullets,n)
end

function draw_bullets()
	foreach(bullets,draw_bullet)
end

function add_monster(x,y)
	return add(monsters,{
		x=x,y=y
	})
end

function update_monster(m)
end

function draw_monster(m)
--	spr(64,m.x*8-cam.x,m.y*8-cam.y,2,2)
		
	sspr(0,32,16,16,m.x*8-cam.x,m.y*8-cam.y,32,32)
end
-->8
-- util

-- slow but maintains order
function compress_slow(a,n)
	local n=n or #a
	local i=1
	while i<n do
		local j=i
		while a[j]==nil and j<n do
			local k=j+1
			while k<n and a[k]==nil do
				k+=1
			end
			a[j]=a[k]
			a[k]=nil
			j=k
		end
		i+=1
	end
end

function compress(a,n)
	local n=n or #a
	local h,t=1,n

	-- wind tail back to first
	-- non-nil entry in case len
	-- is wrong
	while a[t]==nil and t>h do
		t-=1
	end

	while h<t do
		if a[h]==nil then
			a[h]=a[t]
			a[t]=nil
			while a[t]==nil and t>h do
				t-=1
			end
		end
		h+=1
	end
end

function print_array(a,n)
	local n=n or #a
	local str=""
	for i=1,n do
		str=str..tostr(a[i])
		if (i<n) str=str..","
	end
	print(str)
end

function clone_array(a,n)
	local r={}
	local n=n or #a
	for i=1,n do
		r[i]=a[i]
	end
	return r
end

function test_compress()
	local a={1,2,3,4,5,6,7,8}
	local b=clone_array(a)
	b[2]=nil
	b[5]=nil
	print_array(a)
	compress(b)
	print_array(b)
	
	local c=clone_array(a)
	c[0]=nil
	c[8]=nil
	c[6]=nil
	print_array(a)
	compress(c,8)
	print_array(c)
end

--[[
cls()
test_compress()
flip()
]]

__watch={}

function watch(m)
	add(__watch,m)
end

function update_watch()
	__watch={}
end

function draw_watch()
	local n=#__watch
	for i=1,n do
		local m=__watch[i]
		print(m,0,(i-1)*6,11)
	end
end
__gfx__
00000000565656560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700566666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000666666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000566666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700666666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000566666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
444444441111111111f444444444444444444f1111111111111111111ff4444444444ff14444ff1111f4444444444444444444441111111111f444f100000000
4444444411ff1fff1ff4ff444444ff444444ff1111ff11111ff111f11ff4ff444444fff14444ff1111ffff444444ff444444ff441ff111111fff44f100000000
44444444ffffffff11f444444f4444444f444f11ffffff111fffffff1ff444444f444f114f444fffffff44444f4444444f4444441fffff1111f444f100000000
444444444444444411f444444444444444444f114444fff111ff444411f4444444444f11444444ff4ff44444ff44444444444ff411fffff111f444f100000000
44444444444f444f11ff444f444f444f444f4ff1444f4ff111ff444f11ff444f444f4f11444f444f444f444fffff444f444fffff11f444f111f4fff100000000
44444444444444f411f444f4ffffffff44444ff144444f1111f444f411fffffffffffff1444444f4444444f4fff444f44444ffff11f44ff11fffff1100000000
44444444444f44441fff4444f11ff111444f4ff1444f4f111fff44441111fff11ff1fff1444f4444444f444411ff4444444fff111ff444f11ff1111100000000
444444444444444411f444441111111144444ff144444f111ff444441111111111111111444444444444444411ff44444444ff1111f444f11111111100000000
33333333444444444433333333333333333333444444444444444444443333333333334433333344443333333333333333333333000000000000000000000000
33333333444444444433333333333333333333444444444444444444443333333333334433333344443333333333333333333333000000000000000000000000
33333333333333444433333333333333333333443333334444333333443333333333334433333333333333333333333333333333000000000000000000000000
33333333333333444433333333333333333333443333334444333333443333333333334433333333333333333333333333333333000000000000000000000000
33333333333333444433333333333333333333443333334444333333443333333333334433333333333333333333333333333333000000000000000000000000
33333333333333444433333333333333333333443333334444333333443333333333334433333333333333333333333333333333000000000000000000000000
33333333333333444433333344444444333333443333334444333333444444444444444433333333333333334433333333333344000000000000000000000000
33333333333333444433333344444444333333443333334444333333444444444444444433333333333333334433333333333344000000000000000000000000
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1dddd111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111ddd1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11ddd111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111ddd1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00880000000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00e8800000088e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000e88888888e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008828828800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00002ee88ee200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0088eee22eee88000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8888ee2882ee88880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee882828828288ee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88822282282228880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee28882ee28888ee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0022822ee22822000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08e0282ee2820e800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8e002282282200e80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008e02ee20e80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
088e00e00e00e8800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8e000e2002e000e80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003
03030303037131b10202020101010101010101010101020101010101020201020102020101010101010101010101010101010101010101010101010101010101
01010141030303030303030303030303030303030303030303030303030303030303030303030303210101010101010101010202020101410303030303030303
030303030303032101020201010101010101010201010201010101010202020202020202010201010101010101010101010101c1313131313131b10101010101
01010141030303030303030303030303030303030303030303030303030303030303030303030303210101010101010101010202010101410303030303030303
03030303030303210101020202020201020202010101010201010102020102020202010101020201010101010101010101010141030303030303210101010101
01010141030303030303030303030303030303030303030303030303030303030303030303030303210101010101010101010101010101410303030303030303
03030303030303210101010101010101010101010101010201010202020201020202010101010201010101010101010101010141030303030303713131313131
31313181030303030303030303030303030303030303030303030303030303030303030303030303210101010101010101010101010101410303030303030303
03030303030303210101010101010101010101010101010102020202010202020201020101010201010101010101010101010141030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030303030303210101010101010101010101010101410303030303030303
03030303036111a10101010101010101010101010101010102010101010101020102020201020201010101010101010101010141030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030303030303210101010101010101010101010101915103030303030303
03030303032101020101010101010201010101010102010101020101010101020201010102010102010101010101010101010141030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030303030303210101010101010101010101010101014103030303030303
03030303032101020101010102010102010201020101010101020101010101010101010201010101010102020201010101010141030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030303030303210101010101010101010101010101014103030303030303
03030303032102020101020202020101010101010101010101020101010101010102c1313131313131b101010101010101010141030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030303030303210101010101010101010101010101014103030303030303
030303030321020201010101010101010101010101010101010201010102010201014103030303030371313131b1010101010141030303030303030303030303
0303030303030303030303030303030303030303030303030303030303030303030303030303030371313131313131b101010101010101014103030303030303
0303030303210202010101010101010101010101010101010101020202010101010141030303030303030303032101010101c181030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303032101010101010101014103030303030303
03030303032102020101010101010101010101010101010101010101010101010101410303030303030303030371313131318103030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303032101010101010101014103030303030303
03030303032102010101010102020101010101010101010101010101010101010101410303030303030303030303030303030303030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303032101010101010101019111111111115103
030303030371b1020102020101010101010101010101010101010101010101010101410303030303030303030303030303030303030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303032101010101020202020101010101014103
03030303030321010101010101010101010101010101010101010101010101010101410303030303030303030303030303030303030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303032101010102010101020101010101014103
03030303030321020101010101010101010101010101010101010101010101010101410303030303030303030303030303030303030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303032101010201010101020101010101014103
03030303030321020102010102010101010101010101010101010101010101010101410303030303030303030303030303030303030303030303030303030303
0303030303030303030303030303030303030303030303030303030303030303030303030303030303611111111111a102010101010101020101010101014103
03030303030321010102020202010201010101010101010101010101010101010101410303030303030303030303030303030303030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030303030303032101010101010201010101010101020202020201014103
03030303030321010201020102010101020101010101010101010101010101010101410303030303030303030303030303030303030303030303030303030303
0303036151030303030303030303030303030303030303030303030303030303030303030303030303210101010101010101010101010102c131313131318103
03030303030321010102010201020101010101010101010101010101010101010101410303030303030303030303030303030303030303030303030303030303
03030321915103030303030303030303030303030303030303030303030303030303030303030303032101010101020101010101010102024103030303030303
030303030361a1010202010101020201010201010101010101010101010101010101410303030303030303030303030303030303030303030303030303030303
03030321c18103030303030303030303030303030303030303030303030303030303030303030303032101010102020102020102010202014103030303030303
03030303032101010101010102020201010201010101010101010101010101010101911111115103030303030303030303030303030303030303030303030303
03030321410303030303030303030303030303030303030303030303030303030303030303030303032101020201020101010101020202024103030303030303
03030303032101020102010201010102010201010101010101010101010101010101010102019111111111111111115103030303030303030303030303030303
611111a191111111111151030303030303030303030303030303030303611111111111111111111111a101010201010101010101020201014103030303030303
03030303032101010101010101010101020201010101010101010101010101010102010101020201020101010101014103030303030303030303030303030361
a1010101010101010101410303030303030303030303030303030303032101010101010201010101010101010201020101010101020202024103030303030303
030303030321020102020202020202020202010201010201c1313131313131313131313131313131313131313131318103030303030303030303030303030321
0101010101010101010141030303030303030303030303030303030303210101010202010101010101010101010201010201c131313131318103030303030303
03030303032101020202020202010201020201010102010141030303030303030303030303030303030303030303030303030303030303030303030303030371
31313131313131313131810303030303030303030303030303030303032101010101020101010101010101010101010101014103030303030303030303030303
03036151032122020201010201020202010201010101010141030303030303030303030303030303030303030303030303030303030303030303030303030303
03030303030303030303030303030303030303030303030303030303032102010202020202010202020102010102010101014103030303030303030303030303
03037181032122020202020202020201010101020102010241030303030303030303030303030303030303030303030303030303030303030303030303030303
03030303030303030303030303030303030303030303030303030303032102020202020202010201020202010101010101014103030303030303030303030303
03030303032172323232328201020102010201010101010141030303030303030303030303030303030303030303030303030303030303030303030303030303
0303030303030303030303030303030303030361111111111111111111a102010201020201010201020202020102010101014103030303030303030303030303
03030303037131313131313131313131313131313131313181030303030303030303030303030303030303030303030303030303030303030303030303030303
03030303030303030303030303030303030303210101010101010102010101020102010101010101010101010101010101014103030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303
03030303030303030303030303030303030303713131313131313131313131313131313131313131313131313131313131318103030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080800000000000000000000000000000808000000000000000000000000000008080000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030
3030303030303030303030301611111111111111111111111111111111111111111111111111111111111111111115303030303030303030303030303030303030303030303030303030303030303030303030161111111111111111111530303030303016111111111530303030303030303030303030303030303030303030
30303030303030303030303012202020101010101010101010101020101010101010101010101010102010101010191111111111111111111111111111111111111111111111111111111111111111111111111a1010201010101020101430303030303012101020101430303030303030303030303016111115303030303030
3030303030303030303030301220201010101010101010101010101010101010101010101010101010101010101010101010102010101010202020201020202010102010102010202020102010101010202010101010101020202020101430303030303012102010101430303030303030303030303012102014303030303030
3030303030303030303030301220201010101010101010101010201010101010101010101010101010101020101010101020202020101020101020101010101010101010101010101020101010101010202020202020101010201010201430303030303012201010201430303030303030303030303012102014303030303030
3030303030303030303030301210101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010202010101010101010101010102020101010201020101010102020101020202010201430303030303012202010201430303030303030303030303012201014303030303030
303030303030303030303030121010101010101010101010101010101010101010101010101010101010101020101010101010101010101010101010101020102010201020102010201010102010101010201020101010101020101010191111111111111a10101020191111111111111111111111111a101014303030303030
30303030303030303030303017131313131b1010101010101010101010101010101010101010101020202020201010101010101010101010101010101010101010101010101010102020201010101010101020101010101020101010101010101020202020102010102010202010101010101010201020202014303030303030
3030303030303030303030303030303030121010101010101010101010101010101010101010101020101010102020101010101010101010101010101010101010101010101020102010101010101010201010101010102010101010101010101020101010101010101010202010101010101010201010101014303030303030
3030303030303030303030303030303030121010101010101010101020101010101010101010102010101010101010201010101010101010102020101010101010101010202010202010101010101020201010101010201010101010102010202020201020202010101010102010101010201020101010101014303030303030
3030303030303030303030303030303030121010101010101010101010201020202020201010102010101010101010102010101010102020202020101010101010101010101010101020101010201010202020102020201020201020201020102020202020201010101010101020202020201020102010102014303030303030
3030303030303030303030303030303030121020201010101010101010101020201010101010102010101010101010101020101020202010102010101010101010101010101010101010202020102010202020202010202020201010202020202020201010101010101010101010101010101010101010101014303030303030
3030303030303030303030303030303030121020202020202010101010102010101010101010201010101010101010102010102010101010201010201020201010201010102020202010102010101010101010101010102010101010101010101020102010101010101010101010101010101010101010101014303030303030
30303030303030303030303030303030301713131313131b2010101010201010101010101010201010101010101010101020101010101020102020101010101010102020201010101010102010101010101010101010101010101010101010201010101010101010101010101010101010101010101010101014303030303030
3030303030161111111115303030303030303030303030121010101020101010101010101010101010101010101010102010201010102010201010101020102020201020201010101010101010101010101010101010201010101010101020101010101010101010101010101010101010101010101010101014303030303030
3030303030121010101014303030303030303030303030121010101010101010101010101020101010101010101010101010202010101020101010102010202010101010102020101010101010101010101010101020101010101010201010101010101010101010101010101020202010202010201010101019111111153030
303030303012101010101430303030303030303030303012101010101010101010101010101010101010101010101020202020202020102020202010202020101010101010102010101010101010101010101010201010101010102010101010101010101010101010101010201010101010101010201010102010201c183030
3030303030121010101014303030303030303030303030121010101010101010101010101020101010101010101020201020202020102020202020102020101010101010101020101010101010101010101010101020202010201010101010101010101010101010101010201010101010101010101020101020102014303030
3030303030121010101014303030303030303030303030121010101010101010101010101010101010101010101010101020201010101010202020202020101010101020102020101010101010101010101010101010101010101010101010101010101010101010101020101010101010101010101020102010201014303030
303030303012101010101430303030303030303030303012101010101010101010101010102020201010101010101010202020101010101010101010101020202010201c1313131313131313131313131313131313131313131313131b1010101010101010101010101020101010101010101010101010202020101014303030
30303030301220101010191111111111111111111111111a10101010101010101010101010202010101010101010201010201010101010201010101010101010101010143030303030303030303030303030303030303030303030301210101010101010101010101010101010101010101010101010101c1313131318303030
3030303030122010101010101010101010101020201010101010101010101010101010102020201010101010201010101010101010101020101010101010101010101014303030303030303030303030303030303030303030303030121010101010101010101010101020101010101010101010101010143030303030303030
3030303030122010101010101010101010101010202020201010101010101010101010202010202010102010101010101010101010101020101010101010101010201014303030303030303030303030303030303030303030303030121010101010101010101010102010101010101010101010101010143030303030303030
3030303030122020202010101010101010101010101010102020101010101010101020101010102020201010101010101010101010101020101010101010102010101014303030303030303030303030303030303030303030303030121010101010101010101010101020101010101010101010101010143030303030303030
3030303030122020202010101010101010101010101010102020101010101010102010201010101010101010101010101010101010101010102010201020101010101014303030303030303030303030303030303030303030303030121010101010101010101010101010201010101010101010101020143030303030303030
30303030301220201010101010202020201010101010101020101010101020102010202010102010201020102010101010101010101010101010101010101010101010143030303030303030303030303030303030303030303030301713131313131313131313131b1010102010201010101010201020143030303030303030
3030303030121020101010202010202010101010101020102020102010101010101010101010101010101010102020101010101010101010101010101010101010101014303030303030303030303030303030303030303030303030303030303030303030303030121010101010101020102010101020143030303030303030
3030303030121020101010202020101010101010102020201010101010101020102020101010101010101010101010101010101010101010101010101010101010101014303030303030303030303030303030303030303030303030303030303030303030303030121010101010101010101010102010143030303030303030
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400040862302020076200202000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
