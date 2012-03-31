-- Map creation and background
-- map images are 80 x 80
-- chars are all width 64

local tps = require 'tps'

local SCREEN_X, SCREEN_Y = 36, 27
local MAP_X, MAP_Y = 63, 48     -- about 1.75x

local Ob = {}


-- Return a function that moves the map camera by dx and dy every frame
-- until the key that triggered the mover is released.
-- Mostly for testing
local s_move_actions = {}
function Ob:make_mover(dx,dy)
	local function move_infinitely()
		while true do
            print('moving',dx,dy)
			g_map_layer.camera:addLoc(dx/10, dy/10)
            print(g_map_layer.camera:getLoc())
			coroutine.yield()
		end
	end

	local function start_or_stop_mover(key,down)
		-- always stop, just in case the calls aren't properly paired
        print('moving',key,down)
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

function Ob:_make_map_base(tx, ty, desc)
	if not desc then return end
    local prop = MOAIProp2D.new()
    prop:setDeck(desc)
    prop:setLoc(tx, ty)
    g_map_layer:insertProp(prop)
    return prop
end

function Ob:_read_map(filename)
	local function reversed(array)
		local new = {}
		print('len',#array)
		for i,k in ipairs(array) do
			new[(#array)-i+1] = k
		end
		return new
	end

	local byte = string.byte
	local lookup_obj = {
		[byte('A')] = tps.load_single('art/rock_a.png', 1/80),
		[byte('t')] = tps.load_single('art/tree_a.png', 1/80),
		[byte('.')] = tps.load_single('art/grass_1.png',1/80),
	}

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
			local desc = lookup_obj[string.byte(line, tx)]
			local prop = self:_make_map_base(tx,ty, desc)
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