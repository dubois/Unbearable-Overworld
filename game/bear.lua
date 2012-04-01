-- I AM A FRIENDLY BEAR

local animlib = require 'anim'
local tps = require 'tps'

local BEAR_FORCE = 70
local BEAR_DAMPING = 7

local BEAR_EXPAND = 0.8
local SHEET_BEAR = tps.load_sheet('art/sheet_bear.lua', nil, 2+BEAR_EXPAND, -BEAR_EXPAND/2)
local ANIM_DESCS = {
    -- <anim name> =  {
    --     frames = { '<texture name>', '<texture name>' },
    --     rate = <frames per second>,  -- optional; defaults to 2
    -- }

    idle = {
        frames = { 'bear_standing', 'bear_standing1' },
    },
    walk_fwd = {
        frames = { 'bear_walking1', 'bear_walking2' },
    },
    walk_back = {
        frames = { 'bear_walking_back1', 'bear_walking_back2' },
    }
}

local Ob = {}
Ob.move_actions = {}

function Ob:init()
    local body = g_box2d:addBody ( MOAIBox2DBody.DYNAMIC )
    body:addRect ( 0,0, 2-0.1, 2-0.1 )
    body:setTransform ( 10, 10 )
    body:setFixedRotation ( true )
    body:setMassData ( 1 )
    body:setLinearDamping( BEAR_DAMPING )
    self.body = body

    local prop = SHEET_BEAR:make('')
    prop:setParent(self.body)
    g_map_layer:insertProp(prop)
    self.prop = prop

	g_input.keymap.w = self:make_mover(0,1)
	g_input.keymap.a = self:make_mover(-1,0)
	g_input.keymap.s = self:make_mover(0,-1)
	g_input.keymap.d = self:make_mover(1,0)

    self.anims = animlib.make_anims(self.prop, ANIM_DESCS, SHEET_BEAR)

    self.ticker = MOAICoroutine:new()
    self.ticker:run(self.on_tick, self)

    -- debug keybindings for tuning
    g_input.keymap.t = function(k,d)
        if d then
            BEAR_FORCE = BEAR_FORCE * 1.05
            print('force is now',BEAR_FORCE)
        end
    end
    g_input.keymap.g = function(k,d)
        if d then
            BEAR_FORCE = BEAR_FORCE / 1.05
            print('force is now',BEAR_FORCE)
        end
    end

    g_input.keymap.y = function(k,d)
        if d then
            BEAR_DAMPING = BEAR_DAMPING * 1.05
            self.body:setLinearDamping(BEAR_DAMPING)
            print('damp is now',BEAR_DAMPING)
        end
    end
    g_input.keymap.h = function(k,d)
        if d then
            BEAR_DAMPING = BEAR_DAMPING / 1.05
            self.body:setLinearDamping(BEAR_DAMPING)
            print('damp is now',BEAR_DAMPING)
        end
    end
end

function Ob:_get_desired_anim()
    return self.anims['walk_fwd']
end

-- Runs every tick!
function Ob:on_tick()
    while true do
        -- Re-evaluate anims, switching if desired
        local desired_anim = self:_get_desired_anim()
        if self._current_anim ~= desired_anim then
            -- Copy frame time from old anim, if there is one
            if desired_anim then
                if self._currentAnim then
                    desired_anim:setTime(self._currentAnim:getTime())
                else
                    desired_anim:setTime(0)
                end
                desired_anim:start()
            end

            if self._current_anim then
                self._current_anim:stop()
            end

            self._current_anim = desired_anim
        end

        coroutine.yield()
    end
end

-- Utility function to help with keybinding
-- Return a function that starts/stops a movement coroutine
function Ob:make_mover(dx,dy)
	local function move_infinitely()
		while true do
			self.body:applyForce(dx * BEAR_FORCE, dy * BEAR_FORCE)
			coroutine.yield()
		end
	end

	local function start_or_stop_mover(key,down)
        local move_actions = self.move_actions

		-- always stop, just in case the calls aren't properly paired
		if move_actions[key] then
			move_actions[key]:stop()
			move_actions[key] = nil
		end
		if down then
			move_actions[key] = MOAICoroutine:new ()
			move_actions[key]:run(move_infinitely)
		end
	end
	
	return start_or_stop_mover
end

return Ob