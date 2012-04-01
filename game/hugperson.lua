local HugPerson = {
    priority = 2,
    damagePerSecMax = 5,
    minTToDamage = 35,
    minTToHug = 20,
    personLib = {},
    layer = nil,
}

function HugPerson._makePerson(name, eye1x, eye1y, eye2x, eye2y, initialImage, huggedImage, damageStates)
    local personData = {
        initialDeck = makeDeck(initialImage),
        huggedDeck = makeDeck(huggedImage),
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

    return { triggerHealth = triggerHealth, sound = sound, initialSpurtCount = initialSpurtCount, duration = duration, spurtRate = spurtRate, deck = makeDeck(image) }
end

HugPerson.personLib['Chris'] = HugPerson._makePerson('Chris', -60, 80, 90, 80, 'ScaredChris', 'HappyChris',
                                     {_makeDmgState(75, 'ow', 5, 1, 3, 'ScaredChris'),
                                      _makeDmgState(50, 'ow', 5, 1, 3, 'HorrorChris'),
                                      _makeDmgState(25, 'ow', 5, 1, 3, 'HorrorChris'),
                                      _makeDmgState(0, 'ow', 25, 0, 10, 'HorrorChris'),} )


function _doDmgState(person, ds)

    print("Doing state " .. ds.triggerHealth .. " " .. ds.initialSpurtCount)

    if ds.sound then
        print ("play")
        ds.sound:play()
    end

    local pd = person.personData

    if ds.deck then
        person:setDeck(ds.deck)
    end

    Blood.squirt(pd.eye1x, pd.eye1y, ds.initialSpurtCount, ds.spurtRate, ds.duration, person.layer)
    Blood.squirt(pd.eye2x, pd.eye2y, ds.initialSpurtCount, ds.spurtRate, ds.duration, person.layer)
end


function HugPerson.new(name, layer)
    print("name "..name)
    local personData = HugPerson.personLib[name]
    local person = makeProp(personData.initialDeck, layer, 1024, 768, HugPerson.priority)
    person.health = personData.healthMax
    person.layer = layer
    person.personData = personData
    person.damageStatesTriggered = {}
    for index, ds in ipairs(personData.damageStates) do
        person.damageStatesTriggered[index] = false
    end
    return person
end

function HugPerson.updateWithPaw(person, t)
    if not person then
        return
    end

    if person.health >= person.personData.healthMax and t > HugPerson.minTToHug then
        person:setDeck(person.personData.huggedDeck)
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

    local badVolume = (person.personData.healthMax - person.health) / person.personData.healthMax
    Music.setBadness(badVolume)
end


function HugPerson.die(person)
    person:seekColor(1,0.2,0.2,1,3)
    person:seekLoc(0, -600, 3)
    person:seekRot(30, 3)
    person.dead = true
end

return HugPerson