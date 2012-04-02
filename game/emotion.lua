local tps = require 'tps'

-- Start super-saturated with oxygen so player has time to get
-- accustomed to what's going on
INITIAL_OXYGEN = 1.3

-- false: disable oxygen depletion over time
DISABLE_OXYGEN_DEPLETION = false

-- true: enable tgb and yhn for setting oxygen and emotion directly
ENABLE_DEBUG_KEYS = true

-- seconds to go from 100% to 0% oxygen
-- note that we start with a little more than 100% oxygen
SECONDS_OF_OXYGEN = 20

-- The higher this is, the faster emotion tracks oxygen level
EMOTION_TRACKING_STRENGTH = 0.001

HUG_PAYOFF = 0.3
DAMAGE_EMO_RATE = 0.002
KILL_PENALTY = 0.5

KILL_HORROR_TIME = 4

-- If happiness is >= the associated number, use that face
local FACE_MAP = {
    {'happier bear face', 1.1 },
    {'happy bear face',   0.9 },
    {'normal bear face',  0.5 },
    {'sad bear face',     0.2 },
    {'sadder bear face',  -100 }
}

local Ob = {killHorrorTime = 0}

local function pin(val, a,b)
    return math.min(math.max(val,a), b)
end

function Ob:init()
    self.deck = tps.load_sheet('art/sheet_bearface.lua')

    self.ticker = MOAICoroutine:new()
    self.ticker:run(self.on_tick, self)

    local prop = MOAIProp2D.new()
    prop:setDeck(self.deck)
    prop:setIndex(self.deck.names['happy bear face'])
    g_bearemo_layer:insertProp (prop)
    self.prop = prop

    self.oxygen = INITIAL_OXYGEN

    -- a number between 0 and 1
    -- 0 is maximally sad
    -- 1 is maximally happy
    self.emotion = 1

    -- debug keybinds for testing happiness
    if ENABLE_DEBUG_KEYS then
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

function Ob:addAir(a)
    self.oxygen = self.oxygen + a
    self.oxygen = clamp(self.oxygen,0,1)
end

function Ob:onHug()
    self.emotion = self.emotion + HUG_PAYOFF
end

function Ob:onDamage(damage)
    self.emotion = self.emotion - (DAMAGE_EMO_RATE * damage)
end

function Ob:onKill()
    self.emotion = self.emotion - KILL_PENALTY
    self.killHorrorTime = time + KILL_HORROR_TIME
end

-- Pass: happiness level
-- Return: deck index
function Ob:_get_frame_for_emotion(h)
    local found
    for _, t in ipairs(FACE_MAP) do
        if h > t[2] then
            found = t
            break
        end
    end
    if not found then
        print("WARN: couldn't look up emo", h)
        found = FACE_MAP[#FACE_MAP]
    end
    
    local idx = self.deck.names[found[1]]
    if idx == nil then
        print("WARN: couldn't find frame ".. found[1])
        return 0
    end

    return idx
end

function Ob:on_tick()
    while true do
        -- burn some oxygen
        if not DISABLE_OXYGEN_DEPLETION then
            self.oxygen = self.oxygen - deltaTime / SECONDS_OF_OXYGEN
            self.oxygen = pin(self.oxygen, 0, 2)
        end

        -- Happiness tracks oxygen level
        -- But don't let oxygen level increase happiness above 1
        local dest = self.oxygen
        if self.oxygen > self.emotion and self.oxygen > 1 then
            dest = math.max(1, self.emotion)
        end
        local delta = dest - self.emotion
        self.emotion = self.emotion + delta * EMOTION_TRACKING_STRENGTH

        local oxy_01 = pin(self.oxygen, 0,1)
        
        -- set color from oxygen
        local r = 0.2 + 0.8 * oxy_01
        local g = 0.2 + 0.8 * oxy_01
        local b = 1
        self.prop:setColor(r,g,b)

        -- set sprite from happiness
        local idx = self:_get_frame_for_emotion(self.emotion)
        self.prop:setIndex(idx)

        local badness = clamp(1-self.emotion,0,1)
        --print("e"..self.emotion.."b"..badness)
        Music.setBadness(badness)

        coroutine.yield()
    end
end


return Ob