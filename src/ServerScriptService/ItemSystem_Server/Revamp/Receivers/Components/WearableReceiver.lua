local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ItemSystem_Storage = ReplicatedStorage:FindFirstChild("ItemSystem_Storage", true)
local Type_Equipment = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.CharacterSection.Components.Type_Equipment)

local remotes = {
    ToggleWear = ItemSystem_Storage.Wearable.Remotes.ToggleWear:: RemoteEvent,
    OnWorn = ItemSystem_Storage.Wearable.Remotes.OnWorn:: RemoteEvent,
    MakeAccessoryVisibleOnDeath = ItemSystem_Storage.Wearable.Remotes.MakeAccessoryVisibleOnDeath:: RemoteEvent
}

-- Shared server-authority boundary + the catalog (for validating the template accessory).
local Validation = require(script.Parent.Parent.Validation)
local ToolCatalog: Folder = ReplicatedStorage:FindFirstChild("ToolCatalog", true)



return function()
    remotes.ToggleWear.OnServerEvent:Connect(function(player: Player, toggle: boolean, character: Model, originalAccessory: Accessory, thisAccessory: Accessory, tool: Tool, wearableCategory)
        -- Every argument is client-supplied; validate before mutating anything (C13).
        if typeof(toggle) ~= "boolean" or character ~= player.Character then
            return
        end
        -- The tool must be a Tool the sender owns (ownsTool covers character / Backpack, and WornItems
        -- which lives under the Backpack).
        if not Validation.isInstance(tool, "Tool") or not Validation.ownsTool(player, tool) then
            return
        end
        -- Accessories must belong where they claim: thisAccessory inside the sender's own tool, and
        -- originalAccessory inside that tool's ToolCatalog template folder. Blocks cloning an
        -- arbitrary accessory onto the character or toggling visibility on a foreign accessory.
        local catalogFolder = ToolCatalog:FindFirstChild(tool.Name)
        if not Validation.isInstance(originalAccessory, "Accessory") or not Validation.isInstance(thisAccessory, "Accessory") then
            return
        end
        if not catalogFolder or not originalAccessory:IsDescendantOf(catalogFolder) or not thisAccessory:IsDescendantOf(tool) then
            return
        end
        -- The category indexes the WornItems folder — it must be a real equipment category.
        if typeof(wearableCategory) ~= "string" or not table.find(Type_Equipment.validWearableCategories, wearableCategory) then
            return
        end

        local WornItems: Folder? = player.Backpack:FindFirstChild("WornItems"):: Folder?
        if not WornItems then
            warn("[WearableReceiver] Rejecting ToggleWear: WornItems folder not found for", player)
            return
        end
        local wearableCategoryFolder: Folder? = WornItems:FindFirstChild(wearableCategory):: Folder?

        if toggle then
            local clone: Accessory = originalAccessory:Clone()
            clone.Name = originalAccessory.Name .. "Worn"
            clone.Parent = character
            for _, v in thisAccessory:GetChildren() do
                if v:IsA("BasePart") then
                    v.Transparency = 1
                end
            end
            if wearableCategoryFolder then
                tool.Parent = wearableCategoryFolder
            end
        else
            local accessory = character:FindFirstChild(originalAccessory.Name  .. "Worn", true)
            if accessory then
                accessory:Destroy()
            else
                warn(originalAccessory.Name .. "Worn" .. " not found, can't be destroyed")
            end
            for _, v in thisAccessory:GetChildren() do
                if v:IsA("BasePart") then
                    v.Transparency = 0
                end
            end
            if wearableCategoryFolder then
                tool.Parent = player.Character
            end
        end
    end)

    Players.PlayerAdded:Connect(function(player: Player)  
        player.CharacterAdded:Connect(function(character: Model)  
            local WornItems: Folder = Instance.new("Folder")
            WornItems.Name = "WornItems"
            for _, v in Type_Equipment.validWearableCategories do
                local folder = Instance.new("Folder")
                folder.Name = v
                folder.Parent = WornItems
            end
            WornItems.Parent = player.Backpack
        end)
    end)

    remotes.MakeAccessoryVisibleOnDeath.OnServerEvent:Connect(function(player: Player, accessory: Accessory)
        -- Only reveal an accessory that belongs to the sender (lives under their character or
        -- Backpack/WornItems) — not an arbitrary accessory passed in (C13).
        if not Validation.isInstance(accessory, "Accessory") then
            return
        end
        local character = player.Character
        local backpack = player:FindFirstChildOfClass("Backpack")
        local ownsAccessory = (character ~= nil and accessory:IsDescendantOf(character))
            or (backpack ~= nil and accessory:IsDescendantOf(backpack))
        if not ownsAccessory then
            return
        end
        for _, v in accessory:GetChildren() do
            if v:IsA("BasePart") then
                v.Transparency = 0
            end
        end
    end)

    remotes.OnWorn.OnServerEvent:Connect(function(player: Player, tool: Tool, wearableCategory)
        
    end)
end
