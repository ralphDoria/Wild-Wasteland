local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local remotes: {[string] : RemoteEvent} = {
    ToggleWear = ToolSystem_Storage.Wearable.Remotes.ToggleWear
}



return function()
    remotes.ToggleWear.OnServerEvent:Connect(function(player: Player, toggle: boolean, character: Model, originalAccessory: Accessory, thisAccessory: Accessory)  
        if toggle then
            local clone: Accessory = originalAccessory:Clone()
            clone.Name = originalAccessory.Name .. "Worn"
            clone.Parent = character
            for _, v in thisAccessory:GetChildren() do
                if v:IsA("BasePart") then
                    v.Transparency = 1
                end
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
                    v.Transparency = 1
                end
            end
        end
    end)
end
