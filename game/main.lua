-- You are a bear but for some reason your oxygen comes from hugging
-- people. Problem is that hugging people breaks their
-- bones. #Poeticgaming
-- 
-- https://twitter.com/#!/petermolydeux/status/94102529461334017

local tps = require 'tps'
local util = require 'util'
require 'credits'

MAP_NAME = 'art/tiled_map2.lua'

WIN_X, WIN_Y = 1024, 768
local MAP_ZOOM = 30

DISABLE_MUSIC = true
ENABLE_SPLASH = false
ENABLE_PHYSICS_DEBUG = false

local function init_early()
    MOAISim.openWindow ( "https://twitter.com/#!/petermolydeux/status/94102529461334017", WIN_X, WIN_Y )
    MOAIUntzSystem.initialize ()

    time = MOAISim.getElapsedTime()
    deltaTime = 0

    timeThread = MOAICoroutine.new()
    timeThread:run(
        function()
            while true do
                local newTime = MOAISim.getElapsedTime()
                deltaTime = newTime - time
                time = newTime
                coroutine.yield()
            end
        end
    )

    -- Should come before map init
    g_input = require 'input'
    g_input:init()

    Music = require("music")

end

local function do_splash()
    init_early()
    if not ENABLE_SPLASH then
        main()
        return
    end

    local viewport = MOAIViewport.new ()
    viewport:setSize ( WIN_X, WIN_Y )
    viewport:setScale ( WIN_X, WIN_Y )

    local layer = MOAILayer2D.new ()
    layer:setViewport ( viewport )

    MOAISim.pushRenderPass(layer)

    local deck = makeDeck('hugs/splash')
    local prop = makeProp(deck, layer, 1024, 768, 1)

    local thread = MOAICoroutine.new()
    thread:run(function()
        while not g_input.keyPressed do
            coroutine.yield()
        end
        MOAISim.popRenderPass()
        main()
    end )
end

-- ----------------------------------------------------------------------
-- Rendering, viewport management
-- ----------------------------------------------------------------------

local function init_render()

    Hugs = require("hugs")

	-- Set up quadrants
	-- nb: It's setSize(x0,y0,x1,y1), not setSize(x0,y0,w,h)

	--
	-- "map chase" minigame
	--

	-- Map viewport is zoomed in quite a bit, because the map
	-- uses 1 unit = 1 meter = 1 tile.  It hosts these layers:
    --   g_map_layer     (map tiles)
    --   b2d_layer       (debug drawing for box2d)
    g_view_map = MOAIViewport.new ()
    g_view_map:setSize ( 0,0, WIN_X/2, WIN_Y )
    g_view_map:setScale ( WIN_X/2 / MAP_ZOOM, WIN_Y / MAP_ZOOM )

    g_map_layer = MOAILayer2D.new ()
    g_map_layer:setViewport ( g_view_map )
	g_map_layer.camera = MOAICamera2D:new ()
	g_map_layer:setCamera(g_map_layer.camera)
    g_map_layer.camera:setLoc(15,20)

	--
	-- "bear hug" minigame
	--
    g_view_hug = MOAIViewport.new()
    g_view_hug:setSize( WIN_X/2, WIN_Y/2, WIN_X, WIN_Y )
    Hugs.init(g_view_hug, g_map_layer)

    -- Bear Emotion viewport is standard 1 pixel = 1 unit
    -- It only contains g_bearemo_layer
	g_view_bear = MOAIViewport.new ()
	g_view_bear:setSize ( WIN_X/2, 0, WIN_X, WIN_Y/2 )
	g_view_bear:setScale ( 800, 600 )  -- bear faces are authored at 800 x 600
    -- origin in lower-left
    g_view_bear:setOffset(-1,-1)

	g_bearemo_layer = MOAILayer2D.new ()
	g_bearemo_layer:setViewport ( g_view_bear )
	g_bearemo_layer.camera = MOAICamera2D:new ()
	g_bearemo_layer:setCamera(g_bearemo_layer.camera)

    -- physics

	local world = MOAIBox2DWorld.new ()
	world:setGravity ( 0, 0 )
	world:setUnitsToMeters ( 1 )
	world:start()
    g_box2d = world

    -- layer, just for box2d rendering

    local b2d_layer = MOAILayer2D.new ()
    b2d_layer:setViewport( g_view_map )
    b2d_layer:setCamera( g_map_layer.camera )
    b2d_layer:setBox2DWorld ( g_box2d ) 

    g_char_layer = MOAILayer2D.new ()
    g_char_layer:setViewport ( g_view_map )
    g_char_layer:setCamera(g_map_layer.camera)

    -- viewport + layer for endgame rendering
    -- origin in lower-left
    g_view_end = MOAIViewport.new ()
    g_view_end:setSize(0,0, WIN_X,WIN_Y)
    g_view_end:setScale(1024, 768)
    g_view_end:setOffset(-1,-1)
    g_end_layer = MOAILayer2D.new ()
    g_end_layer:setViewport(g_view_end)

	-- Render quadrants
    MOAISim.pushRenderPass ( g_bearemo_layer )
    MOAISim.pushRenderPass ( g_map_layer )
    MOAISim.pushRenderPass ( g_char_layer )
    if ENABLE_PHYSICS_DEBUG then
        MOAISim.pushRenderPass ( b2d_layer )
    end

    -- for paul testing
    -- MOAISim.pushRenderPass( g_end_layer )

    Music.init()
    Music.setSong('hug')
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
    local sheet_test = tps.load_sheet ( 'art/sheet_out.lua' )
    local sheet_map = tps.load_sheet ( 'art/sheet_map.lua',  0.5 )

    -- local prop = sheet_map:make('bg/grass_1')
    -- prop:setLoc(100,-100)
    -- g_bearemo_layer:insertProp(prop)

    -- local prop = sheet_map:make('bg/grass_2', 2)
    -- prop:setLoc(130,-130)
    -- g_bearemo_layer:insertProp(prop)

    -- local prop = sheet_test:make('cathead')
    -- prop:setLoc ( -100, -100 )
    -- g_bearemo_layer:insertProp ( prop )

    -- local prop = sheet_test:make('two')
    -- prop:setLoc ( 0, 0 )
    -- g_bearemo_layer:insertProp ( prop )

    -- local prop = sheet_test:make('one')
    -- prop:setLoc ( 100, 100 )
    -- g_bearemo_layer:insertProp ( prop )
end

function main()
    init_render()
	init_test()

    g_map = require 'map'
    g_map:init()

    g_bear = require 'bear'
    g_bear:init()

    Npc = require("npc")
    g_npc = Npc

    Npc.init(world, g_char_layer, -2)

    g_end = require 'end'
    g_end:init()

    g_map_layer.camera:setParent ( g_bear.body )
    g_map_layer.camera:setLoc ( 1, 1.5 )    -- bear is 2x3

    -- simple cycle through viewport states, for testing
	g_input.keymap.p = function(key,down)
        if down then
            local new_state = _get_viewport_state() + 1
            if new_state > 1 then new_state = 0 end
            _set_viewport_state(new_state)
        end
    end
end

do_splash()
