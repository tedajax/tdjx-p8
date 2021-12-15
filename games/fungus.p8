pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
function _init()

test_deepcopy()
	dt=1/30
	g={
		cam={
			x=0,y=0,
			dx=0,dy=0,
			rx=0,ry=0,
			t=0,
			follow=nil,
		},
	}

	-- make btnp never key repeat
	-- on hold
	poke(0x5f5c,0xff)
	
	play_init()
end

function play_init()
	_update=play_update
	_draw=play_draw
	actors={}
	a0=make_actor({x=64,y=64})
	g.cam.follow=a0
end

function play_update()
	local ix,iy,ijmp=0,0,btnp(4,0)
	if (btn(0,0)) ix-=1
	if (btn(1,0)) ix+=1
	if (btn(2,0)) iy-=1
	if (btn(3,0)) iy+=1

	if a0.t1>0 then
		a0.t1-=dt*5
	end
	
	actor_move(a0,ix,iy)
	if ijmp then
		actor_jump(a0,3.5)
	end
	
	if ix==0 then
		a0.t=0
	else
		a0.t+=dt*8
	end
	
	-- camera follow
	local cam=g.cam
	if cam.follow then
	
		if cam.t<=0 then
			local roomx=cam.follow.x\128
			local roomy=cam.follow.y\96
			if roomx~=cam.rx or roomy~=cam.ry
			then
				cam.t=1
				cam.lx=cam.x
				cam.ly=cam.y
				cam.rx=roomx
				cam.ry=roomy
			end
		else
			local tx=cam.rx*128
			local ty=cam.ry*96
			cam.x=easeio(cam.lx,tx,1-cam.t)
			cam.y=easeio(cam.ly,ty,1-cam.t)
			cam.t-=dt*1.5
		end		
	end
	cam.x=mid(cam.x,0,128)
end

function play_draw()
	cls()
	
	camera(g.cam.x,g.cam.y)
	
	map(0,0,0,0,32,12)
	
	local sp=8+(a0.t%2)
	
	if a0.t1>0 then
		local x=1-a0.t1
		sp=flr(parabola(x)*1.3)+14
--		sp=(-4*x*(x-1))*2+14
--		sp=14+flr(st*2.8)%2
	elseif not a0.ground or a0.dy<0 then
		local v=3.5
		local t=mid((a0.dy+v)/v,0,1)
		sp=10+t*3
	end
	
	local px=a0.x-4
	local py=a0.y-7
	spr(sp,px,py,1,1,a0.face<0)
	
	camera()
	rectfill(0,96,127,127,0)
 print("\^wFUNGUS",2,99,7)
 
 for i=0,19 do
 	local x=i*3+67
 	line(x,99,x,104,11)
 end
end
-->8
-- actors

function make_actor(p)
	p=p or {}
	local self={
		x=p.x or 0,
		y=p.y or 0,
		dx=0,dy=0,
		cx0=-3,cy0=-7,
		cx1=2,cy1=0,
		face=1,
		t=0,
		t1=0,
		on_side=p.on_side or
			function(self,mask)end,
	}
	return add(actors,self)
end

function friction(v,f)
	if (v==0) return 0
	local s,a=sgn(v),-v*f
	v+=a
	if (sgn(v)~=s) v=0
	return v
end

function actor_canjump(self)
	-- todo: forgiveness windows
	return self.ground
end

function actor_jump(self,force)
	if actor_canjump(self) then
		self.dy=-force
	end
end

function actor_move(self,ix,iy,jump)
	if (ix~=0) self.face=sgn(ix)

	local accel=0.8
	local maxspd=32
	local grav=0.3
	
	local ax=ix*accel
	self.dx+=ax	
	local nspd=mid(abs(self.dx)/maxspd,0,1)
	local kf=lerp(0.25,1.0,nspd)
	
	self.dx=friction(self.dx,kf)
	
	self.dy+=grav
	self.dy=mid(self.dy,-8,8)

	local left,top,right,bot=
		bounds(self.x,self.y,
			self.cx0,self.cy0,
			self.cx1,self.cy1)
		
	self.ground=
		solid(left,bot+1) or
		solid(right,bot+1)
		
	if self.ground and self.dy>0.5
		and self.t1<=0
	then
		self.t1=1
	end
		
	while self.dx>0 and
		(solid(right+self.dx,bot) or
			solid(right+self.dx,top+1))
	do
		self.dx=max(self.dx-1,0)
	end
	
	while self.dx<0 and
		(solid(left+self.dx,bot) or
			solid(left+self.dx,top+1))
	do
		self.dx=min(self.dx+1,0)
	end
	
	while self.dy>0 and
		(solid(left,bot+self.dy) or
			solid(right,bot+self.dy))
	do
		self.dy=max(self.dy-1,0)
	end
	
	while self.dy<0 and
		(solid(left,top+self.dy) or
			solid(right,top+self.dy))
	do
		self.dy=min(self.dy+1,0)
	end
	
	self.x+=self.dx
	self.y+=self.dy
	
	while (solid(left,bot) or
			solid(right,bot))
	do
		self.y-=1
		bot-=1
	end
end
-->8
-- world

function solid(x,y)
	local mx,my=x\8,y\8
	return fget(mget(mx,my))&1~=0
end

function bounds(x,y,x0,y0,x1,y1)
	return x+x0,y+y0,x+x1,y+y1
end
-->8
-- generic math

function lerp(a,b,t)
	return (b-a)*t+a
end

function easeio(a,b,t)
	return (b-a)*inout(t)+a
end

function parabola(t)
	return -4*t*t+4*t
end

function inout(x)
	x=2*x
	if x<1 then
		return 1/2*x*x
	else
		x-=1
		return -1/2*(x*(x-2)-1)
	end
end

-- a: current value
-- b: target value
-- vel: current velocity
-- tm: approx time in seconds to take
-- mx: max speed (defaults inf)
-- ts: timestep (defaults dt)
-- returns result,velocity
-- feed velocity back in
-- to subsequent calls
-- e.g.
-- a,v=damp(a,1,v,0.5,2)
function damp(a,b,vel,tm,mx,ts)
	mx=mx or 32767
	ts=ts or dt
	tm=max(.0001,tm or 0)
	local omega=2/tm

	local x=omega*ts
	local exp=1/(1+x+.48*x*x+.235*x*x*x)
	local c=b-a
	local orig=b

	local mxc=mx*tm
	c=mid(c,-mxc,mxc)
	b=a-c

	local tmp=(vel+omega*c)*ts
	vel=(vel+omega*tmp)*exp
	local ret=b+(c+tmp)*exp

	if (orig-a>0)==(ret>orig) then
		ret=orig
		vel=(ret-orig)/ts
	end

	return ret,vel
end

-->8
-- entities

_ent_map={
	[38]={
		name="key",
	}
}

function make_entity(id,x,y)
	
end
-->8
-- utility/table functions

function deepcopy(tab,acc)
	acc=acc or {}
	local ret={}
	for k,v in pairs(tab) do
		if type(v)=="table" then
			if acc[v] then
				ret[k]=v
			else
				ret[k]=deepcopy(v,acc)
				acc[v]=ret[k]
			end
		else
			ret[k]=v
		end
	end
	return ret
end

function test_deepcopy()
	local t02={a=6,b=7}
	local t00={
		a=1,b="test",c=0.2,d=true,
		e={a=3,b="banana"},
		f={a=t02,b=t02}
	}
	local t01=deepcopy(t00)
	
	
end
__gfx__
0000000099999999000000000000000000000000666666660000000000000000008878000000000000888e000088780000887800078878800000000000000000
0000000099444449000000000000000000277200666cc666000000000000000008788870008878000088870008788870087888708fffff870000000000000000
00700700949444940000000000000000027cc72066c22c66000000000000000078ffff88087888700e88888008ffff8078ffff88fffddfff0000000000000000
0007700094494944000000000000000007cccc706c2552c600000000000000008fddddf878ffff88078888e00fdcdcf08fddddf80dddddd00000000000000000
0007700094449444000000000000000007cccc706c2552c600000b0000033b00fddcdcdf8fddddf800de8d7000dddd000ddcdcd00dddddd00088780000000000
00700700944949440000000000000000027cc72066c22c660000000033b333330dddddd0fddcdcdf00d7dd0000dddd000dddddd00ddcdcd08878887808887870
0000000094944494000000000000000000277200666cc666000000003bbbbbbb0dddddd00dddddd000dddd0000dddd0000dddd000dddddd07ddcdcd878788888
0000000099444449000000000000000000000000666666660000000303bbbb330dddddd0dddddddd00dddd0000dddd000000000000dddd00dddddddd8ddcdcd8
bbbbbbbb4433b13400000000000000000000000000000000000b00b003bbbb3000000000000000000000000000000000000000000000000000000000000000b3
1b141b13333b1b3300000000000000000000000000000000000033bb33bbbb000000000000000000000000000000000000000000000000000000000000000000
b331b333bbbbbbbb0000000000000000000000000000000000000030333bb3330000000000000000000000000000000000000000000000000000000000bb0000
1bb31b131bb31b130000000000000000000000000000000000000000bb3333b00000000000000000000000000000000000000000000000000000000000bbb333
b131b33bb131b33b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030
133331331343313300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb
b33b1b34b33b1b340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
343b4344343b33440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000030000000000000333000000000000033300000000000000033300000000000003000
00000000000000000000000000000000000000000000b00000000000003bb30000000000003bb330000000000033b330000000000003b3b30000000000003000
000000000000000000000003333b3000000000b3003bb30000000003033bbb3000000333303bbb30000000003033bb300000000000003b300000000000000000
000003b0000000000000033bbbbbbb00000033bbbbbbbbb000000bbbbb33bb300000033b33333333000000033333333300000000000333330000000000000000
0003b030b00000000003b3bbbbbb33b000033bb33bbbb3b000000bb33333bb300000003bbbbb3bb3000000033bbb333000000000000033330000000000000030
00333bb03b00000000333bbbb333bb00003bbb3bbb33bbbb0000033bbbbbbb33000000033bbbb3b300000000333bb3b300000000000003330000000000000000
0bbbbbbb000b00000bbbbbb33bbbbbb000bbb33bbbbb33b000003b3bb333333300000333333333bb00000033003333bb000000000330033b0000000000000030
0bbbbbb3000300000bbbbbbbbbb33b0000b3bb33333bb3000003bbbb333bbb300000333b33bb3330000000bb3033333000000000000303330000000000030030
00bbb3333000000000bbb3bbb3bbbbb000bb3bbbbbbbbb330000bbb33bbbbb3300003bbb33bbbb30000003bb333bb33000000000000303b30000000000000003
0003bbbb000000000003bbb3bb333b00000bbbbbbbb33b3000033bb3bbbb3b30000003bbb33bbb30000003bbb33bb33000000000000003330000000000000030
00000300000000000000033bbbbbb3000000333bb33333b000003bb3333bbb3000000bb333bbbb3000000bb333bbbb3000000003000033330000000000000000
0000000000000000000000003bb300000000030b3300b000000003003333bb30000000300333bbb3000000300333bbb30000003b303333330000000030000000
0000000000000000000000000000000000000000000000000000000000033b000000000000033333000000000003333300000003003333b30000000000000003
0000000000000000000000000000000000000000000000000000000000000000000000000000033000000000000003300000000000003b330000000000003000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033300000000000000300
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000300
__gff__
0003000000000000080808080808080801010000000000000000000000000000000000000000000008080000000000000000000000000000080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000000000000000000001111111100000011111111111100000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000000000000000000001011110000000011111111110000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000000000000000000000000000000040011111111000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000000000000000000001010101010101011111111000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000000000000000000001111111111110000000011000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000010101010101010101000001111111100000000000011000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000000000000000000001111110000000000000011000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000000000000000000001111000000000000000011000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100001010100000000000101010000000000000000000000011000000001011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000000000000000000000000000000000000000005000000001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1110101010101010101010101010101010101010101010101010101010101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000010100000001010000000000000000000000000000000001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000010100000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000010100000000000000000000000111100000000000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1110101010101011111010101010101111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
