-- Map creation and background
-- map images are 80 x 80
-- chars are all width 64

local tps = require 'tps'

local SCREEN_X, SCREEN_Y = 36, 27
local MAP_X, MAP_Y = 63, 48     -- about 1.75x

local Ob = {}

local b = string.byte

-- 1 tile = 1 world unit = is 80 px
local sheet_map = tps.load_sheet('art/sheet_map.lua', 1/79.9)

local LOOKUP_OBJ = {
    [b'A'] = { 'sheet', sheet_map, 'obj/rock_a_1x1' },
    [b't'] = { 'sheet', sheet_map, 'obj/tree_a_1x1' },
    [b'.'] = { 'sheet', sheet_map, 'bg/grass_1' },
    -- for just loading random textures
    -- [b'A'] = { 'txtr',  'art/tree_a.png', 1/80 },
}

-- Return a function that moves the map camera by dx and dy every frame
-- until the key that triggered the mover is released.
-- Mostly for testing
local s_move_actions = {}
function Ob:make_mover(dx,dy)
	local function move_infinitely()
		while true do
			g_map_layer.camera:addLoc(dx/10, dy/10)
			coroutine.yield()
		end
	end

	local function start_or_stop_mover(key,down)
		-- always stop, just in case the calls aren't properly paired
		if s_move_actions[key] then
			s_move_actions[key]:stop()
			s_move_actions[key] = nil
		end
		if down then
			s_move_actions[key] = MOAICoroutine:new ()
			s_move_actions[key]:run(move_infinitely)
		end
	end
	
	return start_or_stop_mover
end

-- Create a prop (and maybe some background grass) at world location (tx, ty).
--  tx,ty       Worldspace location (1 unit = 1 tile)
--  desc        An entry in the LOOKUP_OBJ table.  Can be:
--    { 'sheet', MOAIGfxQuadDeck2D, sprite name [, scale] }
--    { 'txtr',  texture filename [, scale] }
--
function Ob:_make_map_tile(tx, ty, desc)
	if not desc then return end

    if desc[1] == 'sheet' then
        local sheet, sprite, scale = desc[2], desc[3], desc[4]
        local is_backdrop = false
        if sprite == 'bg/grass_1' then
            -- grass gets randomized
            if math.random() < 0.5 then sprite = 'bg/grass_2' end
            is_backdrop = true
        else
            is_backdrop = false
        end

        local prop = sheet:make(sprite, scale)
        if is_backdrop then
            prop:setLoc(tx,ty)
            g_map_layer:insertProp(prop)
            return prop
        else
            -- Create collision, then parent bg and fg props to it
            local body = g_box2d:addBody ( MOAIBox2DBody.STATIC )
            body:addRect(0,0,1,1)
            body:setTransform(tx, ty, 0)

            local bg_prop = sheet:make('bg/grass_1', scale)
            bg_prop:setParent(body)
            g_map_layer:insertProp(bg_prop)

            prop:setParent(body)
            g_map_layer:insertProp(prop)
        end
        
    elseif desc[1] == 'txtr' then
        -- texture name, scale
        local txtr_name, scale = desc[2], desc[3]
        local prop = MOAIProp2D.new()
        prop:setDeck(tps.load_single(txtr_name, scale))
        prop:setLoc(tx,ty)
        g_map_layer:insertProp(prop)
        return prop
    end

end

function Ob:_read_map(filename)
	local function reversed(array)
		local new = {}
		for i,k in ipairs(array) do
			new[(#array)-i+1] = k
		end
		return new
	end

	local grid = {}

	-- want to read the file from the "bottom up" because that's
	-- the way y increases.
	local lines = {}
	for line in io.lines(filename) do lines[#lines+1] = line end
	lines = reversed(lines)

	for ty,line in ipairs(lines) do
		ty = ty + 1
		grid[ty] = {}
		for tx=1,string.len(line) do
			local desc = LOOKUP_OBJ[string.byte(line, tx)]
			local prop = self:_make_map_tile(tx,ty, desc)
			grid[ty][tx] = prop
		end
		if string.len(line) == 0 then
			break
		end
	end
	return grid
end

function Ob:init()
	self.rows = self:_read_map('levels/1.txt')

	g_input.keymap.w = self:make_mover(0,1)
	g_input.keymap.a = self:make_mover(-1,0)
	g_input.keymap.s = self:make_mover(0,-1)
	g_input.keymap.d = self:make_mover(1,0)

end

return Ob