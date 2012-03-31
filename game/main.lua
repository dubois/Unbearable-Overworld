local tps = require 'tps'

local WIN_X, WIN_Y = 1280, 1024
local MAP_ZOOM = 30

-- ----------------------------------------------------------------------
-- Rendering, viewport management
-- ----------------------------------------------------------------------

local function init_render()
    MOAISim.openWindow ( "Unbearable", WIN_X, WIN_Y )

	-- Set up quadrants
	-- nb: It's setSize(x0,y0,x1,y1), not setSize(x0,y0,w,h)

	--
	-- "map chase" minigame
	--

	-- Map viewport is zoomed in quite a bit, because the map
	-- uses 1 unit = 1 meter = 1 tile
    g_view_map = MOAIViewport.new ()
    g_view_map:setSize ( 0,0, WIN_X/2, WIN_Y )
    g_view_map:setScale ( WIN_X/2 / MAP_ZOOM, WIN_Y / MAP_ZOOM )

    g_map_layer = MOAILayer2D.new ()
    g_map_layer:setViewport ( g_view_map )
	g_map_layer.camera = MOAICamera2D:new ()
	g_map_layer:setCamera(g_map_layer.camera)

	local world = MOAIBox2DWorld.new ()
	world:setGravity ( 0, 0 )
	world:setUnitsToMeters ( 1 )
	world:start()
	g_map_layer.world = world
	g_map_layer:setBox2DWorld ( world )

	--
	-- "bear hug" minigame
	--

	g_view_bear = MOAIViewport.new ()
	g_view_bear:setSize ( WIN_X/2, 0, WIN_X, WIN_Y )
	g_view_bear:setScale ( WIN_X/2, WIN_Y )

	g_bear_layer = MOAILayer2D.new ()
	g_bear_layer:setViewport ( g_view_bear )
	g_bear_layer.camera = MOAICamera2D:new ()
	g_bear_layer:setCamera(g_bear_layer.camera)

	-- Render quadrants
    MOAISim.pushRenderPass ( g_bear_layer )
    MOAISim.pushRenderPass ( g_map_layer )
end

-- Moves the viewports around
-- state 0: map on left, bear on right
-- state 1: bear on left, map on right
local s_viewport_state = 0
local function _get_viewport_state() return s_viewport_state end
local function _set_viewport_state(state)
    s_viewport_state = state
    if s_viewport_state == 0 then
        g_view_map:setSize ( 0,0, WIN_X/2, WIN_Y )
        g_view_bear:setSize ( WIN_X/2, 0, WIN_X, WIN_Y )
    else
        g_view_bear:setSize ( 0,0, WIN_X/2, WIN_Y )
        g_view_map:setSize ( WIN_X/2, 0, WIN_X, WIN_Y )
    end
end

-- ----------------------------------------------------------------------
-- Test scaffolding
-- ----------------------------------------------------------------------

function init_test()
    local quads_test = tps.load_sheet ( 'art/sheet_out.lua' )
    local quads_map = tps.load_sheet ( 'art/sheet_map.lua',  0.5 )

    -- local prop = MOAIProp2D.new()
    -- prop:setDeck( tps.load_single('grass_1.png') )
    -- prop:setLoc(100,-100)
    -- g_bear_layer:insertProp(prop)

    local prop = quads_map:make('bg/grass_1')
    prop:setLoc(100,-100)
    g_bear_layer:insertProp(prop)

    local prop = quads_map:make('bg/grass_2', 2)
    prop:setLoc(130,-130)
    g_bear_layer:insertProp(prop)

    local prop = quads_test:make('cathead')
    prop:setLoc ( -100, -100 )
    g_bear_layer:insertProp ( prop )

    local prop = quads_test:make('two')
    prop:setLoc ( 0, 0 )
    g_bear_layer:insertProp ( prop )

    local prop = quads_test:make('one')
    prop:setLoc ( 100, 100 )
    g_bear_layer:insertProp ( prop )
end

function main()
    init_render()
	init_test()

	-- Should come before map init
	g_input = require 'input'
	g_input:init()

    g_map = require 'map'
    g_map:init()

    -- simple cycle through viewport states, for testing
	g_input.keymap.p = function(key,down)
        if down then
            local new_state = _get_viewport_state() + 1
            if new_state > 1 then new_state = 0 end
            _set_viewport_state(new_state)
        end
    end
end

main()