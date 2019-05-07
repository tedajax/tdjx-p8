pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
_sgn=sgn
function sgn(a)
 if (a==0) return 0
 return _sgn(a)
end

_logs={}
_log_max=21

function log(m,c)
	m=tostr(m)
	c=c or 7
	add(_logs,{m=m,c=c})
	if #_logs>_log_max then
		for i=1,_log_max do
			_logs[i]=_logs[i+1]
		end
		_logs[_log_max+1]=nil
	end
end

function draw_log()
	local n=#_logs
	for i=1,n do
		local l=_logs[i]
		print(l.m,127-#l.m*4,(i-1)*6,l.c)
	end
end

_watches={}
_watch_default_color=11

function watch(m,c)
	m=tostr(m)
	c=c or _watch_default_color
	add(_watches,{m=m,c=c})
end

function clear_watches()
	_watches={}
end

function draw_watches()
	local n=#_watches
	for i=1,n do
		local w=_watches[i]
		print(w.m,0,(i-1)*6,w.c)
	end
end

function input_xy(player)
	player=player or 0

	local ix,iy=0,0
	
	if (btn(0,player)) ix-=1
	if (btn(1,player)) ix+=1
	if (btn(2,player)) iy-=1
	if (btn(3,player)) iy+=1
	
	return ix,iy
end

function tick_sequences()
	if not sequences then
		sequences={}
	end
	
	for s in all(sequences) do
		if s and costatus(s)~="dead" then
			assert(coresume(s))
		else
			del(sequences,s)
		end
	end
end

function sequence(fn)
	if not sequences then
		sequences={}
	end
	
	return add(sequences,cocreate(fn))
end

function wait_sec(sec)
	sec=sec or 0
	local start=t()
	while t()<start+sec do
		yield()
	end
end

gamestates={}
active_gamestate=nil

function add_gamestate(name,init,update,draw)
	gamestates[name]={
		init=init,
		update=update,
		draw=draw
	}
end

function gamestate_update(dt)
	if active_gamestate and
		active_gamestate.update
	then
		active_gamestate.update(dt)
	end
end

function gamestate_draw()
	if active_gamestate and
		active_gamestate.draw
	then
		active_gamestate.draw()
	end
end

function set_gamestate(name)
	local gs=gamestates[name]
	if gs then
		active_gamestate=gs
		active_gamestate.init()
	end
end

-- wip
function sspr_slice(sx,sy,sw,sh,
	dx,dy,dw,dh,
	left,right,top,bot)
	
	sspr(sx,sy,sw,top,
		dx,dy,dw,top)
		
	sspr(sx,sy+sh-bot,sw,bot,
		dx,dy-dh-bot,dw,bot)
		
	sspr(sx,sy,left,sh,
		dx,dy,left,dh)
		
	sspr(sx+sw-right,sy,right,sh,
		dx+dh-right,dy,right,dh)
		
	local h=left+right
	local v=top+bot
		
	sspr(sx+left,sy+top,sw-h,sh-v,
		dx+left,dy+top,dw-h,dh-v)
	
end

function blink(ivl,tt)
	tt=tt or t()
	return flr((tt*2)/ivl)%2==0
end

function chance(perc)
	return rnd()<perc
end

-- weighted table random
function rnd_wt(wt)
	local sum=0
	for w in all(wt) do
		assert(w>=0)
		sum+=w
	end
	
	if sum<=0 then
		return 0
	end
	
	local val=flr(rnd(sum)+1)
	
	local idx=0
	while val>0 do
		idx+=1
		val-=wt[idx]
	end
	
	return idx
end

hex_table={
	"0","1","2","3",
	"4","5","6","7",
	"8","9","a","b",
	"c","d","e","f"
}

function tohex(num)
	local str="0x"
	for i=1,8 do
		local v=(i-4)*4
		local shf=shl
		if v<0 then
			shf=shr
			v=abs(v)
		end
		local h=band(shf(num,v),0xf)
		local hs=hex_table[h+1]
		str=str..hs
		if (i==4) str=str.."."
	end
	
	return str
end

function shuffle(a)
 local n=#a
 for i=n,2,-1 do
  local j=flr(rnd(i))+1
  a[i],a[j]=a[j],a[i]
 end
 return a
end

function rnd_elem(a)
	local n=#a
	return a[flr(rnd(n))+1]
end


function dist2(x1,y1,x2,y2)
 local dx,dy=x2-x1,y2-y1
 return dx*dx+dy*dy
end

function dist(x1,y1,x2,y2)
 return sqrt(dist2(x1,y1,x2,y2))
end

function sqr(n)
 return n*n
end

function angle_to(ox,oy,tx,ty)
 return atan2(tx-ox,ty-oy)
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

function damp_angle(a,b,vel,tm,mx,ts)
 b=a+angle_diff(a,b)
 return damp(a,b,vel,tm,mx,ts)
end

function moveto(a,b,d)
 if abs(b-a)<=d then
  return b
 else
  return a+sgn(b-a)*d
 end
end

function moveto_angle(a,b,d)
 local dl=angle_diff(a,b)
 if -d<dl and dl<d then
  return b
 else
  return moveto(a,a+dl,d)
 end
end

function m01(v)
 return mid(v,0,1)
end

function lerp(a,b,t)
 return a+(b-a)*t
end

function lerp_angle(a,b,t)
 local d=wrap((b-a),1)
 if (d>0.5) d-=1
 return a+d*m01(t)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000