pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
#include util.p8

function set_game_state(state)
	local gs=game_states[state]
	if gs and gs~=game_state then
		game_state_name=state
		game_state=nil
		gs.init()
		game_state=gs
	end
end

function _init()
	poke(0x5f2d,0)

	dt=0x0000.0444
	high_score=0
	
	game_states={
		play={
			init=play_init,
			update=play_update,
			draw=play_draw
		},
		title={
			init=title_init,
			update=title_update,
			draw=title_draw
		}
	}
	
	set_game_state("title")
end


function _update60()
	tick_sequences()	

	if game_state and game_state.update then
		game_state:update()
	end
end

function _draw()
	if game_state and game_state.draw then
		game_state:draw()
	end

	if peek(0x5f2d)~=0 then	
		draw_log()
		draw_watches()
	end
end

function w2s(x,y)
	return x*8,y*8
end

function w2sr(x1,y1,x2,y2)
	return x1*8,y1*8,x2*8,y2*8
end

function input_xy(pid)
	pid=pid or 0
	local ix,iy=0,0
	if (btn(0,pid)) ix-=1
	if (btn(1,pid)) ix+=1
	if (btn(2,pid)) iy-=1
	if (btn(3,pid)) iy+=1
	return ix,iy
end

function fire_bullet(x,y,dx,life)
	local i=bullet_idx
	
	if bullets[i].on then
		return
	end
	
	bullet_idx+=1
	if bullet_idx>bullet_n then
		bullet_idx=1
	end
	
	local bullet=bullets[i]
	
	bullet.on=true
	bullet.x=x
	bullet.y=y
	bullet.dx=dx
	bullet.t=life or 10
end

function bullet_update(self)
	if not self.on then
		return
	end
	
	self.x+=self.dx
	self.t-=1
	
	if self.t<=0 or solid(self.x,self.y) then
		bullet_destroy(self)
	end
end

function bullet_destroy(self)
	self.on=false
	add_spark(self.x-self.dx,self.y)
end

function enemy_control(self)
	local dx=ship.x-self.x
	local dy=ship.y-self.y
	self.dx+=sgn(dx)*0.4*dt
	self.dy+=dy*0.002
--	if dy~=0 then
--		self.dy+=sgn(dy)*0.001
--	end
	--self.dx+=0.01*self.face
	
	if dx~=0 then
		self.face+=sgn(dx)*dt*8
		self.face=mid(-1,self.face,1)
	end
	
	local maxspd=0.085
	local maxy=0.0625
	self.dx=mid(self.dx,-maxspd,maxspd)
	self.dy=mid(self.dy,-maxy,maxy)
	
	self.t_damage-=dt
	if self.t_damage<=0 then
		for i=0,15 do
			self.pals[i]=nil
		end
	end
end

function enemy_postmove(self)
	if false and actor_overlap(self,ship) then
		if score>high_score then
			high_score=score
		end
		set_game_state("title")
	end
end

function enemy_damage(self,amt)
	self.t_damage=0.0833
	self.pals[14]=7
	self.health-=amt
	if self.health<=0 then
		if self.on_death then
			self:on_death()
		end
		sequence(function()
			local x,y=self.x,self.y
			for i=1,8 do
				local a=rnd()
				local m=rnd(0.5)
				x+=cos(a)*m
				y+=sin(a)*m
				add_spark(x,y,{col=8})
				wait_sec(0.08)
			end
		end)
		del(actors,self)
		del(enemies,self)
		score=score+1
	end
end

function ship_control(self)
	local ix,iy=input_xy(self.id)
	
	self.dx+=0.01*ix
	local maxspd=0.125
	self.dx=mid(self.dx,-maxspd,maxspd)
	self.dy=iy*0.125
	
	if ix~=0 then
		self.face+=sgn(ix)*10*dt

		self.face=mid(self.face,-1,1)
	else
		local decay=0.001
		if self.dx<0 then
			self.dx=min(self.dx+decay,0)
		elseif ship.dx>0 then
			self.dx=max(self.dx-decay,0)
		end
	end
	
--			watch(self.face)
end
		
function ship_postmove(self)
	self.t_fire-=dt
	
	if btn(4,self.id) then
		if self.t_fire<=0 then
			fire_bullet(self.x-self.face*0.125,
				self.y+0.125,
				sgn(self.face)*0.6,
				30)
			self.t_fire=self.fire_ivl
		end
	else
		self.t_fire=0
	end
	
	
end

function actor_move(self)
	local l,t,r,b=local_rect(self)
	
	self.dx+=self.nudge_x
	self.dy+=self.nudge_y
	
	self.nudge_x=0
	self.nudge_y=0
	
	if self.dx>0 then
		while solid_x(self.x+r+self.dx,self.y,t,b)
			and self.dx>0
		do
			self.dx=max(self.dx-0.125,0)
		end
	elseif self.dx<0 then
		while solid_x(self.x+l+self.dx,self.y,t,b)
			and self.dx<0
		do
			self.dx=min(self.dx+0.125,0)
		end
	end
	
	if self.dy>0 then
		while solid_y(self.x,self.y+self.dy+b,l,r)
			and self.dy>0
		do
			self.dy=max(self.dy-0.125,0)
		end
	elseif self.dy<0 then
		while solid_y(self.x,self.y+self.dy+t,l,r)
			and self.dy<0
		do
			self.dy=min(self.dy+0.125,0)
		end
	end
	
	self.x+=self.dx
	self.y+=self.dy
end

function draw_actor(self)
	if self.sp then
		if self.pals then
			for i=0,15 do
				if (self.pals[i]) pal(i,self.pals[i])
			end
		end
		local px,py=w2s(self.x,self.y)
		px-=self.w*8
		py-=self.h*8
		local flipx=false
		if self.face and self.face<0 then
			flipx=true
		end
		local sp=self.sp+(self.face+1.5)
		spr(sp,px,py,1,1,false)
		pal()
		local l,t,r,b=world_rect(self)
		l,t,r,b=w2sr(l,t,r,b)
		--rect(l,t,r,b,11)
	end
end

actor={
	tag="default",
	x=0,y=0,w=0.5,h=0.5,
	nudge_x=0,nudge_y=0,
	col_ox=0,col_oy=0,
	col_w=0,col_h=0,
	dx=0,dy=0,
	t=0
}

function actor:new(param)
	self.__index=self
	return setmetatable(param or {},
		self)
end

function solid(x,y)
	return fget(mget(x,y),0)
end

function solid_x(x,y,t,b)
	return solid(x,y+t) or
		solid(x,y+b)
end

function solid_y(x,y,l,r)
	return solid(x+l,y) or
		solid(x+r,y)
end


function add_spark(x,y,params)
--	params=params or {}
--	return add(effects,{
--		x=x,y=y,
--		t=0,nt=0,dur=0.35,
--		col=params.col or 10,
--		draw=function(self)
--			local v=self.nt*1.8
--			local rad=cos(v)*v*2+v+1
--			circ(self.x*8,self.y*8,rad,self.col)
--		end,
--	})
end

-->8
-- title screen

function title_init()
	title={
		start_cr=sequence(function()
			wait_sec(0.5)
			set_game_state("play")
		end)
	}
end

function title_update()
end

function title_draw()
	cls()
	print("★ shippy ★",36+sin(t())*8,62,7)
	
	local hi=high_score
	print("hi score: "..hi,46,96,6)
end


-->8
-- play screen


function play_init()
	actors={}
	enemies={}
	spawners={}
	
	fx_init()

	reload()

	ship=nil	
	for xx=0,32 do
		for yy=0,16 do
			local wx,wy=xx+0.5,yy+0.5
			local m=mget(xx,yy)
			if m==16 then
				mset(xx,yy,0)
				ship=add(actors,
					actor:new({
						x=wx,y=wy,
						col_ox=-0.5,col_oy=-0.375,
						col_w=0.875,col_h=0.625,
						sp=16,id=0,face=1,
						t_fire=0,fire_ivl=0.19}))
			elseif is_spawner(m) then
				add_spawner(mget(xx,yy),xx,yy)
				mset(xx,yy,0)
			end
		end
	end
	
	cam_x=ship.x
	
	bullets={}
	bullet_n=8
	bullet_idx=1
	for i=1,bullet_n do
		add(bullets,
			actor:new({
				x=0,y=0,
				col_ox=-0.375,col_oy=-0.25,
				col_w=0.625,col_h=0.375,
				sp=32,
				face=-1,
				on=false,
			}))
	end
	
	score=0
	lives=3
end

function play_update()
	-- update ship
	ship_control(ship)
	foreach(enemies,enemy_control)

	local rad2=sin_rng(0.33,0.85)
	local overlap=function(a,b)
		local dx,dy=a.x-b.x,a.y-b.y
		return dx*dx+dy*dy<=rad2
	end
	
	-- nudge
	local n=#actors
	for i=1,n-1 do
		for j=i+1,n do
			local a=actors[i]
			local b=actors[j]
			if a.tag=="enemy" and
						b.tag=="enemy" and
						overlap(a,b)
			then
				local dx,dy=norm(a.x-b.x,
					a.y-b.y)
				local nudge=0.06
				local nudge_x=dx*nudge
				local nudge_y=dy*nudge
				a.nudge_x=nudge_x
				a.nudge_y=nudge_y
				b.nudge_x=-nudge_x
				b.nudge_y=-nudge_y
			end
		end
	end
	
	foreach(actors,actor_move)
	
	ship_postmove(ship)
	
	foreach(spawners,spawner_update)
	
	foreach(enemies,enemy_postmove)
	
	-- update bullets
	foreach(bullets,function(b)
		if b.on then
			bullet_update(b)
			
			local len=#enemies
			for i=1,len do
				local e=enemies[i]
				if actor_overlap(b,e) then
					bullet_destroy(b)
					enemy_damage(e,1)
					break
				end
			end
		end
	end)
	
	-- update effects
	fx_update(dt)

	-- update camera
	local t_cam_x=ship.x
	if ship.dx~=0 then
		t_cam_x+=ship.face*2+ship.dx
	end
	local lerp=function(a,b,t)
		return (b-a)*t+a
	end
	cam_x=lerp(cam_x,t_cam_x,0.15)
	cam_x=mid(cam_x,8,24)
	
	watch(stat(0))
	watch("enemies:"..tostr(#enemies))
end

function on_cam(x)
	return abs(x-cam_x)<=9
end

function play_draw()
	cls()

	local cwx,_=w2s(cam_x,0)	
	camera(cwx-64,0)
		
	map(0,0,0,0,32,16)
	
	-- draw ship
	foreach(actors,draw_actor)

	local x1,y1,x2,y2=world_rect(ship)
	x1,y1,x2,y2=w2sr(x1,y1,x2,y2)
	
	pset(x1,y1,10)
	pset(x2,y1,10)
	pset(x1,y2,10)
	pset(x2,y2,10)
	
	-- draw bullets
	foreach(bullets,function(b)
		if b.on then
			draw_actor(b)
		end
	end)
		
	-- draw effects
	fx_draw()
	
	camera()
	
	rectfill(0,121,127,127,0)
	line(0,121,127,121,12)
	
	print("score:"..tostr(score),
		2,123,7)
		
	if false then
	for i=1,lives do
		local x=123-(i-1)*6
		spr(17,x,123)
	end
	local m="lives:"
	local w=#m*4
	print(m,127-6*lives-w,123)
	end
	
	spr(17,110,123)
	spr(1,116,125)
	local m=""
	if (lives<10) m=m.."0"
	print(m..lives,120,123,7)
end


-->8
-- math/utils

k_e=0x0002.b7e1
k_pi=0x0003.243f

function len(x,y)
	return sqrt(x*x+y*y)
end

function norm(x,y)
	local l=len(x,y)
	if (l~=0) return x/l,y/l
	return 0,0
end

function world_rect(self)
	local x1,y1,x2,y2=local_rect(self)
	return self.x+x1,self.y+y1,
		self.x+x2,self.y+y2
end

function local_rect(self)
	return self.col_ox,
		self.col_oy,
		self.col_ox+self.col_w,
		self.col_oy+self.col_h
end

function actor_overlap(a,b)
	if abs(a.x-b.x)<1 and
		abs(a.y-b.y)<1
	then
		local al,at,ar,ab=world_rect(a)
		local bl,bt,br,bb=world_rect(b)
		return al<=br and
			ar>=bl and
			at<=bb and
			ab>=bt
	else
		return false
	end
end

function random_pos(x,y,w,h)
	local px,py=0,0
	repeat
		px=flr(rnd(w))+x
		py=flr(rnd(h))+y
	until not solid(px,py)
	return px,py
end

function sin_rng(a,b,tt)
	tt=tt or t()
	return sin(tt)*(b-a)/2+a
end
-->8
-- effects

function fx_init()
	fx_max=128
	fx_pool={}
	fx_layers={}
	fx_layer_max=5
	for i=1,fx_layer_max do
		fx_layers[i]={}
	end

	for i=1,fx_max do
		fx_pool[i]={
			x=0,y=0,t=0,dur=0,
			tscl=1,
			draw=nil,
		}
	end
	
	
	fx_next=fx_pool[1]
	for i=1,fx_max-1 do
		fx_pool[i]._next=fx_pool[i+1]
	end
	fx_last={}
	fx_pool[fx_max]._next=fx_last
end

function fx_set_layer(effect,layer)
	local old=effect.layer
	if old==layer then
		return
	end
	if old then
		del(fx_layers[old],effect)
	end
	if type(layer)=="number" and 
		layer>=1 and 
		layer<=fx_layer_max
	then
		add(fx_layers[layer],effect)
		effect.layer=layer
	elseif layer==nil then
		effect.layer=nil
	end
end

function fx_acquire(param)
	assert(fx_next~=fx_last,
		"out of fx")

	local eff=fx_next
	fx_next=eff._next
	eff._next=nil
	eff.on_finish=nil
	
	eff.t=0

	param=param or {}
	for k,v in pairs(param) do
		eff[k]=v
	end
	
	return eff
end

function fx_release(effect)
	fx_set_layer(effect,nil)
	effect._next=fx_next
	fx_next=effect
end

function fx_update(dt)
	local rem_q={}

	for i=1,fx_max do
		local effect=fx_pool[i]
		if effect._next==nil then
			effect.t+=effect.tscl*dt
			if effect.t>=effect.dur then
				if effect.on_finish then
					effect:on_finish()
				end
				fx_release(effect)
			end
		end
	end
end

function fx_draw()
	for i,layer in ipairs(fx_layers)
	do
		for j,eff in ipairs(layer) do
			if eff.draw then
				eff:draw()
			end
		end
	end
end

function fx_ntime(effect)
	return effect.t/effect.dur
end

function wait_fx(effect)
	while effect._next==nil do
		yield()
	end
end
-->8
-- fx helpers

function add_spark(x,y,params)
	params=params or {}
	local eff=fx_acquire({
		x=x,y=y,col=params.col or 10,
		dur=0.35,
		draw=function(self)
			local nt=fx_ntime(self)
			local v=nt*1.8
			local rad=cos(v)*v*2+v+1
			circ(self.x*8,self.y*8,rad,self.col)
		end})
	fx_set_layer(eff,3)
end

function add_warp_in(x,y,params)
	params=params or {}
	local eff=fx_acquire({
		x=x,y=y,col=params.col or 2,
		dur=0.5,
		on_finish=params.on_finish,
		draw=function(self)
			local nt=fx_ntime(self)
			local rad=abs(sin(nt))*12
			circ(self.x*8+3,self.y*8+3,rad,self.col)
		end})
	fx_set_layer(eff,4)
	return eff
end

--	params=params or {}
--	return add(effects,{
--		x=x,y=y,
--		t=0,nt=0,dur=0.35,
--		col=params.col or 10,
--		draw=function(self)
--			local v=self.nt*1.8
--			local rad=cos(v)*v*2+v+1
--			circ(self.x*8,self.y*8,rad,self.col)
--		end,
--	})
-->8

-->8
-- enemies

function add_enemy(spawner)
	spawner.n+=1
	local e=add(actors,
		actor:new({
			tag="enemy",
			x=spawner.x+0.5,y=spawner.y+0.5,
			col_ox=-0.5,col_oy=-0.375,
			col_w=0.875,col_h=0.625,
			sp=spawner.def.sp,face=1,
			health=1,
			on_death=function(self)
				spawner.n-=1
			end,
			pals={},
			t_damage=0}))
	add(enemies,e)
	return e
end

-->8
-- spawners

spawner_def={}
spawner_def[51]={
	startup=2,
	interval=k_e*flr(rnd(3)+1)/2,
	nmax=3,
	sp=51,
	types={add_enemy}
}

function add_spawner(id,x,y)
	local def=spawner_def[id]
	add(spawners,{
		def=def,
		x=x,y=y,
		t=def.startup,
		n=0
	})
end

function spawner_update(self)
	if self.n<self.def.nmax then
		-- spawner at half rate when
		-- visible to camera
		local sdt=dt
		if (on_cam(self.x)) sdt/=2
		if (self.t>0) self.t-=sdt
		if self.t<=0
		then
			local dist=flr(rnd(2))
			local x,y=self.x,self.y
			
			for i=1,dist do
				local c=flr(rnd(4))
				if (c==0) x-=1
				if (c==1) x+=1
				if (c==2) y-=1
				if (c==3) y+=1
			end
			
			local i=flr(rnd(#self.def.types))+1
			local spawn=self.def.types[i]
			
			if spawn then

				self.t+=self.def.interval
				local spawner=self
				sequence(function()
					local e=add_warp_in(x,y)
					wait_fx(e)
					spawn(spawner)
				end)
			end
		end
	end
end

function is_spawner(id)
	return spawner_def[id]~=nil
end

__gfx__
0000000070700000000000000000000000000000000000000000000000000000dddddddd00000000000000000000000000000000000000000000000000000000
0000000007000000060c00000000000000000000000000000000000000000000dddddddd00000000000000000000000000000000000000000000000000000000
007007007070000006ccc0000000000000000000000000000000000000000000dddddddd00000000000000000000000000000000000000000000000000000000
0007700000000000066660000000000000000000000000000000000000000000dddddddd00000000000000000000000000000000000000000000000000000000
0007700000000000005500000000000000000000000000000000000000000000dddddddd00000000000000000000000000000000000000000000000000000000
0070070000000000000000000000000000000000000000000000000000000000dddddddd00000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddd00000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddd00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000200020000000000000000000000000000000000000000000000000000000000
000cc066006cc600660cc00000000000000000000000000000000000000000002000200000000000000000000000000000000000000000000000000000000000
00cccc6600cccc0066cccc0000000000000000000000000000000000000000000002220200000000000000000000000000000000000000000000000000000000
06666666066cc6606666666000000000000000000000000000000000000000000020022000000000000000000000000000000000000000000000000000000000
55555566556666556655555500000000000000000000000000000000000000000220020000000000000000000000000000000000000000000000000000000000
55566660556666550666655500000000000000000000000000000000000000002022200000000000000000000000000000000000000000000000000000000000
00006600000660000066000000000000000000000000000000000000000000000002000200000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000020002000000000000000000000000000000000000000000000000000000000
00000000808080008080000088080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000008e800000e0000000ee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
099999908eee8000808000008ee80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9aaaaaa908e800000000000088080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9aaaaaa9808080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90088980998888990898800908008008080000808008008000000000000000000000000000000000000000000000000000000000000000000000000000000000
99e99e88099ee99088e99e9900888880008888000888880000000000000000000000000000000000000000000000000000000000000000000000000000000000
09992ee88e9999e88ee2999008eeee8008eeee8008eeee8000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e922ee28e2992e82ee229e008eeee8008eeee8008eeee8000000000000000000000000000000000000000000000000000000000000000000000000000000000
0eeeeee88eeeeee88eeeeee08eeeeee88eeeeee88eeeeee800000000000000000000000000000000000000000000000000000000000000000000000000000000
0e8eeee80e8ee8e08eeee8e008eeee8008eeee8008eeee8000000000000000000000000000000000000000000000000000000000000000000000000000000000
080e8e80080ee08008e8e08000888880008888000888880000000000000000000000000000000000000000000000000000000000000000000000000000000000
00080800000880000080800008008008080000808008008000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
bbdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dbdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dbdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dbdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
bbbddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000080080080000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000008888800000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000008eeee800000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000008eeee800000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000800800800000000000008eeeeee80000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000888880000000000000008eeee800000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000008eeee80000000000000008888880080000000000000000000000000000000000000000000000000000
dddddddddddddddddddd000000000000000000000000008eeee80000008008008080088888800000000000000000000000000000000000000000dddddddddddd
dddddddddddddddddddd00000000000000000000000008eeeeee80000008a888c00a08eeee800000000000000000000000000000000000000000dddddddddddd
dddddddddddddddddddd000000000000000000000000008eeee800000008eeee8c0008eeee800000000000000000000000000000000000000000dddddddddddd
dddddddddddddddddddd0000000000000000000000000088888000000008eeee86608eeeeee80000000000000000000000000000000000000000dddddddddddd
dddddddddddddddddddd000000000000000000000000080080080000008eeeeee85508eeee800000000000000000000000000000000000000000dddddddddddd
dddddddddddddddddddd0000000000000000000800800800000000000008eeee8555008888800000000000000000000000000000000000000000dddddddddddd
dddddddddddddddddddd0000000000000000000088888000000000000008a888000a080080080000000000000000000000000000000000000000dddddddddddd
dddddddddddddddddddd000000000000000000008eeee80000000000008008008000000000000000000000000800800800000000000000000000dddddddddddd
dddddddddddddddddddd000000000000000000008eeee80000000000000000000000000000000000000000000088888000000000000000000000dddddddddddd
dddddddddddddddddddd00000000000000000008eeeeee80000000000000000000000000000000000000000008eeee8000000000000000000000dddddddddddd
dddddddddddddddddddd000000000000000000008eeee800000000000000000000000000000000000000000008eeee8000000000000000000000dddddddddddd
dddddddddddddddddddd000000000000000000008888800000000000000000000000000000000000000000008eeeeee800000000000000000000dddddddddddd
dddddddddddddddddddd0000000000000000000800800800000000000000000000000000000000000000000008eeee8000000000000000000000dddddddddddd
dddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000088888000000000000000000000dddddddddddd
dddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000800800800000000000000000000dddddddddddd
dddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dddddddddddd
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
0000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077007700770777077700000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077707770
00700070007070707070000700707000000000000000000000000000000000000000000000000000000000000000000000000000000000006cc6000070700070
0077707000707077007700000070700000000000000000000000000000000000000000000000000000000000000000000000000000000000cccc707070700770
00007070007070707070000700707000000000000000000000000000000000000000000000000000000000000000000000000000000000066cc6670070700070
00770007707700707077700000777000000000000000000000000000000000000000000000000000000000000000000000000000000000556666757077707770

__gff__
0000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0808080808080808080808080808080808080808080808080808080808080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000080808080000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000330000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000000000000000000000000003300000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000808080800000000001000000000000008080808000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000808080800000000000000000000000008080808000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000000000000000033000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000033000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000000080808080000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080808080808080808080808080808080808080808080808080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
