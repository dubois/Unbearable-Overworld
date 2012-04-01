
MOAISim.openWindow ( "Unbearable", 1024, 768 )
MOAIUntzSystem.initialize ()

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
print("test3")

time = MOAISim.getElapsedTime()
deltaTime = 0

music = MOAIUntzSound.new ()
music:load ( 'Sound/bearhug.wav' )
music:setVolume ( 1 )
music:setLooping ( true )

badMusic = MOAIUntzSound.new ()
badMusic:load( 'Sound/bearhug_overlay.wav')
badMusic:setLooping ( true )
badMusic:setVolume ( 0 )

music:play()
badMusic:play()


viewport = MOAIViewport.new ()
viewport:setSize  ( 1024, 768 )
viewport:setScale ( 1024, 768 )

layer = MOAILayer2D.new ()
layer:setViewport ( viewport )
MOAISim.pushRenderPass ( layer )

cityDeck = makeDeck('city')
personDeck = makeDeck('Chris')
pawDeck = makeDeck('LeftPaw')

cityProp = makeProp(cityDeck, layer, 1024, 768, 0)
person = HugPerson.new('Chris', layer)
leftPaw = makeProp(pawDeck, layer, 1024, 512, 1)
leftPaw:setLoc(-400,0)
rightPaw = makeProp(pawDeck, layer, -1024, 512, 1)
rightPaw:setLoc(400,0)

tMax = 100
hugT = 0
atDeltaLimit = 0.5
at = 0
vt = 0
atRate = 0.1
atLimit = 2
vtLimit = 100

initUpd = 0

pawYTop =      200
pawYBottom =  -200
pawXLeftMin = -512
pawXLeftMax = -100

function calcPawPos(t)
    local pawX = pawXLeftMin + (pawXLeftMax - pawXLeftMin) * (t / 100)
    local pawY = pawYTop + (pawYBottom - pawYTop) * (t / 100)
    return pawX,pawY
end

function onPointerEvent ( x, y )

	wx, wy = layer:wndToWorld ( x, y )

    --dat = (wy / 384) * atDeltaLimit

    --at = at - dat * (1 / 30) * atRate
    at = -(wy / 384) * atLimit

    at = clamp(at, -atLimit, atLimit)

    --print ("wy"..wy.." dat"..dat.." at"..at)
end

timeThread = MOAICoroutine.new()
timeThread:run(
    function()
        while true do
            local newTime = MOAISim.getElapsedTime()
            deltaTime = newTime - time
            time = newTime
            coroutine.yield()
        end
    end
)

hugThread = MOAICoroutine.new()
hugThread:run(
    function()
        local cap = 10

        while true do
            vt = vt + at * deltaTime
            vt = clamp(vt, -vtLimit, vtLimit)

            hugT = hugT + vt
            
            if hugT > tMax then
                hugT = tMax
                vt = 0
                at = 0
            end
            if hugT < 0 then
                hugT = 0
                vt = 0
                at = 0
            end

            pawX, pawY = calcPawPos(hugT)

            leftPaw:setLoc(pawX, pawY)
            rightPaw:setLoc(-pawX, pawY)

            HugPerson.updateWithPaw(person, hugT)

            --print ("vx" .. vx .. " vy" .. vy .. " px" .. px .. " py" .. py)

            coroutine.yield ()
        end
    end
)

MOAIInputMgr.device.pointer:setCallback ( onPointerEvent )
onPointerEvent ( 0, 0 )

