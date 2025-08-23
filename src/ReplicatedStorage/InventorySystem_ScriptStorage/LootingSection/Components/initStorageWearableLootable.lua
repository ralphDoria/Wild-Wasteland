local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_ItemSystem = require(game:GetService("ReplicatedStorage").RojoManaged_RS.ItemSystem_ScriptStorage.References_ItemSystem)

local lootingSectionComponents = ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components
local initClientLootable = require(lootingSectionComponents.initClientLootable)
local LootGuiManager = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components.LootGuiManager)

local Trove = require(ReplicatedStorage.Packages.Trove)

local function initStorageWearableLootable(storageWearable: Tool)
    local lootPrompt: ProximityPrompt, lootHighlight: Highlight = initClientLootable(storageWearable)
    lootHighlight:Destroy() -- Tool highlight will be used instead

    local toolPrompt: ProximityPrompt
    local toolBodyAttach = storageWearable:WaitForChild("BodyAttach")
    repeat 
        toolPrompt = toolBodyAttach:FindFirstChildOfClass("ProximityPrompt")
        task.wait()
    until toolPrompt ~= nil

    toolPrompt.UIOffset = Vector2.new(0, 15)
    lootPrompt.UIOffset = Vector2.new(0, -15)
    lootPrompt.ObjectText = ""
    lootPrompt.Enabled = false
    lootPrompt.MaxActivationDistance = toolPrompt.MaxActivationDistance

    local trove = Trove.new()
    
    -- Use trove for connection management
    trove:Connect(toolPrompt.PromptShown, function()  
        lootPrompt.Enabled = true
    end)
    
    trove:Connect(toolPrompt.PromptShown, function()  
        lootPrompt.Enabled = false
    end)
    
    local soundObjects = References_ItemSystem.ToolInfo.get(storageWearable.Name).soundObjects
    -- TODO: in the future, storage wearable open/close sounds will be generalized to open/close, & not be named just openLootable/closeLootable
    local openLootable: Sound = soundObjects.openLootable
    local closeLootable: Sound = soundObjects.closeLootable
    
    trove:Connect(toolPrompt.PromptButtonHoldBegan, function()
        lootPrompt.Enabled = false
    end)
    
    trove:Connect(toolPrompt.PromptButtonHoldEnded, function(a0: Player)  
        lootPrompt.Enabled = true
    end)
    
    trove:Connect(lootPrompt.PromptButtonHoldBegan, function()
        openLootable:Play()
        closeLootable:Stop()
    end)
    
    trove:Connect(lootPrompt.PromptButtonHoldEnded, function()
        openLootable:Stop()
    end)

    -----
    -- Character Dependent functionality
    -----
    local function getWearableCategoryFolder(): Folder
        local WornItems = References_ItemSystem.player.Backpack:WaitForChild("WornItems"):: Folder
        local wearableCategory = storageWearable:GetAttribute("WearableCategory") 
        local wearableCategoryFolder = WornItems[wearableCategory]:: Folder
        assert(wearableCategory, "characterDependentReferences.WearableCategoryFolder not found")

        return wearableCategoryFolder
    end

    local characterDependentReferences = {
        wearableCategoryFolder = nil,
        isWearingBackpackAlready = false,
        connections = {}    
    }

    local isEmpty_server: boolean = storageWearable:GetAttribute("isEmpty_server"):: boolean

    local function updatePromptText()
        print(isEmpty_server, characterDependentReferences.isWearingBackpackAlready)
        if not isEmpty_server and characterDependentReferences.isWearingBackpackAlready then
            toolPrompt.ActionText = "Swap"
        elseif not isEmpty_server and not characterDependentReferences.isWearingBackpackAlready then
            toolPrompt.ActionText = "Put On"
        elseif isEmpty_server then
            toolPrompt.ActionText = "Pick Up"
        end
    end

    local function connectCharacterDependentSignals()
        characterDependentReferences.connections.wearableOfSameCategoryPutOn = characterDependentReferences.wearableCategoryFolder.ChildAdded:Connect(function(tool: Tool) 
            assert(tool:IsA("Tool"), "Only tools are supposed to be inserted here")
            characterDependentReferences.isWearingBackpackAlready = true

            updatePromptText()
        end)
        characterDependentReferences.connections.wearableOfSameCategoryTakenOff = characterDependentReferences.wearableCategoryFolder.ChildRemoved:Connect(function(tool: Tool)
            assert(tool:IsA("Tool"), "Only tools are supposed to be inserted here")
            characterDependentReferences.isWearingBackpackAlready = false

            updatePromptText()
        end)
    end

    local function onReferencedUpdated()
        characterDependentReferences.wearableCategoryFolder = getWearableCategoryFolder()
        characterDependentReferences.isWearingBackpackAlready = characterDependentReferences.wearableCategoryFolder:FindFirstChildOfClass("Tool") ~= nil
        for _, v in characterDependentReferences.connections do
            v:Disconnect()
        end
        connectCharacterDependentSignals()
    end

    onReferencedUpdated()

    trove:Connect(References_ItemSystem.updated, function()
        onReferencedUpdated()
    end)

    trove:Connect(storageWearable:GetAttributeChangedSignal("isEmpty_server"), function()  
        isEmpty_server = storageWearable:GetAttribute("isEmpty_server"):: boolean
        updatePromptText()
    end)

    trove:Connect(toolPrompt:GetPropertyChangedSignal("Enabled"), function(...: any) 
        lootPrompt.Enabled = toolPrompt.Enabled
    end)

    trove:Connect(LootGuiManager.renderChanged, function(lootableInstance: (Tool)?)
        -- print(self.State)
        if storageWearable.Parent == workspace then
            -- print(`render changed to {lootableInstance}`)
            toolPrompt.Enabled =  lootableInstance ~= storageWearable
        end
    end)


    storageWearable.Destroying:Once(function(...: any)  
        trove:Destroy()
        for _, v in characterDependentReferences.connections do
            v:Disconnect()
        end
        table.clear(characterDependentReferences)
    end)
end

return initStorageWearableLootable