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
local inventoryBlur = game:GetService("Lighting"):FindFirstChild("inventoryBlur")

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

local currentSlotBeingHovered : typeof(slotTemplate)
local currentSlotBeingDragged : typeof(slotTemplate)
local hoveringInInventory : boolean

hotbar.MouseLeave:Connect(function()
    currentSlotBeingHovered = nil
end)
inventory.MouseEnter:Connect(function()
    hoveringInInventory = true
    inventory.MouseLeave:Once(function()
        hoveringInInventory = false
    end)
end)

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
        local connection
        connection = button.MouseButton1Down:Connect(function()

            local dragSlot
            local currentTime = tick()

            --Event for toggling equip/unequip
            button.MouseButton1Up:Once(function()
                if tick() - currentTime <= dragToggleTime then
                    --toggle equip/unequip
                    --print("Toggle equip/unequip") 
                    local slotNotEmpty = slot:FindFirstChildOfClass("ObjectValue").Value ~= nil
                    if slotNotEmpty then
                        print(slot.Name)
                        --can't used the passed parameter named slot because the button may be reparented to a different slot when slots are swapped
                        inventoryAndHotbarManager.equipSlotToggle(button:FindFirstAncestorWhichIsA("CanvasGroup")) --remember that slots are of the CanvasGroup type
                    end
                end
            end)

            --Event for dragging & reorganizing slots

            task.spawn(function()
                task.wait(dragToggleTime)
                if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    --print("drag = true")
                    currentSlotBeingDragged = inventoryAndHotbarManager.getSlotFromTool(tool)
                    dragSlot = slot:Clone()
                    dragSlot.Parent = gui
                    dragSlot.AnchorPoint = Vector2.new(0.5, 0.5)
                    dragSlot.GroupTransparency = 0.5
                    RunService:BindToRenderStep("DraggingSlot", 200, function()
                        print("currently dragging: " .. if currentSlotBeingDragged then currentSlotBeingDragged.Name else "nothing")
                        print("currently hovering: " .. if currentSlotBeingHovered then currentSlotBeingHovered.Name else "nothing")
                        print("-------------")
                        local mousePosInVector2 : Vector2 = UserInputService:GetMouseLocation()
                        dragSlot.Position = UDim2.new(0, mousePosInVector2.X, 0, mousePosInVector2.Y)

                    end)
                    local dragEndedConnection
                    dragEndedConnection = UserInputService.InputEnded:Connect(function(inputObject, gameProcessed)
                        if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
                            --print("drag = false")
                            dragEndedConnection:Disconnect()
                            dragEndedConnection = nil
                            RunService:UnbindFromRenderStep("DraggingSlot")
                            if dragSlot then dragSlot:Destroy() end
                            if currentSlotBeingDragged and currentSlotBeingHovered then
                                inventoryAndHotbarManager.swapSlots(currentSlotBeingDragged, currentSlotBeingHovered)
                            elseif currentSlotBeingDragged and hoveringInInventory then
                                inventoryAndHotbarManager.transferSlotToInventory(currentSlotBeingDragged)
                            end
                            currentSlotBeingDragged = nil
                        end
                    end)
                end
            end)
        end)

        local objectValue = slot:FindFirstChildOfClass("ObjectValue") 
        local detectSlotEmpty  
        detectSlotEmpty = objectValue:GetPropertyChangedSignal("Value"):Connect(function()
            if objectValue.Value == nil then -- and currentButton == button --meaning a swap didn't occur
                print("Associated tool changed to  nil, disconnecting associated tool's events")
                connection:Disconnect()
                connection = nil
                detectSlotEmpty:Disconnect()
                detectSlotEmpty = nil
                hoverDetection:Disconnect()
                hoverDetection = nil
            end
        end)

    end

    local hoverDetection
    hoverDetection = slot.MouseEnter:Connect(function()
        currentSlotBeingHovered = slot
    end)

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
    --[[ Supposed to make empty hotbar slots invisible when inventory is hidden, but doesn't account for when tools are dropped from hotbar & hotbar slot becomes empty
    ]]
    for _, hotbarSlot in ipairs(getEmptyHotbarSlots()) do
        hotbarSlot.Visible = toggle
    end
    inventoryBlur.Enabled = toggle
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
    slot.Visible = true
    return slot
end

function inventoryAndHotbarManager.intitializeHotbar()
    for i = 1, 10, 1 do
        if hotbar:FindFirstChild(i) == nil then
            inventoryAndHotbarManager.createSlot(nil, "Hotbar", i)
        end
    end
    hotbar:SetAttribute("Initialized", true)
end

function inventoryAndHotbarManager.setSlot(passedTool : Tool, slot)
    initializeSlotIcon(passedTool, slot)
    local isHotbarSlot = slot:FindFirstChild("Number", true).Visible
    local objectValue : ObjectValue = slot:FindFirstChildOfClass("ObjectValue")
    if passedTool then
        assert(isHotbarSlot, "function setSlot is only meant to set hotbar slots, not inventory slots, to non-nil tool parameters because hotbar slots are set whil inventory slots are created & destroyed.")
        passedTool:SetAttribute("HotbarSlot", slot.Name)
        objectValue.Value = passedTool --remember that tool can be nil for hotbar slots
    else
        if isHotbarSlot then
            local associatedTool = objectValue.Value
            if associatedTool then
                associatedTool:SetAttribute("HotbarSlot", nil)
            end
            objectValue.Value = passedTool --remember that tool can be nil for hotbar slots
        else
            slot:Destroy()
        end
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
        if slot:IsA(slotTemplate.ClassName) and slot ~= slotTemplate then
            if slot:FindFirstChildOfClass("ObjectValue").Value == tool then
                return slot
            end
        end
    end
    return nil
end

function inventoryAndHotbarManager.initializeKeybindToHotbarSlot()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        local slotIndex = table.find(slotNameToKeybind, input.KeyCode)
        if slotIndex then
            local slotName = tostring(slotIndex)
            local associatedHotbarSlot = hotbar:FindFirstChild(slotName)
            print("Slot Name: " .. slotName)
            local slotNotEmpty = associatedHotbarSlot:FindFirstChildOfClass("ObjectValue").Value ~= nil
            if slotNotEmpty then
                inventoryAndHotbarManager.equipSlotToggle(associatedHotbarSlot)
            end
        end
    end)
end

--[[
    Equips a slot's associated tool. This function DOES NOT handle slot equip/unequip effects (that is handled by child added/removed events
    in main that monitors how tools move around in the hierarchy.)
]]
function inventoryAndHotbarManager.equipSlotToggle(slot)
    local tool = slot:FindFirstChildOfClass("ObjectValue").Value
    assert(tool ~= nil, "Cannot equip slot because it does not have an associated tool.")

    local isEquipped = tool:FindFirstAncestor(character.Name):FindFirstChild("Humanoid")
    if isEquipped then
        humanoid:UnequipTools()
    else
        humanoid:EquipTool(tool) --"When this function is called, the humanoid will automatically unequip any Tools that it currently has equipped"
    end
end

--[[
    Swaps each tool's "HotbarSlot" attribute values and each slot's ObjectValue.Value and ImageButton/TextButton (depending on which is active)

    !!!This function is bugged & what I'm stuck on is how to swap the guiButtons without messing up the event connections. I see 2 potential
    solutions:
    1) swap both buttons & see if that fixes it & then fix the logic on disconnecting the button's events when the slot's object value changes.
    2) delete & reconstruct the slots (this one might be easier, but may be more work on the client [by very slightly])
]]
function inventoryAndHotbarManager.swapSlots(firstSlot, secondSlot)
    if firstSlot == secondSlot then
        warn("no swap occurred")
        return
    end
    local cachedFirstSlotParent = firstSlot.Parent
    local cachedFirstSlotLayoutOrder = firstSlot.LayoutOrder
    local cachedFirstSlotName = firstSlot.Name
    local cachedFirstSlotNumberLabelObjectReference = firstSlot:FindFirstChild("Number", true).Parent

    --swapping slots' layout orders
    firstSlot.LayoutOrder = secondSlot.LayoutOrder
    secondSlot.LayoutOrder = cachedFirstSlotLayoutOrder
    --swapping slots' parents
    firstSlot.Parent = secondSlot.Parent
    local firstTool = firstSlot:FindFirstChild("ObjectValue", true).Value
    if firstSlot.Parent == hotbar then
        firstSlot.Name = secondSlot.Name --have to set slot's name to it's layout order if its in hotbar because that's how equipping slot from keybind works
        if firstTool then
            firstTool:SetAttribute("HotbarSlot", tostring(firstSlot.Name))
        end
    else
        firstSlot.Name = firstTool.Name
        firstTool:SetAttribute("HotbarSlot", nil)
    end
    secondSlot.Parent = cachedFirstSlotParent
    local secondTool = secondSlot:FindFirstChild("ObjectValue", true).Value
    if secondSlot.Parent == hotbar then
        secondSlot.Name = cachedFirstSlotName
        if secondTool then
            secondTool:SetAttribute("HotbarSlot", tostring(secondSlot.Name))
        end
    else
        if secondTool then
            secondSlot.Name = secondTool.Name
            secondTool:SetAttribute("HotbarSlot", nil)
        else
            --[[
            Remember that the second slot is always the slot being hovered on. 
            ]]
            secondSlot:FindFirstChild("Number", true).Parent = cachedFirstSlotNumberLabelObjectReference
            secondSlot:Destroy()
            return
        end
    end
    --swapping slots' number labels
    firstSlot:FindFirstChild("Number", true).Parent = secondSlot:FindFirstChild("Number", true).Parent
    secondSlot:FindFirstChild("Number", true).Parent = cachedFirstSlotNumberLabelObjectReference
end

function inventoryAndHotbarManager.transferSlotToInventory(slot : typeof(slotTemplate))
    if slot.Parent == hotbar then
        local emptyHotbarSlot = inventoryAndHotbarManager.createSlot(nil, "Hotbar", tonumber(slot.Name))
        emptyHotbarSlot.Parent = inventory
        inventoryAndHotbarManager.swapSlots(slot, emptyHotbarSlot) --feel like I solved a Rubik's cube with this one
        print(emptyHotbarSlot.Name)
        local tool = slot:FindFirstChild("ObjectValue", true).Value
        tool:SetAttribute("HotbarSlot", nil)
        slot.Name = tool.Name
        slot:FindFirstChild("Number", true).Visible = false
    else
        --change the slot's layout order to be +1 the greatest layout order
        slot.LayoutOrder = inventoryAndHotbarManager.getNumberOfInventorySlots() + 1
    end
end

return inventoryAndHotbarManager