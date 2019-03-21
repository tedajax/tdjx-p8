pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	palettes={
		default={
			0,7,8
		},
		amiga={
			1,7,9
		}
	}

	palette=palettes.amiga

	player={
		x=64,
		y=116,
		dx=0,dy=0,
		w=8,h=8,
		face=0,
		sp=16
	}
	
	river_w=116
end

function _update()
	dt=1/30

	local ix,iy=0,0
	
	if (btn(0)) ix-=1
	if (btn(1)) ix+=1
	if (btn(2)) iy-=1
	if (btn(3)) iy+=1
	
	local accel=200
	if ix~=0 then
		if sgn(ix)~=sgn(player.dx) then
			accel*=2
		end
		player.dx+=ix*accel*dt
		player.dx=mid(player.dx,
			-100,100)
	else
		if player.dx<0 then
			player.dx=min(player.dx+accel*dt,0)
		else
			player.dx=max(player.dx-accel*dt,0)
		end
	end
	
	player.face=sgn(ix)
	
	player.x+=player.dx*dt
	player.y+=player.dy*dt
	
	river_w=84
	
	local left=flr(64-river_w/2)
	local right=flr(64+river_w/2)
	
	if player.x<left+8 then
		player.x=left+8
		if (player.dx<0) player.dx=0
	elseif player.x>right-7 then
		player.x=right-7
		if (player.dx>0) player.dx=0
	end
end

function _draw()
	cls(palette[1])
	
	for i=1,#palettes.default do
		pal(palettes.default[i],palette[i])
	end
	
	spr(2,56,20,2,1)
	
	local sp=player.sp
	
	spr(sp,player.x-player.w,
		player.y-player.h,2,2)
	
		
	local left=flr(64-river_w/2)
	local right=ceil(64+river_w/2)
	line(left,0,left,127,7)
	line(right,0,right,127,7)
end

_sgn=sgn
function sgn(v) if v==0 then return 0 else return _sgn(v) end end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888888888888888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000088008800880088008800880088008800000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000880088008800880088008800880088000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000008800880088008800880088008800880000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000008008800880088008800880088008800800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888888888888888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000778877000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000788887000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007788887700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007788887700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007707707700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
