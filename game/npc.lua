local Npc = {
    npcs = {},

    npcDefs = {},

    npcHappyDeck = makeDeck('characters/npc_standing_front_happy'),
    npcScaredDeck = makeDeck('characters/npc_standing_front_scared'),
    eyesDeck = makeDeck('characters/x_eyes'),

    timeBetweenDirectionChanges = 3,

    force = 50,
    damping = 20,
}


function _makeNPCDef(name)
    local npcDef = {
        hugPersonData = HugPerson.MakePersonData(name),
        happyFaceDeck = makeDeck('faces/'..name..'_happy_head'),
        scaredFaceDeck = makeDeck('faces/'..name..'_scared_head'),
    }

    print('FACE: faces/'..name..'_happy_head')
    Npc.npcDefs[name] = npcDef
end

_makeNPCDef('ChrisJurney')
_makeNPCDef('AnnaKipnis')
_makeNPCDef('adam')
_makeNPCDef('benmj')
_makeNPCDef('chrisremo')
_makeNPCDef('christianmalone')
_makeNPCDef('davidburns')
_makeNPCDef('deantate')
_makeNPCDef('deniserockwell')
_makeNPCDef('elizabeth')
_makeNPCDef('garydootan')
_makeNPCDef('GavinFitzgerald')
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

        coroutine.yield()
    end

    -- switch to corpse
    local eyes = makeProp(Npc.eyesDeck, Npc.layer, 1, 1, Npc.basePriority + 2)
    eyes:setParent(prop)
    eyes:setLoc(0,0.75)
    npc.eyes = eyes

    npc.prop:seekRot(-90,2)
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

    local prop = makeProp(Npc.npcScaredDeck, Npc.layer, 2, 2, Npc.basePriority)
    prop:setParent(npc)
    prop:setPiv(0,-0.25)

    local head = makeProp(npcDef.happyFaceDeck, Npc.layer, 1, 1, Npc.basePriority + 1)
    head:setParent(prop)
    head:setLoc(0,0.5)

    npc.npcDef = npcDef
    npc.prop = prop
    npc.head = head
    npc.health = 100
    npc.hugPerson = nil
    npc.dead = false
    npc.direction = math.random(0,360)
    npc.timeToChangeDirection = Npc.timeBetweenDirectionChanges

    npc.thread = MOAICoroutine:new()
    npc.thread:run(Npc.update, npc)

    table.insert(Npc.npcs, npc)
end

function Npc.makeNpcs()
    local bx, by = g_map:get_bounds()

    print('bounds: '..bx..' '..by)

    for key, npcDef in pairs(Npc.npcDefs) do
        local insideCollision = 1
        local x = 0
        local y = 0

        while insideCollision~=0 do
            print ("name "..key)
            x = math.floor(math.random(1, bx - 1))
            y = math.floor(math.random(1, by - 1))
            
            insideCollision = g_map:query_collision(x,y)

            print("name "..key.." tx "..x.." ty "..y.." coll "..insideCollision)
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
