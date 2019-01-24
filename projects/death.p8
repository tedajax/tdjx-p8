pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	g={}
	g.scroll_x=0
	
	g.flowers={}
	-- goto 16 to get offscreen tile
	for y=0,15 do
		for x=0,16 do
			if mget(x,y)==8 then
				make_flower(x,y)
			end
		end
	end
end

function _update()
	g.scroll_x+=1
	if g.scroll_x>=8 then
		g.scroll_x-=8
		
	end
	
	foreach(g.flowers,update_flower)
end

function _draw()
	cls()
	map(0,0,0-g.scroll_x,0,17,16)
	spr(32,32,128-24,2,2)
end

k_flw_alive=0	-- normal
k_flw_decay=1 -- in decay
k_flw_dead=2		-- at final decay

function make_flower(x,y)
	local obj={}

	-- tile coordinates
	obj.x,obj.y=x,y
	
	-- frame interval
	obj.fivl=30
	-- frame timer
	obj.ft=obj.fivl

	-- map value
	obj.mval=8
	
	obj.state=k_flw_alive
	
	return add(g.flowers,obj)
end

function update_flower(fl)
	if fl.state==k_flw_alive then
		if rnd(1000)<5 then
			fl.state=k_flw_decay
		end
	elseif fl.state==k_flw_decay
	then
		fl.ft-=1
		if fl.ft<=0 then
			fl.ft=fl.fivl
			fl.mval+=1
			mset(fl.x,fl.y,fl.mval)
			if fl.mval==12 then
				fl.state=k_flw_dead
			end
		end
	end
end
__gfx__
00000000055006000000000000000000bbbbbbbb0000000000000000000000000d08800000000000000000000000000000000000000000000000000000000000
000000000550666600000000000000003b3333b3000000000000000000000000dcd8800005044000000000000000000000000000000000000000000000000000
00700700555555000000000000000000222332330000000000000000000000000d0b0ee05c544000050240000000000000000000000000000000000000000000
00077000555005000000000000000000424224420000000000000000000000000b0b0be005030dd05c5220000000000000000000000000000000000000000000
00077000555005000000000000000000444444440000000000000000000000000b0bb9a9030303d0050305d00000200000000000000000000000000000000000
00700700555005000000000000000000444444440000000000000000000000000b0b0a9a03033460030303505d52000005000000000000000000000000000000
00000000055005000000000000000000444444440000000000000000000000000b0b09a90303064605053060055505d005500500000000000000000000000000
00000000055005000000000000000000444444440000000000000000000000000b0b00b003030064050506465505255555555555000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055555000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00053335006666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00053335000466660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00053335000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055555000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555ddd400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55d555550004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeee
55d555550004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e88888ee
55d555550004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e8eee8ee
55d555550004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e8eee8ee
33d555550004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e8888eee
330d555d0004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e8eee8ee
000d555d0004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e8eeee8e
000ddddd0004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeee
__map__
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000008000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000080000000800000000080000000804040404000000000404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404040404040404040404040404040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000