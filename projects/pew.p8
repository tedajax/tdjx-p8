pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- collision
function cell_solid(cx, cy)
	return fget(mget(cx, cy), 1)
end

function point_solid(x, y)
	return cell_solid(x / 8, y / 8)
end

function area_solid(x, y, w, h)
	return point_solid(x, y)
		or point_solid(x+w, y)
		or point_solid(x, y+h)
		or point_solid(x+w, y+h)
end

function cast_h(ox, oy, dx)
	for x = ox, ox + dx do
		if point_solid(x, oy) then
			return true, x - ox
		end
	end
	return false, dx
end

function cast_v(ox, oy, dy)
	for y = oy, oy + dy do
		if point_solid(ox, y) then
			return true, y - oy
		end
	end
	return false, dy
end

-- level --
-----------------------------------
function new_level()
	local lvl = {}

	lvl.cx = 0
	lvl.cy = 0
	lvl.cw = 41
	lvl.ch = 15
	lvl.sx = 0
	lvl.sy = 0

	lvl.spn_x = 0
	lvl.spn_y = 0

	lvl.min_x = 64 + 8
	lvl.max_x = 248 + 8

	for x = 0, lvl.cw do
		for y = 0, lvl.ch do
			if fget(mget(x, y), 3) then
				lvl.spn_x = x * 8 + lvl.cx
				lvl.spn_y = y * 8 + lvl.cy
			end
		end
	end

	return lvl
end

function level_draw(lvl)
	map(lvl.cx, lvl.cy,
		lvl.sx, lvl.sy,
		lvl.cw, lvl.ch)
end

-----------------------------------
-- muzzle flashes --
-----------------------------------
function new_flash(x, y, left)
	local fls = {}
	fls.x = x
	fls.y = y
	fls.left = left
	fls.frm = 10
	fls.dx = 0.6 + abs(ship.dx)
	if fls.left then fls.dx *= -1 end
		add(flashes, fls)
	return fls
end

function flash_update(fls)
	if t % 2 == 0 then
		fls.frm -= 1
	end
	fls.x += fls.dx
	if fls.frm <= 0 then
		fls.dead = true
	end
end

function flash_draw(fls)
	spr(5 + 10 - max(fls.frm, 4),
		fls.x, fls.y,
		1, 1,
		fls.left, false)
end

-----------------------------------
-- sparks --
-----------------------------------
function new_spark(x, y)
	local spk = {}

	spk.x = x
	spk.y = y
	spk.spr = 13
	spk.frm = 10
	spk.dead = false

	add(sparks, spk)

	return spk
end

function spark_update(spk)
	spk.frm -= 1
	if spk.frm <= 0 then
		spk.spr += 1
		spk.frm = 10
		if spk.spr > 15 then
			spk.dead = true
		end
	end
end

function spark_draw(spk)
	circ(spk.x, spk.y, spk.frm/2, 10)
	spr(spk.spr,
		spk.x,
		spk.y,
		1, 1,
		false, false)
end

-----------------------------------
-- bullets --
-----------------------------------
function new_bullet(x, y, dx, dy)
	blt = {}

	dx = dx or 0
	dy = dy or 0

	blt.x = x
	blt.y = y
	blt.dx = dx
	blt.dy = dy
	blt.ox = 1
	blt.oy = 1
	blt.w = 6
	blt.h = 4
	blt.hw = blt.w / 2
	blt.hh = blt.h / 2
	blt.spr = 4
	blt.life = 50
	blt.dead = false

	blt.left = ship.left
	if blt.left then
		blt.dx *= -1
		blt.ox = 0
	end

	add(bullets, blt)

	sfx(8)

	return blt
end

function bullet_update(blt)
	blt.x += blt.dx
	blt.y += blt.dy
	blt.life -= 1
	if blt.life <= 0 then
		bullet_kill(blt)
	end

	if area_solid(blt.x + blt.ox,
		blt.y + blt.oy,
		blt.w, blt.h)
	then
		bullet_kill(blt)
	end
end

function bullet_kill(blt)
	blt.dead = true
	new_spark(blt.x + blt.hw,
		blt.y + blt.hh)
end

function bullet_draw(blt)
	spr(blt.spr,
		blt.x,
		blt.y,
		1, 1,
		blt.left, false)
end

-- ship --
-----------------------------------
function new_ship()
	local ship = {}

	ship.x = level.spn_x
	ship.y = level.spn_y
	ship.w = 8
	ship.h = 8
	ship.dx = 0
	ship.dy = 0
	ship.spr = 1
	ship.left = false
	ship.acl_x = 0.05
	ship.acl_y = 0.4
	ship.dcl_x = 0.02
	ship.dcl_y = 0.4
	ship.max_x = 1.5
	ship.max_y = 1
	ship.fire_del = 0

	return ship
end

function ship_solid(ship, dx, dy)
	return area_solid(ship.x + dx,
		ship.y + dy,
		ship.w, ship.h)
end

function ship_update(ship)
	-- movement input
	if btn(1) then
		ship.dx += ship.acl_x
		ship.left = false
	elseif btn(0) then
		ship.dx -= ship.acl_x
		ship.left = true
	else
		ship.dx = decay(ship.dx,
			ship.dcl_x)
	end

	if btn(3) then
		ship.dy += ship.acl_y
	elseif btn(2) then
		ship.dy -= ship.acl_y
	else
		ship.dy = decay(ship.dy,
			ship.dcl_y)
	end

	ship.dx = clamp(ship.dx,
		-ship.max_x, ship.max_x)
	ship.dy = clamp(ship.dy,
		-ship.max_y, ship.max_y)

	if (btn(5)) ship.dx = 0

	-- physics
	local nx = ship.x + ship.dx
	local ny = ship.y + ship.dy

	if ship_solid(ship, ship.dx, 0)
	then
		ship.dx = 0
	end

	if ship_solid(ship, 0, ship.dy)
	then
		ship.dy = 0
	end

	ship.x += ship.dx
	ship.y += ship.dy

	-- animate
	if t % 4 == 0 then
		ship.spr += 1
		if ship.spr > 2 then
			ship.spr = 1
		end
	end

	-- shoot
	if btn(4) then
		ship.fire_del -= 1
		if ship.fire_del <= 0 then
			ship.fire_del = 7

			local kx = 3
			if (ship.left) kx *= -1
			cam_kick(kx)

			local mx = 8
			if (ship.left) mx *= -1
			new_flash(ship.x + mx,
				ship.y + 2,
				ship.left)

			local bx = 8
			if (ship.left) bx = -8
			bx += ship.x
			b = new_bullet(bx,
				ship.y + 2,
				4,
				sin(t / 180) * 0.2)
		end
	else
		ship.fire_del = 0
	end
end

function ship_draw(ship)
	spr(ship.spr,
		ship.x, ship.y,
		1, 1,
		ship.left, false)

	local tx0, ty0 = ship.x, ship.y
	local tx1, ty1 = tx0 + ship.w,
		ty0 + ship.h

	local c = 11
	if area_solid(tx0, ty0,
			ship.w, ship.h) then
		c = 8
	end

	-- rect(tx0, ty0, tx1, ty1, c)
end
-----------------------------------

-- camera --
-----------------------------------
function new_camera()
	local cam = {}

	cam.x = 63
	cam.y = 63
	cam.kx = 0
	cam.kdx = 0.3
	cam.tx = 0

	return cam
end

function cam_update(cam)
	local tar = 0
	local lead = 24
	if ship.left then
		tar = -lead + 4
	else
		tar = lead + 4
	end

	cam.kx = decay(cam.kx, cam.kdx)

	cam.tx = lerp(cam.tx, tar, 0.1)
	cam.x = ship.x + cam.tx

	-- clamp pos before knockback
	-- is added so knockback doesnt
	-- disappear at edges of stages
	cam.x = clamp(cam.x,
		level.min_x, level.max_x)

	cam.x += cam.kx
end

function cam_kick(kx)
	cam.kx = kx
end
-----------------------------------

-----------------------------------
-- managers --
-----------------------------------
function new_mngr(update, draw)
	local mngr = {}

	mngr.rem_q = {}
	mngr.update = update
	mngr.draw = draw

	return mngr
end

function mngr_update(mngr)
	for i = 1, #mngr do
		mngr.update(mngr[i])
		if mngr[i].dead then
			add(mngr.rem_q, i)
		end
	end
	fst_del(mngr, mngr.rem_q)
	arr_clr(mngr.rem_q)
end

function mngr_draw(mngr)
	foreach(mngr, mngr.draw)
end
-----------------------------------

function _init()
	t = 0

	music(0)

	game = {}
	game.score = 0
	game.high = 999

	cam = new_camera()

	level = new_level()
	ship = new_ship()

	bullets = new_mngr(bullet_update,
		bullet_draw)

	flashes = new_mngr(flash_update,
		flash_draw)

	sparks = new_mngr(spark_update,
		spark_draw)
end

function _update60()
	t += 1

	if (t % 4 == 0) game.score += 1

	-- update bullets
	mngr_update(bullets)

	-- update flashes
	mngr_update(flashes)

	-- update sparks
	mngr_update(sparks)

	-- update ship
	ship_update(ship)

	cam_update(cam)
end

function _draw()
	cls()

	camera(0, 0)
	rectfill(0, 0, 127, 127, 0)

	camera(cam.x-64, cam.y-64)
	level_draw(level)
	ship_draw(ship)
	mngr_draw(bullets)
	mngr_draw(sparks)
	mngr_draw(flashes)

	camera(0, 0)
	line(0, 121, 127, 121, 12)

	prn_small(num_to_str(t),
		2, 123)
end

function lerp(a, b, t)
	return a + (b - a) * t
end

function fst_del(arr, idx)
	local l = #arr

	if type(idx) == "table" then
		for i in all(idx) do
			arr[i] = nil
		end
		if #idx == l then
			return
		end
		for i = 1, l do
			if arr[i] == nil then
				while not arr[l]
					and l > i do
					l -= 1
				end
				if i ~= l then
					arr[i] = arr[l]
					arr[l] = nil
				else
					break
				end
			end
		end
	elseif type(idx) == "number" then
		arr[idx] = nil
		if l > idx then
			arr[idx] = arr[l]
			arr[l] = nil
		end
	end
end

function arr_clr(arr)
	for i, _ in pairs(arr) do
		arr[i] = nil
	end
end

function move_to(v, f, dv)
	if v < f then
		v += dv
		if v > f then v = f end
	elseif v > f then
		v -= dv
		if v < f then v = f end
	end
	return v
end

function decay(v, dv, tg)
	return move_to(v, tg or 0, dv)
end

function clamp(v, low, high)
	return max(min(v, high), low)
end


k_smfnt = {}
k_smfnt["0"] = 64
k_smfnt["1"] = 65
k_smfnt["2"] = 66
k_smfnt["3"] = 67
k_smfnt["4"] = 68
k_smfnt["5"] = 69
k_smfnt["6"] = 70
k_smfnt["7"] = 71
k_smfnt["8"] = 72
k_smfnt["9"] = 73

function prn_small(digits, x, y, col)
	x, y = x or 0, y or 0
	col = col or 0
	if col ~= 0 then
		pal(7, col)
	end

	local base_sp = 64
	for i = 1, #digits do
		local c = sub(digits, i, i)
		local sp = k_smfnt[c]
		if sp then
			spr(sp, x, y)
			x += 5
		end
	end

	pal()
end

function num_to_str(num)
	local ret = ""
	if (num == 0) return "0"
	while num > 0 do
		ret = tostr(num % 10) .. ret
		num = flr(num / 10)
	end
	return ret
end

__gfx__
000000000d0000000d000000000000000000000000000000000a770000099a700000499a00000099000000490000000400000000000000000000000000000000
000000000dd000000dd0000000000000000000000aa700000aaa770004999aaa0000049a00000049000000040000000000000000000000000000000000000000
007007000ddd00000ddd00000000000009aaa770aa0000009aaaa00004999aaa0000499900000000000000090000000000000000000000000000000000000000
000770000066cc000866cc000000000009aaaa709777770099aaa77000449a77000449aa00000049000000090000000900000000000000000000000000000000
0007700009d66cd089d66cd00000000009aaaa709777770099aaa77000449a77000449aa00000049000000090000000900000000000000000000000000000000
0070070000ddd66608ddd6660000000009aaa770aa0000009aaaa00004999aaa0000499900000000000000090000000000000000000000000000000000000000
0000000000ddd55600ddd55600000000000000000aa700000aaa770004999aaa0000049a00000049000000040000000000000000000000000000000000000000
0000000000d0000000d00000000000000000000000000000000a770000099a700000499a00000099000000490000000400000000000000000000000000000000
ccccccccd000000cccdd000cd000ddccccccccccccccccccd000ddccccdd000cd000000cd000ddccccdd000cd000000cd000000c000000000000000000000000
cccccccc0cd00000ccdd00000cd0ddcccccccccccccccccc0cd0ddccccdd00000cd000000cd0ddccccdd00000cd000000cd00000000000000000000000000000
dddddddd000cd000ccddd000000cddccccddddddddddddcc000cddccccddd000000cd000000cddddddddd000000cd000000cd000000000000000000000000000
dddddddd00000cd0ccdd0cd00000ddccccddddddddddddcc0000ddccccdd0cd000000cd00000dddddddd0cd000000cd000000cd0000000000000000000000000
d000000cd000000cccdd000cd000ddccccdd000cd000ddccddddddccccddddddddddddddd000000cd000000cd000cccccccc000c000000000000000000000000
0cd000000cd00000ccdd00000cd0ddccccdd00000cd0ddccddddddccccdddddddddddddd0cd000000cd000000cd0cccccccc0000000000000000000000000000
000cd000000cd000ccddd000000cddccccddd000000cddcccccccccccccccccccccccccc000cd000000cd000000cccddddccd000000000000000000000000000
00000cd000000cd0ccdd0cd00000ddccccdd0cd00000ddcccccccccccccccccccccccccc00000cd000000cd00000ccddddcc0cd0000000000000000000000000
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
07700000777000007777000077770000077000000777000077770000777700007777000077770000000000000000000000000000000000000000000000000000
70070000007000000077000000770000707000007700000070000000000700007777000070070000000000000000000000000000000000000000000000000000
70070000007000000700000000070000777700000077000077770000007000007007000077770000000000000000000000000000000000000000000000000000
07700000777700007777000077770000007000007777000077770000070000007777000000070000000000000000000000000000000000000000000000000000
__label__
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d00000000000000000000000000000000000
0000000000000000000cccccccccccccccc00000000cccccccccccccccc00000000000000000000000000000000dd00000000000000000000000000000000000
0000000000000000000cccccccccccccccc00000000cccccccccccccccc0000000000000000000000000000000ddd00000000000000000000000000000000000
0000000000000000000ccddddddddddddcc00000000ccddddddddddddcc00000000000000000000000000000cc66800000000000000000000000000000000000
0000000000000000000ccddddddddddddcc00000000ccddddddddddddcc0000000000000000000077a00000dc66d980000000000000000000000000000000000
0000000000000000000ccdd000cd000ddcc00000000ccdd000cd000ddcc0000000000000000000077aaa00666ddd800000000000000000000000000000000000
0000000000000000000ccdd00000cd0ddcc00000000ccdd00000cd0ddcc00000000000000077aaa9aaaa90655ddd000000000000000000000000000000000000
0000000000000000000ccddd000000cddcc00000000ccddd000000cddcc0000000000000007aaa77aaa99000000d000000000000000000000000000000000000
0000000000000000000ccdd0cd00000ddcc00000000ccdd0cd00000ddcc0000000000000007aaa77aaa990000000000000000000000000000000000000000000
0000000000000000000ccdd000cd000ddcc00000000ccdd000cd000ddcc00000000000000077aaa9aaaa90000000000000000000000000000000000000000000
0000000000000000000ccdd00000cd0ddcc00000000ccdd00000cd0ddcaaa00000000000000000077aaa00000000000000000000000000000000000000000000
0000000000000000000ccddd000000cddcc00000000ccddd000000cdaac00aa000000000099000077a0000000000000000000000000000000000000000000000
0000000000000000000ccdd0cd00000ddcc00000000ccdd0cd00000dacc000a00000000009400000000000000000000000000000000000000000000000000000
0000000000000000000ccddddddddddddcc00000000ccddddddddddadcc0000a0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000ccddddddddddddcc00000000ccddddddddddadcc0000a0000000009400000000000000000000000000000000000000000000000000000
0000000000000000000cccccccccccccccc00000000ccccccccccccaccc0000a0000000009400000000000000000000000000000000000000000000000000000
0000000000000000000cccccccccccccccc00000000cccccccccccccacc000a00000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000aa000aa00000000009400000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000aaa0000000040009900000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000090000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000077aaa900000000000000000000000090000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000007aaaa900000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000007aaaa900000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000077aaa900000000000000000000000040000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000077aaa90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000007aaaa90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000007aaaa90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000077aaa90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000077aaa90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007aaaa90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007aaaa90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000077aaa90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd0000
0000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd00
000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd
cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777707777077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700007000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777707777000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777707777077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000002020202020202020202020202000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1010101500000000000000000000000000000000000000000000000000000000000000000014101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111300000000000000000000000000000000000000000000000000000000000000000012111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111300000000000000000000000000000000000000000000000000000000000000000012111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111300000000000000000000000000000000000020000000000000000000000000000012111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111300000000000000001410150000000000000000000000000000000000000000000012111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111300000000000000001211130000000000000000000000000000000000000000000012111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111300000000000000001718160000000000000000000000000000000000000000000012111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111300000000000000000000000000001415001415000000000000000000000000000012111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111300000000000000000000000000001716001716000000000000000000000000000012111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111300000000000000000000000000000000000000000000000000000000000000000012111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111300000000000000000000000000000000000000000000000000000000000000000012111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111300000000000000000000000000000000000000000000000000000000000000000012111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111300000000000000000000000000000000000000000000000000000000000000000012111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111300000000000000000000000000000000000000000000000000000000000000000012111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111111191010101010101010101010101010101010101010101010101010101010101010101a111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00020000031000310012100171001c1002110024100241002510025100221001e1001a100121000b1000810008100091000a1000b10035100351003510033100301002e1002b1002710001100031000010000100
01100000107751377517775137751077513775177751377510775137751777513775107751377517775137750f7751277517775127750f7751277517775127750f7751277517775127750f775127751777512775
011000001c3601c3511c3411c331233602335123341233311e3601e3511e3411e3311f3601f3511f3411f3311b3601b3511b3411b331233602335123341233311e3601e3511e3411e3311b3601b3511b3411b331
011000001c4701c4711c4711c47126470264712647126471244702447124471244711c4701c4711c4711c47121470214712147121471264702647126471264712447024471244712447121470214712147121471
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000c150191500b3501c350161501715017150293500d1501515014150121500f1500c150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 01424344
00 41424344
02 41424344

