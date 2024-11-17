local CollectionService = game:GetService("CollectionService")
local GuiController = require(script.Parent.LootingGuiController)
local TAG_LOOT_CONTAINER = "LootContainerPP"
local rev_toggleOpen = game:GetService("ReplicatedStorage").LootingSystem:FindFirstChild("toggleOpen", true)
local exit : TextButton = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("LootingGui").Exit

GuiController.init()

local function handleLootContainerTag(taggedInstance)
    local pp = taggedInstance
    local hingeConstraint = pp.Parent.Parent:FindFirstChildWhichIsA("HingeConstraint", true)

    pp.Triggered:Connect(function()

        rev_toggleOpen:FireServer(true, hingeConstraint)
        pp.Enabled = false
        GuiController.showGui()
    
        exit.MouseButton1Click:Once(function()
            GuiController.closeGui()
            pp.Enabled = true
            rev_toggleOpen:FireServer(false, hingeConstraint)
        end)

    end)

end

for _, taggedInstance in CollectionService:GetTagged(TAG_LOOT_CONTAINER) do
    handleLootContainerTag(taggedInstance)
end
CollectionService:GetInstanceAddedSignal(TAG_LOOT_CONTAINER):Connect(function(taggedInstance)
    handleLootContainerTag(taggedInstance)
end)