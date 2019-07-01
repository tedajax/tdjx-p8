pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

particle_types={
	"point",
	"circle",
	"rect",
}

particle=class({
	x=0,y=0,					-- position
	dx=0,dy=0,			-- velocity
	ddx=0,ddy=0,	-- acceleration
	ox=0,oy=0,			-- origin
	ptype="point",
	rad=0,
	w=0,h=0,
	t_life=0,
	life_dist=0,
})

function init_pfx()
	particles={}
end

function add_pfx(p)
	return add(particles,
		particle:new(p))
end

function update_particles(dt)
	for p in all(particles) do
		p.dx+=p.ddx*dt
		p.dy+=p.ddy*dt
		p.x+=p.dx*dt
		p.y+=p.dy*dt
		
		p.t_life-=dt
		
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000