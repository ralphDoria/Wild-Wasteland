local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local remotes: {[string] : RemoteEvent} = {
    ToggleWear = ToolSystem_Storage.Wearable.Remotes.ToggleWear,
    OnWorn = ToolSystem_Storage.Wearable.Remotes.OnWorn,
    CreateWornItemStorage = ToolSystem_Storage.Wearable.Remotes.CreateWornItemStorage
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

    remotes.CreateWornItemStorage.OnServerEvent:Connect(function(player: Player, validWearableCategories)  
        local WornItems: Folder = Instance.new("Folder")
        WornItems.Name = "WornItems"
        for _, v in validWearableCategories do
            local folder = Instance.new("Folder")
            folder.Name = v
            folder.Parent = WornItems
        end
        WornItems.Parent = player.Backpack
    end)

    remotes.OnWorn.OnServerEvent:Connect(function(player: Player, tool: Tool, wearableCategory)
        
    end)
end
