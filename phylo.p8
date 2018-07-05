pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
k_max_layer=4

function _init()
	poke(0x5f2d,1)
	
	init_console()

	actors={}
	k_max_actors=32
	
	for x=0,127 do
		for y=0,63 do
			local val=mget(x,y)
			if val==32 then
				player=make_player(x+.5,y+1,1)
				flag=make_flag(x+.5,y+1)
			end
		end
	end
	
	cam_x=0
	cam_y=0
end

function _update()
	if (stat(30)) onkey(stat(31))

	update_console()

	foreach(actors,move_actor)
	
	cam_x=mid(0,player.x*8-64,1024-128)
	cam_y=mid(0,player.y*8-64,512-128)
	
	btnpoll()
end

function _draw()
	cls()
	
	camera(cam_x,cam_y)
	map(0,0,0,0,128,64,2)
	
	if debug_slopes then
 	for x=0,127 do
 		for y=0,32 do
 			local m=mget(x,y)
 			if fget(m,4) then
 				for wx=x*8,(x+1)*8-1 do
 					for wy=y*8,(y+1)*8-1 do
 						local lx,ly=wx-x*8,wy-y*8
 						local flx,fly=fget(m,5),fget(m,6)
 						if not flx then
 							if lx>(6-ly) then
 								pset(wx,wy,8)
 							end
 						else
 							if lx<=ly then
 								pset(wx,wy,8)
 							end
 						end
 					end
 				end
 			end
 		end
 	end
 end
 	
	local n=#actors
	for layer=0,k_max_layer-1 do
		for i=1,n do
			local a=actors[i]
			if a.layer==layer then
				draw_actor(a)
			end
		end
	end
	
	camera()
	
	draw_console()
end

function onkey(key)
	if key=="`" then
		console.show=not console.show
	end
end

function make_flag(x,y)
	local fl=make_actor(x,y,1,"flag")
	fl.frame=32
	fl.controller=control_flag_idle
	fl.bounce=0
	fl.id=0
	fl.grabbed=false
	return fl
end

function make_player(x,y,face)
	local pl=make_actor(x,y,face,"p1")
	pl.frame=48
	pl.controller=control_player
	pl.bounce=0
	pl.id=0
	pl.layer=1
	return pl
end

function control_player(pl)
	if btnp(5,pl.id) and 
		player_on_flag(pl,flag)
	then
		if not flag.grabbed then
			grab_flag(flag)
		else
			release_flag(flag,pl.dx+pl.face*.8,pl.dy-.4)
		end
	end

	accel=0.05
	
	if not pl.standing then
		accel*=0.5
	end
	
	if btn(0,pl.id) then
		pl.dx-=accel
		pl.face=-1
	end
	
	if btn(1,pl.id) then
		pl.dx+=accel
		pl.face=1
	end
	
	if btnp(4,pl.id) and pl.standing
	then
		pl.dy=-0.7
	end
	
	if pl.standing then
		pl.f0=(pl.f0+abs(pl.dx)*2+4)%4
	else
		pl.f0=(pl.f0+abs(pl.dx)/2+4)%4
	end
	
	if abs(pl.dx)<0.1 then
		pl.frame=48
		pl.f0=0
	else
		pl.frame=49+flr(pl.f0)
	end
end

function kill_player(pl)
	pl.x=flag.x
	pl.y=flag.y
	pl.dx=0
	pl.dy=0
end

function grab_flag(fl)
	fl.grabbed=true
	fl.controller=control_flag_grab
	fl.ddy=0
end

function release_flag(fl,fx,fy)
	fl.grabbed=false
	fl.controller=control_flag_idle
	fl.ddy=0.06
	fl.dx=fx or 0
	fl.dy=fy or 0
end

function control_flag_grab(fl)
	fl.x=player.x
	fl.y=player.y+.1
end

function control_flag_idle(fl)
end

function make_actor(x,y,face,tag)
	local a={}
	a.tag=tag or "_"
	a.x=x or 63
	a.y=y or 15
	a.dx=0
	a.dy=0
	a.ddy=0.06 --gravity
	-- half-width/height
	a.w=0.3
	a.h=0.5
	a.face=face
	a.frame=1
	a.layer=0
	a.f0=0
	a.t=0
	a.standing=false
	a.controller=nil
	if #actors<k_max_actors then
		add(actors,a)
	end
	return a
end

function move_actor(a)
	if type(a.controller)==
		"function"
	then
		a:controller()
	end
	
	a.standing=false

	-- x movement
		
	x1=a.x+a.dx+sgn(a.dx)*0.3
	
	if not solid(x1,a.y-0.5) then
		-- didn't collide so move
		a.x+=a.dx
	else
		-- hit wall
		
		-- find contact point
		while not solid(
			a.x+sgn(a.dx)*0.3,
			a.y-0.5)
		do
			a.x+=sgn(a.dx)*0.1
		end
		
		-- bounce
		a.dx*=-0.5
		
		-- custom on collider callback	
	end
	
	-- y movement
	if a.dy<0 then
		-- going up
		if solid(a.x-0.2,a.y+a.dy-1) or
			solid(a.x+0.2,a.y+a.dy-1)
		then
			-- hit ceiling
			a.dy=0
			
			-- search for contact point
			while not solid(a.x-0.2,a.y-1)
				and not solid(a.x+0.2,a.y-1)
			do
				a.y-=0.01
			end
		else
			a.y+=a.dy
		end
	else
		-- going down
		if solid(a.x-0.2,a.y+a.dy) or
			solid(a.x+0.2,a.y+a.dy)
		then
			-- bounce
			if a.bounce>0 and
				a.dy>0.2
			then
				a.dy*=-a.bounce
			else
				a.standing=true
				a.dy=0
			end
			
			-- snap down
			while not solid(a.x-0.2,a.y)
				and not solid(a.x+0.2,a.y)
			do
				a.y+=0.05
			end
			
			-- pop up
			while solid(a.x-0.2,a.y-0.1)
			do
				a.y-=0.05
			end
			while solid(a.x+0.2,a.y-0.1)
			do
				a.y-=0.05
			end
		else
			a.y+=a.dy
		end
	end
	
	a.dy+=a.ddy
	a.dy*=0.95
	
	if a.standing then
		a.dx*=0.8
	else
		a.dx*=0.9
	end
	
	a.t+=1
end

function solid(x,y)
	if x<0 or x>=128 then
		return true
	end
	val=mget(x,y)
	if fget(val,0) then
		if fget(val,4) then
			-- slope
			local l,r=flr(x),ceil(x)
			local t,b=flr(y),ceil(y)
			local nx,ny=x-l,y-t
			local flipx=fget(val,5)
			local flipy=fget(val,6)
			if not flipx then	
				return nx>(1-ny)
			else
				return nx<=ny
			end
			return false
		else
			return true
		end
	end
	return false
end

function hurts(x,y)
	if x<0 or x>=128 then
		return false
	end
	val=mget(x,y)
	return fget(val,2)
end

function player_on_flag(pl,fl)
	local dx=pl.x-fl.x
	local dy=pl.y-fl.y
	return sqrt(dx*dx+dy*dy)<=1
end

function draw_actor(a)
	spr(a.frame,a.x*8-4,a.y*8-8,
		1,1,a.face<0)
end

_btns={}
k_max_players=4
for p=0,k_max_players-1 do
	_btns[p]={}
	for b=0,5 do
		_btns[p][b]=false
	end
end

btnpd=btnp

function btnp(b,p)
	p=p or 0
	return btn(b,p) and
		not _btns[p][b]
end

function btnpoll()
	for p=0,k_max_players-1 do
		for b=0,5 do
			_btns[p][b]=btn(b,p)
		end
	end
end

function init_console()
 console={}
 console.show=false
 console.max_logs=100
 console.vis_lines=12
 console.height=console.vis_lines*6+2
 console.hide_pos=-console.height-2
 console.show_pos=0
 console.y=console.hide_pos
 k_con_max_lines=20
end

function log(m)
	add(console,tostr(m))
	if #console>console.max_logs
	then
		for i=2,#console+1 do
			console[i-1]=console[i]
		end
	end
end

function update_console()
	if console.show then
		console.y=moveto(console.y,
			console.show_pos,8)
	else
		console.y=moveto(console.y,
			console.hide_pos,8)
	end
end

function draw_console()
	rectfill(0,console.y,
		127,console.height+console.y,
		0)
		
	rect(0,console.y,
		127,console.y+console.height,
		7)

	local fin=#console		
	local start=max(fin-console.vis_lines+1,1)
	for i=start,fin do
		local b=i-start
		print(console[i],2,console.y+b*6+2,7)
	end
end
-->8
function lerp(a,b,t)
	return a+(b-a)*t
end

function clamp(v,mn,mx)
	if (mn>mx) mn,mx=mx,mn
	return min(max(v,mn),mx)
end

function clamp01(v)
	return clamp(v,0,1)
end

function dot(x1,y1,x2,y2)
	return x1*x2+y1*y2
end

function len(x,y)
	return sqrt(x*x+y*y)
end

function norm(x,y)
	local l=len(x,y)
	if (l>0) return x/l,y/l
	return 0,0
end

function moveto(v,tg,d)
	if v<tg then
		return min(v+abs(d),tg)
	elseif v>tg then
		return max(v-abs(d),tg)
	else
		return v
	end
end
__gfx__
00000000ffffffff0000000ff0000000ffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000f99ff99f000000ffff0000000f9ff99ff99ff9f000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700f99ff99f00000f9ff9f0000000fff99ff99fff0000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000ffffffff0000ffffffff0000000ffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000ffffffff000ffffffffff0000000ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700f99ff99f00fff99ff99fff0000000f9ff9f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000f99ff99f0f9ff99ff99ff9f0000000ffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ffffffffffffffffffffffff0000000ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700070000000765500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07760776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07660766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07650765000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77657765000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76657665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76557655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00588888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00588888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00588888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00588888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000e222e200e222e20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e222e200e222e2002e222e002e222e00e222e200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02e222e002e222e0034646300346463002e222e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03464630034646300344443003444430034646300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
034444300344443000222dd000222000034444300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0022200000222dd00dd00000dd222000dd2220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d0d00000d000000000000000000d000000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d0d00000d0000000000000000000d00000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0003133353730000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000000000000000000000000000000000000000001000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000000000000000000000000000000000000000101010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000000000000000000000000000000000000000201010103000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000000000000000000000000000000000000020101010101030000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020000000000000000000000000000200002010101010101010300000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101000000000000000000000001010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001101010101010101010101001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
