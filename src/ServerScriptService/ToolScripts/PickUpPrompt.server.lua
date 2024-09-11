--maybe modify this in the future by centralizing it (making it so there's only one of this script in the server) & use CollectionService

------------------------------------------------------------------------<<<ROBLOX LIBRARIES & SERVICES>>>
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------<<<LOCAL VARIABLES>>>
local COLLECTION_TAG = "PUP" --acronym for Pick Up Prompt   

------------------------------------------------------------------------<<<Modules (Classes, Data Package, Utility, Functional)>>>
local playSound = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("PlaySoundUtil"))

------------------------------------------------------------------------<<<SFX>>>
local pickUpSound = game:GetService("SoundService"):WaitForChild("Item Pick Up")

------------------------------------------------------------------------<<<FUNCTIONS>>>
local function handleTaggedInstance(taggedObject)
    assert(taggedObject:IsA("Tool"), "Instance with PickUpPrompt Collection Tag is not a tool that contains a PickUpPrompt inside of a BodyAttach")
    local tool = taggedObject
    local toolModel = tool:FindFirstChild("ToolModel")
    local SFX_part = if tool:FindFirstChild("SFX_part") then tool:FindFirstChild("SFX_part") else tool.BodyAttach
    local ProximityPrompt = tool:FindFirstChildWhichIsA("ProximityPrompt", true)

    if tool.Parent:IsA("Backpack") then
        ProximityPrompt.Enabled = false
        local toolModel = tool:FindFirstChild("ToolModel")
        for _, v in tool:WaitForChild("ToolModel"):GetChildren() do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end

    --[[
        ProximityPrompt event for picking up the tool
    ]]
    ProximityPrompt.Triggered:Connect(function(playerWhoTriggered)
        local humanoid : Humanoid = playerWhoTriggered.Character:FindFirstChild("Humanoid")
        if humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
            local backpack = playerWhoTriggered:WaitForChild("Backpack")
            if backpack then
                print("playing pickup sound")
                playSound(pickUpSound, SFX_part, 0)
                tool.Parent = backpack
            end 
        end
    end)

    --[[
        Loops through each part in the ToolModel (which is a model inside of every tool in this game that stores all the physicals parts of the 
        tool) and sets CanCollide to either true or false depending on the @Param shouldEnable
    ]]
    local function modifyToolModelCollisions(toolModel : Model, shouldEnable : boolean)
        if shouldEnable then
            for _, v in toolModel:GetDescendants() do
                if v:IsA("BasePart") or v:IsA("MeshPart") then
                    v.CanCollide = true
                end
            end
        else
            for _, v in toolModel:GetDescendants() do
                if v:IsA("BasePart") or v:IsA("MeshPart") then
                    v.CanCollide = false
                end
            end
        end
    end

    --[[
        Turns the tool model's collisions and ProximityPrompt off or on depending on whether the tool is equipped or not.
    ]]
    tool.AncestryChanged:Connect(function(child, parent)
        if parent and parent:FindFirstChild("Humanoid") == nil and not parent:IsA("Backpack") then --if the tool isn't equipped by a player or npc
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
end

------------------------------------------------------------------------<<<EVENT CONNECTIONS>>>
for _, v in CollectionService:GetTagged(COLLECTION_TAG) do
    handleTaggedInstance(v)
end
CollectionService:GetInstanceAddedSignal(COLLECTION_TAG):Connect(function(object)
    handleTaggedInstance(object)
end)