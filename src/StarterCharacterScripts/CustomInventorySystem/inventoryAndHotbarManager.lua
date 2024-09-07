local KEY_BIND_INVENTORY = Enum.KeyCode.Tab

----[[ Modules ]]----

local miscManager = require(script.Parent.miscStatsManager)

----[[ SERVICES ]]----
local Players = game:GetService("Players") 
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----[[ STANDARD PLAYER SPECIFIC VARIABLES ]]----
local player = Players.LocalPlayer 
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character.Humanoid
local backpack = player.Backpack -- the player's backpack (used to store all tools by default)

local viewportCharacter = ReplicatedStorage:FindFirstChild("WearablesViewportCharacter")

local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local dragSound : Sound = SoundService:FindFirstChild("dragSound", true)
local swapSound : Sound = SoundService:FindFirstChild("swapSound", true)
local playSound = require(game:GetService("ReplicatedStorage"):FindFirstChild("PlaySoundUtil", true))
local lerp =  require(game:GetService("ReplicatedStorage"):FindFirstChild("lerp", true))

local mouseTrailEffect = require(script.Parent.mouseTrailEffect)
local ViewportModel = require(ReplicatedStorage:FindFirstChild("ViewportModel", true)) --credit to EgoMoose

local rev_generalToolDrop = ReplicatedStorage.Tools:FindFirstChild("GeneralToolDrop", true)

----[[ GUI VARIABLES ]]----
local gui : ScreenGui = player.PlayerGui:WaitForChild("InventoryAndHotbar")
local forModal : Textbutton = gui:FindFirstChild("ForModal")
local inventory : ScrollingFrame = gui:FindFirstChild("Inventory", true) -- the bag/inventory frame
local main : Frame = inventory.Parent
local wearables : Frame = gui:FindFirstChild("Wearables", true)
local viewportFrame : ViewportFrame = wearables:FindFirstChildOfClass("ViewportFrame")
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
local hoveringInInventory : boolean = false
local hoveringInHotbar : boolean = false

local hoverColor : Color3 = Color3.fromRGB(123, 0, 255)
local dragColor : Color3 = Color3.fromRGB(0, 181, 217)   
local defaultColor : Color3 = Color3.fromRGB(217, 145, 0)

inventory.MouseEnter:Connect(function()
    hoveringInInventory = true
    inventory.MouseLeave:Once(function()
        hoveringInInventory = false
    end)
end)

local inventoryAndHotbarManager = {}

local hotbarFadeTime = 0.5
function inventoryAndHotbarManager.toggleHotbar(toggle : boolean)
    local easingStyle = Enum.EasingStyle.Linear
    local newlyCalculatedToggleTime
    if toggle then
        TweenService:Create(hotbar, TweenInfo.new(0), {GroupTransparency = 0}):Play()
    else
        newlyCalculatedToggleTime = hotbarFadeTime * (1 - hotbar.GroupTransparency)
        TweenService:Create(hotbar, TweenInfo.new(newlyCalculatedToggleTime, easingStyle), {GroupTransparency = 1}):Play()
    end
end
hotbar.MouseEnter:Connect(function()
    hoveringInHotbar = true
    inventoryAndHotbarManager.toggleHotbar(true)
end)
hotbar.MouseLeave:Connect(function()
    hoveringInHotbar = false
    if main.Visible == false then
        inventoryAndHotbarManager.toggleHotbar(false)
    end
end)

local oldMousePosition = UserInputService:GetMouseLocation()
local function getMouseDelta()
	-- Measure mouse position & delta since last measurement
	local mousePosition = UserInputService:GetMouseLocation()
	local delta = mousePosition - oldMousePosition

	-- Update the old mouse position & return the delta
	oldMousePosition = mousePosition
	return delta
end

function inventoryAndHotbarManager.initializeWearablesGui()
end

local function createHoverInfoDisplay(tool : Tool)
    local hoverInfoDisplay = gui:FindFirstChild("itemInfoDisplayTemplate", true):Clone()
    hoverInfoDisplay.Name = tool.Name    
    hoverInfoDisplay:FindFirstChildOfClass("TextLabel").Text = tool.Name
    hoverInfoDisplay:FindFirstChildWhichIsA("TextBox", true).Text = "This is a test description. a tool typically used for chopping wood, usually a steel blade attached at a right angle to a wooden handle."
    hoverInfoDisplay.Visible = false
    hoverInfoDisplay.Parent = gui

    return hoverInfoDisplay
end

--[[
    Has slot use TextButton or ImageButton based on whether the tool has a TextureId property that isn't nil.
]]
local function initializeSlotIcon(tool : Tool, slot)
    local imageButton : ImageButton = slot:FindFirstChildWhichIsA("ImageButton", true)
    local textButton : TextButton = slot:FindFirstChildWhichIsA("TextButton", true)
    local button
    local hoverStartDetection
    local hoverEndDetection
    local hoverInfoRunService

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
                        --print(slot.Name)
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
                    slot.GroupTransparency = 0.7
                    dragSlot.Parent = gui
                    dragSlot.AnchorPoint = Vector2.new(0.5, 0.5)
                    --dragSlot.GroupTransparency = 0.5
                    dragSlot:FindFirstChildWhichIsA("UIStroke", true).Color = dragColor
                    dragSlot:FindFirstChild("Number", true).TextColor3 = dragColor
                    dragSlot.Position = UDim2.fromOffset(slot.AbsolutePosition.X, slot.AbsolutePosition.Y + if gui.IgnoreGuiInset then game:GetService("GuiService"):GetGuiInset().Y else 0)
                    --mouseTrailEffect.toggleEnabled(true)
                    --[[ for drag sounds
                    dragSound.Volume = 0.1 --clamp from 0.1 - 0.7
                    dragSound:Play()
                    oldMousePosition = UserInputService:GetMouseLocation()
                    ]]
                    RunService:BindToRenderStep("DraggingSlot", 200, function()
                        --print("currently dragging: " .. if currentSlotBeingDragged then currentSlotBeingDragged.Name else "nothing")
                        --print("currently hovering: " .. if currentSlotBeingHovered then currentSlotBeingHovered.Name else "nothing")
                        --print("-------------")
                        local mousePosInVector2 : Vector2 = UserInputService:GetMouseLocation()
                        --dragSlot.Position = UDim2.new(0, mousePosInVector2.X, 0, mousePosInVector2.Y)
                        dragSlot.Position = dragSlot.Position:Lerp(UDim2.fromOffset(mousePosInVector2.X, mousePosInVector2.Y), 0.3)
                        --[[ for drag sounds
                        local calculatedVolume = math.sqrt(getMouseDelta().Magnitude) * 0.1
                        print(calculatedVolume)
                        dragSound.Volume = lerp(dragSound.Volume, math.clamp(calculatedVolume, 0.1, 0.3), 0.1)
                        ]]
                        local dropLabel = dragSlot:FindFirstChild("DropLabel", true)
                        if not (hoveringInHotbar or hoveringInInventory) then --this means cursor is hovering outside of inventory system
                            if  not dropLabel.Visible then
                                dropLabel.Visible = true
                                --print("making drop arrow visible")
                            end
                        else
                            if dropLabel.Visible then
                                dropLabel.Visible = false
                                --print("making drop arrow invisible")
                            end
                        end
                    end)
                    local dragEndedConnection
                    dragEndedConnection = UserInputService.InputEnded:Connect(function(inputObject, gameProcessed)
                        if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
                            --print("drag = false")
                            --mouseTrailEffect.toggleEnabled(false)
                            --dragSound:Stop()
                            dragEndedConnection:Disconnect()
                            dragEndedConnection = nil
                            RunService:UnbindFromRenderStep("DraggingSlot")
                            if dragSlot then dragSlot:Destroy() end
                            if currentSlotBeingDragged and currentSlotBeingHovered then
                                --playSound(swapSound, nil, 0)
                                print(currentSlotBeingDragged.Name .. " <-->" .. currentSlotBeingHovered.Name)
                                inventoryAndHotbarManager.swapSlots(currentSlotBeingDragged, currentSlotBeingHovered)
                            elseif currentSlotBeingDragged and hoveringInInventory then
                                --playSound(swapSound, nil, 0)
                                inventoryAndHotbarManager.transferSlotToInventory(currentSlotBeingDragged)
                            elseif currentSlotBeingDragged and hoveringInInventory == false then
                                print("dropping tool")
                                rev_generalToolDrop:FireServer(tool)
                            end
                            currentSlotBeingDragged.GroupTransparency = 0
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
                --print("Associated tool changed to  nil, disconnecting associated tool's events")
                connection:Disconnect()
                connection = nil
                detectSlotEmpty:Disconnect()
                detectSlotEmpty = nil
                hoverStartDetection:Disconnect()
                hoverStartDetection = nil
                hoverEndDetection:Disconnect()
                hoverEndDetection = nil
            end
        end)
    end

    --[[
    --print("connecting hover event for " .. slot.Name)
    hoverStartDetection = slot.MouseEnter:Connect(function()
        if currentSlotBeingHovered ~= nil then
            --print("former: " .. currentSlotBeingHovered.Name)
            local uiStroke = currentSlotBeingHovered:FindFirstChildWhichIsA("UIStroke", true)
            if uiStroke then
                uiStroke.Color = defaultColor
            end

            local itemInfoDisplay : Frame
            if tool then
                itemInfoDisplay = gui:FindFirstChild("itemInfoDisplayTemplate", true):Clone()
                itemInfoDisplay.Name = tool.Name    
                itemInfoDisplay:FindFirstChildOfClass("TextLabel").Text = tool.Name
                itemInfoDisplay:FindFirstChildWhichIsA("TextBox", true).Text = "This is a test description. a tool typically used for chopping wood, usually a steel blade attached at a right angle to a wooden handle."
                itemInfoDisplay.Visible = true
                itemInfoDisplay.Parent = gui
                local mouse = player:GetMouse()
                hoverInfo = RunService.RenderStepped:Connect(function()
                    itemInfoDisplay.Position = UDim2.fromOffset(mouse.X, mouse.Y - itemInfoDisplay.AbsoluteSize.Y + if gui.IgnoreGuiInset then game:GetService("GuiService"):GetGuiInset().Y else 0)
                end)
            end
            slot.MouseLeave:Once(function()
                local noQuickHoverChange = currentSlotBeingHovered == slot
                if noQuickHoverChange then
                    print("test change")
                    currentSlotBeingHovered:FindFirstChildWhichIsA("UIStroke", true).Color = defaultColor
                    currentSlotBeingHovered = nil
                    --print("currentSlotBeingHovered: nil")
                end

                if tool then
                    if hoverInfo then
                        hoverInfo:Disconnect()
                        hoverInfo = nil
                        itemInfoDisplay:Destroy()
                    end 
                end
            end)
        end
        currentSlotBeingHovered = slot
        slot:FindFirstChildWhichIsA("UIStroke", true).Color = hoverColor
        --print("currentSlotBeingHovered: " .. currentSlotBeingHovered.Name .. " | " .. slot.Name)
    end)
    ]]

    local hoverInfoDisplay
    --print("connecting hover event for " .. slot.Name)
    hoverStartDetection = slot.MouseEnter:Connect(function()
        if currentSlotBeingHovered ~= nil then
            --print("former: " .. currentSlotBeingHovered.Name)
            local uiStroke = currentSlotBeingHovered:FindFirstChildWhichIsA("UIStroke", true)
            if uiStroke then
                --[[
                When a filled slot is swapped to an empty slot in the hotbar, the two slots actually swap places (parents) and the filled slot is made to look like the hotbar
                slot, meanwhile the empty hotbar slot is destroyed. For some reason, this "destroyed" slot gets past the "does it exist" check, but the uiStroke "does exist"
                check catches it. My theory is that when an object is destroyed, it's children are destroyed first before its parents. Wow. that sounds really dark. But it's
                only a theory.
                ]]
                uiStroke.Color = defaultColor
            end
        end
        currentSlotBeingHovered = slot
        slot:FindFirstChildWhichIsA("UIStroke", true).Color = hoverColor
        --print("currentSlotBeingHovered: " .. currentSlotBeingHovered.Name .. " | " .. slot.Name)

        if currentSlotBeingHovered:FindFirstChildOfClass("ObjectValue").Value ~= nil then
            print("creating hover info")
            hoverInfoDisplay = createHoverInfoDisplay(currentSlotBeingHovered:FindFirstChildOfClass("ObjectValue").Value)
            hoverInfoDisplay.Parent = nil
            hoverInfoDisplay.Visible = true
            local mouse = player:GetMouse()
            hoverInfoRunService = RunService.RenderStepped:Connect(function()
                hoverInfoDisplay.Position = UDim2.fromOffset(mouse.X, mouse.Y - hoverInfoDisplay.AbsoluteSize.Y + if gui.IgnoreGuiInset then game:GetService("GuiService"):GetGuiInset().Y else 0)
                if hoverInfoDisplay.Parent == nil then
                    hoverInfoDisplay.Parent = gui
                end        
            end)
        end
    end)
    hoverEndDetection = slot.MouseLeave:Connect(function()
        local noQuickHoverChange = currentSlotBeingHovered == slot
        if noQuickHoverChange then
            currentSlotBeingHovered:FindFirstChildWhichIsA("UIStroke", true).Color = defaultColor
            currentSlotBeingHovered = nil
            --print("currentSlotBeingHovered: nil")
        end

        if hoverInfoDisplay ~= nil then
            print("destroying hover info")
            hoverInfoDisplay:Destroy()
            hoverInfoDisplay = nil
            hoverInfoRunService:Disconnect()
            hoverInfoRunService = nil
        end
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


inventoryBlur.Enabled = true
main.Visible = true
local toggleTime = 0.2
local easingStyle = Enum.EasingStyle.Linear
function inventoryAndHotbarManager.toggleInventory(toggle : boolean)
    for _, v in inventory:GetChildren() do
        if v:IsA("CanvasGroup") then
            v.Visible = toggle
        end
    end
    for _, v in wearables:GetDescendants() do
        if v:IsA("CanvasGroup") then
            v.Visible = toggle
        end
    end
    forModal.Modal = toggle --unlocks mouse in first person
    inventoryAndHotbarManager.toggleHotbar(toggle)
    local newlyCalculatedToggleTime
    if toggle then
        --[[
            TODO: inventory quick drop/swap
            
            Bind w/ ContextActionService here.

            if input.KeyCode == Enum.KeyCode.X then
        ]]
        main.Visible = true
        newlyCalculatedToggleTime = toggleTime * (0.5 - main.Size.Y.Scale)
        TweenService:Create(main, TweenInfo.new(newlyCalculatedToggleTime, easingStyle), {Size = UDim2.new(0.5, 0, 0.5, 0)}):Play()
        TweenService:Create(inventoryBlur, TweenInfo.new(newlyCalculatedToggleTime, easingStyle), {Size = 24}):Play()
    else
        --unbind w/ ContextActionService here.
        newlyCalculatedToggleTime = toggleTime * ( main.Size.Y.Scale - 0)
        TweenService:Create(main, TweenInfo.new(newlyCalculatedToggleTime, easingStyle), {Size = UDim2.new(0.5, 0, 0, 0)}):Play()
        TweenService:Create(inventoryBlur, TweenInfo.new(newlyCalculatedToggleTime, easingStyle), {Size = 0}):Play()
        task.spawn(function()
            task.wait(newlyCalculatedToggleTime)
            if main.Size.Y.Offset == 0 then
                main.Visible = false
            end
        end)
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
    slot.Visible = true
    return slot
end

function inventoryAndHotbarManager.intitializeHotbar()
    for i = 1, 10, 1 do
        if hotbar:FindFirstChild(i) == nil then
            inventoryAndHotbarManager.createSlot(nil, "Hotbar", i)
        else
            hotbar:FindFirstChild(i):Destroy()
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

local function setSlotParentAndUpdateNameAndToolAttribute(slot : typeof(slotTemplate), newParent : Instance, potentialHotbarName : string)
    local hotbarName = potentialHotbarName
    local xTool = slot:FindFirstChild("ObjectValue", true).Value

    slot.Parent = newParent

    if newParent == inventory and xTool == nil then
        slot:Destroy() --destroys slot because empty slots cannot exist in inventory
        return
    end

    slot.Name = if newParent == hotbar then hotbarName elseif newParent == inventory and xTool ~= nil then xTool.Name else slot:Destroy()

    if xTool then
        xTool:SetAttribute("HotbarSlot", if newParent == hotbar then tostring(hotbarName) else nil)
    end
end

--[[
    Swaps each tool's "HotbarSlot" attribute values and each slot's ObjectValue.Value and ImageButton/TextButton (depending on which is active)

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
    --swapping slots' number labels
    firstSlot:FindFirstChild("Number", true).Parent = secondSlot:FindFirstChild("Number", true).Parent
    secondSlot:FindFirstChild("Number", true).Parent = cachedFirstSlotNumberLabelObjectReference
    --swapping slots' parents, names, and then updating potentially existing tool's "HotbarSlot" attribute
    setSlotParentAndUpdateNameAndToolAttribute(firstSlot, secondSlot.Parent, secondSlot.Name) --remember, the first parameter is written to, while the second is only read from
    setSlotParentAndUpdateNameAndToolAttribute(secondSlot, cachedFirstSlotParent, cachedFirstSlotName)
end

function inventoryAndHotbarManager.transferSlotToInventory(slot : typeof(slotTemplate))
    print("transferSlotToInventory()")
    if slot.Parent == hotbar then
        local emptyHotbarSlot = inventoryAndHotbarManager.createSlot(nil, "Hotbar", tonumber(slot.Name))
        emptyHotbarSlot.Parent = inventory
        inventoryAndHotbarManager.swapSlots(slot, emptyHotbarSlot) --feel like I solved a Rubik's cube with this one
        --print(emptyHotbarSlot.Name)
        local tool = slot:FindFirstChild("ObjectValue", true).Value
        tool:SetAttribute("HotbarSlot", nil)
        slot.LayoutOrder = getNumberOfInventorySlots() + 1
        slot.Name = tool.Name
        slot:FindFirstChild("Number", true).Visible = false
    else --slot is already in inventory
        --change the slot's layout order to be +1 the greatest layout order
        slot.LayoutOrder = getNumberOfInventorySlots() + 1
    end
end

function inventoryAndHotbarManager.initializeMisc()
    miscManager.init()
end

return inventoryAndHotbarManager