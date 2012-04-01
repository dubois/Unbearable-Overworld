-- Helper for turning anim descriptors into anim curves

local t = {}

local DEFAULT_FPS = 4

-- pass a desc (keyframe names and timing) plus a deck (converts
-- keyframe names to sprites).
--
-- Returns a table mapping names to MOAIAnims
--
function t.make_anims(prop, descs, deck)
    local anims = {}
    for anim_name, desc in pairs(descs) do
        local curve = MOAIAnimCurve.new()
        curve:reserveKeys( #desc.frames )

        local fps = desc.rate or DEFAULT_FPS

        for i, txtr_name in ipairs( desc.frames ) do
            txtr_name = string.lower(txtr_name)
            local deck_idx = deck.names[txtr_name]
            if deck_idx == nil then
                print(string.format("Anim sprite %s doesn't exist", txtr_name))
            end                
            curve:setKey( i, (i-1) / fps, deck_idx, MOAIEaseType.FLAT )
        end

        local anim = MOAIAnim:new() 
        anim:reserveLinks( 1 )
        anim:setLink( 1, curve, prop, MOAIProp2D.ATTR_INDEX )
        anim:setMode( desc.mode or MOAITimer.LOOP )        
        anim:setSpan( 0.0, #desc.frames / fps )

        anims[anim_name] = anim
    end

    return anims
end

return t