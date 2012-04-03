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
    font:loadFromTTF('art/JandaSafeandSound.ttf', ' abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!.,\'"-:;[]{}()|/\\', 24)

    -- MOAIDebugLines.setStyle( MOAIDebugLines.TEXT_BOX, 2 )

    text_name = MOAITextBox.new()
    text_name:setAlignment(MOAITextBox.CENTER_JUSTIFY,
                           MOAITextBox.LEFT_JUSTIFY)
    text_name:setFont(font)
    text_name:setString("")
    text_name:setRect(0,0,350,120)
    text_name:setPriority(99)
    text_name:setYFlip(true)
    text_name:setLoc(120, 530)
    g_end_layer:insertProp (text_name)

    text_realname = MOAITextBox.new()
    text_realname:setAlignment(MOAITextBox.CENTER_JUSTIFY,
                           MOAITextBox.LEFT_JUSTIFY)
    text_realname:setFont(font)
    text_realname:setString("")
    text_realname:setRect(0,0,350,120)
    text_realname:setPriority(99)
    text_realname:setYFlip(true)
    text_realname:setLoc(205, 100)
    text_realname:setScl(.5,.5)
    g_end_layer:insertProp (text_realname)

    text = MOAITextBox.new()
    text:setFont(font)
    text:setString("")
    text:setRect(0,0,400,768)
    text:setLoc(600,700)
    text:setPriority(99)
    text:setYFlip(1)
    local scx, scy = text:getScl()
    text:setScl(scx,-scy)
    g_end_layer:insertProp(text)

	local seen = false
    for i,npc in ipairs(g_npc.npcs) do
        local def = npc.npcDef
        local state = npc:final_state()

        if state == 'dead' then
			seen = true
            text_name:setString(def.fake_name .. '\n(R.I.P.)')
            text_realname:setString('(' .. def.name .. ')')

            self.face:setDeck(npc.npcDef.scaredFaceDeck)
            text:setString(npc.npcDef.text_dead)
            waitForInput()
        elseif state == 'happy' then
			seen = true
            text_name:setString(def.fake_name)
            text_realname:setString('(' .. def.name .. ')')

            self.face:setDeck(npc.npcDef.happyFaceDeck)
            text:setString(npc.npcDef.text_alive)
            print (npc.npcDef.text_alive)
            waitForInput()
        elseif false then
            -- testing
            text_name:setString(def.fake_name .. '\n(test)')
            text_realname:setString('(' .. def.name .. ')')

            self.face:setDeck(npc.npcDef.happyFaceDeck)
            text:setString(npc.npcDef.text_alive)
            coroutine.yield()
            text:setString(npc.npcDef.text_dead)
            coroutine.yield()
            waitForInput()
        end
    end
	if not seen then
		text:setString("Too shy to hug anyone, the bear eventually died of loneliness and lack of oxygen.")
		waitForInput()
	end

	text:setString("Thanks for playing!\n\n-- Adam, Chris, Chris, Elizabeth, Paul, and Pietro")
end

return Ob
