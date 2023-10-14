--Private vars
local BaseModule = dofile_once("mods/AdventureMode/files/ObjFactory/ObjModule.lua")
local Settings = dofile_once("mods/AdventureMode/files/SettingsCache.lua")

--Init new module
local This = BaseModule.New("NourishmentIconController", 10)

---@param Context table
function This.Tick(Context)

    local Icon = EntityGetFirstComponent(GetUpdatedEntityID(), "UIIconComponent", "NourishIcon")

    --UIManagement
    if (Icon == nil) then
        This:ModPrint("Unable to access status icon", 3)
        return
    end

    --Set Icon
    local IconPath = "mods/AdventureMode/files/TummySim/img/store_waning.png"
    local IconName = "Nourishment (Barren) "

    if (Context.Health.StoredHealing >= 0.75 * Settings.MaxNourishment) then
        IconPath = "mods/AdventureMode/files/TummySim/img/store_good.png"
        IconName = "Nourishment (Good) "
        Context.Modifier = 0.75
    elseif (Context.Health.StoredHealing >= 0.50 * Settings.MaxNourishment) then
        IconPath = "mods/AdventureMode/files/TummySim/img/store_fair.png"
        IconName = "Nourishment (Satiated) "
        Context.Modifier = 0.50
    elseif (Context.Health.StoredHealing >= 0.25 * Settings.MaxNourishment) then
        IconPath = "mods/AdventureMode/files/TummySim/img/store_waning.png"
        IconName = "Nourishment (Meagre) "
        Context.Modifier = 0.00
    else
        IconPath = "mods/AdventureMode/files/TummySim/img/store_barren.png"
        IconName = "Nourishment (Barren) "
        Context.Modifier = -0.50
    end

    ComponentSetValue2(Icon, "icon_sprite_file", IconPath)

    --Update description
    local FormattedAmount = string.format("%.1f", Context.Health.StoredHealing)
    ComponentSetValue2(Icon, "name", IconName)
    ComponentSetValue2(Icon, "description", "Stored: "..FormattedAmount)
end

return This