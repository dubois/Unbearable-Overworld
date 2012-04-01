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
    pawYBottom =  -200,
    pawXLeftMin = -512,
    pawXLeftMax = -100,
}

deckLib = {}

function makeDeck(asset)
    if deckLib[asset] then
        return deckLib[asset]
    end

    local deck = MOAIGfxQuad2D.new()
    deck:setTexture('art/hugs/'..asset..'.png')
    deckLib[asset] = deck

    return deck
end

function makeProp(deck, layer, sx, sy, priority)
    local prop = MOAIProp2D.new()
    prop:setDeck(deck)
    prop:setScl(sx, sy)
    prop:setPriority(priority)
    layer:insertProp(prop)
    return prop
end

function clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    end

    return value
end

function randVec(size)
    local x = math.random(-size, size)
    local y = math.random(-size, size)
    return x,y
end

Blood = require("blood")
HugPerson = require("hugperson")


function Hugs.init(viewport)
    Hugs.viewport = viewport

    viewport:setScale(1024,768)

    local layer = MOAILayer2D.new ()
    Hugs.layer = layer
    layer:setViewport ( viewport )
    MOAISim.pushRenderPass ( layer )

    Hugs.cityDeck = makeDeck('city')
    Hugs.personDeck = makeDeck('Chris')
    Hugs.pawDeck = makeDeck('LeftPaw')

    Hugs.cityProp = makeProp(Hugs.cityDeck, layer, 1024, 768, 0)
    Hugs.person = HugPerson.new('Chris', layer)
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
	local wx, wy = Hugs.layer:wndToWorld ( x, y )

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

            HugPerson.updateWithPaw(Hugs.person, Hugs.hugT)

            coroutine.yield ()
        end
    end
)

MOAIInputMgr.device.pointer:setCallback ( Hugs.onPointerEvent )

return Hugs
