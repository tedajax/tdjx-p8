pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

function is_dev() return peek(0x5f2d)~=0 end

function _init()
	poke(0x5f2d,1)

	enable_light=true
	g_timescale=1

	jk_init()
	init_light_palettes()
	
	levels={
		{
			name="test_01",
			x=0,y=0,w=16,h=16,
		},
		{
			name="test_02",
			x=16,y=0,w=16,h=8,
		},
		{
			name="test_03",
			x=0,y=16,w=16,h=16,
		},
	}
	
	for i=1,#levels do levels[i].id=i end
	
	level_id=3
	level=levels[level_id]
	
	reset()
end

function keypress(key)
	if key=="=" then
		level_id+=1
		level_id=mid(level_id,1,#levels)
		level=levels[level_id]
		reset()
	elseif key=="-" then
		level_id-=1
		level_id=mid(level_id,1,#levels)
		level=levels[level_id]
		reset()
	elseif key=="l" then
		enable_light=not enable_light
	end
end

function reset()
	reload()
	init_actors()
	init_articles()
	init_entities(level.x,level.y,
		level.w,level.h)
end

function _update() dt=g_timescale/30; update(dt) end
--function _update60() dt=g_timescale/60; update(dt) end

function update(dt)
	while stat(30) do
		keypress(stat(31))
	end

	jk_update()
	
	watch(level.name)
	
	local ix,iy=0,0
	if (btn(0)) ix-=1
	if (btn(1)) ix+=1
	if (btn(2)) iy-=1
	if (btn(3)) iy+=1
	
	local bts={btnp(4),btnp(5),btn(4),btn(5)}
	local bt=0
	for i=1,#bts do
		if bts[i] then
			bt+=shl(1,i-1)
		end
	end
	
	if player:getf(af.dead) then
		if bts[1] then reset() end
	end
	
	if not player:getf(af.dead) then
 	player.inp.x=ix
 	player.inp.y=iy
 	player.inp.btns=bt
 else
 	player.inp.x=0
 	player.inp.y=0
 	player.inp.btns=0
 end
 
	tick_entities(dt)
	update_articles(dt)
	
	foreach(actors,function(a)
		a:move(dt)
	end)
	
	watch("pos:"..player.x..","..player.y)
	watch("vel:"..player.dx/dt..","..player.dy/dt)
	watch("fps:"..stat(7))
	watch("cpu:"..band(stat(1)*100,0xffff).."%")
end
function _draw()
	cls()
		
	map(128-16,0,0,0,16,16)
	--sspr(0,40,8,8,0,0,127,127)
	local level_map=function(layer)
		map(level.x,level.y,
			64-level.w*4,64-level.h*4,
			level.w,level.h,
			layer)
	end
	
	level_map(127)
	
	foreach(actors,function(a)
 	local sx,sy=w2s(a.x,a.y)
 	local sp=a.sp
 	if a:getf(af.dead) then
 		sp+=16
 	end
 	
 	spr(sp,sx-4,sy-8,1,1,a.face<0)
--[[ 	rect(sx-a.w*8,sy-a.h*8,
 		sx+a.w*8,sy,11)
 	pset(sx,sy,8)]]
 end)
 
 draw_articles()
 
	local draw_ghost=function(gx,gy)
		
		
		local range=player.light.bright*player.light.range
		local d=dist2(player.light.x,
			player.light.y,
			gx,gy)
		
		local wx,wy=w2s(gx,gy)
		palt(0,false)
		palt(14,true)
		spr(72,wx-8,wy-8,2,2)
		watch("asdf:"..d)
		watch(light_rng[1]/8)
		if d<=12 then
			circ(wx,wy,8,8)
		end
		palt()
	end
	
	draw_ghost(27,4)
 
 level_map(128)
 
 local conew=1/6
 local hcw=conew/2
 local conesz=48
 local wx,wy=w2s(player.x,player.y)
 wx,wy=flr(wx),flr(wy-4)

	if player and enable_light then 
	 lighting(player.light)
	end
--[[ 
 ]]

	--cellipse(64,64,64,24,fl_blend(4))
	
	
	
--[[	
	if band(player.inp.btns,0x8)~=0 then
		local ang=player.look_r
		light_circ(wx,wy,conesz,-hcw+ang,hcw+ang)
	else
		if player.face>0 then
		 light_circ(wx,wy,conesz,-hcw,hcw)
		else
			light_circ(wx,wy,conesz,-hcw+.5,hcw+.5)
		end
	end]]
 
 draw_entity_colliders()

	local f=player.light:brightf()
	if f>1/128 then
		rectfill(0,127,128*f,127,10)
	end

	if is_dev() then	
		draw_log()
		draw_watch()
	end
end

function lighting(light)
	local lx,ly=w2si(light.x,light.y)
	local bright=light:brightness()
	local range=flr(bright*light.range)
	local noise=light.noise or 0
	
	srand(flr(t()*light.noise_rate))
	
 local top=max(ly-range-1,0)
 memset(0x6000,0,(top+1)*64)
 
 local bot=min(ly+range+1,127)
 memset(0x6000+bot*64,0,(127-bot+1)*64)
 
 local light_fill=fl_light(
 	lx,ly,bright,noise)
 crect(lx-range-1,ly-range,
 	lx+range,ly+range,light_fill)
 crect(0,top,lx-range-2,bot,fl_black)
 crect(lx+range,top,127,bot,fl_black)
end
-->8
-- actors

-- actor flags
af={
	grounded=shl(1,0),
	platdrop=shl(1,1),
	dead=shl(1,2),
}

actor={
	x=0,y=0,					-- position
	dx=0,dy=0,			-- velocity
	pushx=0,pushy=0,
	ddx=0,ddy=8,	-- acceleration
	w=0.2,h=0.5, -- half width/height
	sp=1,
	face=1,
	flags=0,
	jumps=0,
	mass=1,
	drag=0,
	look_r=0,
	look_dr=0,
	t_air=0,
	t_jump_hold=0,
	t_plat_drop=0,
	k_accel=64,
	k_coldst=0.3, -- collision check distance
	k_scndst=0.1, -- scan distance while searching for contact point
	k_bounce_wall=0,
	k_bounce_floor=0,
	k_jump_force=24,
	k_max_move=8,
	k_jump_forgive_t=5/60,
	k_jump_hold_t=1/2,
	k_jump_hold_force=1,
	k_jump_hold_delay=5/60,
	k_plat_drop_t=4/60
}

function actor:premove()
end

function actor:postmove()
end

function actor:kill()
	self:setf(af.dead,true)
end

function actor:jump(force)
	force=force or self.k_jump_force
	local f=min(force*dt,1)
	self.dy=-f
end

function actor:force(fx,fy)
	local m=max(self.mass,0.01)
	self.dx+=fx/m*dt
	self.dy+=fy/m*dt
end

function actor:friction(fx,fy)
	fx=mid(fx,0,1)
	fy=mid(fy,0,1)
	self.dx=self.dx*(1-fx)
	self.dy=self.dy*(1-fy)
end

function actor:linfric(fx,fy)
	self.dx=moveto(self.dx,0,fx*dt)
	self.dy=moveto(self.dy,0,fy*dt)
end

function actor:on_wall() end

function actor:move(dt)
	-- apply inputs
	local accel=self.k_accel*dt
	if not self:getf(af.grounded) then
		accel=shr(accel,1)
	end
		
	local stand=self:getf(af.grounded)
	if (self.t_plat_drop>0) self.t_plat_drop-=dt
	if self.inp.y>0 then
		self.t_plat_drop=self.k_plat_drop_t
	end
	
	local lockpos=band(self.inp.btns,0x8)~=0
	
	local tg_look=self.look_r
	
	if lockpos then
		if self.inp.x<0 then
			self.face=-1
		elseif self.inp.x>0 then
			self.face=1
		end
		local a=accel
		if (not stand) a/=2
		self.dx=moveto(self.dx,0,a*dt)
		if self.inp.x==0 and self.inp.y==0 then
			if self.face>0 then
				tg_look=0
			else
				tg_look=0.5
			end
		else
			tg_look=atan2(self.inp.x,self.inp.y)
		end
	else
 	if self.inp.x<0 then
 		self.dx-=accel*dt
 		self.face=-1
 		tg_look=0
 		self.look_r=0
 	elseif self.inp.x>0 then
 		self.dx+=accel*dt
 		self.face=1
 		tg_look=0.5
 		self.look_r=0.5
 	else
 		local a=accel
 		if (not stand) a/=2
 		self.dx=moveto(self.dx,0,a*dt)
 	end
 end
 
 self.look_r=moveto_angle(
 	self.look_r,tg_look,0.5*dt)

	if stand then	
		self.jumps=0
	end
	
	local canjump=stand
		or self.jumps<0
		or (not stand
						and self.t_air<self.k_jump_forgive_t)

	canjump=canjump and not self:getf(af.dead)
	canjump=canjump and
		not solid(self.x,self.y-0.5)
		
	local jumpreq=band(self.inp.btns,1)~=0
	local jumphold=band(self.inp.btns,4)~=0
		
	if jumpreq and canjump then
		self:jump()
		self.jumps+=1
	end
	
	if not stand
		and jumphold
		and self.t_jump_hold<self.k_jump_hold_t+self.k_jump_hold_delay
	then
		self.t_jump_hold+=dt
		if self.t_jump_hold>=self.k_jump_hold_delay then
			self.dy-=self.k_jump_hold_force*dt
		end
	elseif stand then
		self.t_jump_hold=0
	end

	-- do physics
	self:setf(af.grounded,false)
	
	self.dx+=self.ddx*dt
	self.dy+=self.ddy*dt
	
	local max_x,max_y=
		self.k_max_move*dt,30*dt
	self.dx=mid(self.dx,-max_x,max_x)
	self.dy=mid(self.dy,-max_y,max_y)
	
	-- x movement
	local nx=self.x+
		self.dx+sgn(self.dx)*self.k_coldst+
		self.pushx
				
	if not solid(nx,self.y-self.h) then
		-- no contact, move normally
		self.x+=self.dx+self.pushx
	else
		-- hit solid
		-- find contact point
		while not solid(
			self.x+sgn(self.dx+self.pushx)*self.k_coldst,
			self.y-0.5)
		do
			self.x+=sgn(self.dx+self.pushx)*self.k_scndst
		end
		
		-- bounce
		self.dx*=-self.k_bounce_wall
		
		self:on_wall()
	end

	-- y movement	
	local left,right=
		self.x-self.w,self.x+self.w

	if self.dy<0 then
		-- going up
		if solid(left,self.y+self.dy-1) or
			solid(right,self.y+self.dy-1)
		then
			-- hit ceiling
			self.dy=0
			
			-- search contact point
			while not solid(left,self.y-1)
				and not solid(right,self.y-1)
			do
				self.y-=0.01
			end
		else
			self.y+=self.dy
		end
	else
		-- going down
		
		local is_solid=nil
		if self.t_plat_drop<=0
		then
			is_solid=platform_solid
		else
			is_solid=blocked_platform_solid
		end
	
		if is_solid(left,self.y+self.dy)
			or is_solid(right,self.y+self.dy)
		then
			-- bounce
			if self.k_bounce_floor>0 and
				self.dy>0.2
			then
				self.dy*=-self.k_bounce_floor
			else
				self:setf(af.grounded,true)
				self.dy=0
			end
			
			-- snap down
			while not is_solid(left,self.y)
				and not is_solid(right,self.y)
			do
				self.y+=0.05
			end

			-- pop up
			local count=5
			while 
				(is_solid(left,self.y-0.1)
					or is_solid(right,self.y-0.1))
				and not is_solid(left,self.y-0.5)
				and not is_solid(right,self.y-0.5)
			do
				self.y-=0.05
				count+=1
			end
--[[			while solidfn(right,self.y-0.1)
			do
				self.y-=0.05
			end]]
		else
			self.y+=self.dy
		end
	end
	
	if self:getf(af.grounded) then
		self.t_air=0
	else
		self.t_air+=dt
	end
	
	local shootreq=band(self.inp.btns,2)~=0

	if shootreq then
		add_article(bullet:new({
			x=self.x,y=self.y-0.5,
			dx=self.face*12}))
	end
	
	self.pushx=0
	self.pushy=0
end

function actor:new(p)
	self.__index=self
	p=p or {}
	p.inp=p.inp or {x=0,y=0,btns=0}
	return setmetatable(p,self)
end

function actor:setf(f,v)
	if v then
		self.flags=bor(self.flags,f)
	else
		self.flags=band(self.flags,
			bnot(f))
	end
	return self.flags
end

function actor:getf(f)
	return band(self.flags,f)~=0
end

function actor:left() return self.x-self.w end
function actor:right() return self.x+self.w end
function actor:top() return self.y-self.h end
function actor:bottom() return self.y end

function actor:overlap(other)
	return self:left()<=other:right()
		and self:right()>=other:left()
		and self:top()<=other:bottom()
		and self:bottom()>=other:top()
end

function init_actors()
	actors={}
end

function add_actor(p)
	return add(actors,actor:new(p))
end
-->8
-- utils

_sgn=sgn
function sgn(v)
	if (v==0) return 0
	return _sgn(v)
end

function moveto(a,b,d)
	if abs(b-a)<=d then
		return b
	else
		return a+sgn(b-a)*d
	end
end

_watches={}

function watch(msg,col)
	add(_watches,{msg=tostr(msg),
		col=col or 12})
end

function draw_watch(col)
	col=col or 12
	local n=#_watches
	for i=0,n-1 do
		local w=_watches[i+1]
		print(w.msg,0,i*6,w.col)
	end
end

_logs={}

function log(msg,col)
	add(_logs,{msg=tostr(msg),col=col or 6})
	local n=#_logs
	if n>20 then
		for i=2,n do
			_logs[i-1]=_logs[i]
		end
		_logs[n]=nil
	end
end

function draw_log()
	local n=#_logs
	for i=1,n do
		local l=_logs[i]
		print(l.msg,127-#l.msg*4,(i-1)*6,l.col)
	end
end


function jk_init()
	_jk_btns={}
	for i=0,5 do
		_jk_btns[i]={
 		last={},
 		curr={},
 	}
	end
end

function jk_update()
	_watches={}

	for p=0,5 do
		local pl=_jk_btns[p]
		for b=0,5 do
			pl.last[b]=pl.curr[b] or false
			pl.curr[b]=btn(b,p)
		end
	end
end

_btnp=btnp
function btnp(b,p)
	p=p or 0
	local pl=_jk_btns[p]
	return pl.curr[b] and not pl.last[b]
end

function btnr(b,p)
	p=p or 0
	local pl=_jk_btns[p]
	return not pl.curr[b] and pl.last[b]
end

function clone(o,m)
	local ret={}
	for k,v in pairs(o) do
		ret[k]=v
	end
	m=m or {}
	for k,v in pairs(m) do
		ret[k]=v
	end
	return ret
end


function wrap(a,l)
	return mid(a-flr(a/l)*l,0,l)
end

function angle_diff(a,b)
	local d=wrap(b-a,1)
	if (d>0.5) d-=1
	return d
end

-- a: current value
-- b: target value
-- vel: current velocity
-- tm: approx time in seconds to take
-- mx: max speed (defaults inf)
-- ts: timestep (defaults dt)
-- returns result,velocity
-- feed velocity back in
-- 	to subsequent calls
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

function damp_angle(a,b,vel,tm,mx,ts)
	b=a+angle_diff(a,b)
	return damp(a,b,vel,tm,mx,ts)
end

function moveto_angle(a,b,d)
	local dl=angle_diff(a,b)
	if -d<dl and dl<d then
		return b
	else
		return moveto(a,a+dl,d)
	end
end

function lerp(a,b,t)
	return (b-a)*t+a
end

function dist(x1,y1,x2,y2)
	return sqrt(dist2(x1,y1,x2,y2))
end

function dist2(x1,y1,x2,y2)
	watch(x1..","..y1..":"..x2..","..y2)
	local dx,dy=(x2-x1),(y2-y1)
	return dx*dx+dy*dy
end

function round(x)
 return flr(x+0.5)
end

function set(a,b)
	a=a or {}
	b=b or {}
	for k,v in pairs(b) do
		a[k]=v
	end
	return a
end

function class(clob)
	clob=clob or {}
	setmetatable(clob,
		{__index=clob.extends})
	clob.new=function(self,ob)
		ob=set(ob,{class=clob})
		setmetatable(ob,{__index=clob})
		if (clob.create) clob:create()
		return ob
	end
	return clob
end

function blink(ivl,tt)
	tt=tt or t()
	return tt%(ivl*4)<ivl*2
end
-->8
-- physics

function w2s(wx,wy)
	return wx*8-level.x*8+64-level.w*4,wy*8-level.y*8+64-level.h*4
end

function w2si(wx,wy)
	local sx,sy=w2s(wx,wy)
	return flr(sx),flr(sy)
end

function solid(wx,wy)
	-- todo: other things
	return map_solid(wx,wy)
end

-- is world coord: wx,wy solid
-- 1 world unit == 8 pixels
function map_solid(wx,wy)
	--return fget(mget(wx,wy),0)
	local val=mget(wx,wy)
	if fget(val,0) then
		if fget(val,4) then
			-- slope
			local l,r=flr(wx),ceil(wx)
			local t,b=flr(wy),ceil(wy)
			local nx,ny=wx-l,wy-t
			local flipx=fget(val,5)
			local flipy=fget(val,6)
			local chx,chy
			if flipx then
				if flipy then
					return nx<(0.875-ny)
				else
					return nx<=ny
				end
			else
				if flipy then
					return nx>=ny
				else
					return nx>(0.875-ny)
				end
			end
		elseif fget(val,2) then
		else
			return true
		end
	end
	return false
end

function platform_solid(wx,wy)
	local ret=solid(wx,wy)
	local val=mget(wx,wy)
	if fget(val,2) then
		return wy-flr(wy)<0.5
	end
	return ret
end

function blocked_platform_solid(wx,wy)
	local ret=solid(wx,wy)
	local val=mget(wx,wy)
	if fget(val,2) and fget(val,6) then
		return wy-flr(wy)<0.5
	end
	return ret
end

function map_kill(wx,wy)
	return fget(mget(wx,wy),1)
end
-->8
-- entity

entity={
	x=0,y=0,val=0,
	wx=0,wy=0,
	w=0.5,h=0.5,
}

function entity:new(p)
	self.__index=self
	return setmetatable(p or {},self)
end

function entity:left()
	return self.wx-self.w
end

function entity:right()
	return self.wx+self.w
end

function entity:top()
	return self.wy-self.h
end

function entity:bottom() 
	return self.wy+self.h
end

function entity:center()
	return self.x+0.5,self.y+0.5
end

function entity:start(self) end
function	entity:tick(self,dt) end
--function	entity:actor_touch(a) end

switch_block=entity:new({
	name="switch_block",
	start=function(self)
		self.ivl=self.ivl or 1
		self.t0=self.ivl
		self.frame=0
		self.base=self.val
		if self.on then
			self.frame=1
			self.base-=1
		end
	end,
	tick=function(self,dt)
		self.t0-=dt
		if self.t0<=0 then
			self.t0+=self.ivl
			self.frame=(self.frame+1)%2
			mset(self.x,self.y,self.base+self.frame)
		end
	end
})

spring=entity:new({
	name="spring",
	ivl=0.25,
	force=22,
	w=0.125,
	h=0.25,
	start=function(self)
		self.t0=0
		self.sp=self.val
		self.wx=self.x+0.5
		self.wy=self.y+0.75
	end,
	tick=function(self,dt)
		if (self.t0>0) self.t0-=dt
		if self.t0>0.8*self.ivl then
			mset(self.x,self.y,self.sp+1)			
		else
			mset(self.x,self.y,self.sp)
		end
	end,
	actor_touch=function(self,a)
		if self.t0<=0 then
			a.y=self.wy
			a:jump(self.force)
			self.t0=self.ivl
		end
	end,
})

key_door=entity:new({
	name="key_door",
	tdoor=0,
	closed=true,
	w=0.75,
	start=function(self)
		local f=fget(self.val)
		if band(f,1)~=0 then
			closed=false
		end
		f=band(f,0x60)
		f=shr(f,5)
		self.tdoor=f
		self.wx,self.wy=self:center()
	end,
	actor_touch=function(self,a)
		if self.closed then
			local k=a.keys or {}
			if k[self.tdoor] then
				self.closed=false
				mset(self.x,self.y,self.val-self.tdoor-1)
			end
		end
	end
})

door_key=entity:new({
	name="door_key",
	tdoor=0,
	taken=false,
	w=0.4,
	h=0.2,
	start=function(self)
		self.tdoor=shr(band(fget(self.val),0x60),5)
		self.wx,self.wy=self:center()
	end,
	actor_touch=function(self,a)
		if a.keys and not self.taken then
			self.taken=true
			a.keys[self.tdoor]=true
			mset(self.x,self.y,0)
		end
	end
})

actor_spawn=entity:new({
	name="actor_spawn",
	spawn=function(self) end,
	start=function(self)
		mset(self.x,self.y,0)
		self:spawn(self.x+0.5,self.y+1)
	end
})

wall_gun=entity:new({
	name="wall_gun",
	facex=1,
	facey=0,
	shot_speed=6,
	fire_ivl=2,
	t_fire=0,
	start=function(self)
		self.t_fire=self.fire_ivl
	end,
	tick=function(self,dt)
		self.t_fire-=dt
		if self.t_fire<=0 then
			self.t_fire+=self.fire_ivl
			add_article(bullet:new({
				x=self.x+0.5,y=self.y+0.5,
				t_life=2,
				dx=self.facex*self.shot_speed,
				dy=self.facey*self.shot_speed}))
		end
	end,
})

portal=entity:new({
	name="portal",
	t=0,
	f=0,
	start=function(self)
		self.t=0.25
	end,
	tick=function(self,dt)
		self.t-=dt
		if self.t<=0 then
			self.t+=0.25
			self.f+=1
			mset(self.x,self.y,self.val+self.f%2)
		end
	end
})

light_power=entity:new({
	name="light_power",
	w=0.5,h=0.5,
	start=function(self)
		self.wx,self.wy=self:center()
	end,
	actor_touch=function(self,a)
		if a.light then
			a.light.bright_tg+=a.light.bright_power
			mset(self.x,self.y,0)
			del(entities,self)
		end
	end
})

conveyor_block=entity:new({
	name="conveyor_block",
	w=0.5,h=2/8,
	ox=0,oy=-0.5,
	fx=0,fy=0,
	start=function(self)
		self.wx,self.wy=self:center()
		self.wx+=self.ox
		self.wy+=self.oy
	end,
	actor_touch=function(self,a)
		a.pushx+=self.fx*dt
		a.pushy+=self.fy*dt
	end
})

kill_volume=entity:new({
	name="kill_volume",
	w=0.5,h=0.5,
	ox=0,oy=0,
	start=function(self)
		self.wx,self.wy=self:center()
		self.wx+=self.ox
		self.wy+=self.oy
	end,
	actor_touch=function(self,a)
		a:kill()
	end,
})

_entity_map={}
_entity_map[7]=switch_block
_entity_map[8]=clone(switch_block,{on=true})
_entity_map[23]=switch_block
_entity_map[24]=clone(switch_block,{on=true})
_entity_map[19]=spring
_entity_map[1]=clone(
	actor_spawn,{
		spawn=function(self,ax,ay)
			player=add_actor({
  		x=ax,y=ay,
  		keys={},
  		ddy=2,
  		light=add_article(light:new()),
  		k_accel=2*30,
  		k_max_move=6,
  		k_jump_force=16,
  		k_jump_hold_force=0
  	})
  	player.light.owner=player
		end
	}
)

_entity_map[16]=clone(actor_spawn,{
	spawn=function(self,ax,ay)
		add_actor({
			x=ax,y=ay,sp=16,
			k_max_move=1,
			k_accel=3,
			inp={x=1,y=0,bx=false,by=false},
			on_wall=function(self)
				self.inp.x=-self.inp.x
			end
		})
	end,
})

_entity_map[35]=wall_gun
_entity_map[36]=clone(wall_gun,{facex=-1})
_entity_map[51]=wall_gun
_entity_map[52]=clone(wall_gun,{facex=-1})
_entity_map[53]=clone(wall_gun,{facex=0,facey=1})
_entity_map[54]=clone(wall_gun,{facex=0,facey=-1})

_entity_map[37]=portal

_entity_map[40]=light_power

_entity_map[10]=kill_volume
_entity_map[11]=kill_volume
_entity_map[39]=clone(
	kill_volume,
	{oy=0.25,h=0.25})
	
_entity_map[57]=clone(
	conveyor_block,
	{fx=2,fy=0})
_entity_map[58]=clone(
	conveyor_block,
	{fx=-2,fy=0})

for i=0,3 do
 _entity_map[26+i]=key_door
 _entity_map[42+i]=door_key
end

function init_entities(x,y,w,h)
	entities={}
	for xx=x,x+w-1 do
		for yy=y,y+h-1 do
			local val=mget(xx,yy)
			local entdef=_entity_map[val]
			if entdef then
				local def=clone(entdef)
				def.x=xx
				def.y=yy
				def.val=val
				local ent=add(entities,entity:new(def))
				ent:start()
			end
		end
	end
end

function tick_entities(dt)
	for e in all(entities) do
		e:tick(dt)
		if e.actor_touch then
			for a in all(actors) do
				if a:overlap(e) then
					e:actor_touch(a)
			 end
			end
		end
	end
end

function draw_entity_colliders()
	for e in all(entities) do
		if e.actor_touch then
 		local l,r,t,b=
 			e:left(),e:right(),
 			e:top(),e:bottom()
 		local tlx,tly=w2s(l,t)
 		local brx,bry=w2s(r,b)
 		rect(tlx,tly,brx,bry,11)
 	end
	end
end
-->8
-- articles

article=class({
	id=0,
	x=0,y=0,
	dx=0,dy=0,
	w=0.5,h=0.5,
	dead=false,
})

function article:start() end

function article:update(dt)
	self.x+=self.dx*dt
	self.y+=self.dy*dt
end

function article:draw()end

bullet=class({
	extends=article,
	t_life=0.5,
})

function bullet:start()
	self.spawnx=flr(self.x)
	self.spawny=flr(self.y)
end

function bullet:update(dt)
	article.update(self,dt)
	
	if solid(self.x,self.y) and
		(flr(self.x)~=self.spawnx or
			flr(self.y)~=self.spawny)
	then
		self.dead=true
	end
	
	if self.t_life>0 then
		self.t_life-=dt
		if self.t_life<=0 then
			self.dead=true
		end
	end
end

function bullet:draw()
	local wx,wy=w2s(self.x,self.y)
	circfill(wx,wy,1,10)
end

-- article manager
function init_articles()
	articles={}
	article_id=0
end

function add_article(a)
	a.id=article_id
	article_id+=1
	a:start()
	return add(articles,a)
end

function update_articles(dt)
	foreach(articles,
		function(a)
			a:update(dt)
			if a.dead then
				del(articles,a)
			end
		end)
end

function draw_articles()
	foreach(articles,
		function(a) a:draw() end)
end

light=class({
	extends=article,
	bright=0.4,
	bright_tg=1.2,
	range=42,
	flicker=0.01,
	flicker_rate=1,
	bright_decay=0,
	bright_min=0,
	bright_max=1.2,
	bright_power=0.2,
	noise=0.08,
	noise_rate=5,
	t=0,
})

function light:start()
	self.bright=self.bright_tg
end

function light:brightness()
	return self.bright+
		sin(self.t)*self.flicker
end

function light:brightf()
	return (self.bright-self.bright_min)/
		(self.bright_max-self.bright_min)
end

function light:update(dt)
	article.update(self,dt)

	self.t+=dt*self.flicker_rate
	
	self.bright=lerp(self.bright,
		self.bright_tg,4*dt)
		
	local decay=self.bright_decay*dt
	if self.bright_tg<self.bright_min+0.15 then
		decay*=8
	elseif self.bright_tg<self.bright_min+0.25 then
		decay/=4
	elseif self.bright_tg<self.bright_min+0.5 then
		decay/=2
	end
	self.bright_tg-=decay
	
	self.bright_tg=mid(self.bright_tg,
		self.bright_min,self.bright_max+0.2)
	self.bright=mid(self.bright,
		self.bright_min,self.bright_max)
	
	if self.owner then
		self.x=self.owner.x
		self.y=self.owner.y-0.5
	end
end

-->8
-- lighting

function init_light_palettes()
	_sqrt={}
	for i=0,4096 do
		_sqrt[i]=sqrt(i)
	end

	load_palette(14,0)
end

-- sp: sprite to load palette from
-- reads two sprites vertically
-- pi: palette index to write to
--	[0,2]
function load_palette(sp)
	local spx,spy=
		sp%16*8,flr(sp/16)*8

	for li=1,6 do
		local addr=0x4300+li*0x100
		local sx=li-1+spx
		for l=0,15 do
			local lc=sget(sx,l+spy)
			local ax=shl(lc,4)
			for r=0,15 do
				poke(addr,
					ax+sget(sx,r+spy))
				addr+=1
			end
		end
	end
end


function crect(x1,y1,x2,y2,ln)
	x1,x2=max(x1,0),min(x2,127)
	y1,y2=max(y1,0),min(y2,127)
	if (x2<x1 or y2<y1) return
	for y=y1,y2 do
		ln(x1,x2,y)
	end
end

function cellipse(cx,cy,rx,ry,ln)
	cy,ry=round(cy),round(ry)
	local w=0
	local ryx,rxy=ry/rx,rx/ry
	local dy=(-2*ry+1)*rxy
	local dx=ryx
	local ddx=2*ryx
	local ddy=2*rxy
	local lim=rx*ry
	local v=ry*ry*rxy
	local my=cy+ry-1
	for y=cy-ry,cy-1 do
		while true do
			if v+dx<=lim then
				v+=dx
				dx+=ddx
				w+=1
			else
				break
			end
		end
		
		if w>0 then
			local l,r=
				mid(cx-w,0,127),
				mid(cx+w-1,0,127)
			if (y>=0 and y<128) ln(l,r,y)
			if (my>=0 and my<128) ln(l,r,my)
		end
		
		v+=dy
		dy+=ddy
		my-=1
	end
end

-- fill functions
function fl_color(c)
	return function(x1,x2,y)
		line(x1,y,x2,y,c)
	end
end

fl_black=fl_color(0)

function fl_none() end

function fl_blend(l)
	local lutaddr=0x4300+shl(l,8)
	return function(x1,x2,y)
		local laddr=lutaddr
		local yaddr=0x6000+shl(y,6)
		local saddr,eaddr=
			yaddr+band(shr(x1+1,1),0xffff),
			yaddr+band(shr(x2-1,1),0xffff)
			
		if band(x1,1.99995)>=1 then
			local a=saddr-1
			local v=peek(a)
			poke(a,
				band(v,0xf)+
				band(peek(bor(laddr,v)),0xf0)
			)
		end
		
		for addr=saddr,eaddr do
			poke(addr,
				peek(
					bor(laddr,peek(addr))
				)
			)
		end
		
		if band(x2,1.99995)<1 then
			local a=eaddr+1
			local v=peek(a)
			poke(a,
				band(peek(bor(laddr,v)),0xf)+
				band(v,0xf0)
			)
		end
	end
end

light_rng={
	16*42,26*42,
	30*42,36*42,
	42*42,
}

light_rng[0]=-1000

light_fills={
	fl_none,fl_blend(2),fl_blend(3),
	fl_blend(4),fl_blend(5),fl_color(0)
}
brkpts={}
function fl_light(lx,ly,bright,noise)
	noise=noise or 0
	local nmin=1-noise
	local nrange=noise*2
	local brightf,fills=
		bright*bright,
		light_fills
	return function(x1,x2,y)
		local ox,oy,oe=x1-lx,y-ly,x2-lx
		
		local mul=brightf*(rnd(nrange)+nmin)
		local ysq=oy*oy
		local srng,erng,slv,elv=
			ysq+ox*ox,
			ysq+oe*oe
		for lv=5,0,-1 do
			local r=band(light_rng[lv]*mul,0xffff)
			if not slv and srng>=r then
				slv=lv+1
				if (elv) break
			end
			if not elv and erng>=r then
				elv=lv+1
				if (slv) break
			end
		end
		
		local llv,hlv=1,max(slv,elv)
		local mind=max(x1-lx,lx-x2)
		for lv=hlv-1,1,-1 do
			local brng=band(light_rng[lv]*mul,0xffff)
			local brp=_sqrt[brng-ysq]
			brkpts[lv]=brp
			if not brp or brp<mind then
				llv=lv+1
				break
			end
		end
	
 	local xs,xe=lx+ox
 	for l=slv,llv+1,-1 do
 		xe=lx-brkpts[l-1]
 		fills[l](xs,xe-1,y)
 		xs=xe
 	end
 	
 	for l=llv,elv-1 do
 		xe=lx+brkpts[l]
 		fills[l](xs,xe-1,y)
 		xs=xe
 	end
 	
 	fills[elv](xs,x2,y)
	end
end
-->8
-- todo/notes

-- story:
-- 	
__gfx__
00000000033333309999999900000009900000009999999999999999999999994444444499999999808080800088008866666666000000000000000000000000
000000003bbbbbb09999999900000099990000000999999999999990999999994444444499999999088888880088008866666666000000001110000011000000
007007003bbb1b10999999990000099999900000009999999999990099999999444444440000000088eeee808800880000000000000000002211000021100000
000770003bbbbbb0999999990000999999990000000999999999900099949999444944440000000008eeee888800880000000000000000003331100033110000
000770003bbbbbb3999999990009999999999000000099999999000099994999444494440000000088eeee800088008800000000000000004221100044221000
007007003bbb11b3999999990099999999999900000009999990000099999999444444440000000008eeee880088008800000000000000005511100055110000
000000003bbbbbb399999999099999999999999000000099990000009999999944444444000000008888888088008800000000000000000066d5100066dd5100
0000000003333330999999999999999999999999000000099000000099999999444444440000000008080808880088000000000000000000776d100077776d51
0cc000000000ddd09000000900000000000000000000000000000000999999999999999999999999999999999999999999999999999999998822100088842100
0ccc0000d656666d9000000900000000099999900000000000000000900000099888888990000009999cc99999988999999bb999999229999422100099942100
0cccccc0d666666d900000090000000000099000000000000000000090000009988888899000000999c99c999989989999b99b9999299297a9421000aa994210
0ccdddd0d656666d90000009000000000009900000000000000000009000000998888889900000099cccccc9988888899bbbbbb992222229bb331000bbb33100
cccdedecd666666d90000009000000000009900000000000000000009000000998888889900000099cc99cc9988998899bb99bb992299229ccd51000ccdd5100
cccdccccd666666d90000009000000000009900000000000000000009000000998888889900000099cc99cc9988998899bb99bb992299229dd511000dd511000
cccddcdcd666666d90000009099999900009900000000000000000009000000998888889900000099cccccc9988888899bbbbbb992222229ee421000ee444210
0cccccc00dddddd0900000090009900000099000000000000000000099999999999999999999999999999999999999999999999999999999f9421000fff94210
00005550003bbb309999999900000000000000000002200000022000000000000000000000000000000000000000000000000000000000000000000000000000
0000555003bb9aa0999999998000000000000008002dde0000edd200000000000080080000000000000000000000000000000000000000000000000000000000
0056256503bbb9a09900009988000000000000880edccd2002dccde0000000000809908000000000000000000000000000000000000000000000000000000000
00566555003b33309900009988800000000008882dcc7cd22dc7ccd200000000009aa900000000000cccccc0088888800bbbbbb0022222200000000000000000
0056256503bbb6609999999988800000000008882dc7ccd22dcc7cd200000600009aa900000000000cc0c0c0088080800bb0b0b0022020200000000000000000
005666650366666699999999880000000000008802dccde00edccd200600060608099080000000000000ccc0000088800000bbb0000022200000000000000000
055556650bb5665099000099800000000000000800edd200002dde00050605060080080000000000000000000000000000000000000000000000000000000000
5505555503b003b09900009900000000000000000002200000022000050505050000000000000000000000000000000000000000000000000000000000000000
0000000000000000ccccccccaaaa31311313aaaaaaaaaaaa1500006105050505aaaaaaaa99999999999999990000000000000000000000000000000000000000
0000000000000000cccccccc99a313655631399999a49999367887b90505050599a4999999998999999899990000000000000000000000000000000000000000
0000000065465767cccccccc49a651700715649949a444991317716b0505050549a4449999998899998899990000000000000000000000000000000000000000
0000000074465576cccccccc49a3778008773444436365b4315773430505050549a4444498888889988888890000000000000000000000000000000000000000
0000000054766550ccccccccaaa6778008776aaa315773a3a36365ba05050505aaaaaaaa98888889988888890000000000000000000000000000000000000000
0000000066665660cccccccc949531700713599a1317716b9499999a050505059499999a99998899998899990000000000000000000000000000000000000000
0000000056566556cccccccc449b96b66b69b99a367887ba4499999a050505054499999a99998999999899990000000000000000000000000000000000000000
0000000005505556cccccccc44443b9114b3499a150000614444499a050505054444499a99999999999999990000000000000000000000000000000000000000
aaaaaaaaaaaaaaaa31b31bbbbbb13b13bbb13bbb1b3bb3b1aaaa13baba3aaaaaeeeeee1111eeeeee000000000000000000000000000000000000000000000000
99a4999999a49999931b31bbbb13b139bb1331bb31b3bb1399a4391b93149999eeeee110011eeeee000000000000000000000000000000000000000000000000
49a4449949a44499493343b11b3433991b3443b193b11b3949a413b11b3b4499eeeee100001eeeee000000000000000000000000000000000000000000000000
491b3b4449a4444449a41b1bb1b14444b1b1bb1b1b1bb1b149a4331bb1b14444eeeee100001eeeee000000000000000000000000000000000000000000000000
aab313baaaaaaaaaaaaaaa3113aaaaaa13aaaa31aa3113aaaaaaa1b11b33aaaaeeee22200222eeee000000000000000000000000000000000000000000000000
943131ba9499999a9499993bb399999ab399993b943bb3499499933b33b9999aeeee121221212eee000000000000000000000000000000000000000000000000
44939b1a4499999a449999933499999a399994434493394444991b93b199999aeee2112122112eee000000000000000000000000000000000000000000000000
4444439a4444499a444449933444499a39944443444334444444493a4b13499aeee12121122222ee000000000000000000000000000000000000000000000000
99a4499a93bb433baaaaaaaab3b13b3baba13aaa0000000000000000ba3a13baee002212212112ee000000000000000000000000000000000000000000000000
949aa499933ba3b999ab99999b3bb3939134b99900000000000000009314391bee70e212221212ee000000000000000000000000000000000000000000000000
49999a4443b333b449a344994314b19949b3149900000000000000001b3b13b1ee77e212211200ee000000000000000000000000000000000000000000000000
a49444a4a3b43bb449a31b4449a43444491b3b440000000000000000b1b1331beeeee212122207ee000000000000000000000000000000000000000000000000
9494aa9a9334ab3aaaba31aaaaaaaaaaaab313ba00000000000000001b33a1b1eeeee212121177ee000000000000000000000000000000000000000000000000
9a44999a93b49b3a9413bb1a9499999a943131ba000000000000000033b9933beeee21122112eeee000000000000000000000000000000000000000000000000
499a449a4933b39a433b31ba4499999a44939b1a0000000000000000b1991b93eeee212112212eee000000000000000000000000000000000000000000000000
44999a494b3bb34943b11b314444499a444b439a00000000000000004b13493aeee21e2e1e2e1eee000000000000000000000000000000000000000000000000
00000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0008011131517109080508884500000008008088800000888a8089a9c9e900000000010808080888080088a8c8e800000000010101010103010909000000000001010101010101010000000000000000010101010100000100000000000000000100000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0200000000000000000000000000000202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606060606060606060606060606060
0202020202000000000000000000000202282828282828020000000000000502000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606060606060606060606060606060
02000000020000000000000000000002022828282828281a0000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606060606060606060606060606060
020000001a000000000000030909090202090902090902023939393939390002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606060606060606060606060606060
0202020202020202020c0c020000000202280002000002000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606060606060606060606060606060
020000001700180017001302001300020200000200000200003a3a3a3a3a3a02000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606060606060606060606060606060
0209090902020202020902020009000202130102132a02000010000000000202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606060606060606060606060606060
020000000000000a0a0000120000000202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606060606060606060606060606060
0200130000000000000000120000130200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606060606060606060606060606060
020b020807080209090202020c02020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606060606060606060606060606060
0200000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606060606060606060606060606060
0200000000000000000000001300000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606060606060606060606060606060
0200000000000000000000000209090200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606060606060606060606060606060
020202020202002a2b2c2d001200030200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606060606060606060606060606060
02001a1b1c1d0001000000000203020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606060606060606060606060606060
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606060606060606060606060606060
4057573535353535353557474141414100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4600000000000000000000450000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5300000708070807080700570000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5200000000000000000000450000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45250000000000000000001a00002a4100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4653455452544552545353414141094100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5200000000000000000000000000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5700000028000000000000000000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4400000000000000000000000000134100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000043000000000000000000094100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5428000941002800070000000000004700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5457000940000000000000000000003400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4600000052004300000000525743134700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4700000057284700000000575441414100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5401001357135727272727474141414100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4253534543414153535353414141414100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
