pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
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

-- muzzle flashes
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
	blt.spr = 4
	blt.life = 50
	blt.dead = false

	blt.left = ship.left
	if blt.left then
		blt.dx *= -1
		blt.ox = 0
	end

	add(bullets, blt)

	return blt
end

function bullet_update(blt)
	blt.x += blt.dx
	blt.y += blt.dy
	blt.life -= 1
	if blt.life <= 0 then
		blt.dead = true
	end

	if area_solid(blt.x + blt.ox,
		blt.y + blt.oy,
		blt.w, blt.h) then
		blt.dead = true
	end
end

function bullet_draw(blt)
	spr(blt.spr,
		blt.x,
		blt.y,
		1, 1,
		blt.left, false)
end

function _init()
	t = 0

	cam_x = 63
	cam_y = 63
	cam_kx = 0
	cam_kdx = 0.3
	cam_tx = 0

	ship = {}

	ship.x = 63
	ship.y = 63
	ship.hw = 4
	ship.hh = 4
	ship.dx = 0
	ship.dy = 0
	ship.spr = 1
	ship.left = false
	ship.acl_x = 0.1
	ship.acl_y = 0.4
	ship.dcl_x = 0.02
	ship.dcl_y = 0.08
	ship.max_x = 2
	ship.max_y = 1
	ship.fire_del = 0

	bullets = {}
	bullets.rem_q = {}

	flashes = {}
	flashes.rem_q = {}
end

function _update60()
	t += 1

	-- update bullets

	arr_clr(bullets.rem_q)

	for i = 1, #bullets do
		local blt = bullets[i]
		bullet_update(blt)
		if blt.dead then
			add(bullets.rem_q, i)
		end
	end

	fst_del(bullets, bullets.rem_q)

	-- update flashes

	arr_clr(flashes.rem_q)

	for i = 1, #flashes do
		local fls = flashes[i]
		flash_update(fls)
		if fls.dead then
			add(flashes.rem_q, i)
		end
	end

	fst_del(flashes, flashes.rem_q)

	-- update ship

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

if btn(5) then ship.dx = 0 end
	ship.x += ship.dx
	ship.y += ship.dy

	if t % 4 == 0 then
		ship.spr += 1
		if ship.spr > 2 then
			ship.spr = 1
		end
	end

	local tar = 0
	local lead = 20
	if ship.left then
		tar = -lead + 4
	else
		tar = lead + 4
	end

	cam_kx = decay(cam_kx, cam_kdx)

	cam_tx = lerp(cam_tx, tar, 0.1)
	cam_x = ship.x + cam_tx + cam_kx
	cam_x = clamp(cam_x, 64, 248)


	-- shoot
	if btn(4) then
		ship.fire_del -= 1
		if ship.fire_del <= 0 then
			ship.fire_del = 15

			cam_kx = 0
			if (ship.left) cam_kx *= -1

			local mx = 4
			if (ship.left) mx *= -1
			-- new_flash(ship.x + mx,
			-- 	ship.y + 1,
			-- 	ship.left)

			local bx = 8
			if (ship.left) bx = -8
			bx += ship.x
			b = new_bullet(bx, ship.y + 2, 4)
		end
	else
		ship.fire_del = 0
	end
end

function _draw()
	cls()

	camera (0, 0)
	rectfill (0,0,127,127,1)

	camera(cam_x-64, cam_y-64)

	map(0, 0, 0, 0, 127, 20)

	spr(ship.spr,
		ship.x, ship.y,
		1, 1,
		ship.left, false)

	foreach(bullets, bullet_draw)
	foreach(flashes, flash_draw)

	-- line(cam_x+16, ship.y-4,
	-- 	cam_x+16, ship.y+12, 10)
	-- line(cam_x-16, ship.y-4,
	-- 	cam_x-16, ship.y+12, 10)
end

function lerp(a, b, t)
	return a + (b - a) * t
end

function fst_del(arr, idx)
	local l = #arr
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


__gfx__
000000000d0000000d000000000000000000000000000000000a770000099a700000499a00000099000000490000000400000000000000000000000000000000
000000000dd000000dd0000000000000000000000aa700000aaa770004999aaa0000049a00000049000000040000000000000000000000000000000000000000
007007000ddd00000ddd00000000000009aaa770aa0000009aaaa00004999aaa0000499900000000000000090000000000000000000000000000000000000000
000770000066cc000866cc000000000009aaaa709777770099aaa77000449a77000449aa00000049000000090000000900000000000000000000000000000000
0007700009d66cd089d66cd00000000009aaaa709777770099aaa77000449a77000449aa00000049000000090000000900000000000000000000000000000000
0070070000ddd66608ddd6660000000009aaa770aa0000009aaaa00004999aaa0000499900000000000000090000000000000000000000000000000000000000
0000000000ddd55600ddd55600000000000000000aa700000aaa770004999aaa0000049a00000049000000040000000000000000000000000000000000000000
0000000000d0000000d00000000000000000000000000000000a770000099a700000499a00000099000000490000000400000000000000000000000000000000
44444444b3bbb3bb43bbb3bbb3bbb4b4444444444444444400000000000000000000000000000000000000000000000000000000000000000000000000000000
4344b444b3bbb3bb44bbb3bbb3bbb3444444b444444b444400000000000000000000000000000000000000000000000000000000000000000000000000000000
434b43bbb3bbb3bb43bbb3bbb3bbb34444bb434bb4b4b44400000000000000000000000000000000000000000000000000000000000000000000000000000000
b3b4b33bb3bbb33b434bb33bb3bbb33443b4b33bb3bb433400000000000000000000000000000000000000000000000000000000000000000000000000000000
b3bbb3bbb3bbb3bb43bbb3bbb3bbb4b443bbb3bbb3bbb34400000000000000000000000000000000000000000000000000000000000000000000000000000000
33bbb3bb33bbb3bb44bbb3bb33bbb3b444bbb3bb33bbb34400000000000000000000000000000000000000000000000000000000000000000000000000000000
b3bb33bbb3bb33bb44bb33bbb3bb334444bb33bbb3bb33b400000000000000000000000000000000000000000000000000000000000000000000000000000000
b33bb3bbb33bb3bb434bb3bbb33bb3b4434bb3bbb33bb34400000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000002020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1410150000000000000000000000000000000000000000000000000000000000000000001410150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1211130000000000000000000000000000000000000000000000000000000000000000001211130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1211130000000000000000000000000000000000000000000000000000000000000000001211130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1211130000000000000000000000000000000000000000000000000000000000000000001211130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1211130000000000000000000000000000000000000000000000000000000000000000001211130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1211130000000000000000000000000000000000000000000000000000000000000000001211130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1211130000000000000000000000000000000000000000000000000000000000000000001211130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1211130000000000000000000000000000000000000000000000000000000000000000001211130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1211130000000000000000000000000000000000000000000000000000000000000000001211130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1211130000000000000000000000000000000000000000000000000000000000000000001211130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1211130000000000000000000000000000000000000000000000000000000000000000001211130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1211130000000000000000000000000000000000000000000000000000000000000000001211130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1211130000000000000000000000000000000000000000000000000000000000000000001211130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1211130000000000001600000000000000000000000000000000000000000000000000001211130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111010101010101010101010101010101010101010101010101010101010101010101111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
