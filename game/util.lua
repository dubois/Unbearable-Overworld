local Util = {
    deckLib = {}
}

function threadSleep(time)
	local rTimer = MOAITimer.new()
	rTimer:setSpan(0, time)
    MOAIThread.blockOnAction(rTimer:start())	
end

function makeDeck(asset)
    if Util.deckLib[asset] then
        return Util.deckLib[asset]
    end

    local deck = MOAIGfxQuad2D.new()
    deck:setTexture('art/'..asset..'.png')
    Util.deckLib[asset] = deck

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

function calcDistanceSq(x1,y1,x2,y2)
    local xd = x1 - x2
    local yd = y1 - y2
    return xd*xd + yd*yd
end

function calcDistance(x1,y1,x2,y2)
    local xd = x1 - x2
    local yd = y1 - y2
    return math.sqrt(xd*xd + yd*yd)
end

function randVec(size)
    local x = math.random(-size, size)
    local y = math.random(-size, size)
    return x,y
end

function angleToVec(angle)
    local rads = math.rad(angle)
    local x = math.sin(rads)
    local y = math.cos(rads)
    return x,y
end

return Util
