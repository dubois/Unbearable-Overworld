-- I AM A FRIENDLY BEAR

local FORCE_SCALE = 1

local Ob = {}
Ob.move_actions = {}

function Ob:init()
    body = g_box2d:addBody ( MOAIBox2DBody.DYNAMIC )
    body:addRect ( 0,0, 2,3 )
    body:setTransform ( 10, 10 )
    body:setFixedRotation ( true )
    body:setMassData ( 1 )
    self.body = body

	g_input.keymap.i = self:make_mover(0,1)
	g_input.keymap.j = self:make_mover(-1,0)
	g_input.keymap.k = self:make_mover(0,-1)
	g_input.keymap.l = self:make_mover(1,0)
end

function Ob:make_mover(dx,dy)
	local function move_infinitely()
		while true do
			self.body:applyForce(dx * FORCE_SCALE, dy * FORCE_SCALE)
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