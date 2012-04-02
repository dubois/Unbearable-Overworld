local tps = require 'tps'

local Ob = {}

function Ob.main()
    while true do
        if g_bear.emotion.oxygen <= 0 then
            Ob.doEnd()
            break
        end
    end
end

function Ob.doEnd()
    MOAISim.popRenderPass ()
    MOAISim.popRenderPass ()
    MOAISim.popRenderPass ()
    if ENABLE_PHYSICS_DEBUG then
        MOAISim.popRenderPass ()
    end

    --More
end

Ob.thread = MOAICoroutine.new()
Ob.thread:run(Ob.main)

function Ob:init()
    local prop = MOAIProp2D.new()
    prop:setDeck(tps.load_single('art/frame.png'))
    g_end_layer:insertProp (prop)
end

return Ob

