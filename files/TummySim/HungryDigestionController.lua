--Private vars
local BaseModule = dofile_once("mods/AdventureMode/files/ObjFactory/ObjModule.lua")
local Settings = dofile_once("mods/AdventureMode/files/SettingsCache.lua")

--Init new module
local This = BaseModule.New("HungryDigestionController")

--Entities
local Player
local CellInventory
local CellInventoryTable

--Vars
local DigestionPerFrame
local DigestedThisFrame

---@param Material integer
---@param Context table
function DigestMaterial(Material, Context)

    local Healing = 0

    --We have to do this because the table is off
    local Amount = CellInventoryTable[Material+1]

    --Skip very small amounts
    if (Amount < 1) then
        This:ModPrint("Skipping digestion this frame, too low contents")
        DigestedThisFrame = DigestionPerFrame
        return
    end

    local TotalAmount = Amount
    local MaterialString = CellFactory_GetName(Material)
    local DigestionLeftThisFrame = DigestionPerFrame - DigestedThisFrame
    local MaterialValue = 0

    if (Amount == 0) then
        This:ModPrint("[WARNING] amount is 0 for MaterialID: "..tostring(Material).." "..MaterialString)
    end

    if (GetIsInSpecificTable(MaterialString)) then
        MaterialValue = GetSpecificMaterialValue(MaterialString)
    else
        MaterialValue = GetGenericMaterialValue(Material)
    end

    if (MaterialValue ~= 0) then
        if (Amount > DigestionLeftThisFrame) then
            Amount = DigestionLeftThisFrame
        end

        --This function deceptively does not care what is already in the container and just
        --Overwrites it so we have to do the math for it
        AddMaterialInventoryMaterial(Player, MaterialString, TotalAmount - Amount)

        --Get healing
        Healing = MaterialValue * Amount
        --Add healing
        Context:ModifyStoredHealth(Healing)
        DigestedThisFrame = DigestedThisFrame + Amount

        This:ModPrint("Digesting "..tostring(Amount).." "..MaterialString.." for "..tostring(Healing).." healing.")
    else
        --Clear this material from the inventory
        AddMaterialInventoryMaterial(Player, MaterialString, 0)

        This:ModPrint("Skipping material "..MaterialString)
    end
end

--[[
    Todo: Require a small amount of satiation for each digestion tick
    This is to ensure the player didn't just vomit up their stomach
]]

---@param Context table
function This.Tick(Context)
    --Get Entities
    Player = GetUpdatedEntityID()
    CellInventory = EntityGetFirstComponent(Player, "MaterialInventoryComponent")

    --set variables
    DigestedThisFrame = 0
    DigestionPerFrame = 40

    if (Context.StoredHealing == Settings.MaxNourishment) then
        This:ModPrint("Slow metabolism this frame")
        DigestionPerFrame = math.ceil(DigestionPerFrame * 0.1)
    end

    if (CellInventory == nil) then
        This:ModPrint("Unable to find MaterialInventory on Player")
        return
    end

    CellInventoryTable = ComponentGetValue2(CellInventory, "count_per_material_type")

    if (CellInventoryTable == nil) then
        This:ModPrint("CellInventoryTable is nil")
        return
    end

    --[[
    for key, value in pairs(CellInventoryTable) do
        if (value > 0) then
            print(tostring(key), tostring(value))
        end
    end
    ]]--

    --Load MaterialDataTable
    dofile_once("mods/AdventureMode/files/TummySim/MaterialDataTable.lua")

    local Material = GetMaterialInventoryMainMaterial(Player, false)

    --Consume the material we have the most of until we've hit our cap for the frame
    while((DigestedThisFrame < DigestionPerFrame) and (Material ~= 0))
    do
        DigestMaterial(Material, Context)
        Material = GetMaterialInventoryMainMaterial(Player, false)
    end
end

return This