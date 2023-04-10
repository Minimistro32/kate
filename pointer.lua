--include these in their respective callback functions
function init_point(enabled)
	point_x = 64
	point_y = 64
    return enabled --doesn't do anything at the minute <shrug>
end

function upd_point()
	if (btn(0)) then
		point_x-=1
	end
	if (btn(1)) then
		point_x+=1
	end
	if (btn(2)) then
		point_y-=1
	end
	if (btn(3)) then
		point_y+=1
	end
end

function drw_point(cursor_col, point_col)
	prev = color(cursor_col)
	line(point_x-2,point_y,point_x+2,point_y)
	line(point_x,point_y+2,point_x,point_y-2)
	print(point_x, 1, 1)
	print(point_y, 1, 7)
	pset(point_x, point_y,point_col)
	color(prev)
end