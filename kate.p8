pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- INIT
function _init()
	poke(0x5f2e,1) --persist pal swap
	pal({1,2,3,4,5,6,7,10,134,133,132,128,13,11,15,16}, 1)

	pal_swap_screen_segment()
	
	timer = 0
	x_scroll = 16
	can_scroll_back = false

	x_pos = 64
	y_pos = 56
	facing_cam = true

	house_palettes = { --can't use 14, 12, 6, or 8
		{	--tan
			front = 15,
			side = 9
		},
		{	--brown
			front = 4,
			side = 11
		},
		{	--purple
			front = 2,
			side = 10
		},
		{	--blue
			front = 1,
			side = 13
		}
	}
	
	houses = {}
	add_houses(6)
	should_cycle_once = true
end

function add_houses(n)
	for i=0,n-1 do
		rng = rnd(100)
		pal_i = 1
		if rng < 50 then
			pal_i = 1
		elseif rng < 80 then
			pal_i = 2
		elseif rng < 90 then
			pal_i = 3
		else
			pal_i = 4
		end
		add(houses, house_palettes[pal_i])
	end
end


-->8
--UPDATE
function _update()
	--player data
	kate_scale = min(max(((y_pos-4)/32)^2, 0.4), 2) --literal magic
	
	--input
	speed_scale = min(((y_pos)/56)^2, 1) --literal magic (56?)	
	moving = btn() & 0x0f > 0

	if (btn(0)) then
		if y_pos > 39 and x_pos < 12 and x_scroll % 128 > 10 then
			x_scroll-=0.5
		elseif x_pos > -4 then
			x_pos-=(1*speed_scale)
		end
		facing_cam = false
	end
	if (btn(1)) then
		if y_pos > 39 and x_pos > 80 then
			x_scroll+=0.5
		else
			x_pos+=(1*speed_scale)
		end
		facing_cam = true
	end
	if (btn(2)) and y_pos > 22.5 then
		y_pos-=(1*speed_scale)
		facing_cam = false
	end
	if (btn(3)) and y_pos < 56 then
		y_pos+=(1*speed_scale)
		facing_cam = true
	end

	--cycles houses
	if x_scroll % 128 == 0 and should_cycle_once then
		for i=0,2 do
			add_houses(1) 
			deli(houses, 1)
		end
		should_cycle_once = false
	else
		should_cycle_once = true
	end
	
	timer += 1
end

-->8
--DRAW
function _draw()
	cls(3)
	rectfill(0,56,128,128,0)
	palt(0, false)
	palt(14, true)
	
	-- print(x_pos, y_pos)
	-- print(x_scroll % 128)
	
	--sidewalk
	for i=0,4 do
		spr(128,0 + i*32 - ((x_scroll*2) % 32),56,4,4)
	end
	
	--houses
	for i, palette in pairs(houses) do
		house_x = 19 + i*32 + flr(i/4)*32 - (x_scroll % 128)
		draw_house(house_x,21,0.001953125*house_x+0.375,palette)
	end
	
	
	sspr(40 + 40 * tonum(facing_cam) + 8 * tonum(moving) * (flr(timer / 5) % 4), 0, 8, 16, x_pos, y_pos, 8 * kate_scale, 16 * kate_scale)
	

	palt()
end

function draw_kate_face()
	scale = 1
	sspr(64,32,30,32,16,96,30*scale,32*scale)
end

function draw_house(x, y, angle, palette)
	--data
    d=10
    w=18
    h=-10
    theta_y=30
    theta_x=angle
    pitch=30 --of roof
    overhang=2

	--draw
	x_off = sin(theta_x)*d
    y_off = sin(theta_y/360)*d
    hang_off = tan(pitch/360)*(overhang)
	roof_off = sin(pitch/360)*(w/2) --peak
	--side
	for i = h,0 do
		line(x+((w/2)*sgn(x_off))+x_off,y+(-h/2)+y_off+i,x+((w/2)*sgn(x_off)),y+(-h/2)+i,palette["side"])
	end
	--front
	rectfill(x-(w/2),y+(h/2),x+(w/2),y-(h/2),palette["front"]) --todo: remove this rectfill change polyfill below to pentagon
	polyfill({x-(w/2),y+(h/2),x,y+(h/2)+roof_off,x+(w/2),y+(h/2),x,y+(h/2)},palette["front"])
	--roof
	polyfill({x-(w/2)-overhang,y+(h/2)-hang_off,x+x_off-(w/2)-overhang,y+y_off+(h/2)-hang_off,x+x_off,y+y_off+(h/2)+roof_off,x,y+(h/2)+roof_off},12)
	polyfill({x+x_off,y+y_off+(h/2)+roof_off,x,y+(h/2)+roof_off,x+(w/2)+overhang,y+(h/2)-hang_off,x+x_off+(w/2)+overhang,y+y_off+(h/2)-hang_off},12)
	--window
	rectfill(x-6,y+1,x-1,y-2,12)
	rectfill(x-5,y,x-2,y-1,6)
	--door
	rectfill(x+2,y,x+5,y+5,12)
	--knob
	pset(x+4,y+3,8)
end

-->8
--HELPERS
function tan(x) return sin(x) / cos(x) end

function polyfill(coords, col)
	--build_obj
    points={}
    for i=1,8,2  do
        add(points,{x=coords[i],y=coords[i+1]})
    end

    local xl,xr,ymin,ymax={},{},129,0xffff
    for k,v in pairs(points) do
        local p2=points[k%#points+1]
        local x1,y1,x2,y2=v.x,flr(v.y),p2.x,flr(p2.y)
        if y1>y2 then
            y1,y2,x1,x2=y2,y1,x2,x1
        end
        local d=y2-y1
        for y=y1,y2 do
            local xval=flr(x1+(x2-x1)*(d==0 and 1 or (y-y1)/d))
            xl[y],xr[y]=min(xl[y] or 32767,xval),max(xr[y] or 0x8001,xval)
        end
        ymin,ymax=min(y1,ymin),max(y2,ymax)
    end
    for y=ymin,ymax do
        rectfill(xl[y],y,xr[y],y,col)
    end
end

-->8
--JUNK
function draw_pal()
	for c=0,15 do
		local x = (c%4)*32
		local y = flr(c/4)*32
		rectfill(x, y, x+31,y+31, c)
	end
end

function draw_junk()
	palt(6, true)
	spr(4,64,64,2,2)
	palt()
end

function pal_swap_screen_segment()
	--use separate palette
	poke(0x5f5f,0x10)
	pal({1,2,143,4,5,6,7,142,134,133,132,128,13,14,15,16}, 2)
	--on bottom section
	memset(0x5f7b,0xff,7)
end

__gfx__
eecccceeeecccceeeecccceeeecccceeeecceeeeeecccceeeecccceeeecccceeeecccceeeecccceeeecccceeeecccceeeecccceeeecccceeeeccccee00000000
eefccceeeefccceeeefccceeeefccceeecccceeeeefccceeeefccceeeefccceeeefccceeeefccceeeeccfceeeeccfceeeeccfceeeeccfceeeeccfcee00000000
eeffcceeeeffcceeeeffcceeeeffcceeeffccceeeeffcceeeeffcceeeeffcceeeeffcceeeeffcceeeecfffeeeecfffeeeecfffeeeecfffeeeecfffee00000000
eeffcceeeeffcceeeeffccee1effcceeefffcceeeeffcceeeeffcceeeeffcceeeeffcceeeeffcceeeecfffeeeecfffeeeecfffeeeecfffeeeecfffee00000000
eeefcceeeeefcceefeefccee1eefcceeeeefcceeeeefcceeeeefcceeeeefcceeeeefcceeeeefcceeeeccfeeeeeccfeeeeeccfeeeeeccfeeeeeccfeee00000000
eef1cceeeef1cceefef1ccee1ef1cceeeef1cceeeef1cceeeef1cceeeef1cceeeef1cceeeef1cceeeecc11eeeecc11eeeecc11eeeecc11eeeecc11ee00000000
eef1cceefef1cceeeff1cceeeff1cceeeef1c1eeeef1cceeeef1cceeeef1cceeeef1cceeeef1cceeeecc01eeeecc01eeeecc01eeeecc01eeeecc01ee00000000
eef1cfeeeff1cfeeee11cfeeeef1c1eeeef111eeeef1c1eeeef1c1eeeef1c1eeeef1c1eeeef1c1eeeefc1feeeefc1feeeefc1feeeefc1feeeefc1fee00000000
eeffffeeee111feeee111feeeef111eeeef111eeeef111eeeef111eeeef111eeeef111eeeef111eeeef11feeeef11feeeef11feeeef11feeeef11fee00000000
ee111feeee111feeee111feeeef111eeeef111eeeef111eeeef111eeeef111eeeef111eeeef111eeeef11feeeef11feeeef11feeeef11feeeef11fee00000000
ee111feeee111feeee111feeee1111eeeef111eeee1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee1111ee00000000
ee1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee1111ee00000000
ee1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee111eeeee1111eeee1111eeee1111eeee1111eeee1111eeee1111ee00000000
eeeffeeeeeeffeeeeeeffeeeeeeffeeeeeeffeeeeeeffeeeeefefeeeeefefeeeeeeffeeeeefefeeeeeeffeeeeeefefeeeeefefeeeeeffeeeeeefefee00000000
eeeffeeeeeeffeeeeeeffeeeeeeffeeeeeeffeeeeeeffeeeee0efeeeeefefeeeeeef0eeeeefefeeeeeeffeeeeeefe0eeeeefefeeeee0feeeeeefefee00000000
eee00eeeeee00eeeeee00eeeeee00eeeeee00eeeeee00eeeeeee0eeeee0e0eeeeee0eeeeee0e0eeeeee00eeeeee0eeeeeee0e0eeeeee0eeeeee0e0ee00000000
88888888888888888888888888888888888888882222222222222222222222222222222222222222111111111111111111111111111111111111111100000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000eef111ee000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000eef111ee000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000ee1111ee000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000e11111ee000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000e11111ee000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000efeefeee000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000e0eefeee000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000eeee0eee000000000000000000000000000000000000000000000000000000000000000000000000
11111111111115d555d11111111111cccc11111111111115d555d11111111111aaccccccccccc59aaa9aacacaaaaaaee66666666666666666666666666666666
111111111155d5dd44411111111111cccc111111111155d5dd44411111111111cccccccccaaa9599999acccccaaaaaee66666666666666666666666666666666
111111111d554f4444455111111111cccc111111111d554f4444455111111111ccccccccc95b939b444aaccccaaaaaee66666666666666666666666666666666
11111155554554ff55511151111111cccc11111155554554ff55511151111111ccccccaa5545b9ff5bbaccaacccccaee00666700777776666666666666666666
000115515d55ef7ff4506051111111cccc000115515d55ef7ff4506051111111ccccc5aaa9aa9ffff95c9caccccccaee66000077777776666662666626666666
001155515654fffffd45d011111111cccc001155515654fffffd45d011111111ccccaaac595437ff399a9ccacccccaee60000007777777766662222222226666
00005511514effffddd40551111111cccc00005511514effffddd40551111111cccc55ac5c99ffff99990b5aacccccee60707007777777766662feeeefff2666
00015510056fffff666d1001510000cccc00015510056fffff666d1001510000cccc5accca9ff3f39999ccca5accccee6000000777777776662eeeeeeefff266
00155510506fdd66665d5505510000cccc00155510506fdd66665d5505510000ccc55accac6f993939995acaaaccccee66000077777777766620ee0eeeeff266
005111110466d4d66dddd015150000cccc005111110466d4d66dddd015150000ccaacaaac9639993999990caaaccccee6677777777777776688888eeeeeef226
015511150d6eddd66d4dd001150000cccc015511150d6eddd66d4dd001150000ca5aaaca0969999f699990caa5ccccee6666777777777666684848eeeeeee262
1155551006666d6f6dddd005110000cccc1155551006666d6f6dddd005110000aa55aac00666996f399990c5aa00ccee6666707070707666688888eefffee266
15555100566666ff66d66115111000cccc15555100566666ff66d66114441000c5555a00566666ff66999ca5aca000ee6666606060606666662eeeefffffe266
1555510056ff66ff66666555551000cccc1555510056ff66ff66666555551000aa555c0c56ff66ff69666a555aacccee66666060606066666662222222222666
55555100066ff6eedd66d55555010dcccc55555100066ff6eedd66d55555010da9955c00c66ff639996695a5aaca0dee66666060606066666666262666262666
5dd55100066ff66f6666d055550100cccc5dd55100066ff66f6666d05555010099555c00c66ff66f69669a5a5acc00ee66666666666666666666666666666666
dd555515566666666666d0d5150165ccccdd555515566666666666d0d515016599555acaa96666666666909ac5cc65ee66666666666666666666666666666666
55d55d515566666d6d66d055d51566cccc55d55d515566666dee66d055d5156655955a5aaa6666996999905ad5ca66ee66666666666666666666666666666666
555505555566666e6ddd505d515166cccc555505555566666e22dd505d515166555ac55a5a96666369990c595aaa66ee66666666666666666666666666666666
51151555055d666dd46d011551555dcccc51151555055d666d226d011551555d5ca5caa5c559663999990ac55c5559ee66666666666666666666666666666666
15515555150d666d4d6d001d555d56cccc15515555150d666d2d6d001d555d56a5aca5a5aac9666949990cc955ad56ee66666666666666666666666666666666
1d5115d55550d66666d00555555556cccc1d5115d55550d66666d00555555556195aa59aaa5c9966669005a55a5556ee66666666666666666666666666666666
11155d55511555dd6d000155655d5dcccc11155d55511555dd6d000155655d5d11a55955aac5559999c00aa5655d59ee66666666666666666666666666666666
1115555515155dd55100150d655511cccc1115555515155dd55100150d65551111aa555aaaaa59995c00a5c96555ccee66666666666666666666666666666666
11050d0555515ddd5000515561d510cccc11050d0555515ddd5000515561d51011c5caca55aa59995cc05aa56a95a0ee66666666666666666666666666666666
1105050515551ddd5000555565d550cccc1105050515551ddd5000555565d55011c5cc05a555a99950c05aa565d5a0ee66666666666666666666666666666666
15151110001155d550001155d5d550cccc15151110001155d550001155d5d55015a5acc00ccaa5955cc0ac55d5d55cee66666666666666666666666666666666
105d5d100000500550000555555551cccc105d5d100000500550000555555551115d5a1c0ccc5cc55ccccaaa55a551ee66666666666666666666666666666666
110555111005051551110d55551551cccc110555111005051551110d5555155111c5a5111cc5c5a55acccd5555aa51ee66666666666666666666666666666666
11015551100051510111105ddd5155cccc11015551100051510111105ddd5155110155ac100caaacca11ac59dd5a5aee66666666666666666666666666666666
11010d5110000151011110d5055151cccc11010d5110000151011110d50551511101ca5110000caacc111cd5c55a5aee66666666666666666666666666666666
110011111100005000111155055155cccc110011111100005000111155055155110011111c00cc5cc011cc55c55ca5ee66666666666666666666666666666666
6666665666666566666665666666656600000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000000000000000000000000
6666665666666566666665666666656600000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000000000000000000000000
6666665666666566666665666666656600000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000000000000000000000000
6666656666666656666665666666566600000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000000000000000000000000
6666656666666656666665666666566600000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000000000000000000000000
6666656666666656666665666666566600000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000000000000000000000000
6666656666666656666665666666566600000000000000000000000000000000eeeeeeeeeeeeeecccceeeeeeeeeeeeee00000000000000000000000000000000
5555555555555555555555555555555500000000000000000000000000000000eeeeeeeeeeeecccccccceeeeeeeeeeee00000000000000000000000000000000
5555555555555555555555555555555500000000000000000000000000000000eeeeeeeeeecccccccccccceeeeeeeeee00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000eeeeeeeecccccccccccccccceeeeeeee00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000eeeeeecccccccccccccccccccceeeeee00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000eeeeccccccccccccccc00cccccceeeee00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000eeeeeccccccccccccffff00ccccceeee00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000eeeee9cccccccccffffffff00cccceee00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000eeeee999cccccffffffffffff00cccee00000000000000000000000000000000
0008888000088880000888800008888000000000000000000000000000000000eeeee9999ccfffffffffffffffff0cce00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000eeeee99999fffffffffffffffffffeee00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000eeeee99999fffffffffffffffffffeee00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000eeeee99999fffffffffffffffffffeee00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000eeeee99999fffccccccffffffffffeee00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000eeeee99999fffc6666cffffffffffeee00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000eeeee99999fffc6666cffccccffffeee00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000eeeeee9999fffccccccffccccffffeee00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000eeeeeee999fffffffffffccccffffeee00000000000000000000000000000000
6666666656666666656666666666566600000000000000000000000000000000eeeeeeee99fffffffffffcc8cffffeee00000000000000000000000000000000
6666666656666666656666666666566600000000000000000000000000000000eeeeeeeee9fffffffffffccccffffeee00000000000000000000000000000000
6666666656666666656666666666566600000000000000000000000000000000eeeeeeeeeefffffffffffccccffffeee00000000000000000000000000000000
6666666656666666656666666666566600000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000000000000000000000000
6666666566666666665666666666566600000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000000000000000000000000
6666666566666666665666666666566600000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000000000000000000000000
6666666566666666665666666666566600000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000000000000000000000000
6666666566666666665666666666566600000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000000000000000000000000
__sfx__
000c00000010000100000000000000000000000000000000000000000000000000000000000000000000000007150071500715007150051500515005150051500415004150041500415002150021500215002150
000c00200c5500c5500c5500c55018550185501855018550175501755017550175501555015550155501555010550105501055011550135501355013550155501355013550135501355010550105501055010550
010c00000e5500e5500e5500e550135501355013550135500e5500e5500e5500e5501355013550135501355010550105501055018550175501755017550155501355013550135501355013550135501355013550
000c00000e5500e5500e5500b5500e5500e5500e55013550175501755017550175501555015550155501555013550135501355013550135501355013550135501355013550135501355000000000000000000000
010c00001855018550185501855018550185501855018550185501855018550185501755017550175501555013550135501355013550135501355013550135501355013550135501355010550105501055011550
010c00000000000000000000000010553105531055300000105501055010550105500000000000000000000010553105531055300000105501055010550105500000000000000000000000000000000000000000
000c00001355013550135501355015550155501555015550105501055010550105501355013550135501355011550115501155011550115501155011550115501155011550115501155000000000000000000000
000c00000c1500c1500c1500c150071500715007150071500c1500c1500c1500c1500d1500d1500d1500d1500e1500e1500e1500e1500b1500b1500b1500b1500915009150091500915007150071500715007150
000c0000175501755017550175501755017550175501755017550175501755017550155501555015550135501155011550115501155011550115501155011550115501155011550115500e5500e5500e55010550
000c00000000000000000000000011553115531155300000115501155011550115500000000000000000000011500115001150011500115531155311553000001155011550115501155000000000000000000000
010c00000c1500c1500c1500c150071500715007150071500c1500c1500c1500c150071500715007150071500c1500c1500c1500c150071500715007150071500c1500c1500c1500c15007150071500715007150
000c00000e1500e1500e1500e150071500715007150071500e1500e1500e1500e150071500715007150071500e1500e1500e1500e150071500715007150071500e1500e1500e1500e15007150071500715007150
000c00000e1500e1500e1500e150071500715007150071500e1500e1500e1500e150071500715007150071500c1500c1500c1500c150101501015010150101500e1500e1500e1500e15007150071500715007150
010c00001155011550115501155013550135501355013550175501755017550175501a5501a5501a5501a55013550135501355013550135501355013550135501355013550135501355013550135501355013550
000c00001855018550185501855018550185501855018550185501855018550185501755017550175501555013550135501355013550135501355013550135501355013550135501355010550105501055011550
000c00001355013550135501355018550185501855018550175501755017550175501615016150161501615015550155501555015550155501555015550155501555015550155501555000000000000000000000
000c00001a5501a5501a5501a5501855018550185501855017550175501755017550155501555015550155501355013550135501355013550135501555015550135501355010550105500e5500e5500c5500c550
000c00001355013550135501355013550135501355013550155501555015550155501755017550175501755018550185501855018550185501855018550185501855018550185501855500000000000000000000
000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c00000c1500c1500c1500c1500c1500c1500c1500c1500e1500e1500e1500e150101501015010150101501115011150111501115002150021500215002150091500915009150091500c1500c1500c1500c150
010c0000051500515005150051500515005150051500515006150061500615006150051500515005150051500715007150071500715007150071501515015150131501315010150101500e1500e1500c1500c150
010c00001315013150131501315513150131501315013155071500715007150071550715007150071500715500150001500015000150001500015000150001500015000150001500015500000000000000000000
__music__
00 01424344
00 02424344
00 01424344
00 03404300
00 0405470a
00 06474307
00 0809430b
00 0d42430c
00 0e05430a
00 0f424313
00 10424314
00 11424315

