Blood = {
    deck = nil,
    priority = 5,
    vMax = 200,
    additionalLifespan = 5,
    gravity = -300,
    dropSize = 64,
}

Blood.deck = makeDeck('blood')

function Blood._makeDrop(parent)
    local drop = makeProp(Blood.deck, squirt.layer, Blood.dropSize, Blood.dropSize, Blood.priority)
    drop.vx,drop.vy = randVec(Blood.vMax)
    drop:setParent(parent)
    table.insert(parent.drops, drop)
    return drop
end

function Blood._updateSquirtThread(squirt)
    local totalLife = squirt.duration + Blood.additionalLifespan
    local timeBetweenDrops = 1 / squirt.spurtRate
    local dropTime = timeBetweenDrops

    while true do
        for key, drop in pairs(squirt.drops) do
            local x,y = drop:getLoc()
            drop.vy = drop.vy + Blood.gravity * deltaTime
            y = y + drop.vy * deltaTime
            x = x + drop.vx * deltaTime
            drop:setLoc(x,y)
        end

        squirt.timeLived = squirt.timeLived + deltaTime
        if squirt.timeLived > totalLife then
            print("Done!")
            break
        end

        if squirt.timeLived < squirt.duration then
            dropTime = dropTime - deltaTime
            if dropTime < 0 then
                dropTime = dropTime + timeBetweenDrops
                Blood._makeDrop(squirt)
            end
        end

        coroutine.yield()
    end

    for key, drop in pairs(squirt.drops) do
        squirt.layer:removeProp(drop)
    end
end

function Blood.squirt(x, y, intialSpurts, spurtRate, duration, layer)
    squirt = MOAIProp2D.new()
    squirt:setLoc(x,y)
    squirt.drops = {}
    squirt.timeLived = 0
    squirt.duration = duration
    squirt.layer = layer
    squirt.spurtRate = spurtRate

    -- Spurt
    local spurtsToMake = intialSpurts
        
    while spurtsToMake >= 0 do
        local drop = Blood._makeDrop(squirt)
        spurtsToMake = spurtsToMake - 1
    end

    squirt.thread = MOAICoroutine.new()
    squirt.thread:run( Blood._updateSquirtThread, squirt )

    return squirt
end

return Blood