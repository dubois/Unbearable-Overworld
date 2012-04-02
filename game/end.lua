local tps = require 'tps'

local Ob = {}

function Ob:init()
    local prop = MOAIProp2D.new()
    prop:setDeck(tps.load_single('art/frame.png'))
    g_end_layer:insertProp (prop)

    self.thread = MOAICoroutine.new()
    self.thread:run(self.main, self)

end

function Ob:main()
    while g_bear.emotion.oxygen > 0 do
        coroutine.yield()
    end
    self:doEnd()
end

function Ob:doEnd()
    MOAISim.popRenderPass ()
    MOAISim.popRenderPass ()
    MOAISim.popRenderPass ()
    if ENABLE_PHYSICS_DEBUG then
        MOAISim.popRenderPass ()
    end
end

return Ob

