pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
function _init()
	poke(0x5f2d,1)
	
	cam={x=0,y=0}

	units={}
	selection={}
	
	for xx=0,31 do
		for yy=0,31 do
			if mget(xx,yy)==16 then
				mset(xx,yy,48)
				add_unit(1,xx,yy)
			end
		end
	end
	
	mou_x,mou_y,mou_b,
	mou_px,mou_py,mou_pb=
		0,0,0,0,0,0

	sel_box_x1,sel_box_y1,
	sel_box_x2,sel_box_y2=-1,-1,-1,-1
	
	mcel_x,mcel_y=-1,-1
	worl_x,worl_y=-1,-1
	
	coroutines={}
end

function _update()
	mou_px,mou_py,mou_pb=mou_x,mou_py,mou_b
	mou_x=stat(32)
	mou_y=stat(33)
	mou_b=stat(34)
	
	local dx,dy=
		mou_x-mou_px,
		mou_y-mou_py
	
	for i=1,5 do
		local b=band(mou_b,shl(1,i-1))~=0
		local pb=band(mou_pb,shl(1,i-1))~=0
		if b and not pb then
			mou_down(i)
		elseif not b and pb then
			mou_up(i)
		elseif b and pb and 
			(dx~=0 or dy~=0)
		then
			mou_drag(i,dx,dy)
		end
	end
	
	for cr in all(coroutines) do
		if cr and costatus(cr)~="dead" then
			assert(coresume(cr))
		else
			del(coroutines,cr)
		end
	end
	
	local ix,iy=0,0
	for i=0,1 do
		if (btn(0,i)) ix-=1
		if (btn(1,i)) ix+=1
		if (btn(2,i)) iy-=1
		if (btn(3,i)) iy+=1
	end
	ix,iy=norm(ix,iy)
	
	cam.x+=ix*4
	cam.y+=iy*4
	
	-- update units
	
	foreach(units,function(unit)
		local move_x,move_y=0,0
		
		local trymove=false
		
		if unit.path and #unit.path>0
			and unit.tstuck<1
		then
			if not unit.next then
				unit.next=unit.path[1]
				
			end
			
			local dx,dy=unit.next.x-unit.x,
					unit.next.y-unit.y

			local dist=sqrt(dx*dx+dy*dy)
			
			if dist<0.1
			then
				del(unit.path,unit.next)
				unit.next=nil
			else
				local ms=0.125
				dx,dy=norm(dx,dy)
				move_x=dx*min(ms,dist)
				move_y=dy*min(ms,dist)
				
			end
			
			trymove=true
		end

		if move_x~=0 or move_y~=0 then
			unit.t0+=0.5
		end
		
		local mx,my=move_x+unit.nudge_x,
			move_y+unit.nudge_y
			
		if move_x~=0 or move_y~=0 then
			if abs(mx)>=abs(my) then
				unit.sp=16
				if mx<0 then
					unit.spfx=true
				else
					unit.spfx=false
				end
			else
				if my<0 then
					unit.sp=20
				else
					unit.sp=18
				end
			end
		end
			
		unit.nudge_x=0
		unit.nudge_y=0
			
		local t=1
		while solid(unit.x+unit.w+mx*t,unit.y+unit.h+my*t) and t>0 do
			t-=0.1
		end
		unit.x+=mx*t
		unit.y+=my*t
		
		local sdx,sdy=unit.stuck_x-unit.x,
			unit.stuck_y-unit.y
		if sqrt(sdx*sdx+sdy*sdy)>0.1 then
			unit.stuck_x=unit.x
			unit.stuck_y=unit.y
			unit.tstuck=0
		else
			if trymove then
				unit.tstuck+=1/30
			end
		end
	end)
	
	local n=#units
	for i=1,n-1 do
		for j=i+1,n do
			local a,b=units[i],units[j]
			local hit,nx,ny=unit_coll(a,b)
			if hit then
				if nx==0 and ny==0 then
					nx=1
				end
				local mx,my=nx/8,ny/8
				a.nudge_x+=mx
				a.nudge_y+=my
				b.nudge_x-=mx
				b.nudge_y-=my
			end
		end
	end
end

function norm(x,y)
	local l=sqrt(x*x+y*y)
	if (l==0) return 0,0
	return x/l,y/l
end

function unit_coll(a,b)
	local ax1,ay1,ax2,ay2=extents(a)
	local bx1,by1,bx2,by2=extents(b)
	
	if ax1<=bx2 and
		ax2>=bx1 and
		ay1<=by2 and
		ay1>=by1
	then
		local dx,dy=a.x-b.x,a.y-b.y
		local nx,ny=norm(dx,dy)
		return true,nx,ny
	end
	return false,0,0
end


function mou_down(b)
	if b==1 then
		sel_box_x1,sel_box_y1,
		sel_box_x2,sel_box_y2=
			mou_x,mou_y,mou_x,mou_y
	elseif b==2 then
		worl_x,worl_y=flr(mou_x/8),flr(mou_y/8)
	elseif b==3 then
		mcel_x,mcel_y=s2w(mou_x,mou_y)
	end
end

function mou_up(b)
	if b==1 then
		select(sel_box_x1,sel_box_y1,
			sel_box_x2,sel_box_y2)
	
		sel_box_x1,sel_box_y1,
		sel_box_x2,sel_box_y2=-1,-1,-1,-1
	elseif b==2 then
		if flr(mou_x/8)==worl_x and
			flr(mou_y/8)==worl_y
		then
			-- do action
			direct(mou_x,mou_y)
		end
	elseif b==3 then
		local wx,wy=s2w(mou_x,mou_y)
		if wx==mcel_x and wy==mcel_y
		then
			local m=mget(mcel_x,mcel_y)
			local n=32
			if (m==32) n=48
			mset(mcel_x,mcel_y,n)
		end
	end
end

function mou_drag(b,dx,dy)
	sel_box_x2,sel_box_y2=
		mou_x,mou_y
end

function select(x1,y1,x2,y2)
	if (x2<x1) x1,x2=x2,x1
	if (y2<y1) y1,y2=y2,y1
	
	x1+=cam.x
	x2+=cam.x
	y1+=cam.y
	y2+=cam.y

	selection={}

	for unit in all(units) do
		local ux1,uy1,ux2,uy2=
			extents(unit)
		
		if intersect(x1,y1,x2,y2,
			ux1,uy1,ux2,uy2)
		then
			add(selection,unit)
		end
	end
end

function direct(px,py)
	local wx,wy=flr((px+cam.x)/8),flr((py+cam.y)/8)
	for unit in all(selection) do
		unit.tx=wx+0.5
		unit.ty=wy+0.5

		local f=function()
			unit.path=get_path(unit.x+unit.w,unit.y+unit.h,unit.tx,unit.ty)
		end
		unit.path=nil
		add(coroutines,cocreate(f))
	end
end

function intersect(ax1,ay1,ax2,ay2,bx1,by1,bx2,by2)
	return ax1<=bx2 and
		ax2>=bx1 and
		ay1<=by2 and
		ay2>=by1
end

function extents(r)
	return r.x*8,r.y*8,
		(r.x+r.w*2)*8-1,
		(r.y+r.h*2)*8-1
end

function _draw()
	cls()

	-- game camera
	
	camera(cam.x,cam.y)
	
	map(0,0,0,0,32,32)
	
	foreach(units,function(self)
		spr(self.sp+(self.t0%2),
			self.x*8,
			self.y*8,
			self.sw,self.sh,
			self.spfx,self.spfy)
			
		if false and self.path then
			local n=#self.path
			for i=1,n-1 do
				local a=self.path[i]
				local b=self.path[i+1]
				line(a.x*8+4,a.y*8+4,b.x*8+4,b.y*8+4,12)
			end
		end
	end)
	
	foreach(selection,function(self)
		local x1,y1,x2,y2=extents(self)
		rect(x1-1,y1-1,x2+1,y2+1,10)
	end)
	
	-- ui camera
	
	camera()
		
	pset(stat(32),stat(33),11)
	if sel_box_x1>=0 and
		sel_box_y1>=0
	then
		rect(sel_box_x1,sel_box_y1,
			sel_box_x2,sel_box_y2,
			11)
	end
end

function add_unit(utype,x,y)
	local sp=0
	if utype==1 then
		sp=16
	end

	return add(units,{
		utype=utype or 0,
		x=x or 0,
		y=y or 0,
		w=0.5,h=0.5,
		tx=x or 0,ty=y or 0,
		path={},
		sp=sp,sw=1,sh=1,
		nudge_x=0,nudge_y=0,
		t0=0,
		tstuck=0,
		stuck_x=0,stuck_y=0
	})
end

function s2w(sx,sy)
	return flr((sx+cam.x)/8),
		flr((sy+cam.y)/8)
end
-->8
function get_path(x1,y1,x2,y2)
	x1=flr(x1)
	y1=flr(y1)
	x2=flr(x2)
	y2=flr(y2)

	local dist=function(x1,y1,x2,y2)
		return abs(x1-x2)+abs(y1-y2)
	end
	
	
	local hash=function(x,y)
		return y*64+x+10000
	end
	
	local unhash=function(h)
		local i=h-10000
		return i%128,flr(i/128)
	end
	
	local open,closed={},{}
	
	local make_node=function(x,y,p,g,h)
		g=g or 0
		h=h or 0
		return {
			x=x,y=y,p=p,
			g=g,h=h,f=g+h
		}
	end
		
	local add_open=function(n)
		local h=hash(n.x,n.y)
		if not open[h] and not closed[h] then
			open[h]=true
			return add(open,n)
		end
	end
	
	local add_closed=function(n)
		local h=hash(n.x,n.y)
		if not closed[h] then
			open[h]=nil
			del(open,n)

			closed[h]=true
			add(closed,n)
		end
	end
		
	
	local process=function(node,ctx)
		if solid(node.x,node.y) then
			return nil
		end
		
		if node.x==ctx.x2 and
			node.y==ctx.y2
		then
			return node
		end
	
		add_closed(node)
		
		local valid=function(x,y)
			return x>=0 and x<=31 and
				y>=0 and y<=31
		end
			
		local diag_open=function(x1,y1,x2,y2)
			local dx,dy=abs(x1-x2),abs(y1-y2)
			return dx~=1 or dy~=1 or
				not (solid(x2,y1) or solid(x1,y2))
		end
		
		for xx=node.x-1,node.x+1 do
			for yy=node.y-1,node.y+1 do
				if valid(xx,yy) and not solid(xx,yy) and
					diag_open(node.x,node.y,xx,yy)
				then
					-- todo: diagnol blockers
					local g=14
					if xx==node.x or
					 yy==node.y
					then
						g=10
					end
					g+=node.g
					local h=dist(xx,yy,
						ctx.x2,ctx.y2)
					add_open(
						make_node(xx,yy,node,g,h))
				end
			end
		end
		
		local adj={}
		for o in all(open) do
			if abs(node.x-o.x)==1 and
				abs(node.y-o.y)==1
			then
				if o.g<node.g then
					o.parent=node
					o.g=node.g+10
					o.f=o.g+o.h
				end
			end
		end
		
		if #open==0 then
			return nil
		end
		
		local minf=32767
		local low=nil
		for o in all(open) do
			if o.f<minf then	
				minf=o.f
				low=o
			end
		end

		return ctx.process(low,ctx)
	end

	local node=add_open(make_node(x1,y1))
	local final=process(node,{x1=x1,y1=y1,x2=x2,y2=y2,process=process})
	
	local ret={}
	if final then
		local slide=final
		add(ret,slide)
		while slide.p do
			slide=slide.p
			add(ret,slide)
		end
	end
	
	-- todo: reverse
	local h,t=1,#ret
	while t>h do
		ret[h],ret[t]=ret[t],ret[h]
		h+=1
		t-=1
	end
	return ret
end

function solid(x,y)
	return fget(mget(x,y),0)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00eeee0000eeee007e2ee2e00e2ee2e70eeeeee77eeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000
0222e2e00222e2e0727ee727727ee727002ee207702ee20000000000000000000000000000000000000000000000000000000000000000000000000000000000
222ee72e222ee72e22eeee2222eeee227e2222eeee2222e700000000000000000000000000000000000000000000000000000000000000000000000000000000
7ee2eeee7ee2eeeee22ee22ee22ee22eee22222ee22222ee00000000000000000000000000000000000000000000000000000000000000000000000000000000
2ee22e202e222e20e222222ee222222ee22222277222222e00000000000000000000000000000000000000000000000000000000000000000000000000000000
e7ee77677ee77777722222eeee222227722772200227722700000000000000000000000000000000000000000000000000000000000000000000000000000000
02ee22200ee222200ee222b77e222ee072222ee00ee2222700000000000000000000000000000000000000000000000000000000000000000000000000000000
0ee70ee7000ee7007ee7000770007ee70000eeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65555556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65555556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65555556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65555556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65555556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65555556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3030303030303030303030303030303030303030303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3020303030303030302030303020203030303030303030202020202020303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3020303020303030303030303030303030303030302030203030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030302030303030303030303030303030103030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3010303030103030302030303030302030303030303030103030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303020203030302030303030302020203030303030302020303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030203030203030302030303030303020203030303030303020202030301030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030302030302030303030303030302030303030303030303030303030303020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030301030303030303030303030303030203030302030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030203030303030303030303030303010303030202030302020303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030302030302030302030303010301030303030302020303020203030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030301030303030202030303030303030303010303030303020203030202030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030202030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030302020303030303030303030303030103030303030303030302020303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303020202020303030303020303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303020303030303030303030303030303020303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303010303030303030303030303030303030303030303030303020303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030103030303030303030303030303020303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030302030303030303030303020203030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030302020303030303030303030302030303030303030303030203030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030203020303030303030303030202030303030303030303030203030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303020303020203030303030303030303030303030303030303030203030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030302030303030303030303030303030303030303020203030303030203030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030202030303030303030303030303030303030302020203030303030203030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3020203030303010303030303030202020202020203030202030103030203030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3020203030303030303030303030303030303030303030302030303030203030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030302030303030203030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030203030303030302030303030303030303030302030303030203030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030203030303030303030303030303010303030202030303030203030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030202020203030303030303030303030303030303030303030203030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303010303030303030303030303020203030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
