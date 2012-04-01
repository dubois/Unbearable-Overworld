local tps = require 'tps'

local Ob = {}

function Ob:init()
    self.ticker = MOAICoroutine:new()
    self.ticker:run(self.on_tick, self)

    local frames = {
        'art/hugs/HorrorChris.png',
        'art/hugs/ScaredChris.png',
        'art/hugs/HappyChris.png',
    }

    self.emo_frames = {}
    for i, f in ipairs(frames) do
        local deck = tps.load_single(f)
        self.emo_frames[#self.emo_frames + 1] = deck
    end
    
    local prop = MOAIProp2D.new()
    prop:setDeck(self.emo_frames[1])
    g_bearemo_layer:insertProp(prop)
    self.prop = prop

    self.oxygen = 1
    -- a number between 0 and 1
    -- 0 is maximally sad
    -- 1 is maximally happy
    self.emotion = 1
end


function Ob:on_tick()
    while true do
        -- for testing bear
        local x,y = g_bear:getLoc()
        self.emotion = y / 10
        self.oxygen = x / 10

        -- set color from oxygen
        local r = self.oxygen
        local g = self.oxygen
        local b = 1
        self.prop:setColor(r,g,b)

        local idx = math.floor(self.emotion * #self.emo_frames) + 1
        idx = math.min(math.max(idx,1), #self.emo_frames)
        self.prop:setDeck(self.emo_frames[idx])
        coroutine.yield()

        
    end
end


return Ob