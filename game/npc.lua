local Npc = {
    npcs = {},

    npcDefs = {},

    npcHappyDeck = makeDeck('characters/npc_standing_front_happy'),
    npcScaredDeck = makeDeck('characters/npc_standing_front_scared'),
    eyesDeck = makeDeck('characters/x_eyes'),

    timeBetweenDirectionChanges = 3,

    force = 50,
    damping = 20,

    maxDistanceToGetHugged = 3,
}


function _makeNPCDef(name)
    local npcDef = {
        hugPersonData = HugPerson.MakePersonData(name),
        happyFaceDeck = makeDeck('faces/'..name..'_happy_head'),
        scaredFaceDeck = makeDeck('faces/'..name..'_scared_head'),
        name = name,
    }

    local CREDIT = CREDITS[string.lower(name)]
    if not CREDIT then
        print("WARNING: can't find credits for"..name)
    else
        npcDef.fake_name = CREDIT[2]
        npcDef.text_alive = CREDIT[3]
        npcDef.text_dead = CREDIT[4]
    end

    --print('FACE: faces/'..name..'_happy_head')
    Npc.npcDefs[name] = npcDef
end


_makeNPCDef('adam')
_makeNPCDef('alexrubens')
_makeNPCDef('AnnaKipnis')
_makeNPCDef('benmj')
_makeNPCDef('ChrisJurney')
_makeNPCDef('chrisremo')
_makeNPCDef('christianmalone')
_makeNPCDef('davidburns')
_makeNPCDef('deantate')
_makeNPCDef('deniserockwell')
_makeNPCDef('elizabeth')
_makeNPCDef('garydooton')
_makeNPCDef('GavinFitzgerald')
_makeNPCDef('gregrice')
_makeNPCDef('joelburgess')
_makeNPCDef('mikecosimano')
_makeNPCDef('murdersandwich')
_makeNPCDef('paul')
_makeNPCDef('pietro')
_makeNPCDef('rentaylor')
_makeNPCDef('scottlagrasta')
_makeNPCDef('WhitneyHills')


function Npc.calcNewDir()
    if math.random(0,1) < 0.3 then
        return 0,0
    end

    return angleToVec(math.random(0,360))
end

function Npc.update(npc)
    
    local curDirX, curDirY = Npc.calcNewDir()
    while true do
        if npc.dead then
            break;
        end

        npc:applyForce(curDirX * Npc.force, curDirY * Npc.force)

        npc.timeToChangeDirection = npc.timeToChangeDirection - deltaTime
        if npc.timeToChangeDirection < 0 then
            curDirX, curDirY = Npc.calcNewDir()
            npc.timeToChangeDirection = npc.timeToChangeDirection + Npc.timeBetweenDirectionChanges
        end

        local x,y = npc:getPosition()
        npc.prop:setPriority(-y)
        npc.head:setPriority(-y + 0.0001)

        -- Check if I need to start gettin hugged
        local bx,by = g_bear:getPos()
        local dist = calcDistance(x,y,bx,by)
        local dist = dist - 1.4

        --print("dist:"..dist)

        if dist < Npc.maxDistanceToGetHugged then
            if not npc.hugPerson then
                npc.hugPerson = HugPerson.new(npc.name)
                npc.hugPerson.npc = npc
            end

            local t = 1.0 - dist / Npc.maxDistanceToGetHugged

            --print ("n: "..npc.name)

            npc.hugPerson.distanceFromBear = dist

        elseif npc.hugPerson and (dist >= Npc.maxDistanceToGetHugged) then
            npc.hugPerson.disabled = true
            npc.hugPerson = nil
        end

        coroutine.yield()
    end

    -- switch to corpse
    local eyes = makeProp(Npc.eyesDeck, Npc.layer, 1, 1, Npc.basePriority + 2)
    eyes:setParent(npc.node)
    eyes:setLoc(0,0.9)
    npc.eyes = eyes

    npc.node:seekRot(-90,2)
end

-- npc is the body, .prop is the prop
function Npc.makeNPC(name, x, y)
    local npcDef = Npc.npcDefs[name]

    if not npcDef then
        print("WTF! No def for " .. name)
        return
    end

    local npc = g_box2d:addBody ( MOAIBox2DBody.DYNAMIC )
    npc:addCircle(0,0,0.49)
    npc:setTransform ( x, y )
    npc:setFixedRotation ( true )
    npc:setMassData ( 1 )
    npc:setLinearDamping( Npc.damping )

    local node = MOAIProp2D.new()
    node:setParent(npc)
    node:setPiv(0,-0.25)
    Npc.layer:insertProp(node)

    local prop = makeProp(Npc.npcScaredDeck, Npc.layer, 2, 2, Npc.basePriority)
    prop:setParent(node)
    prop:setLoc(0,0.5)
    prop:setColor(math.random(0.2,1),math.random(0.2,1),math.random(0.2,1),1)

    local head = makeProp(npcDef.happyFaceDeck, Npc.layer, 1, 1, Npc.basePriority + 1)
    head:setParent(node)
    head:setLoc(0,1)

    npc.name = name
    npc.npcDef = npcDef
    npc.node = node
    npc.prop = prop
    npc.head = head
    npc.health = 100
    -- hugPerson.hugged says if they were successfully hugged
    npc.hugPerson = nil
    npc.beenHugged = false
    npc.dead = false
    npc.direction = math.random(0,360)
    npc.timeToChangeDirection = Npc.timeBetweenDirectionChanges

    npc.thread = MOAICoroutine:new()
    npc.thread:run(Npc.update, npc)

    function npc:final_state()
        if self.dead then
            return 'dead'
        elseif self.beenHugged then
            return 'happy'
        else
            return 'none'
        end
    end

    table.insert(Npc.npcs, npc)
end

function Npc.makeNpcs()
    local bx, by = g_map:get_bounds()

    for key, npcDef in pairs(Npc.npcDefs) do
        local insideCollision = 1
        local x = 0
        local y = 0

        while insideCollision~=0 do
            x = math.floor(math.random(1, bx - 1))
            y = math.floor(math.random(1, by - 1))
            
            insideCollision = g_map:query_collision(x,y)
        end

        Npc.makeNPC(key, x, y)
    end
end

function Npc.init(world, layer, basePriority)
    Npc.world = world
    Npc.layer = layer
    Npc.basePriority = basePriority

    Npc.makeNpcs()
end

return Npc
