pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
function _init()
	poke(0x5f2e,1)
	
	k=0
--	k=128
	for i=0,15 do
		pal(i,k+i,1)
	end
end
__gfx__
00000000222222222222222211111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000222eeee22222222211811188111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070022ee22222222222211881188811118810000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700022ee22222ee22222118881e8111888110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000222ee2ee2ee2222211eeee88e18881110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007002222ee2eee2222221e888888e888eee10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000022222e222e2eeee21e888888e888e1ee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ee222ee22e2e22ee11eee888e888e81e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000002ee22ee22e22e22e1188ee88e888e1ee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000002eeeee22e222e22e11888e8e8888e1e10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000002222222ee22e22ee18888e8e8888eee10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000022222eee2222eee21888ee8e88ee81110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000002222eeeeeee2222211eee88eeee888110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000022222ee22eeee22211188111818188110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000222222222222222211888118811111810000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000222222222222222211111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
