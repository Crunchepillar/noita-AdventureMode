dofile_once("mods/AdventureMode/files/utils/DebugPrint.lua")

--[[
    Material Data Table used to store healing for the advanced tummy simulation.
    Values are listed in StoredHealing / CellConsumed. A flask of liquid can store
    1000 cells of material. Other notable measures include: The player's default maximum
    ingestion size (their whole stomach) is about 7500 cells. A player will consume around
    75 - 90 cells from the world while eating
]]

local MaterialDataTable = {}

local function AddToMaterialTable(Material, Value)
    MaterialDataTable[CellFactory_GetType(Material)] = Value
end

--[[
        STANDARD MATERIALS:

        Water is everywhere so the number has to be low or we can suck it up for healing
    ]]
AddToMaterialTable("water", 0.010)
AddToMaterialTable("water_ice", 0.009)
AddToMaterialTable("water_salt", 0.008)
--These two induce vomiting so they wil rarely do anything useful
AddToMaterialTable("swamp", 0.005)
AddToMaterialTable("water_swamp", 0.005)
--I only know GRASS out of all of these, think they're just recolors
AddToMaterialTable("grass", 0.005)
AddToMaterialTable("grass_dark", 0.005)
AddToMaterialTable("grass_dry", 0.005)
AddToMaterialTable("ice", 0.009)

--[[
        Meat will not become "warm" "hot" "done" or "burnt" without oil so
        it seems there is an oil that is suited both to burning and cooking in Noita
        Either way, oil is unpleasant and the player will throw it up so we're not
        likely to get much out of it
    ]]
AddToMaterialTable("oil", 0.015)

--[[
        MEAT:

        Meat is a tough one to decide because it should obviously be better than
        things like water but most things don't leave behind much meat. Blood and
        water may be less valuable numerically but they're everywhere and you can
        bottle them.
    ]]
AddToMaterialTable("meat", 0.130)
--teehee
AddToMaterialTable("meat_helpless", 0.145)
AddToMaterialTable("meat_warm", 0.160)
AddToMaterialTable("meat_hot", 0.180)
AddToMaterialTable("meat_done", 0.230)
--This is called "Stinky Meat", it can't taste good
AddToMaterialTable("meat_polymorph_protection", 0.115)

--Bad Meat
AddToMaterialTable("meat_slime", -0.050)
AddToMaterialTable("meat_slime_green", -0.050)
AddToMaterialTable("meat_slime_cursed", -0.050)
AddToMaterialTable("meat_burned", -0.050)

--[[
        BLOOD:

        Blood is plentiful and can sorta be farmed by using a plasma cutter on a corpse.
        Can't say I'm opposed to the idea since its kinda works like dressing game
        Worm blood is certainly a bit harder to find and has no negative effects
    ]]
AddToMaterialTable("blood", 0.020)
AddToMaterialTable("blood_fading", 0.015)
AddToMaterialTable("blood_fading_slow", 0.015)
AddToMaterialTable("blood_worm", 0.020)
--No real analogue for this. Fungus don't really have blood, how nutritious is it?
AddToMaterialTable("blood_fungi", 0.015)

--[[
        ALCHOHOL:

        Whiskey, Juhannussima and Sima are all various strengths of fermented beverage

        Given how incredibly intoxicated whiskey gets the player I've always treated
        it (in other mods) as tho it was a very high proof distilled spirit made for
        alchemical use (such as creating tinctures/essence infusions)

        The other two are both types of Finnish Holiday Mead that only show up in game
        on their specific holdiays.
    ]]
AddToMaterialTable("alcohol", 0.012)
AddToMaterialTable("sima", 0.016)
AddToMaterialTable("juhannussima", 0.016)

--[[
        PREPARED FOOD

        This only includes the two items right now. Not much prepared food in Noita
    ]]
AddToMaterialTable("porridge", 0.250)
AddToMaterialTable("pea_soup", 0.250)

--[[
        MAGIC:

        Ambrosia is an emetic and has no benefits taken orally so it may as well pay
        out a bit of healing in the short time its in your tum
    ]]
AddToMaterialTable("magic_liquid_protection_all", 0.060)

--[[
        HARMFUL:

        The player will probably puke these up before long but its worth being thorough
        and having a punishment for the brief time they were in Mina's tummy.
    ]]
AddToMaterialTable("vomit", -0.080)
AddToMaterialTable("poison", -0.100)
AddToMaterialTable("urine", -0.010)

--[[
        OTHER:

        I dunno what to do with these, tbh.
    ]]
AddToMaterialTable("material_rainbow", 0.001)

--[[
        The numbers in this table are super suspect. I can't do any better
        because it is based on generic tags to try and match mod content
        or any I was too lazy to make into specific material matches
]]

local GenericTagsTable = {
    ["[food]"] = 0.080,
    ["[blood]"] = 0.015,
    ["[meat]"] = 0.100,
    ["[magic_liquid]"] = -0.020,
    ["[magic_faster]"] = -0.020,
    ["[magic_polymorph]"] = -0.020,
    ["[plant]"] = 0.004,
    ["[radioactive]"] = -0.020,
    ["[regnerative]"] = -0.010,
    ["[water]"] = 0.006,
    ["[cold]"] = -0.005,
    ["[frozen]"] = -0.006,
    ["[fungus]"] = 0.030,
    ["[sand_ground]"] = -0.015,
    ["[earth]"] = -0.015,
    ["[molten_metal]"] = -0.05,
    ["[slime]"] = -0.30,
}

--[[
    With this beauty we don't look up the same material twice in a game session.
    Since each lookup in the generic table can be up to 10+ iterations of the
    whole generic table this saves a bit of overhead
]]

local GenericMaterialCache = {

}

---@param MaterialID integer
---@return number
function GetSpecificMaterialValueByID(MaterialID)
    return MaterialDataTable[MaterialID]
end

---@param Material string
---@return number
function GetSpecificMaterialValueByName(Material)
    return GetSpecificMaterialValueByID(CellFactory_GetType(Material))
end

---comment
---@param MaterialID integer
---@return number
function GetGenericMaterialValue(MaterialID)
    --Return cached material data
    if (GenericMaterialCache[MaterialID]) then
        dPrint("Using material cache for ID " .. tostring(MaterialID), "MaterialDataTable", 1)
        return GenericMaterialCache[MaterialID]
    end

    local Total = 0.0
    local Tags = CellFactory_GetTags(MaterialID)

    if (Tags == nil) then
        return 0.0
    end

    for _, value in pairs(Tags) do
        if (GenericTagsTable[value]) then
            Total = Total + GenericTagsTable[value]
        end
    end

    GenericMaterialCache[MaterialID] = Total
    dPrint("Caching " .. tostring(Total) .. " for generic material ID " .. tostring(MaterialID), "MaterialDataTable", 1)

    return Total
end

---comment
---@param MaterialID integer
---@return number
function TryGetMaterialValue(MaterialID)
    if (MaterialDataTable[MaterialID]) then
        return MaterialDataTable[MaterialID]
    end

    return GetGenericMaterialValue(MaterialID)
end
