local KEY_BIND_INVENTORY = Enum.KeyCode.Tab

----[[ SERVICES ]]----
local Players = game:GetService("Players") 
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

----[[ STANDARD PLAYER SPECIFIC VARIABLES ]]----
local player = Players.LocalPlayer 
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character.Humanoid
local backpack = player.Backpack -- the player's backpack (used to store all tools by default)

----[[ GUI VARIABLES ]]----
local gui : ScreenGui = player.PlayerGui:WaitForChild("InventoryAndHotbar")
local forModal : Textbutton = gui:FindFirstChild("ForModal")
local inventory : ScrollingFrame = gui:FindFirstChild("Inventory", true) -- the bag/inventory frame
local main : Frame = inventory.Parent
local wearables : Frame = gui:FindFirstChild("Wearables", true)
local hotbar : CanvasGroup = gui:FindFirstChild("Hotbar", true) -- the hotbar frame
local slotTemplate : CanvasGroup = gui:FindFirstChild("slotTemplate", true)

--[[ Array
]]

local slotNameToKeybind = {
	[1] = Enum.KeyCode.One,
	[2] = Enum.KeyCode.Two,
	[3] = Enum.KeyCode.Three,
	[4] = Enum.KeyCode.Four,
	[5] = Enum.KeyCode.Five,
	[6] = Enum.KeyCode.Six,
    [7] = Enum.KeyCode.Seven,
    [8] = Enum.KeyCode.Eight,
    [9] = Enum.KeyCode.Nine,
    [10] = Enum.KeyCode.Zero --there is no tenth number key on most keyboards, so the tenth slot is usually binded to 0
}

local inventoryAndHotbarManager = {}

--[[
    Has slot use TextButton or ImageButton based on whether the tool has a TextureId property that isn't nil.
]]
local function initializeSlotIcon(tool : Tool, slot)
    local imageButton : ImageButton = slot:FindFirstChildWhichIsA("ImageButton", true)
    local textButton : TextButton = slot:FindFirstChildWhichIsA("TextButton", true)
    local button
    if tool == nil then
        imageButton.Visible = false
        textButton.Visible = false
    else
        if tool.TextureId then
            imageButton.Image = tool.TextureId
            imageButton.Visible = true
            textButton.Visible = false
            button = imageButton
        else
            textButton.Text = tool.Name
            textButton.Visible = true
            imageButton.Visible = false
            button = textButton
        end
        slot.Visible = true

        --toggle equip/unequip & drag events
        local dragToggleTime : number = 0.1
        button.MouseButton1Down:Connect(function()
            local dragSlot
            local currentTime = tick()
            button.MouseButton1Up:Once(function() --USE UIS:INPUTENDED BECAUSE THIS DOESN'T WORK WELL FOR DRAG
                if tick() - currentTime <= dragToggleTime then
                    --toggle equip/unequip
                    print("Toggle equip/unequip")
                else
                    print("drag = false")
                    --[[
                    RunService:UnbindFromRenderStep("DraggingSlot")
                    if dragSlot then dragSlot:Destroy() end
                    ]]
                end
            end)
            task.spawn(function()
                task.wait(dragToggleTime)
                if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    print("drag = true")
                    --[[
                    RunService:BindToRenderStep("DraggingSlot", 200, function()
                        dragSlot = slot:Clone()
                        dragSlot.Parent = gui
                        dragSlot.Position = UserInputService:GetMouseLocation()
                    end)
                    ]]
                end
            end)
        end)

    end

    return slot
end

local function getNumberOfHotbarSlots()
    local count = 0
    for _, v in pairs(hotbar:GetChildren()) do
        if v:IsA(slotTemplate.ClassName) and v ~= slotTemplate then
            count += 1
        end
    end
    return count
end

local function getNumberOfInventorySlots()
    local count = 0
    for _, v in pairs(inventory:GetChildren()) do
        if v:IsA(typeof(slotTemplate)) then
            count += 1
        end
    end
    return count
end

local function getEmptyHotbarSlots()
    assert(getNumberOfHotbarSlots() == 10, "Hotbar not initialized to 10 slots.")

    local emptySlots = {}
    for _, v in ipairs(hotbar:GetChildren()) do
        if v:IsA(slotTemplate.ClassName) and v ~= slotTemplate then
            local hotbarSlot = v -- for readability
            if hotbarSlot:FindFirstChildOfClass("ObjectValue").Value == nil then
                table.insert(emptySlots, hotbarSlot)
            end
        end
    end
    return emptySlots
end

function inventoryAndHotbarManager.findMinimumEmptyHotbarSlot()
    assert(getNumberOfHotbarSlots() == 10, "Hotbar not initialized to 10 slots.")

    local emptySlots = getEmptyHotbarSlots()

    for i, _ in ipairs(slotNameToKeybind) do --remember that ipairs loops for arrays iterate in order
        for _, emptySlot in emptySlots do
            if tostring(i) == emptySlot.Name then
                return emptySlot --returns the smallest slot number that is empty
            end
        end
    end

    return nil --the hotbar is full (no slot is empty)
end

function inventoryAndHotbarManager.toggleInventory(toggle : boolean)
    forModal.Modal = toggle
    main.Visible = toggle
    for _, hotbarSlot in ipairs(getEmptyHotbarSlots()) do
        hotbarSlot.Visible = toggle
    end
end

function inventoryAndHotbarManager.createSlot(tool : Tool, hotbarOrInventory : string, hotbarSlotNumber : number)
    assert(hotbarOrInventory == "Hotbar" or hotbarOrInventory == "Inventory", hotbarOrInventory .. " is an invalid argument for this function.")

    local slot : CanvasGroup = initializeSlotIcon(tool, slotTemplate:Clone())
    slot:FindFirstChildOfClass("ObjectValue").Value = tool --remember that tool can be nil for hotbar slots
    local slotNumber : TextLabel = slot:FindFirstChild("Number", true)

    if hotbarOrInventory == "Hotbar" then
        assert(slotNameToKeybind[hotbarSlotNumber] ~= nil, tostring(hotbarSlotNumber) .. " is not a valid hotbar slot.")
        slot.LayoutOrder = hotbarSlotNumber
        slotNumber.Text = if hotbarSlotNumber == 10 then 0 else hotbarSlotNumber
        slotNumber.Visible = true
        slot.Name = tostring(hotbarSlotNumber)
        slot.Parent = hotbar
    elseif hotbarOrInventory == "Inventory" then
        local inventorySlotNumber = getNumberOfInventorySlots() + 1
        slot.LayoutOrder = inventorySlotNumber
        slotNumber.Visible = false
        slot.Name = tool.Name
        slot.Parent = inventory
    end
end

function inventoryAndHotbarManager.intitializeHotbar()
    for i = 1, 10, 1 do
        if hotbar:FindFirstChild(i) == nil then
            inventoryAndHotbarManager.createSlot(nil, "Hotbar", i)
        end
    end
    hotbar:SetAttribute("Initialized", true)
end

function inventoryAndHotbarManager.setHotbarSlot(tool : Tool, slot)
    initializeSlotIcon(tool, slot)
    slot:FindFirstChildOfClass("ObjectValue").Value = tool --remember that tool can be nil for hotbar slots
    if tool then
        tool:SetAttribute("HotbarSlot", slot.Name)
    else
        tool:SetAttribute("HotbarSlot", nil)
    end
end

function inventoryAndHotbarManager.toggleSlotEquippedEffect(slot, toggle : boolean)
    if toggle == true then
        Instance.new("UICorner").Parent = slot:FindFirstChild("innerFrame")
    else
        local uiCorner = slot:FindFirstChildWhichIsA("UICorner", true)
        if uiCorner then
            uiCorner:Destroy()
        end
    end
end

function inventoryAndHotbarManager.getSlotFromTool(tool : Tool)
    local source = if tool:GetAttribute("HotbarSlot") then hotbar else inventory
        print(source.Name)
    for _, slot in ipairs(source:GetChildren()) do
        if slot:FindFirstChildOfClass("ObjectValue").Value == tool then
            return slot
        end
    end
end

return inventoryAndHotbarManager