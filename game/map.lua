-- Map creation and background
-- map images are 80 x 80
-- chars are all width 64

local tps = require 'tps'

local SCREEN_X, SCREEN_Y = 36, 27
local MAP_X, MAP_Y = 63, 48     -- about 1.75x

local COLLISION_LAYER_ALL = 1
local COLLISION_LAYER_PEDESTRIAN = 2

local Ob = {}

local b = string.byte

-- 1 tile = 1 world unit = is 80 px

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

function Ob:_create_layer(tiled, layer, is_obj)
    local gdai = tiled.get_deck_and_index
    for x=0,layer.width-1 do
        for row=0,layer.height-1 do
            -- rows are specified from top-down
            local y = layer.height - row
            local gid = layer.data[( row * layer.width ) + x + 1]
            if gid > 0 then
                local deck, idx = gdai(tiled, gid)

                local prop = MOAIProp2D.new()
                prop:setDeck(deck)
                prop:setIndex(idx)
                prop:setLoc(x,y)
                if is_obj then
                    g_char_layer:insertProp(prop)
                    prop:setPriority(-y+1.2)
                else
                    g_map_layer:insertProp(prop)
                end
            end
        end
    end
end

function Ob:_create_collision(layer, collision_layer)
    for x=0,layer.width-1 do
        for y=0,layer.height-1 do
            local idx = layer.data[( y * layer.width ) + x + 1]
            if idx ~= 0 then
                local body = g_box2d:addBody ( MOAIBox2DBody.STATIC )
                body:addRect(0,0,1,1)
                body:setTransform(x, layer.height-y, 0)
            end
        end
    end
end

function Ob:query_collision(x,y)
    local layer = self.tiled_layers[4]
    local index = (layer.height - y) * layer.width + x
    local data = layer.data[index]
    return data
end

function Ob:get_bounds()
    if MAP_NAME == 'art/tiled_map3.lua' then
        -- there's a big strip of non-playable area around the map
        return 20,14, 80,58
    else
        local layer = self.tiled_layers[4]
        return 1, 1, layer.width-1, layer.height-1
    end
end

function Ob:init()
    self.tiled = tps.load_tilesheet(MAP_NAME or 'art/tiled_map.lua')
    self.tiled_layers = self.tiled.layers

    -- 1: background
    -- 2: background top
    -- 3: objects
    -- 4: bear collisions
    -- 5: victim collisions
    self:_create_layer(self.tiled, self.tiled_layers[1])
    self:_create_layer(self.tiled, self.tiled_layers[2])
    self:_create_layer(self.tiled, self.tiled_layers[3], g_char_layer)
    self:_create_collision(self.tiled_layers[4], COLLISION_LAYER_ALL)
    self:_create_collision(self.tiled_layers[5], COLLISION_LAYER_PEDESTRIAN)
end

function Ob:setup_debug_input()
	g_input.keymap.i = self:make_mover(0,1)
	g_input.keymap.j = self:make_mover(-1,0)
	g_input.keymap.k = self:make_mover(0,-1)
	g_input.keymap.l = self:make_mover(1,0)
end

return Ob