local Npc = {
    npcs = {},

    npcDefs = {},

    npcHappyDeck = makeDeck('characters/npc_standing_front_happy'),
    npcScaredDeck = makeDeck('characters/npc_standing_front_scared'),
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
    npc:setLinearDamping( BEAR_DAMPING )

    local prop = makeProp(Npc.npcScaredDeck, Npc.layer, 2, 2, Npc.basePriority)
    prop:setParent(npc)

    local head = makeProp(npcDef.happyFaceDeck, Npc.layer, 1, 1, Npc.basePriority + 1)
    head:setParent(npc)
    head:setLoc(0,0.75)

    npc.npcDef = npcDef
    npc.prop = prop
    npc.head = head

end

function Npc.init(world, layer, basePriority)
    Npc.world = world
    Npc.layer = layer
    Npc.basePriority = basePriority
end



return Npc
