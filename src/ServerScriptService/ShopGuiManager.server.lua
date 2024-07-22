local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolCatalog = require(game:GetService("ServerScriptService"):FindFirstChild("ToolCatalog", true))
local rev_initializeShopGui : RemoteEvent = ReplicatedStorage:FindFirstChild("InitializeShopGui", true)
local rfn_getToolModel : RemoteFunction = ReplicatedStorage:FindFirstChild("GetToolModel", true)

Players.PlayerAdded:Connect(function(player : Player)
    local PlayerGui = player.PlayerGui
    local shopUI :  ScreenGui = PlayerGui:WaitForChild("ShopUI")
   
    --items frame
    local itemCatalog : ScrollingFrame = shopUI:FindFirstChild("Catalog", true)
    local template : TextButton = itemCatalog.Template
    --type tab
    local types = {}
        --initialize types table
    for _, v in shopUI:FindFirstChild("TypeTab", true):GetChildren() do
        if v:IsA("TextButton") then
            types[v.Name] = shopUI:FindFirstChild(v.Name, true)
        end
    end

    --use the template to create text buttons for all weapons in tool catalog
    for toolName, info in ToolCatalog do
        local itemButton : TextButton = template:Clone()
        itemButton.Text, itemButton.Name = toolName, toolName
        itemButton.Parent = itemCatalog
        itemButton:SetAttribute("Type", info.Type)
        itemButton:SetAttribute("Price", info.Price)
        rev_initializeShopGui:FireClient(player, itemButton)
    end
    template:Destroy()

    --for sorting items by type
    for _, tab in types do
        rev_initializeShopGui:FireClient(player, tab)
    end

    rev_initializeShopGui:FireClient(player, "Completed")
end)

--for the viewport frame
rfn_getToolModel.OnServerInvoke = function(player : Player, toolName : string)
    local toolModel : Model = ToolCatalog[toolName].Model:Clone()
    toolModel.Parent = ReplicatedStorage
    return toolModel
end