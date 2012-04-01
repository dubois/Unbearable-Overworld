local tps = require 'tps'

-- seconds to go from 100% to 0% oxygen
-- note that we start with a little more than 100% oxygen
local SECONDS_OF_OXYGEN = 30

local Ob = {}

local function pin(val, a,b)
    return math.min(math.max(val,a), b)
end

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

    -- start super-saturated with oxygen
    self.oxygen = 1.5

    -- a number between 0 and 1
    -- 0 is maximally sad
    -- 1 is maximally happy
    self.emotion = 1

    -- debug keybinds for testing happiness
    if true then
        m = g_input.keydownmap
        -- oxygen
        m.t = function() self.oxygen = 1.0 end
        m.g = function() self.oxygen = 0.5 end
        m.b = function() self.oxygen = 0.1 end
        -- happiness
        m.y = function() self.emotion = 1.0 end
        m.h = function() self.emotion = 0.5 end
        m.n = function() self.emotion = 0.1 end
    end

end

function Ob:test__adjust_state_from_pos()
    local x,y = g_bear:getLoc()
    self.emotion = y / 10
    self.oxygen = x / 10
end

function Ob:on_tick()
    while true do
        -- burn some oxygen
        if true then
            self.oxygen = self.oxygen - deltaTime / SECONDS_OF_OXYGEN
            self.oxygen = pin(self.oxygen, 0, 2)
        end

        -- Happiness tries to track oxygen level.  But not exactly, so
        -- we can have temporary changes in happiness and sadness

        -- self:test__adjust_state_from_pos()

        -- set color from oxygen
        local r = self.oxygen
        local g = self.oxygen
        local b = 1
        self.prop:setColor(r,g,b)

        -- set sprite from happiness
        local idx = math.floor(self.emotion * #self.emo_frames) + 1
        idx = pin(idx, 1, #self.emo_frames)
        self.prop:setDeck(self.emo_frames[idx])
        coroutine.yield()
    end
end


return Ob