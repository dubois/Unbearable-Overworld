local Ob = { keyPressed = false }

Ob.keymap = {}
Ob.keydownmap = {}

function Ob:init()
	-- Redirect keypresses to the keymap
	-- Other systems will poke the keymap
	if MOAIInputMgr.device.keyboard then
		local function on_keyboard(key, down)
			local cb = self.keymap[string.char(key)]
			if cb then cb(key,down) end
            self.keyPressed = true

            if down then
                cb = self.keydownmap[string.char(key)]
                if cb then cb(key) end
            end
		end
		MOAIInputMgr.device.keyboard:setCallback(on_keyboard)
	end
end

return Ob