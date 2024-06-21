--maybe modify this in the future by centralizing it (making it so there's only one of this script in the server) & use CollectionService
local tool = script.Parent.Parent
local ProximityPrompt = tool:WaitForChild("BodyAttach"):WaitForChild("PickUpPrompt")
if tool.Parent:IsA("Backpack") then
    ProximityPrompt.Enabled = false
end
local pickUpSound = game:GetService("SoundService"):WaitForChild("Item Pick Up")

--[[
    ProximityPrompt event for picking up the tool
]]
ProximityPrompt.Triggered:Connect(function(playerWhoTriggered)
    local backpack = playerWhoTriggered:WaitForChild("Backpack")
    if backpack then
        pickUpSound:Play()
        tool.Parent = backpack
    end
end)

--[[
    Loops through each part in the ToolModel (which is a model inside of every tool in this game that stores all the physicals parts of the 
    tool) and sets CanCollide to either true or false depending on the @Param shouldEnable
]]
local function modifyToolModelCollisions(toolModel : Model, shouldEnable : boolean)
    if shouldEnable then
        for _, v in toolModel:GetChildren() do
            if v:IsA("BasePart") then
                v.CanCollide = true
            end
        end
    else
        for _, v in toolModel:GetChildren() do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
end

--[[
    Turns the tool model's collisions off or on depending on whether the tool is equipped or not.
]]
tool.AncestryChanged:Connect(function(child, parent)
    local toolModel = tool:FindFirstChild("ToolModel")
    if parent:FindFirstChild("Humanoid") == nil and not parent:IsA("Backpack") then --if the tool isn't equipped by a player or npc
        ProximityPrompt.Enabled = true
        if toolModel then
            modifyToolModelCollisions(toolModel, true)
        else
            warn("ToolModel not found in " .. tool.Name)
        end
    else
        --tool has been equipped by a player or npc
        ProximityPrompt.Enabled = false
        if toolModel then
            modifyToolModelCollisions(toolModel, false)
        else
            warn("ToolModel not found in " .. tool.Name)
        end
    end
end)