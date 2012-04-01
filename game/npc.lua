local Npc = {
    npcs = {},

    npcDefs = {},

    npcHappyDeck = makeDeck('characters/npc_standing_front_happy'),
    npcScaredDeck = makeDeck('characters/npc_standing_front_scared'),
}


function _makeNPCDef(name)
    local npcDef = {
        hugPersonData = HugPerson.MakePersonData(name),
        happyFaceDeck = makeDeck('face/'..name..'_happy_head'),
        scaredFaceDeck = makeDeck('face/'..name..'_scared_head'),
    }

    npcDefs[name] = npcDef
end

-- npc is the body, .prop is the prop
function Npc.makeNPC(name, x, y)
    local npcDef = npcDefs[name]

    if not npcDef then
        print("WTF! No def for " .. name)
        return
    end

    local npc = g_box2d:addBody ( MOAIBox2DBody.DYNAMIC )
    npc:addCircle(0,0.0.49)
    npc:setTransform ( x, y )
    npc:setFixedRotation ( true )
    npc:setMassData ( 1 )
    npc:setLinearDamping( BEAR_DAMPING )

    local prop = makeProp(Npc.npcScaredDeck, Npc.layer, 2, 2, Npc.basePriority)
    prop:setParent(npc)

    npc.npcDef = npcDef
    npc.prop = prop

end

function Npc.init(world, layer, basePriority)
    Npc.world = world
    Npc.layer = layer
    Npc.basePriority = basePriority
end



return Npc
