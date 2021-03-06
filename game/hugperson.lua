local HugPerson = {
    priority = 2,
    backPriority = 0.5,
    damagePerSecMax = 5,
    minTToDamage = 50,
    minTToHug = 25,
    personLib = {},
    layer = nil,
    maxDistanceFromBear = 3,
    disableRate = 1,
    blockDistance = 2,
    airPerTPerSecond = 3,

    fromXs = {-800, -1000, 1000},
    targetXs = { 0, -256, 256 },
    nextTargetX = 1,
}

function HugPerson._makePerson(name, eye1x, eye1y, eye2x, eye2y, initialImage, huggedImage, damageStates)
    local personData = {
        initialDeck = makeDeck('faces/'..initialImage),
        huggedDeck = makeDeck('faces/'..huggedImage),
        eye1x = eye1x,
        eye1y = eye1y,
        eye2x = eye2x,
        eye2y = eye2y,
        healthMax = 100,
        damageStates = damageStates,
    }

    return personData
end


function _makeDmgState(triggerHealth, soundName, initialSpurtCount, duration, spurtRate, image)
    local sound = MOAIUntzSound.new ()
    sound:load ( 'sound/'..soundName..'.wav' )
    sound:setVolume ( 1 )
    sound:setLooping ( false )
    -- print(image)

    return { triggerHealth = triggerHealth, sound = sound, initialSpurtCount = initialSpurtCount, duration = duration, spurtRate = spurtRate, deck = makeDeck('faces/'..image) }
end

function HugPerson.MakePersonData(name)
    local personData = HugPerson._makePerson(name, -60, 80, 90, 80, name..'_scared', name..'_happy',
                                     {_makeDmgState(75, 'ow', 5, 1, 3, name..'_scared'),
                                      _makeDmgState(50, 'ow', 5, 1, 3, name..'_pain'),
                                      _makeDmgState(25, 'ow', 5, 1, 3, name..'_pain'),
                                      _makeDmgState(0, 'ow', 25, 0, 10, name..'_pain'),} )
    HugPerson.personLib[name] = personData
    return personData
end

--HugPerson.MakePersonData('ChrisJurney')
--HugPerson.MakePersonData('AnnaKipnis')

--[[HugPerson.personLib['Chris'] = HugPerson._makePerson('Chris', -60, 80, 90, 80, 'ScaredChris', 'HappyChris',
                                     {_makeDmgState(75, 'ow', 5, 1, 3, 'ScaredChris'),
                                      _makeDmgState(50, 'ow', 5, 1, 3, 'HorrorChris'),
                                      _makeDmgState(25, 'ow', 5, 1, 3, 'HorrorChris'),
                                      _makeDmgState(0, 'ow', 25, 0, 10, 'HorrorChris'),} )

HugPerson.person]]--


function _doDmgState(person, ds)

    if ds.sound then
        -- print ("play")
        ds.sound:play()
    end

    local pd = person.personData

    if ds.deck then
        person:setDeck(ds.deck)
    end

    Blood.squirt(pd.eye1x, pd.eye1y, ds.initialSpurtCount, ds.spurtRate, ds.duration, person.layer)
    Blood.squirt(pd.eye2x, pd.eye2y, ds.initialSpurtCount, ds.spurtRate, ds.duration, person.layer)
end

function HugPerson.thread(person)
    local t = 0
    local pt = 0

    while not person.dead do
        pt = t

        if not person.disabled then
            t = 1 - (person.distanceFromBear / HugPerson.maxDistanceFromBear)
            local blockDistT = 1 - HugPerson.blockDistance / HugPerson.maxDistanceFromBear

            if Hugs.isBlocking() then
                if pt < (blockDistT - 0.01) then
                    t = clamp(t, 0, blockDistT - 0.02)
                end
            else
            end

            if t > (blockDistT + 0.01) then
                person.hugged = true
            else
                person.hugged = false
            end
        else
            t = t - HugPerson.disableRate * deltaTime
        end

        if person.hugged then
            person:setPriority(HugPerson.priority)
        else
            person:setPriority(HugPerson.backPriority)
        end

        --t = t + 0.005
        t = clamp(t, 0, 1)
        --t = 1

        local x = 1024*t
        local y = 768*t
        person:setScl(x,y)

        local px = person.targetX
        local py = -768*(1-t)*0.5
        if t < 0.5 then
            local tt = t * 2
            px = person.fromX + tt * (person.targetX - person.fromX)
            --px = -800 + 1600*t
        end
        person:setLoc(px,py)

        if person.disabled and t <= 0 then
            break;
        end

        coroutine.yield()
    end

    if person.dead then
        threadSleep(5)
    end

    Hugs.removeHuggee(person)

    person.layer:removeProp(person)
end

function HugPerson.new(name)
    local layer = HugPerson.layer
    local personData = HugPerson.personLib[name]
    local person = makeProp(personData.initialDeck, layer, 1024, 768, HugPerson.priority)

    person.health = personData.healthMax
    person.layer = layer
    person.personData = personData
    person.damageStatesTriggered = {}
    person.distanceFromBear = 0
    person.disabled = false
    person.dead = false
    person.hugged = false
    person.targetX = HugPerson.targetXs[HugPerson.nextTargetX]
    person.fromX = HugPerson.fromXs[HugPerson.nextTargetX]
    person.beenHappy = false

    HugPerson.nextTargetX = HugPerson.nextTargetX + 1
    if HugPerson.nextTargetX > #HugPerson.targetXs then
        HugPerson.nextTargetX = 1
    end

    person:setColor(1,1,1,0)
    person:seekColor(1,1,1,1,0.1)
    person:setScl(0.1,0.1)
    person:seekScl(1024,768,3)

    for index, ds in ipairs(personData.damageStates) do
        person.damageStatesTriggered[index] = false
    end

    person.thread = MOAICoroutine.new()
    person.thread:run( HugPerson.thread, person )

    Hugs.addHuggee(person)

    return person
end

function HugPerson.updateWithPaw(person, t)
    if (not person) or (not person.hugged) then
        return
    end

    if person.health >= person.personData.healthMax and t > HugPerson.minTToHug then
        person:setDeck(person.personData.huggedDeck)
        if not person.beenHugged then
            person.beenHugged = true
            person.npc.beenHugged = true
            g_bear.emotion:onHug()
        end
    end

    if t > HugPerson.minTToHug and not person.dead then
        local airT = (t - HugPerson.minTToHug) / (100 - HugPerson.minTToHug)
        local air = airT * HugPerson.airPerTPerSecond * deltaTime
        g_bear.emotion:addAir(air)
        --print("a: "..air.." ba: "..g_bear.emotion.oxygen)
    end

    if person.health <= 0 then  
        return
    end

    if t > HugPerson.minTToDamage then
        local damage = HugPerson.damagePerSecMax * deltaTime * (t - HugPerson.minTToDamage)
        HugPerson.damage(person, damage)
    end
end

function HugPerson.damage(person, damage)
    person.health = person.health - damage
    person.npc.health = person.health

    g_bear.emotion:onDamage(damage)

    for index, ds in ipairs(person.personData.damageStates) do
        if not person.damageStatesTriggered[index] then
            if person.health < ds.triggerHealth then
                _doDmgState(person, ds)
                person.damageStatesTriggered[index] = true
            end
        end
    end

    if person.health <= 0 then
        person.health = 0
        HugPerson.die(person)
    end

    --local badVolume = (person.personData.healthMax - person.health) / person.personData.healthMax
    --Music.setBadness(badVolume)
end


function HugPerson.die(person)
    person:seekColor(1,0.2,0.2,1,3)
    person:seekLoc(0, -600, 3)
    person:seekRot(30, 3)
    person.dead = true
    person.npc.dead = true
    g_bear.emotion:onKill()
end

return HugPerson
