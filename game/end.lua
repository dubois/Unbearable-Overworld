Ob = {}

function Ob.main()
    while true do
        if g_bear.emotion.oxygen <= 0 then
            Ob.doEnd()
            break
        end
    end
end

function Ob.doEnd()
    MOAISim.popRenderPass ()
    MOAISim.popRenderPass ()
    MOAISim.popRenderPass ()
    if ENABLE_PHYSICS_DEBUG then
        MOAISim.popRenderPass ()
    end

    --More
end

Ob.thread = MOAICoroutine.new()
Ob.thread:run(Ob.main)

return Ob
