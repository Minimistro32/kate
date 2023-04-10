-- SAMPLE TEXTBOX
-- text_box={
--     x1=40,
--     y1=92,
--     x2=122,
--     y2=120,
--     sfx=0,
--     text=nil,
--     buffer="The quick brown fox jumped over the lazy dog. It was remarkable, I'm so glad I was able to see it.",--\rMOAR",
--     start=nil,
--     flushed=false,
--     paginated=false
-- }

function init_text_box()
	return {
        --PUBLIC
        is_active=false,
		sfx=0,

        --PRIVATE
        --pos data
		x1=40,
		y1=92,
		x2=122,
		y2=120,
        --state
        print_chars=nil, --preprocessed letters
		box_text=nil,--words on screen
		buffer="",--\r for page breaks",
		t_start=nil,
		box_full=true, --filled up the screen
		ellipsis=false
	}
end

function queue_text_box(tb, text)
    if tb.box_text == "" then
        tb.box_text..=text
    else
        tb.buffer..=text
    end
end

function cycle_text_box(tb)
    tb.is_active = true

    if tb.box_full then --resets box animation when full
        tb.t_start=time()
        tb.box_text=nil
        tb.ellipsis=false
        tb.box_full=false
    end
    if tb.box_text == nil then
        local screens = split(tb.buffer,'\r')
        tb.box_text = screens[1]
        tb.is_active = tb.box_text != ''
        tb.buffer=sub(tb.buffer,#tb.box_text+2) --one to move to next screen, two for \r
    end
    
    --add linebreaks
    tb.print_chars = split(tb.box_text,"")
    local x=tb.x1
    local y=tb.y1
    local last_space=nil
    
    for i=1,#tb.print_chars do
        if tb.print_chars[i]==" " then
            last_space=i
        end
        
        if x >= tb.x2 then
            if last_space == nil then
                add(tb.print_chars,'\n',i)
            else
                tb.print_chars[last_space]='\n'
            end
            x=tb.x1+((i-last_space)*4)
            y+=6
            
            if y >= tb.y2 then
                --? add ... and boot three chars to buffer
                tb.buffer=sub(tb.box_text,-(#tb.print_chars-last_space))..(tb.buffer!="" and '\r'..tb.buffer or "")
                tb.box_text=sub(tb.box_text,1,-(#tb.print_chars-last_space+1))
                for i=1,#tb.print_chars-last_space+1 do
                    deli(tb.print_chars)
                end
                tb.ellipsis=true
                break
            end

            last_space=nil
        else
            x+=4
        end
    end
end

--DRAW
function drw_text_box(tb, speed)
    print(tb.print_chars[#tb.print_chars], 3,3)
    print(tb.ellipsis, 3,20)

	local y=tb.y1
	local x=tb.x1
	for i, letter in pairs(tb.print_chars) do
		if i >= (time() - tb.t_start) * speed then
			return
		end
		if letter=='\n'then
			y+=6
			x=tb.x1
		else
			print(letter,x,y,7)
			x+=4
		end
	end
	if tb.ellipsis then
		print('...',tb.x1,y+6)
	end

	--clear the text
	tb.box_full=true
end