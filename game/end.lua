local tps = require 'tps'

local Ob = {}

function Ob:init()
    local prop = MOAIProp2D.new()
    prop:setDeck(tps.load_single('art/frame.png'))
    g_end_layer:insertProp (prop)

    self.thread = MOAICoroutine.new()
    self.thread:run(self.main, self)

    local face = MOAIProp2D.new()
    face:setDeck(g_npc.npcs[3].npcDef.scaredFaceDeck)
    assert (g_npc.npcs[3].npcDef.scaredFaceDeck)
    face:setScl(300,300)
    g_end_layer:insertProp(face)
    face:setLoc(1024/4+30,768/2)
    self.face = face

end

function Ob:main()
    while g_bear.emotion.oxygen > 0 do
        coroutine.yield()
    end
    
    MOAISim.popRenderPass ()
    MOAISim.popRenderPass ()
    MOAISim.popRenderPass ()
    if ENABLE_PHYSICS_DEBUG then
        MOAISim.popRenderPass ()
    end
    -- MOAISim.popRenderPass ()
    MOAISim.popRenderPass ()
    MOAISim.pushRenderPass( g_end_layer )
    
    for i,npc in ipairs(g_npc.npcs) do
        local state = npc:final_state()
        if state == 'dead' then
            self.face:setDeck(npc.npcDef.npcScaredDeck)
        elseif state == 'happy' then
            self.face:setDeck(npc.npcDef.happyFaceDeck)
        else
            self.face:setDeck(npc.npcDef.happyFaceDeck)
            print('name',npc.npcDef.name,'nothing happened')
        end
        coroutine.yield()
        coroutine.yield()
    end
end

return Ob

