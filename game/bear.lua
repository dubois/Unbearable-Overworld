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

    idle_f     = { 'bear_standing_front' },
    idle_f_h   = { 'bear_standing_front_readytohug' },
    idle_b     = { 'bear_standing_back', },
    idle_b_h   = { 'bear_standing_back_readytohug', },
    idle_l     = { 'bear_standing_left', },
    idle_l_h   = { 'bear_standing_left_readytohug', },
    idle_r     = { 'bear_standing_right', },
    idle_r_h   = { 'bear_standing_right_readytohug', },

    walk_f     = { 'bear_walking1',
                   'bear_standing_front',
                   'bear_walking2',
                   'bear_standing_front',
    },
    walk_f_h   = { 'bear_walking1_readytohug',
                   'bear_standing_front_readytohug',
                   'bear_walking2_readytohug',
                   'bear_standing_front_readytohug',
    },

    walk_b     = { 'bear_walking_back1',
                   'bear_standing_back',
                   'bear_walking_back2',
                   'bear_standing_back',
    },
    walk_b_h   = { 'bear_walking_back1_readytohug',
                   'bear_standing_back_readytohug',
                   'bear_walking_back2_readytohug',
                   'bear_standing_back_readytohug',
    },

    walk_l     = { 'bear_walking_left1',
                   'bear_standing_left',
                   'bear_walking_left2',
                   'bear_standing_left',
    },
    walk_l_h   = { 'bear_walking_left1_readytohug',
                   'bear_standing_left_readytohug',
                   'bear_walking_left2_readytohug',
                   'bear_standing_left_readytohug',
    },

    walk_r     = { 'bear_walking_right1',
                   'bear_standing_right',
                   'bear_walking_right2',
                   'bear_standing_right',
    },
    walk_r_h   = { 'bear_walking_right1_readytohug',
                   'bear_standing_right_readytohug',
                   'bear_walking_right2_readytohug',
                   'bear_standing_right_readytohug',
    },

}

local Ob = {}
Ob.move_actions = {}
Ob.test__ready_to_hug = true

function Ob:setLoc(x,y)
    self.body:setTransform(x,y, 0)
end

function Ob:is_ready_to_hug()
    -- shitty text implementation
    return self.test__ready_to_hug
end

function Ob:init()
    local body = g_box2d:addBody ( MOAIBox2DBody.DYNAMIC )
    -- body:addRect ( 0,0, 2-0.1, 2-0.1 )
    body:addCircle(0,1, 1-0.1)
    body:setTransform ( 10, 10 )
    body:setFixedRotation ( true )
    body:setMassData ( 1 )
    body:setLinearDamping( BEAR_DAMPING )
    self.body = body

    local prop = SHEET_BEAR:make('bear_walking1')
    prop:setParent(self.body)
    prop:setLoc(-1,0)
    g_char_layer:insertProp(prop)
    self.prop = prop

	g_input.keymap.w = self:make_mover(0,1)
	g_input.keymap.a = self:make_mover(-1,0)
	g_input.keymap.s = self:make_mover(0,-1)
	g_input.keymap.d = self:make_mover(1,0)

	g_input.keymap.W = self:make_mover(0,1)
	g_input.keymap.A = self:make_mover(-1,0)
	g_input.keymap.S = self:make_mover(0,-1)
	g_input.keymap.D = self:make_mover(1,0)


    self.anims = animlib.make_anims(self.prop, ANIM_DESCS, SHEET_BEAR)

    self.ticker = MOAICoroutine:new()
    self.ticker:run(self.on_tick, self)

    if true then
        -- debug keybinds for testing anims
        g_input.keymap.t = function(k,d) if d then
            self.test__ready_to_hug = not self.test__ready_to_hug
        end end
    end

    if false then
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
end

Ob._last_direction = '_f'
function Ob:_get_desired_anim()
    local x,y = self.body:getLinearVelocity ()
    local vel = math.sqrt(x*x + y*y)

    -- what facing?
    local direction = nil
    if vel < 0.1 then
        direction = self._last_direction
    elseif math.abs(x) > math.abs(y) then
        direction = (x > 0) and '_r' or '_l'
    else
        direction = (y > 0) and '_b' or '_f'
    end
    self._last_direction = direction

    local name
    if vel < 0.2 then
        name = 'idle' .. direction
    else
        name = 'walk' .. direction
    end

    if self:is_ready_to_hug() then
        -- try the hug anim
        local try = self.anims[name .. '_h']
        if try then return try end
    end

    local try = self.anims[name]
    if try then return try end

    print(string.format('WARN: Canot find anim %s', try))
    return self.anims['idle_f']
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

function Ob:getPos()
    return self.body:getPosition()
end


return Ob