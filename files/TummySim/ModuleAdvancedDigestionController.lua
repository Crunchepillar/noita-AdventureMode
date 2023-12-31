--[[
    HungryDigestionController

    Attempts to digest whatever material is most prominent in the player's
    MaterialInventoryComponent each time Tick is called. Requires a small
    amount of satiation from the IngestionComponent to ensure the player
    hasn't "relieved" themselves from the contents of their stomach early
]]

--Private vars
local BaseModule = dofile_once("mods/AdventureMode/files/ObjFactory/ObjModule.lua")
dofile_once("mods/AdventureMode/files/TummySim/MaterialDataTable.lua")

--Init new module
local This = BaseModule.New("TummyDigestionController", 10)
--This is to match a constant the game uses, do not modify
local SatiationPerCell = 6

---@param Material integer
---@param Amount number
---@return number
function GetHealingAmount(Material, Amount)
    return TryGetMaterialValue(Material) * Amount
end

---@param Material integer
---@param Amount number
---@return number
function GetSatiationCostToDigest(Material, Amount)
    local mValue = TryGetMaterialValue(Material)

    if (mValue < 0) then
        mValue = 0
    end

    return SatiationPerCell * (1 - mValue) * Amount
end

---@param Material integer
---@param Satiety number
---@return number
function GetDigestableAmount(Material, Satiety)
    local CostPerUnit = GetSatiationCostToDigest(Material, 1)
    return Satiety / CostPerUnit
end

---@param Context table
function This.Tick(_, Context)
    --Get Entities
    local Player = GetUpdatedEntityID()
    local CellInventory = EntityGetFirstComponent(Player, "MaterialInventoryComponent")
    local Tummy = EntityGetFirstComponent(Player, "IngestionComponent")

    --I see you, polymorph bug in the making
    if (Tummy == nil) then
        This:ModPrint("Player is probably polymorphed, skipping digestion", 1)
        return
    end

    --Skip digestion when the tummy is on cooldown, solidarity okay?
    if (ComponentGetValue2(Tummy, "m_ingestion_cooldown_frames") > 0) then
        return
    end

    if (CellInventory == nil) then
        This:ModPrint("CellInventory missing on player", 3)
        return
    end

    local CellInventoryTable = ComponentGetValue2(CellInventory, "count_per_material_type")
    if (CellInventoryTable == nil) then
        This:ModPrint("CellInventoryTable doesn't exist on player", 4)
        return
    end

    --set variables
    local SatiationThisUpdate = 0
    local Satiation = ComponentGetValue2(Tummy, "ingestion_size")
    local NextMaterial = GetMaterialInventoryMainMaterial(Player, false)

    --Main loop
    while (NextMaterial > 0) and (SatiationThisUpdate < Context.Settings.ExpSatiationTarget) do
        --Consume materials

        --Seriously reduce digestion if we're at max healing
        if (Context.Health.StoredHealing == Context.Settings.MaxNourishment) then
            SatiationThisUpdate = SatiationThisUpdate + (Context.Settings.ExpSatiationTarget * 0.7)
            This:ModPrint("Slow digestion this frame", 1)
        end

        --We have to do this because the table is off by 1 (??)
        local Amount = CellInventoryTable[NextMaterial + 1]
        local TotalAmount = Amount
        local MaxAmount = GetDigestableAmount(NextMaterial, Context.Settings.ExpSatiationTarget - SatiationThisUpdate)

        --Trim the amount we're digesting if it is too high
        if (MaxAmount < Amount) then
            Amount = MaxAmount
        end

        local Cost = GetSatiationCostToDigest(NextMaterial, Amount)

        This:ModPrint(
            "Material " ..
            tostring(CellFactory_GetName(NextMaterial) .. " amount: " .. tostring(Amount) .. " cost: " .. tostring(Cost)),
            1)

        SatiationThisUpdate = SatiationThisUpdate + Cost

        --Don't do health/tummy if tummy is empty
        if (Satiation > 0) then
            --Modify health storage
            Context.Health:ModifyStoredHealth(GetHealingAmount(NextMaterial, Amount))
            --Modify tummy storage
            ComponentSetValue2(Tummy, "ingestion_size", Satiation - (Cost * Context.Settings.ExpSatiationRatio))

            This:ModPrint("Added to health storage this update", 1)

            --Modify material inventory
            AddMaterialInventoryMaterial(Player, CellFactory_GetName(NextMaterial), TotalAmount - Amount)
        else
            --Clear material inventory, tummy is empty
            AddMaterialInventoryMaterial(Player, CellFactory_GetName(NextMaterial), 0)
            This:ModPrint("Cleared a material inventory due to empty tummy", 1)
        end

        --Update our control values
        Satiation = ComponentGetValue2(Tummy, "ingestion_size")
        NextMaterial = GetMaterialInventoryMainMaterial(Player, false)
    end
end

return This
