local Ob = { keyPressed = false }

Ob.keymap = {}

function Ob:init()
	-- Redirect keypresses to the keymap
	-- Other systems will poke the keymap
	if MOAIInputMgr.device.keyboard then
		local function on_keyboard(key, down)
			local cb = self.keymap[string.char(key)]
			if cb then cb(key,down) end
            print("k: "..key)
            Ob.keyPressed = true
		end
		MOAIInputMgr.device.keyboard:setCallback(on_keyboard)
	end
end

return Ob