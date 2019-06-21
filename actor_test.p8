pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
#include util.p8
#include actors.p8

function _init()
	poke(0x5f2d,1)

	level={x=0,y=0,w=32,h=32}
	init_actors()
	init_entities(level)
	
	actor_config.gravity=60
	
	a1=add_actor({
		x=8,y=4,w=0.2,
		k_accel=24,
		k_max_move=6,
		k_jump_force=18.5,
		k_jump_hold_force=20
	})
	
	cam={x=0,y=0}
end

function keypress(key)
	if key=="a" then
		local a=rnd(0.5)
		local f=50
		a1:force(f*cos(a),f*sin(a))
	elseif key=="]" then
		a1.mass+=0.2
	elseif key=="[" then
		a1.mass-=0.2
	end
end

--function _update() dt=fps30_dt; update() end
function _update60() dt=fps60_dt; update() end

function update()
	clear_watches()
	
	while stat(30) do
		keypress(stat(31))
	end
	
	watch("mass:"..a1.mass)
	
	local ix,iy=input_xy()
	local ibtns=input_btns()
	a1:control(ix,iy,ibtns,dt)
	
	foreach(actors,function(a)
		a:move(dt)
	end)
	
	tick_entities(dt)
	
	cam_bounds=4
	cam.targ=a1
	
	local tx,ty=(cam.targ.x-8)*8,
		(cam.targ.y-8)*8
	
	if cam.x>tx+cam_bounds then
		cam.x=tx+cam_bounds
	elseif cam.x<tx-cam_bounds then
		cam.x=tx-cam_bounds
	end
	
	cam.y=min(cam.y,ty+cam_bounds)
	cam.y=max(cam.y,ty-cam_bounds)
	
	cam.x=mid(0,16*8,cam.x)
	cam.y=mid(0,16*8,cam.y)
end

function _draw()
	cls()
	
	camera(cam.x,cam.y)
		
	map(level.x,level.y,0,0,level.w,level.h,0b01111111)
	
	local x,y=w2s(a1.x-0.5,a1.y-1)
	spr(a1.sp,x,y,1,1,a1.face<0)
	watch(x..","..y)
	
	map(level.x,level.y,0,0,level.w,level.h,0b10000000)
	
	draw_entity_colliders()
	
	camera()
	
	draw_watches()
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
	force=17,
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
	h=0.75,
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
				self:unlock()
			end
		end
	end,
	unlock=function(self)
		self.closed=false
		mset(self.x,self.y,self.val-self.tdoor-1)
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
	ivl=-1,
	t=0,
	replace=0,
	spawn=function(self) end,
	start=function(self)
		mset(self.x,self.y,self.replace)
		self:spawn(self.x+0.5,self.y+1)
		self.t=self.ivl
	end,
	tick=function(self,dt)
		if self.t>=0 then
			self.t-=dt
			if self.t<=0 then
				self.t+=self.ivl
				self:spawn(self.x+0.5,self.y+1)
			end
		end
	end
})

wall_gun=entity:new({
	name="wall_gun",
	facex=1,
	facey=0,
	shot_speed=6,
	fire_ivl=2,
	init_delay=2,
	t_fire=0,
	start=function(self)
		self.t_fire=self.init_delay
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
		self.wx,self.wy=self:center()
	end,
	tick=function(self,dt)
		self.t-=dt
		if self.t<=0 then
			self.t+=0.25
			self.f+=1
			mset(self.x,self.y,self.val+self.f%2)
		end
	end,
	actor_touch=function(self,a)
		if a==player then
			game.won=true
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
	w=0.5,h=0,
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

shatter_touch_block=entity:new({
	name="shatter_touch_block",
	w=0.6,h=0.8,
	f=0,
	t=0,
	ivl=0.125,
	delay=4,
	state=0,
	start=function(self)
		self.wx,self.wy=self:center()
		self.wy+=0.3
	end,
	tick=function(self,dt)
		if self.state==1 then
			self.t-=dt
			if self.t<=0 then
				self.f+=1
				mset(self.x,self.y,self.val+self.f)
				self.t=self.ivl
				if self.f==4 then
					mset(self.x,self.y,0)
					self.t=self.delay
					self.state=2
				end
			end
		elseif self.state==2 then
			self.t-=dt
			if self.t<=0 then
				self.f-=1
				self.t=self.ivl/4
				mset(self.x,self.y,self.val+self.f)
				if self.f==0 then
					self.state=0
				end
			end
		end
	end,
	actor_touch=function(self,a)
		if self.state==0 then
			self.state=1
			self.t=self.ivl
		end
	end,
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
_entity_map[21]=spring
_entity_map[77]=clone(
	actor_spawn,{
		spawn=function(self,ax,ay)
			player=add_actor({
  		x=ax,y=ay,
  		keys={},
  		ddy=35,
  		sp=77,
  		light=add_article(light:new()),
  		k_accel=40,
  		k_max_move=6,
  		k_jump_force=13,
  		k_jump_hold_force=0,
  		on_death=function(self)
  			self.sp+=16
  		end,
  	})
  	player.light.owner=player
		end
	}
)

_entity_map[16]=shatter_touch_block


local spawn_crate=function(ax,ay)
	add_actor({
		x=ax,y=ay,sp=48,
		k_max_move=0,
		inp=make_inp(),
		on_death=function(self)
			del(actors,self)
		end
	})
end

_entity_map[48]=clone(actor_spawn,{
	spawn=function(self,ax,ay)
		spawn_crate(ax,ay)
	end
})

_entity_map[59]=clone(actor_spawn,{
	ivl=2,
	replace=59,
	spawn=function(self,ax,ay)
		spawn_crate(ax,ay)
	end
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
_entity_map[46]=clone(kill_volume,{oy=0.25,h=0.25})
_entity_map[47]=clone(kill_volume,{ox=0.25,w=0.25})
_entity_map[62]=clone(kill_volume,{oy=-0.25,h=0.25})
_entity_map[63]=clone(kill_volume,{ox=-0.25,w=0.25})
	
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

function init_entities(level)
	local x,y,w,h=
		level.x,level.y,
		level.w,level.h

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
			end
		end
	end
	
	local find_entity=function(x,y)
		for e in all(entities) do
			if (e.x==x and e.y==y) return e
		end
	end
	
	-- apply entity override data
	-- from level
	level.entities=level.entities or {}
	for eo in all(level.entities) do
		local ent=find_entity(eo.x,eo.y)
		if ent then
			for k,v in pairs(eo) do
				ent[k]=eo[k]
			end
		end
	end
	
	-- start entities
	foreach(entities,function(e)
		e:start()
	end)
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
__gfx__
00000000bbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000b33333b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700b3b3b3bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000b333333b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000b333333b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700b333333b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000b333333b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999dddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999dddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999dddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999dddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999dddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999dddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999dddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999dddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000009900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000099990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009999999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999999999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09999999999999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09999999999999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999999999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009999999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000099990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000009900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000001400000000000000000000000000000091900000000000000000000000000002939000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000010000000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000002021000000000000001000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101000001000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000101010101010000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000010100000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000002010101000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000201010101010101010101000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000002010101010101000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000002010101010101010101000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000002010101010101010101010101000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000001010101010101010101010101000000000001010101010100000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000001010101010101010101010101000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000001010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010100000000000000000000000001000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000100000000000000000000000001000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000101010101010000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000001000100000000000000000001000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000001000000000000000001010101010000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000010100000000000001000001010101010101010100000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000001000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000100000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000010100000000000000000000000000000000010100010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000100000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
