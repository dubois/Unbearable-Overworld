local Ob = {}

Ob.keymap = {}

function Ob:init()
	-- Redirect keypresses to the keymap
	-- Other systems will poke the keymap
	if MOAIInputMgr.device.keyboard then
		local function on_keyboard(key, down)
            print('input',key,string.char(key),down)
			local cb = self.keymap[string.char(key)]
			if cb then cb(key,down) end
		end
		MOAIInputMgr.device.keyboard:setCallback(on_keyboard)
	end
end

return Ob