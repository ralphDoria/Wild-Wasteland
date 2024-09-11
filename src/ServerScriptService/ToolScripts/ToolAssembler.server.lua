local ToolCatalog = require(script.Parent:WaitForChild("ToolCatalog"))
local proxProm : ProximityPrompt = game:GetService("ServerStorage").ToolModels:FindFirstChildOfClass("ProximityPrompt")
local rev_giveItem : RemoteEvent = game:GetService("ReplicatedStorage"):FindFirstChild("GiveItem", true)

local function assembleTool(toolName : String, parent)
    --Exception Handler
    if ToolCatalog[toolName] == nil then
        warn(toolName .. " cannot be created: does not exist in ToolCatalog")
        return
    end

    --assmebling the tool
    local tool : Tool = ToolCatalog[toolName].ToolObject:Clone()
    local scripts = ToolCatalog[toolName].Scripts:Clone()
    scripts.Parent = tool

    local bodyAttach = tool:FindFirstChild("BodyAttach")
    if bodyAttach then
        local x = proxProm:Clone()
        x.ObjectText = "\"" .. string.upper(tool.Name) .. "\""
        x.ActionText = "[PICK UP]"
        x.Parent = bodyAttach
    else
        print("tool is missing body attach")
    end

    --enabling the scripts
    for _, file : Script in scripts:GetChildren() do
        if not file:IsA("ModuleScript") and not file.Enabled then
            file.Enabled = true
        end
    end

    --puts tool in specified parent
    tool.Parent = parent
    tool:AddTag("PUP")
    tool:AddTag("Droppable")
    --print(toolName .. " was successfully created: " .. tool.ClassName)
    return tool
end

local Players = game:GetService("Players")
--[[
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        assembleTool("Beretta", player.Backpack)
        assembleTool("Raider Axe", player.Backpack)
        assembleTool("Healing Injection", player.Backpack)
        assembleTool("Healing Injection", player.Backpack)
        assembleTool("Healing Injection", player.Backpack)
        --assembleTool("Beretta", player.Backpack)
    end)
end)
]]

rev_giveItem.OnServerEvent:Connect(function(player, itemName)
    if ToolCatalog[itemName] == nil then warn(itemName .. " is not a valid item name") return end
    local currencyAmount = player:GetAttribute("Caps")
    local price = ToolCatalog[itemName].Price
    if currencyAmount >= price then
        player:SetAttribute("Caps", currencyAmount - price)
        assembleTool(itemName, player.Backpack)
    else
        --this either means the client that called this is hacking or I need to change the name of this remote function name to purchaseItem
        warn("How did you call this remote, huhhhhhh??????")
    end
end)