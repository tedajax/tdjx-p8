pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
#include util.p8

k_pit=48

function _init()
	poke(0x5f2d,1)
	poke(0x5f2e,1)
	
	mou_x=stat(32)
	mou_y=stat(33)
	mou_lb=0
	mou_cb=0
		
	levels={
		{
			x=0,y=0,
			config=config_level_1
		},
		{
			x=16,y=0,
			config=config_level_2
		}
	}
	
	gamestates={
		play={
			init=play_init,
			update=play_update,
			draw=play_draw
		},
		win={
			init=win_init,
			update=win_update,
			draw=win_draw
		}
	}
	
	set_gamestate("play")
end

debug_colliders=false
function keypress(key)
	if key=="k" then
		debug_colliders=not debug_colliders
	end
end

mouse={}
function clickdown(b,x,y)
	if b==1 then
		local level=levels[g.level or 1]
		local mx,my=flr(x/8)+level.x,
			flr(y/8)+level.y
		local e=mapent(mx,my)
		if e then
			e:push(mouse)
			calculate_lasers()
		end
	end
end

function clickup(b,x,y)
	if b==1 then
		local level=levels[g.level or 1]
		local mx,my=flr(x/8)+level.x,
			flr(y/8)+level.y
		local e=mapent(mx,my)
		if e then
			e:pop(mouse)
			calculate_lasers()
		end
	end
end

function _update()
	dt=fps30_dt
	
	while stat(30) do
		keypress(stat(31))
	end
	
	mou_x=stat(32)
	mou_y=stat(33)
	mou_lb=mou_cb
	mou_cb=stat(34)
	
	for i=1,3 do
		if band(mou_cb,i)~=0 and
			band(mou_lb,i)==0
		then
			clickdown(i,mou_x,mou_y)
		elseif band(mou_cb,i)==0 and
			band(mou_lb,i)~=0
		then
			clickup(i,mou_x,mou_y)
		end
	end
	
	tick_sequences()
	gamestate_update()

	watch(band(stat(0)/204.8,0xffff.f).."%")
	watch(band(stat(1)/100,0xffff).."%")
	watch(band(stat(2)/100,0xffff).."%")
end

k_special_palette={
	133,140,130,137, -- 01-04
	nil,nil,nil,nil, -- 05-08
	nil,nil,nil,nil, -- 09-12
	nil,135,nil,nil, -- 13-16
}

function _draw()
	for k,v in pairs(k_special_palette) do
		pal(k,v,1)
	end
	cls()

	gamestate_draw()

	if peek(0x5f2d)>0 then
		draw_log()
		draw_watches()

		circ(mou_x,mou_y,1,11)
	end
end



function play_init()
	g={
		gun_wait_flag=true,
		level=2,
		checkpoint_lock=false,
		checkpoint=nil,
		input_lock=false,
	}
	
	sequence(play_reset)
end

function play_reload()
	g.checkpoint_lock=true
	sequence(play_reset)
end

function play_reset()
	reload(0x2000,0x2000,0x1000)

	entities={}
	mapentities={}
	drawables={}
	players={}
 goals={}
	
	g.gun_wait_flag=true
	g.input_lock=true
	
	g_pid=0
	
	local level=levels[g.level]
	assert(level,"no known level with id:"..tostr(g.level))
	
	local bx,by=level.x,level.y

	-- iterate over map tiles
	-- spawn entities based
	-- on the entity map (_emap page #3)
	for y=by,by+15 do
		for x=bx,bx+15 do
			local m=mget(x,y)
			local add_fn=emap_add_fn(m)
			add_fn(x,y,m)
		end
	end
	
	-- if the level defines a 
	-- config function call it
	-- this will chain entities
	-- together for logic
	-- e.g. switches to doors etc...
	if level.config then
		level.config()
	end
	
	-- calculate lasers
	calculate_lasers()
	
	-- unlock checkpoint assignment
	-- and set active checkpoint
	-- to found checkpoint when
	-- spawning entities if found	
	g.checkpoint_lock=false
	if g.checkpoint then
		set_checkpoint(g.checkpoint)
		wait_sec(0.25)
		g.checkpoint:spawn()
	end
	
	g.input_lock=false
end

function play_update()
	local n=#entities
	
	for i=1,n do
		local e=entities[i]
		if e and e.on_update then
			e:on_update(dt)
		end
	end
	
	local n=#drawables

	for j=1,3 do
		for i=1,n-1 do
			if drawables[i].y>drawables[i+1].y
			then
				local t=drawables[i]
				drawables[i]=drawables[i+1]
				drawables[i+1]=t
			end
		end
	end
end

function check_win()
 local win=true
 for id,goal in pairs(goals) do
  if not goal.on then
   win=false
  end
 end
 
 if win then
  set_gamestate("win")
 end
end

function play_draw()
	cls(1)
	
	local level=levels[g.level]
	
	local mapx,mapy=level.x,level.y
	
	map(mapx,mapy,0,0,16,16)
	
	palt(0,false)
	map(mapx,mapy,0,0,16,16,0x80)
	palt()
	
	camera(mapx*8,mapy*8)
	foreach(drawables,function(e)
		if (e.on_draw) e.on_draw(e)
		if debug_colliders then
			--rect_draw(e,10)
			local r={x=e.x+(e.cx or 0),
				y=e.y+(e.cy or 0),
				w=e.cw or e.w,h=e.ch or e.h}
			rect_draw(r,10)
		end
	end)
	camera()

	map(mapx,mapy,0,0,16,16,0x40)
	
	if btn(4,0) or btn(4,1)
	then
		camera(mapx*8,mapy*8)
		draw_power_lines()
		camera()
	end
end

function draw_power_lines()
	function helper(node,fn1,fn2)
		for c in all(node.chain) do
			if (fn1) fn1(node,c)
			helper(c,fn1,fn2)
			if (fn2) fn2(node,c)
		end
	end
	local fline=function(a,b)
		line(a.x,a.y,b.x,b.y,11)
	end
	local fpoint=function(b,a)
		circ(a.x,a.y,2,7)
	end
	for e in all(entities) do
		if e.etype=="switch" or
			e.etype=="power_switch"
		then
			helper(e,fline,nil)
			
		end
	end
	for e in all(entities) do
		if e.etype=="switch" or
			e.etype=="power_switch"
		then
			helper(e,nil,fpoint)			
		end
	end	

end

function kill_player(player,death)
	del_entity(player)
	sequence(function()
		wait_sec(0.25)
		play_reload()
	end)
end

function win_init()
end

function win_update()
	if btnp(4,0) or btnp(4,1) then
		set_gamestate("play")
	end
end

function win_draw()
	play_draw()
	print("win",58,61,7)
end
-->8
-- utilities/actors

function move_actor(self,dx,dy)
	-- do physics	
	
	local x=function() return self.x+self.cx end
	local y=function() return self.y+self.cy end
	local w=self.cw
	local h=self.ch
	
	--[[
	if solid_area(self.x+dx,
		self.y+dy,
		w,h)
	then
		dx,dy=0,0
	end
	
	self.x+=dx
	self.y+=dy]]

	-- x movement
	local dirx=sgn(dx)
	local col_ox=dirx*w
	-- search an extra pixel ahead
	-- when moving left
	if (col_ox<0) col_ox-=1
	
	local nx=x()+dx+col_ox

	local chkx=x()+dx+col_ox				
	if not solid(chkx,y()-h+1) and
		not solid(chkx,y()+h-1)
	then
		-- no contact, move normally
		self.x+=dx
	else
		-- hit solid
		-- find contact point
		while not solid(x()+col_ox,y()-h+1)
			and not solid(x()+col_ox,y()+h-1)
		do
			self.x+=dirx*1
		end
	end

	-- y movement
	local diry=sgn(dy)
	local col_oy=diry*h
	-- search an extra pixel ahead
	-- when moving left
	if (col_oy<0) col_oy-=1
		
	local ny=y()+dy+col_oy

	local chky=y()+self.dy+col_oy
	if not solid(x()-w+1,chky)
		and not solid(x()+w-1,chky)
	then
		-- no contact, move normally
		self.y+=dy
	else
		dy=0
		-- hit solid
		-- find contact point
		while not solid(x()-w+1,y()+col_oy)
			and not solid(x()+w-1,y()+col_oy)
		do
			dy+=diry*1
			self.y+=diry*1
		end
	end
end

function solid_world(x,y)
	return fget(mget(x,y),0)
		or x<0 or x>127
		or y<0 or y>63
end

function solid(x,y)
	return fget(mget(x/8,y/8),0)
end

function nofloor(x,y)
	return mget(x/8,y/8)==k_pit
end

function area_fn(x,y,w,h,fn,t)
	t=t or "any"
	local r={x=x,y=y,w=w,h=h}
	local x1,y1=topleft(r)
	local x2,y2=botright(r)
	local ret={fn(x1,y1),
		fn(x2,y1),
		fn(x1,y2),
		fn(x2,y2)}
	if t=="any" then
		for r in all(ret) do
			if r then
				return true
			end
		end
		return false
	elseif t=="all" then
		for r in all(ret) do
			if not r then
				return false
			end
		end
		return true
	end
end

function solid_area(x,y,w,h)
	return area_fn(x,y,w,h,solid)
end

function nofloor_area(x,y,w,h)
	return area_fn(x,y,w,h,nofloor,"all")
end

-- x and y are constrained
-- to map coordinates
-- so we can happily
-- store them in 8 bits
-- 4 each
function hash_xy(x,y)
	x=band(x or 0,0xf)
	y=band(y or 0,0xf)
	return bor(shl(x,4),y)
end

function unhash_xy(h)
	return shr(band(h,0xf0),4),
		band(h,0xf)
end
-->8
-- entities

entity=class({
	etype="entity",
	x=0,y=0,w=4,h=4,
})

player=class({
	extends=entity,
	etype="player",
	cx=0,cy=2,cw=3,ch=2,
	w=4,
	id=0,
})

bullet=class({
	extends=entity,
	etype="bullet",
	dx=0,dy=0,
	t=0,
})

function bullet:on_update()
	self.x+=self.dx
	self.y+=self.dy
	self.t-=1
	
	local die=self.t<=0

	die=die or area_fn(self.x,self.y,
		self.w,self.h,
		function(x,y)
			local on_spawn=
				self.mx==flr(x/8) and
				self.my==flr(y/8)
			return not on_spawn
				and solid(x,y)
		end)
		
	if die then
		del_entity(self)
	end
end

function bullet:on_draw()
	local x,y=topleft(self)
	spr(3,x,y)
end

function is_map_entity(e)
	return e.mx~=nil
		and e.my~=nil
		and e.mv~=nil
end

mapentity=class({
	extends=entity,
	mx=0,my=0,mv=0,
})

function mapentity:hash()
	return bor(shl(self.mx,4),self.my)
end

toggleentity=class({
	extends=mapentity,
	m_on=0,m_off=0,
	blocker=false,
	down_ct=0,
	power_delay=2,
	health=-1,
	auto_chain=false
})

function toggleentity:parent(child,delay)
--	assert(child and type(child)=="table")
	self.power_delay=delay or self.power_delay
	if child
		and type(child)=="table"
	then
		add(self.chain,child)
	end
end

function toggleentity:swap_states()
	self.m_on,self.m_off=self.m_off,self.m_on
end

function toggleentity:on_on(sender)
	mset(self.mx,self.my,self.m_on)
	if self.blocker then
		calculate_lasers()
	end
 self.on=true
end

function toggleentity:on_off(sender)
	mset(self.mx,self.my,self.m_off)
	if self.blocker then
		calculate_lasers()
	end
 self.on=false
end

function toggleentity:toggle(sender)
	if self.on then
		self:on_off(sender)
	else
		self:on_on(sender)
	end
end

function toggleentity:push(sender)
	sender=sender or {}
	self.set=self.set or {}
	if not self.set[sender] then
		self.set[sender]=sender
		if self.down_ct==0 then
			self:on_on(sender)
		end
		self.down_ct+=1
	end
	sequence(
		function()
			if self.chain then
				for i=1,self.power_delay do
					yield()
				end
				for c in all(self.chain) do
					c:push(sender)
				end
			end
		end)
end

function toggleentity:pop(sender)
	if self.set[sender] then
		self.set[sender]=nil
		self.down_ct-=1
		if self.down_ct==0 then
			self:on_off(sender)
		end
	end
	sequence(
		function()
			if self.chain then
				for i=1,self.power_delay do
					yield()
				end
				for c in all(self.chain) do
					c:pop(sender)
				end
			end
		end)
end

-- breadth first search for
-- children of the same mget
function toggleentity:bfs_chain(delay)
	local q={hash_xy(self.mx,self.my)}
	local found={}
	
	local offsets={
		{x=1,y=0},
		{x=-1,y=0},
		{x=0,y=-1},
		{x=0,y=1}
	}
	
	while #q>0 do
		local id=q[1]

		-- remove first entry
		-- by moving last entries
		-- back 1 index
		local n=#q
		for i=2,n+1 do
			q[i-1]=q[i]
		end
		
		found[id]=true
		local x,y=unhash_xy(id)
		
		local e=mapent(x,y)

		if e then
			for o in all(offsets) do
				local ox,oy=o.x+x,o.y+y
				local oid=hash_xy(ox,oy)
				if not found[oid] then
					local child=mapent(
						ox,oy)
					if child and child.etype==e.etype then
						e:parent(child,delay)
						add(q,oid)
					end
				end
			end
		end
	end
end

door=class({
	extends=toggleentity,
	etype="door",
	m_on=17,m_off=18,
	blocker=true,
})

function door:on_death()
	mset(self.mx,self.my,0)
	del_entity(self)
end

bridge=class({
	extends=toggleentity,
	etype="bridge",
	m_on=49,m_off=k_pit
})

switch=class({
	extends=toggleentity,
	etype="switch",
	w=2,h=2,
	m_on=33,m_off=32,
	auto_chain=true
})

function switch:on_enter(sender)
	self:push(sender)
end

function switch:on_exit(sender)
	self:pop(sender)
end

gun=class({
	extends=toggleentity,
	etype="gun",
	d=0,
	on=false,
	interval=12,
	frames=0,
})

function gun:calc()
 self.points={}
 
 if not self.on or g.gun_wait_flag then
  return
 end
 
 --[[if self.laser_cr then
  del(sequences,self.laser_cr)
 end]]
 
 --self.laser_cr=sequence(function()
	 add(self.points,
	  {x=self.x,y=self.y})
	
	 pts=self.points
	 local add_world=function(wx,wy,dx,dy)
	  local x=wx*8+4
	  local y=wy*8+4
	
	  add(pts,{x=x,y=y})
	 end
	 
	 local d=self.d
	 local wx,wy=self.mx,self.my
	 local dx,dy=d_to_xy(self.d)
	 
	 local short_stop=false
	 
	 local laser_solid=function(wx,wy,dx,dy)
	  local v=mget(wx,wy)
	  local pass=fget(v,4)

			if pass then
				local vert=fget(v,5)
				pass=(dy==0 and not vert)
					or (dx==0 and vert)
			end

	  local exclude=
	   emap_add_fn(v)==add_mirror
	   or pass
	  return solid_world(wx,wy) and
	   not exclude
	 end
	 
	 while not laser_solid(wx+dx,wy+dy,dx,dy) do
	  wx+=dx
	  wy+=dy
	  
	  if emap_add_fn(mget(wx,wy))==add_mirror
	  then
	   
	   add_world(wx,wy,dx,dy)
	   --wait_sec(0.1)
	   local e=mapent(wx,wy)
	   d=e:reflect(d)
	   if d==-1 then
	    short_stop=true
	    break
	   end
	   dx,dy=d_to_xy(d)
	  end
	 end
	 
	 local xx,yy=dx*4,dy*4
	 if (dx>0) xx-=1
	 if (dy>0) yy-=1
	 if short_stop then
	  xx,yy=0,0
	 end
	 
	 add(self.points,
	  {x=wx*8+4+xx,y=wy*8+4+yy})
	  
	 entity=mapent(wx+dx,wy+dy)
	 if entity~=self.powered then
	  --wait_sec(0.25)
	  if self.powered then
	   self.powered:pop(self)
	  end
	  if not entity or
	   entity.etype~="power_switch"
	  then
	   self.powered=nil
	  else
	   self.powered=entity
	   self.powered:push(self)
	  end
	 end
	 if entity~=self.zapping then
	 	if not entity or
	 		entity.destruct
			then
	 		self.zapping=entity
	 	elseif not entity.destruct then
	 		self.zapping=nil
	 	end
	 end
 --end)
end

function gun:on_update()
	local k_zap=0.033
	if self.zapping then
		if damage(self.zapping,k_zap)
		then
			self.zapping=nil
			calculate_lasers()
		end
	end
end

function aa_line_rect_x
	(x1,y1, -- segment point a
		x2,y2, -- segment point b
		r)					-- rectangle
	--
	local l,t,r,b=bounds(r)
	local code=function(x,y)
		local c=0
		if x<l then c+=1
		elseif x>r then c+=2 end
		if y<t then c+=4
		elseif y>b then c+=8 end
		return c
	end
	
	local c1,c2=code(x1,y1),code(x2,y2)
	local mask=0xf
	if x1==x2 then
		mask=0x3
	elseif y1==y2 then
		mask=0xc
	end
	
	return band(c1,mask)==0 and
		band(c1,c2)==0
end

function gun:intersect_laser(r)
	local n=#self.points
	for i=1,n-1 do
		local a=self.points[i]
		local b=self.points[i+1]
		if aa_line_rect_x(a.x,a.y,b.x,b.y,r)
		then
			return true
		end
	end
	return false
end

function calculate_lasers()
	g.gun_wait_flag=false
	for e in all(entities) do
		if e.calc then
			e:calc()
		end
	end
end

function gun:on_on(sender)
	self.on=true
	mset(self.mx,self.my,self.mv)
	self:calc()
end

function gun:on_off(sender)
	self.on=false
	mset(self.mx,self.my,self.mv+2)
	self:calc()
end

function gun:on_draw()
	if self.points then
		local n=#self.points
		for i=1,n-1 do
			local a=self.points[i]
			local b=self.points[i+1]
			line(a.x,a.y,b.x,b.y,14)
		end
	end
end

function d_to_xy(d,m)
	d=d or 0
	m=m or 1
	if d==0 then  return -m,0
	elseif d==1 then return m,0
	elseif d==2 then return 0,-m
	elseif d==3 then return 0,m
	else return 0,0 end
end

function player:on_update(dt)
	local ix,iy=0,0
	
	if not g.input_lock
	then
		ix,iy=input_xy(self.id)
	end
	
	local speed=30*dt
	self.dx=ix*speed
	self.dy=iy*speed
	
	move_actor(self,self.dx,self.dy)
	
	local cr={
		x=self.x+self.cx,
		y=self.y+self.cy,
		w=self.cw,h=self.ch
	}
	
	if nofloor_area(cr.x,cr.y,cr.w,cr.h) then
		kill_player(self,"pit")
	end
	
	for e in all(entities) do
		if e~=self then
			if rect_overlap(cr,e) then
				if not self.touch[e] then
					self.touch[e]=e
					if (e.on_enter) e:on_enter(self)
				end
			else
				if self.touch[e] then
					self.touch[e]=nil
					if (e.on_exit) e:on_exit(self)
				end
			end
			
			if e.etype=="gun" then
				if e:intersect_laser(cr)
				then
					kill_player(self,"laser")
				end
			end
		end
	end
end

k_pcols={4,2}
function player:on_draw()
	local x,y=topleft(self)
	pal(7,k_pcols[self.id+1])
	spr(1,x,y)
	pal(7,7)
end

function make_refl_t(i1,o1,i2,o2)
	local r={}
	for i=0,3 do
		r[i]=-1
	end
	r[i1]=o1
	r[i2]=o2
	return r
end



mirror=class({
	extends=toggleentity,
	etype="mirror",
	d=0
})

cw_tbl={}
cw_tbl[38]=54
cw_tbl[54]=55
cw_tbl[55]=39
cw_tbl[39]=38

function mirror:push(sender)
	self.d=(self.d+1)%4
	self.mv=cw_tbl[self.mv]
	mset(self.mx,self.my,self.mv)
	calculate_lasers()
end

function mirror:on_off()
	calculate_lasers()
end

refl_tt={}
refl_tt[0]=make_refl_t(3,1,0,2)
refl_tt[1]=make_refl_t(0,3,2,1)
refl_tt[2]=make_refl_t(1,3,2,0)
refl_tt[3]=make_refl_t(3,0,1,2)

function mirror:reflect(d)
	return refl_tt[self.d][d]
end

power_switch=class({
	extends=toggleentity,
	etype="power_switch",
	m_on=20,m_off=19,
})

checkpoint=class({
	extends=toggleentity,
	m_on=7,m_off=6
})

function checkpoint:spawn(sender)
	if g_pid<2 then
		add_player(self.mx+1,self.my,1)
		add_player(self.mx-1,self.my,1)
	end
end

function checkpoint:activate()
	
end

function checkpoint:on_enter(sender)
	set_checkpoint(self)
end

function set_checkpoint(checkpoint)
	if not g.checkpoint_lock
	then
		if (g.checkpoint) g.checkpoint:on_off()
		g.checkpoint=checkpoint
		if (g.checkpoint) g.checkpoint:on_on()
	end
end

goal=class({
 extends=toggleentity
})

function goal:on_enter(sender)
 if sender.id==self.id then
  self:push(sender)
 end
end

function goal:on_exit(sender)
 if sender.id==self.id then
  self:pop(sender)
 end
end

function goal:on_on(sender)
 toggleentity.on_on(self)
 check_win()
end

function add_entity(e)
	local ret=add(entities,e)
	if is_map_entity(e) then
		e.chain={}
		e.set={}
	 local h=hash_xy(e.mx,e.my)
	 assert(not mapentities[h])
	 mapentities[h]=e
	end
	if e.on_draw then
		add(drawables,e)
	end
	return ret
end

function del_entity(e)
	del(entities,e)
	if is_map_entity(e) then
		local h=hash_xy(e.mx,e.my)
		mapentities[h]=nil
	end
	if e.on_draw then
		del(drawables,e)
	end
end

g_pid=0
function add_player(x,y,m)
	local p=add_entity(player:new({
		id=g_pid,
		x=x*8+4,
		y=y*8+4,
		touch={},
	}))
	players[g_pid]=p
	g_pid+=1
	mset(x,y,0)
	return p
end

order={}
for i=0,63 do
	add(order,i)
end
shuffle(order)

function add_door(x,y,m)
	local ctx=emap_context(m)

	m=ctx.m or m

	m_on=18
	m_off=17
	
	local destruct=fget(m,5)
	local on_draw=nil
	local etype=door.etype

	if destruct then
		on_draw=function(self)
			local f=mid(self.dmg_f,0,1)
			f=f*f
			for i=1,f*64 do
				local x=order[i]%8+self.mx*8
				local y=flr(order[i]/8)+self.my*8
				pset(x,y,1)
			end
		end
		etype="crate"
	end

	local d=add_entity(door:new({
		mx=x,my=y,mv=m,
		m_on=m_on,m_off=m_off,
		x=x*8+4,y=y*8+4,
		w=4,h=4,
		destruct=destruct,
		on_draw=on_draw,
		dmg_f=0,
		etype=etype,
	}))
	
	if fget(m,1) then
		d:swap_states()
	end
	
	return d
end

function add_switch(x,y,m)
	return add_entity(switch:new({
		mx=x,my=y,mv=32,
		x=x*8+4,y=y*8+4,
	}))
end

function add_bridge(x,y,m)
	local b=add_entity(bridge:new({
		mx=x,my=y,mv=49,
		x=x*8+4,y=y*8+4,
	}))
	
	if fget(m,1) then
		b:swap_states()
		b:on_on(b)
	else
		b:on_off(b)
	end
	return b
end

function add_gun(x,y,m)
	local ctx=emap_context(m)
	
	local d=ctx.d or 0
	
	-- use orange flag to tell
	-- gun is on by default
	local default_on=fget(m,1)
	
	local m_on=m
	local m_off=m_on+2
	
	if not default_on then
		m_on,m_off=m_off,m_on
	end
	
	local g=add_entity(gun:new({
		mx=x,my=y,mv=m,
		m_on=m_on,m_off,
		x=x*8+4,y=y*8+4,
		d=d,
		default_on=default_on,
		points={},
	}))

	-- some further initialization
	if g.default_on then
		g:on_on(g)
	end
end

function add_mirror(x,y,m)
	local ctx=emap_context(m)
	
	local d=ctx.d or 0
	
	return add_entity(mirror:new({
		mx=x,my=y,mv=m,
		x=x*8+4,y=y*8+4,
		d=d,
	}))
end

function add_power_switch(x,y,m)
	return add_entity(
		power_switch:new({
			mx=x,my=y,mv=m,
			x=x*8+4,y=y*8+4,
		}))

end

function add_checkpoint(x,y,m)
	local c=add_entity(
		checkpoint:new({
			mx=x,my=y,mv=m,
			x=x*8+4,y=y*8+4,
			w=3,h=2
		}))
		
	if fget(m,1) then
		set_checkpoint(c)
		c:on_off()
	end
end

function add_goal(x,y,m)
 local ctx=emap_context(m)
 
 local id=ctx.id or 0
 
 assert(not goals[pid],
  "only 1 goal per player id per level.")
 
 local g=add_entity(goal:new({
  mx=x,my=y,m=m,
  id=id,
  m_off=m,m_on=m+2,
  x=x*8+4,y=y*8+4,w=3,h=2,cy=1
 }))
 
 goals[id]=g
 
 return g
end 

function mapent(x,y)
	local h=hash_xy(x,y)
	if mapentities[h] then
		return mapentities[h]
	end
	return nil
end

function damage(e,amt)
	if e and e.dmg_f~=nil then
		e.dmg_f+=amt
		if e.dmg_f>=1 then
			e.dmg_f=1
			if (e.on_death) e:on_death()
			return true
		end
	end
	return false
end
-->8
-- entity map

--[[
_emap={
	add_player,
	add_checkpoint,
	add_checkpoint,
	add_goal,
	{add_goal,{id=1}},
	add_switch,
	add_door,
	add_door,
	add_bridge,
	add_bridge,
	{add_gun,{d=0}},
	{add_gun,{d=1}},
	{add_gun,{d=2}},
	{add_gun,{d=3}},
	{add_gun,{d=0}},
	{add_gun,{d=1}},
	{add_gun,{d=2}},
	{add_gun,{d=3}},
	{add_mirror,{d=0}},
	{add_mirror,{d=3}},
	{add_mirror,{d=1}},
	{add_mirror,{d=2}},
	add_power_switch
}
]]

_emap={}
_emap[1]=add_player
_emap[17]=add_door
_emap[18]=add_door
_emap[5]=add_door
_emap[32]=add_switch
_emap[49]=add_bridge
_emap[4]=add_bridge

_emap[34]={add_gun,{d=0}}
_emap[35]={add_gun,{d=1}}
_emap[50]={add_gun,{d=2}}
_emap[51]={add_gun,{d=3}}

_emap[36]={add_gun,{d=0}}
_emap[37]={add_gun,{d=1}}
_emap[52]={add_gun,{d=2}}
_emap[53]={add_gun,{d=3}}

_emap[38]={add_mirror,{d=0}}
_emap[39]={add_mirror,{d=3}}
_emap[54]={add_mirror,{d=1}}
_emap[55]={add_mirror,{d=2}}

_emap[19]=add_power_switch

_emap[6]=add_checkpoint
_emap[7]=add_checkpoint

_emap[22]=add_goal
_emap[23]={add_goal,{id=1}}

function emap_context(v)
	local em=_emap[v]
	if type(em)=="table" then
		return em[2]
	end
	return {}
end

function emap_add_fn(v)
	local em=_emap[v]
	if type(em)=="table" then
		return em[1]
	elseif type(em)=="function" then
		return em
	end
	return function() end
end
-->8
--
-->8
-- level configs

function chain_entities(data)
	local n=#data
sequence(function()
	local i=1
	local safety=1000
	while safety>0 do
		safety-=1
		local fx=data[i]
		local fy=data[i+1]
		local tx=data[i+2]
		local ty=data[i+3]
		local delay=data[i+4]
		
		if fx==nil then
			break
		end
		
		if fx==tx and fy==ty then			
			mapent(fx,fy):bfs_chain(delay)
		else
			mapent(fx,fy):parent(mapent(tx,ty),delay)
		end
		
		i+=5
	end
end)
end

function config_level_1()
	-- 4227
	
	-- each data line is two points and an optional delay
	-- from_x,from_y,to_x,to_y,delay (optional)
	-- from and to being equal indicates auto chaining
	-- with breadth first search
	-- bfs_chain
	
	local data={
		8,5,7,4,nil,
		7,12,7,12,nil,
		5,11,7,12,nil,
		9,13,7,12,nil,
		11,10,11,10,nil,
		12,11,11,10,nil,
		10,8,11,10,nil,
		4,8,4,8,2,
		5,8,4,8,nil,
		8,2,8,2,nil,
		5,2,8,2,nil,
		9,2,8,2,nil,
	}
		
	chain_entities(data)	
--[[
	mapent(8,5):parent(mapent(7,4))
	mapent(8,5):parent(mapent(6,7))
	local d1=mapent(7,12)
	d1:bfs_chain()
	
	local s1=mapent(5,11)
	local s2=mapent(9,13)
	s1:parent(d1)
	s2:parent(d1)
	
	local b1=mapent(11,10)
	mapent(11,10):parent(mapent(11,9))
	b1:bfs_chain()
	
	mapent(12,11):parent(b1)
	mapent(10,8):parent(b1)
	
	local asdf=mapent(4,8)
	asdf:bfs_chain(10)
	
	mapent(5,8):parent(asdf)
--	mapent(5,8):parent(mapent(7,2))

	s1=mapent(9,2)
	s2=mapent(5,2)
	d1=mapent(8,2)
	d1:bfs_chain()
	s1:parent(d1)
	s2:parent(d1)
	]]
end

function config_level_2()
	local data={
		21,1,22,1,nil,
		22,1,22,1,4,
		23,4,24,3,nil,
		25,5,26,4,nil,
		26,6,25,6,nil,
		25,6,25,6,nil,
		23,8,22,8,nil,
		25,12,24,12,nil,
		24,12,24,12,nil
	}

	chain_entities(data)	
	--[[local offsets={
		{1,0},
		{0,1},
		{-1,0},
		{0,-1}
	}
	for h,e in pairs(mapentities) do
		if e.auto_chain then
			local found=nil
			for rad=1,1 do
				if (found) break
				for o in all(offsets) do
					local x,y=o[1],o[2]
					x=x*rad+e.mx
					y=y*rad+e.my
					found=mapent(x,y)
					if found then
						e:parent(found)
						break
					end
				end
			end
		end
	end]]
end
-->8
-- notes

-- things we got:
-- - floor switch
-- - laser
-- - laser powered switch
-- - powered doors
-- - powered bridges
-- - mirrors
__gfx__
0000000000077000000000000aa00000eeeeeeee555555550000000000eea0000000000000000000000000000000000000000000000000000000000000000000
000000000007700000000000aaaa0000e0eeee0e5dddddd5000000000eeea0000000000000000000000000000000000000000000000000000000000000000000
00700700077777700ddddd00aaaa0000ee0ee0ee5dddddd5000000000000a0000000000000000000000000000000000000000000000000000000000000000000
0007700000077000000d00000aa00000eeeeeeee5dddddd500dddd0000eeae000000000000000000000000000000000000000000000000000000000000000000
0007700000077000000d000000000000eeeeeeee5dddddd503dddd300aeeaea00000000000000000000000000000000000000000000000000000000000000000
007007000077770000000dd000000000ee0ee0ee5dddddd503dddd300aeeeea00000000000000000000000000000000000000000000000000000000000000000
00000000007007000000000000000000e0eeee0e5dddddd50033330000aaaa000000000000000000000000000000000000000000000000000000000000000000
00000000007007000000000000000000eeeeeeee5555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddddddeeeeeeee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d333333deaaaaaae0000000000066000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d333333deaaaaaae0033330000633600007ee7000000000000000000000000000077770000777700000000000000000000000000000000000000000000000000
d333333deaaaaaae003333000633336007eeee700009900000444400002222000799997777cccc70000000000000000000000000000000000000000000000000
d333333deaaaaaae00333300033333300eeeeee000099000046666442266662079999999ccccccc7000000000000000000000000000000000000000000000000
d333333deaaaaaae003333000053350000aeea0000000000046666442266662079999999ccccccc7000000000000000000000000000000000000000000000000
d333333deaaaaaae0000000000055000000aa0000000000000444400002222000799997777cccc70000000000000000000000000000000000000000000000000
ddddddddeeeeeeee0000000000000000000000000000000000000000000000000077770000777700000000000000000000000000000000000000000000000000
0000000000000000dddddddddddddddddddddddddddddddd7700000000000067ddddddddddd00ddd000000000000000000000000000000000000000000000000
0000000000000000333333dddd333333333333dddd3333336770000000000677d333333dd3d00d3d000000000000000000000000000000000000000000000000
000cc000000330003333dddddddd33333333dddddddd3333d67700000000677dddddddddd3d00d3d000000000000000000000000000000000000000000000000
00cccc00003ee30033333eeddee33333333333dddd333333dd667000000767dd00000000d3d00d3d000000000000000000000000000000000000000000000000
00dccd0003eeee3033333eeddee33333333333dddd333333ddd7660000767ddd00000000d3d00d3d000000000000000000000000000000000000000000000000
001dd100003ee3003333dddddddd33333333dddddddd3333dddd77600776ddddddddddddd3d00d3d000000000000000000000000000000000000000000000000
0001100000033000333333dddd333333333333dddd333333ddddd776776dddddd333333dd3d00d3d000000000000000000000000000000000000000000000000
0000000000000000dddddddddddddddddddddddddddddddd0ddddd7776ddddd0ddddddddddd00ddd000000000000000000000000000000000000000000000000
00000000eeeeeeeed333333dddddddddd333333ddddddddd0ddddd6777ddddd00000000000000000000000000000000000000000000000000000000000000000
00000000e0eeee0ed333333ddddeedddd333333dddddddddddddd677677ddddd0000000000000000000000000000000000000000000000000000000000000000
00000000ee0ee0eed333333dd3deed3dd333333dd3d33d3ddddd67700677dddd0000000000000000000000000000000000000000000000000000000000000000
00000000eeeeeeeed333333dd3d33d3dd333333dd3d33d3dddd7670000667ddd0000000000000000000000000000000000000000000000000000000000000000
00000000eeeeeeeed3d33d3dd333333dd3d33d3dd333333ddd767000000766dd0000000000000000000000000000000000000000000000000000000000000000
00000000ee0ee0eed3deed3dd333333dd3d33d3dd333333dd77600000000776d0000000000000000000000000000000000000000000000000000000000000000
00000000e0eeee0edddeedddd333333dddddddddd333333d77600000000007760000000000000000000000000000000000000000000000000000000000000000
00000000eeeeeeeeddddddddd333333dddddddddd333333d76000000000000770000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000000eea000000000000000000000000000eeeeeeeee000000eeeeeeeeeeeeeeeeeddddddddddddddddd333333ddddddddddddddddd
0000000000077000000000000eeea000000000000000000000000000eaaaaaae00000000e0eeee0ee0eeee0e333333dddd333333d333333ddddeeddd333333dd
0000000007777770000000000000a0000000000000000000000cc000eaaaaaae00000000ee0ee0eeee0ee0ee3333dddddddd3333d333333dd3deed3d3333dddd
000000000007700000dddd0000eeae00004444000022220000cccc00eaaaaaae00000000eeeeeeeeeeeeeeee33333eeddee33333d333333dd3d33d3d333333dd
000000000007700003dddd300aeeaea0046666442266662000dccd00eaaaaaae00000000eeeeeeeeeeeeeeee33333eeddee33333d3d33d3dd333333d333333dd
000000000077770003dddd300aeeeea00466664422666620001dd100eaaaaaae00000000ee0ee0eeee0ee0ee3333dddddddd3333d3deed3dd333333d3333dddd
00000000007007000033330000aaaa00004444000022220000011000eaaaaaae00000000e0eeee0ee0eeee0e333333dddd333333dddeedddd333333d333333dd
00000000007007000000000000000000000000000000000000000000eeeeeeeee000000eeeeeeeeeeeeeeeeeddddddddddddddddddddddddd333333ddddddddd
ddddddddd333333ddddddddd77000000000000670ddddd6777ddddd0000000000000000000000000000000000000000000000000000000000000000000000000
dd333333d333333ddddddddd6770000000000677ddddd677677ddddd000660000000000000000000000000000000000000000000000000000000000000000000
dddd3333d333333dd3d33d3dd67700000000677ddddd67700677dddd006336000000000000000000000000000000000000000000000000000000000000000000
dd333333d333333dd3d33d3ddd667000000767ddddd7670000667ddd063333600000000000000000000000000000000000000000000000000000000000000000
dd333333d3d33d3dd333333dddd7660000767ddddd767000000766dd033333300000000000000000000000000000000000000000000000000000000000000000
dddd3333d3d33d3dd333333ddddd77600776ddddd77600000000776d005335000000000000000000000000000000000000000000000000000000000000000000
dd333333ddddddddd333333dddddd776776ddddd7760000000000776000550000000000000000000000000000000000000000000000000000000000000000000
ddddddddddddddddd333333d0ddddd7776ddddd07600000000000077000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077077707700077077707770777000007770777077707770777077707770777077707770777077000000000000000000000000000000000000000000
00000000700070707070700070007070070000007070707007000700777007000070707007000700707070700000000000000000000000000000000000000000
00000000700070707070700077007770070000007070777007000700707007000700777007000700707070700000000000000000000000000000000000000000
00000000700070707070700070007000070000007070700007000700707007007000707007000700707070700000000000000000000000000000000000000000
00000000077077707070077077707000070000007770700007007770707077707770707007007770777070700000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dddddddd
000000000000000000000000000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000d333333d
00000000007777000077770000033000007ee70000000000000000000000000000000000000000000000000000000000000000000000000000000000d333333d
000000000799997777cccc70003ee30007eeee7000000000000000000000000000000000000000000000000000000000000000000000000000000000d333333d
0000000079999999ccccccc703eeee300eeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000d333333d
0000000079999999ccccccc7003ee30000aeea0000000000000000000000000000000000000000000000000000000000000000000000000000000000d333333d
000000000799997777cccc7000033000000aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000d333333d
000000000077770000777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dddddddd
__gff__
0000000082230002000000000000000001010201038200000000000000000000000003030101010111310000000000008080030301010101000000000000000000000002000000014280820303030301010101010101010100000000000000000000000000000000000000000000000080000000030000000000000000000001
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1010101010101033101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1016173030000000000000000000001010000700361312121212121212121210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003030201212122000000700001010000000291010101010101010101210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003030000000000000000000001010000000260000001100370000001210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003131000027000005000037001010000000000000201000260000001222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003131000000200000000000001010000000000000001020290000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003131000000000000000005001010111111111111111211131010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003131360000000005000027001010000000000000001000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000003131130000000020000000001010360000000024201000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010303030313030301010000000000000001036050505053710000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000010303030313030301010000000000000001026050505050010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000200011000000002000001010000000000000001100000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000011000000000000001010000000000000001120000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000600000010002000000600001010000000000000001100001617000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000010000000000000001010260000000000002800000000002710000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
