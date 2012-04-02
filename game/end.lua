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

function waitForInput()
    local seen_input = false
    local function onkbd(key,down)
        if down then
            seen_input = true
        end
    end

    MOAIInputMgr.device.keyboard:setCallback(onkbd)
    while not seen_input do
        coroutine.yield()
    end
    -- threadSleep(0.3)
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
    
    font = MOAIFont.new()
    font:loadFromTTF('art/JandaSafeandSound.ttf', ' abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!.,\'"-', 24)

    text = MOAITextBox.new()
    text:setFont(font)
    text:setString("blah")
    text:setRect(0,0,400,768)
    text:setLoc(600,700)
    text:setPriority(99)
    text:setYFlip(1)
    local scx, scy = text:getScl()
    text:setScl(scx,-scy)
    g_end_layer:insertProp(text)

    for i,npc in ipairs(g_npc.npcs) do
        local state = npc:final_state()
        if state == 'dead' then
            self.face:setDeck(npc.npcDef.scaredFaceDeck)
            text:setString(npc.npcDef.text_dead)
            waitForInput()
        elseif state == 'happy' then
            self.face:setDeck(npc.npcDef.happyFaceDeck)
            text:setString(npc.npcDef.text_alive)
            print (npc.npcDef.text_alive)
            waitForInput()
        elseif true then
            self.face:setDeck(npc.npcDef.happyFaceDeck)
            text:setString(npc.npcDef.text_alive)
            coroutine.yield()
            text:setString(npc.npcDef.text_dead)
            coroutine.yield()
            waitForInput()
        end
    end
end

return Ob

