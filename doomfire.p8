pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
function _init()
	//cls()
	memcpy(0x0000,0x6000,0x2000)
	k={0,0,2,4,4,8,8,8,
				9,9,10,10,10,7,7,7}
				
	l=127
	for x=0,l do
		sset(x,l,15)
		local i=flr(x/8)
		pal(i,k[i+1])
	end
	
	cr=cocreate(fire)
end

function fire()

	while true do
		for y=0,126 do
			for x=0,l do
				c=sget(x,y+1)
				r=flr(rnd(3))
				if c>0 then
				 sset(x+r-1,y,c-band(r,1))
				end
			end
		end
		
		for x=0,127 do
			local v=max(sget(x,127)-1,0)
--			sset(x,127,v)
		end
	end
end

function _update()
	if btnp(4) then
		cstore(0x0000,0x6000,0x2000,"doomfire.p8")
	end

	if cr and costatus(cr)~="dead" then
		coresume(cr)
	end
end

function _draw()
	sspr(0,0,128,128)
end

__gfx__
02020202020202000202020202020202020202020202020202020202002020202020202020202020202020202020202020202020202020202020202020202000
20202020202020202020202020202020202020202020202020202020220202020202000202020202020202020202020202020202020202020202020202020202
02020202020202020202020202020202020202020202020202020202000020202020202020202020202020202020202020202020202020202020202020202020
20202020202020202020202020202020202020202020202020202020202002020202020202020202020202020202020202020202020202020202020202020202
02020202020202020202020202020202020202020202020202020202020000202020202020202020202020202020202020202020202020202020202020202020
20202020202020202020202020202020202020202020202020202020202222020202020202020202020202020202020202020202020202020202020202020202
02020202020202020202020202020202020202020202020202020202020202202020202020202020202020202020202020202020202020202020202020202020
20202020202020202020202020202020202020202020202020202020202000020202020202020202020202020202020202020202020202020202020202020202
02020202020202020202020202020202020202020202020202020202020200000020202020202020202020202020202020202020202020202020202020202020
20202020202020202020202020202020202020202020202020202020202002000202020202020202020202020202020202020202020202020202020202020202
02020202020202020202020202020202020202020202020202020202020200202020202020202020202020202020202020202020202020202020202020202020
20202020202020202020202020202020202020202020202020202020202002020202020202020202020202020202020202020202020202020202020202020202
02020202020202020202020202020202020202020202020202020202020202202020202020202020202020202020202020202020202020202020202020202020
20202020202020202020202020202020202020202020202020202020202020020202020202020202020202020202020202020202020202020202020202020202
02020202020202020202020202020202020202020202020202020202020200002020202020202020202020202020202020202020202020202020202020202020
20202020202020202020202020202020202020202020202020202020202000002202020202020202020202020202020202020202020202020202020202020202
02020202020202020202020202020202020202020202020202020202020200020020222002002020202020202020202020202020202020202020202020202020
20202020202020202020202020202020202020202020202020202020202020200002020002000202020202020202020202020202020202020202020202020202
02020202020202020202020202020202020202020202020202020202020202020000220202222020202020202020202020202020202020202020202020202020
20202020202020202020202020202020202020202020202020202020202020202000022022220202020202020202020202020202020202020202020202020202
02020202020202020202020202020202020202020202020202020202020202020000200202002020202020202020202020202020202020202020202020202020
20202020202020202020202020202020202020202020202020202020202020202000000020220202020202020202020202020202020202020202020202020202
02020202020202020202020202020202020202020202020202020202020200000200020202002000202020202020202020202020202020202020202020202020
20202020202020202020202020202020202020202020202020202020202020002020002020000000020202020202020202020202020202020202020202020202
02020202020202020202020202020202020202020202020202020202020202020202020200000000202020202020202020202020202020202020202020202020
20202020202020202020202020202020202020202020202020202020202020202020202000000000020202020202020202020202020202020202020202020202
02020202020202020202020202020202020202020202020202020202020202020202020200000000002020202020202020202020202020202020202020202020
20202020202020202020202020202020202020202020202020202020202020202020202000000000000202020202020202020202020202020202020202020202
02020202020202020202020202020202020202020202020202020202020202020202020202000000000020002020202000202020202020202020202020202020
20202020202020202020202020202020202020202020202020202020202020202020202000200000000000020202000000000202020202020202020202020202
02020202020202020202020202020202020202020202020202020202020202020202020002020200000000002020202020000020202020202020202020202020
20202020202020202020202020202020200020222000202020202020202020202020202020202020200000020002020202020202020202020202020202020202
02020202020202020202020202020202020202002022020202020202020202020202020202020202020202000200002000202020202020202020202020202020
20002020202020202020202020202020202022220200202020202020202020202020202020200020202020200020200000000202020202020202020202020202
22220242020202020202020202020202020200202022000202020202020202020202020202000202020202020002020000000220220020202020202020202020
40442420202020202020202020202020202220020202002020202020202020202020202020202020202000200020200000000020002202020202020202020202
02444202000202020202020202020202000220202220000202020202020202020202020202020202020002020202020202020200022020202020202020202020
00440020000000002020202020200020202022020022000000202020202020202020202020202020200020200020202020202020200202020202020002020202
02000000002020020202020202020202020200222022000000020202020202020202020202020202020002020202020002020202020020202020402000222020
20200000020202022020202020202020202020200020002000202020202020202020202020202020202000202020202020202020200002020202220222020202
02000020002020200202020202020202020202000202020202020202020202020202020202020202020202020202020202020202000000244220442022402020
20220202020200020220200020202020002020000020202020202020202020202020202020202020202020202020202020202020000000004422244222420202
02002020202020202002000202020202020200000002020202020202020202020202020202020202020202020202020202020202020000000242022044242020
20022202020202020200000020202020202020000020202020202020202020202020202020202020202020202020202020202020202000000020222204020202
00202220202020202000200202020202020200000002020202020202020202020202020202020202020202020202020202020202020000000002442220200220
02020202020202020202000020202020202000002000202020202020202020202020202020202020202020202020202020202020200000000000442202002020
00202020202020202020200002020202020200000202020202020202020202020202020202020202020202020202020202020202000000000000020020020200
00000202020202020002000000202020202000000020202020202020202020202020202020202020202020202020202020202020200000000000002020202000
00202020202020202020202000020202020200000002020202020202020202020202020202020202020202020202020202000200020000000000040202020202
00020202020202020202000200002020002000000020202020202020202020202020202020202020202020202020202020202020200000000020002020202020
00002020202020002020202000000202000000000002020202020202020202020202020202020202020202020202020202020200020000000002020202020202
00000202020200000202020000002020200020200000202020202020202020202020202020202020202020202020202020202020202020002000202020202020
80002020202000002020200000000202020202020000020202020202020202020202020202020202020202020200020202020202020202020202020202020202
88000202020200020202020200002020202020202000002020202020202020202020202020202020202020202020202020202020202020202020202020202020
98002020202000002020202020000202020202020000020202020202020202020202020202020202020202020202020202020202020202020202020202020202
09820002020200000202020202000000202020202020002020202020202020202020202020202020202020202020202000202020202020202020202020202020
20902020202000000020202020000000020202020202020202020202020202020202020202020202020202020202020000020202020202020202020202020202
02020200020000000002020000020000002020202020202020202020202020202020202020202020202020202020202000202020202020202020202020202020
20202020000000000000202000202000000202020202020200000202020202020202020202020002020202420202020200020202020202020202020202020202
02020200000000000002020200020202002020202000200020000002202020202020202020200000202024244020202000202020202020222020200020202020
80202020202002000002202020002020220202020200000022202020000202020202020202000002020202042202020202020402020000002202000202020202
88080202220020200020020202020202020020202020200202000202000020202020202020200000202000204220202020202024242200020000200020202020
88880022202002020000002020202020200002020202000020000020002000020202020202020000024244244442020204022244420020202020202000020202
84880202002020200200020002020202020000000000000002020202020000202022202020202000002444024020202420204040202002000202020200000020
88808020200202000000002000202020202020200020000020202000202000200222222202020002000244444402200202000200020020000020202000202222
48480002022020200000020202020202020002020200000202020202020202000022200220202020000000244020022000422020020200000202020000020222
88888000000202020202002020202020202020202000000020202020202020000020200002020202020202004002020000440220202000002020202020202022
88880000000020202020220202020202000202000200000202020202020202000200020020202020200024240202040000044020020202000202020202020200
88800000020002020222202020202020202020200020202020202020202020000020202202020202000004002020204000242002200020202020202020202000
08020000202020202020020202020202020202020202020202020202020202000002020020202000002000020202020402040200020202220202020202020000
20200000020002020202002020002020202020202020202020202020202020000000000002020200000020202040202020404020202020202020202020202000
02020000202020202000202200220202020202020202020202020202020200000000002000202020002024024422224402240202020202040202020202020200
20202000020202020202020202000020202020202020202020202020202022020002000202020224004824202422402024442020202020442020202022202000
02020200002020202020202020000002020202020202020202000202020202200020202020204240202082820042040204400002020202424202020222020000
20202000020202020202020200020020202020202020202020020200202000020202020202020402228288280420202020040020202024442420404042202000
00020000002020002020202000202202020202020202020000002020200002202020222020202422222848444022020202020202020200424444040044020000
00000000020202020202020200020000202020202020200002000202022020220202220200020244424280442022202020202020202000242444204220202000
00000200002020202020202020200020020202020202020020200020200202002020002020002024242402040222020202020002040202024242024402020000
20202000202202020202020202220202002020202020200002000202020042024244000202220202420244224240202020202222204442204424244020200000
02020202020220202020002020222020020000020202022020200020202024244420442040202020200244444404020202022022202244044442424202000000
20202020002000020202000202022000000000002020202000020202020202044402442002420202022024440442402020204202020420204044042020000200
02020200020220002000200020220200000000020202020200202020202020204000420404202020200204440442420204020420002044420202200220002000
00202020202002020202020202002020002020002020202022020202020202020000444422020202000424404424242244404002020004402040020202020000
02020202020000202020202020200002020202020202020200002000200020242044044202202000000044204400440424440000000002424220202000202000
00202020202000020202020202000020002020004040202000000000000000024444004420000000000004020404202444040000002020244242020202020000
22020200020000020020222020202002020000020402000200000000000000004440000040000000000000200002024204204000420244044440202020202000
00002020000000202400220202020200020000002002202000000000000020000400020200000000000002002004202222242024402420244400020202020200
00020200000000020244402020202020002020020220020020000000000202000000002022020000000000202222424224204240204240424040202020202020
02022020200000202044020202020202020200002020002200002000200020000000020202202000000000020000202088002022228202020402020200020202
20200202020000022000202000220000202002000200202022020202020202000020202020200000000000002022220848000402028820244400202020002020
02022020200002020042020202202020020020002020220200002020202020200002020002022000000000000422408984404040202802044000020202000202
20200202000022202204202022022222200202000202002020000002020202000200202020200000000000000044440840920002020200240200000020002020
02022022000002222204420202222220202020202220020002020000202020202000020202020200000000000004242882824800222020002000004200020200
20200220200000220222402020220202020202020200200020202020020200020000402020202000000000000000442894928484040202020002004424202020
02000002020000020022020202202220202020202022020202020200002000000002020202020000000200000000044288448884204020402020404042020202
20202000200000002020200020200202020202020202000020002000000000000000202020202000202000000000002028849448240208044202044402202020
02020000020000020202020202022000200000202020202000000000000000000000020202020000020000000202000409094944288088208400404424000200
20200020200000002000202020200020000000040202020200000220000020200000002020200000000000202020200028409409029884020222040202402200
02020202000000000200020202044002002020244020202000002020020202020002020202000000000000020202020440842498288048202020202800220204
20202020200000002020202020202220000202024202000000020202002020200000202000000002000200002020204040044402820400420422020822020242
02020202020000000202000202020402000020402200200000002020200020002022020202002000002200000202020424802440244844404000204220242424
00202000202020202020202020200020400202044422020000000202020202220220202000202000202220002020202082490984044424422244222402022004
00020200000222020202000202020202442024202002002020002020202000202022020002000202020202020202020288048820204244442440088042222020
02002020002020202020202020202020220242420002020202000202020240020200002020002020202020202000202080404880029444424280444420220002
20000202000202020202020202020202222020202020202020020040404024002020020202000202020202020202000002090908882944492020244444022020
00000020204020002020202020222420220202020202020202000204044442440202002020002020202020002020000000208848448488899202084440200202
00000022024220020202020202042042002420202020202020202420444404400020202200000202020242200000000400840484844988889920220024002020
00020200202000202020202020404420220402020202020202020204444424020202002020202020202024002002004042908848284898428904204242420202
20202000022204440422020202444204242020202020202020202020444440002020022202020202020200000402000404020980428484849022424420002020
02020000000220244240202020442020200202020202020202020202024420020222202020202020202002440044220400202090949889884404909802020202
00200000002002044402020200024242020020202020222020222020424442402022020202020202020022204044404040420202092498848444498980204020
00200000020000020020202200002420404222020204002242222202022024020200202020202020202002440244042044020090208888084888909092020402
00000200020000020202020200020242040442202220422024402042024242402000220202020202020400444000024044042202028888884944890200002442
00002020000200204020202020002020204022244402440202420404240424020002022020202020204004242400044400400220282998849488482022002224
00000202020020020444020202220202440244444020242024440020444242042022220002020202020402420202002420200400029898884889080202004442
02020020202202020040202220404020242024200402020202444424242444222222002000002020202040202400224024442044029989888899902020402444
20200002020220402402020224440402020200442022204424204042404442022200200020000202020202044000022244240442209980998899990202044024
00022000202022204440240240204040402242440202202402240424240200202020020200000020202022204220204224242442428880989949992024244442
20200204020220044044202002220402040200444000220424224240002024040202000022220002000200020442020220224242009808999999820202424424
22222020044442044004442022000042202424240444404042004440440202400020020022200020202000002004222000044044202989999890892020204402
20222002200404004440444224202204200204424040404400002002024440200200020002020002020202020044242200004424444998999889020202020220
02200020042020202202440002000202442040042200040422002000024444020002000222002020202000204220402040000440442449989880902020242044
02220020202240202424442042220040424044024220424022202000040004200200202022222200020202020244442402000044442244998999020202020224
20020200222204020242442422002444222404402222442200004222002042000020000202002200202020244424440200000024444440999989202020202044
00202002022040204020044444220422440200002420424202240222024424400002022020222002020200222404442002002204444400099999020202020244
20000220200242440200004444022024422022242402242022222222202444020020222202002020202020424024440220222220444000009990002020202004
02222002000024242000000404202204240202224220024200224220020040002202022020000222000202240002442002022002040000000900000200020000
