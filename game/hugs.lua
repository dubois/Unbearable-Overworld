Hugs = {
    tMax = 100,
    hugT = 0,
    atDeltaLimit = 0.5,
    at = 0,
    vt = 0,
    atRate = 0.1,
    atLimit = 2,
    vtLimit = 100,

    initUpd = 0,

    pawYTop =      200,
    pawYBottom =  -100,
    pawXLeftMin = -800,
    pawXLeftMax = -400,

    blockT = 0.24,

    huggees = {},
}


Blood = require("blood")
HugPerson = require("hugperson")

function Hugs.isBeingHugged(person)
    for index, value in ipairs(Hugs.huggees) do
        if person == value then
            return true
        end
    end

    return false
end

function Hugs.isBlocking()
    return Hugs.hugT >= Hugs.blockT
end

function Hugs.addHuggee(person)
    if Hugs.isBeingHugged(person) then
        return
    end

    table.insert(Hugs.huggees, person)
end

function Hugs.removeHuggee(person)
    for index, value in ipairs(Hugs.huggees) do
        if person == value then
            table.remove(Hugs.huggees, index)
        end
    end
end

function Hugs.init(viewport, uilayer)
    Hugs.viewport = viewport
    Hugs.uilayer = uilayer

    viewport:setScale(1024,768)

    local layer = MOAILayer2D.new ()
    Hugs.layer = layer
    HugPerson.layer = layer
    layer:setViewport ( viewport )
    MOAISim.pushRenderPass ( layer )

    Hugs.cityDeck = makeDeck('hugs/gmaps_screen')
    Hugs.pawDeck = makeDeck('hugs/LeftPaw')

    Hugs.cityProp = makeProp(Hugs.cityDeck, layer, 1024, 768, 0)
    Hugs.leftPaw = makeProp(Hugs.pawDeck, layer, 1024, 512, 1)
    Hugs.leftPaw:setLoc(-400,0)
    Hugs.rightPaw = makeProp(Hugs.pawDeck, layer, -1024, 512, 1)
    Hugs.rightPaw:setLoc(400,0)
end


function calcPawPos(t)
    local pawX = Hugs.pawXLeftMin + (Hugs.pawXLeftMax - Hugs.pawXLeftMin) * (t / 100)
    local pawY = Hugs.pawYTop + (Hugs.pawYBottom - Hugs.pawYTop) * (t / 100)
    return pawX,pawY
end

function Hugs.onPointerEvent ( x, y )
    local wy = WIN_Y - y - WIN_Y/2
    Hugs.at = -(wy / 384) * Hugs.atLimit
    Hugs.at = clamp(Hugs.at, -Hugs.atLimit, Hugs.atLimit)
end

Hugs.hugThread = MOAICoroutine.new()
Hugs.hugThread:run(
    function()

        while true do
            Hugs.vt = Hugs.vt + Hugs.at * deltaTime
            Hugs.vt = clamp(Hugs.vt, -Hugs.vtLimit, Hugs.vtLimit)

            Hugs.hugT = Hugs.hugT + Hugs.vt
            
            if Hugs.hugT > Hugs.tMax then
                Hugs.hugT = Hugs.tMax
                Hugs.vt = 0
                Hugs.at = 0
            end
            if Hugs.hugT < 0 then
                Hugs.hugT = 0
                Hugs.vt = 0
                Hugs.at = 0
            end

            local pawX, pawY = calcPawPos(Hugs.hugT)

            Hugs.leftPaw:setLoc(pawX, pawY)
            Hugs.rightPaw:setLoc(-pawX, pawY)

            for key, person in ipairs(Hugs.huggees) do
                HugPerson.updateWithPaw(person, Hugs.hugT)
            end

            coroutine.yield ()
        end
    end
)

MOAIInputMgr.device.pointer:setCallback ( Hugs.onPointerEvent )

return Hugs
