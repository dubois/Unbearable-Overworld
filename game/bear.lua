-- I AM A FRIENDLY BEAR

local BEAR_FORCE = 20
local BEAR_DAMPING = 1.7

local Ob = {}
Ob.move_actions = {}

function Ob:init()
    body = g_box2d:addBody ( MOAIBox2DBody.DYNAMIC )
    body:addRect ( 0,0, 2,3 )
    body:setTransform ( 10, 10 )
    body:setFixedRotation ( true )
    body:setMassData ( 1 )
    body:setLinearDamping( BEAR_DAMPING )
    self.body = body

	g_input.keymap.i = self:make_mover(0,1)
	g_input.keymap.j = self:make_mover(-1,0)
	g_input.keymap.k = self:make_mover(0,-1)
	g_input.keymap.l = self:make_mover(1,0)

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