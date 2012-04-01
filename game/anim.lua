-- Helper for turning anim descriptors into anim curves

local t = {}

-- pass a desc (keyframe names and timing) plus a deck (converts
-- keyframe names to sprites).
--
-- Returns a table mapping names to MOAIAnims
--
function t.make_anims(descs, deck)
    local anims = {}
    for anim_name, desc in pairs(descs) do
        local curve = MOAIAnimCurve.new()
        curve:reserveKeys( #desc.frames )

        local fps = desc.rate or 2

        for i,txtr_name in ipairs( desc.tAnimFrames ) do
            txtr_name = 'chars/' .. string.lower(txtr_name)
            local deck_idx = g_deck.by_name[txtr_name]
            if deck_idx == nil then
                Trace(TT_Anna, "Anim sprite %s doesn't exist", txtr_name)
            elseif desc.bFlip then 
                local flip = g_deck.by_name[txtr_name .. '_xflip']
                if flip then
                    deck_idx = flip
                else
                    Trace(TT_Anna, "Sprite %s has no flipped version", txtr_name)
                end
            end                
            curve:setKey( i, (i-1) * dt, deck_idx, MOAIEaseType.FLAT )
        end

        local anim = MOAIAnim:new() 
        anim:reserveLinks( 1 )
        anim:setLink( 1, curve, self, MOAIProp2D.ATTR_INDEX )
        anim:setMode( desc.mode )        
        anim:setSpan( 0.0, #desc.tAnimFrames * desc.nTimePerFrame )

        self.anims[anim_name] = anim
    end
end