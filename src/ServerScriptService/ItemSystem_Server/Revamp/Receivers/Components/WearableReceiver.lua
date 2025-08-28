local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ItemSystem_Storage = ReplicatedStorage:FindFirstChild("ItemSystem_Storage", true)
local Type_Equipment = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.CharacterSection.Components.Type_Equipment)

local remotes = {
    ToggleWear = ItemSystem_Storage.Wearable.Remotes.ToggleWear:: RemoteEvent,
    OnWorn = ItemSystem_Storage.Wearable.Remotes.OnWorn:: RemoteEvent,
    MakeAccessoryVisibleOnDeath = ItemSystem_Storage.Wearable.Remotes.MakeAccessoryVisibleOnDeath:: RemoteEvent
}



return function()
    remotes.ToggleWear.OnServerEvent:Connect(function(player: Player, toggle: boolean, character: Model, originalAccessory: Accessory, thisAccessory: Accessory, tool: Tool, wearableCategory)  
        if toggle then
            local clone: Accessory = originalAccessory:Clone()
            clone.Name = originalAccessory.Name .. "Worn"
            clone.Parent = character
            for _, v in thisAccessory:GetChildren() do
                if v:IsA("BasePart") then
                    v.Transparency = 1
                end
            end
            local WornItems: Folder? = player.Backpack:FindFirstChild("WornItems"):: Folder?
            if WornItems then
                local wearableCategoryFolder: Folder? = WornItems:FindFirstChild(wearableCategory):: Folder?
                if wearableCategoryFolder then
                    tool.Parent = wearableCategoryFolder
                end 
            else
                error("Failed to properly store Wearable tool, WornItems folder not found")
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
            local WornItems: Folder? = player.Backpack:FindFirstChild("WornItems"):: Folder?
            if WornItems then
                local wearableCategoryFolder: Folder? = WornItems:FindFirstChild(wearableCategory):: Folder?
                if wearableCategoryFolder then
                    tool.Parent = player.Character
                end 
            else
                error("Failed to properly store Wearable tool, WornItems folder not found")
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
        for _, v in accessory:GetChildren() do
            if v:IsA("BasePart") then
                v.Transparency = 0
            end
        end
    end)

    remotes.OnWorn.OnServerEvent:Connect(function(player: Player, tool: Tool, wearableCategory)
        
    end)
end
