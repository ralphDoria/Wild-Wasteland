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
local TweenService = game:GetService("TweenService")
local dragSound : Sound = SoundService:FindFirstChild("dragSound", true)
local swapSound : Sound = SoundService:FindFirstChild("swapSound", true)
local playSound = require(game:GetService("ReplicatedStorage"):FindFirstChild("PlaySoundUtil", true))
local lerp =  require(game:GetService("ReplicatedStorage"):FindFirstChild("lerp", true))

local mouseTrailEffect = require(script.Parent.mouseTrailEffect)
local ViewportModel = require(ReplicatedStorage:FindFirstChild("ViewportModel", true)) --credit to EgoMoose

----[[ GUI VARIABLES ]]----
local gui : ScreenGui = player.PlayerGui:WaitForChild("InventoryAndHotbar")
local forModal : Textbutton = gui:FindFirstChild("ForModal")
local inventory : ScrollingFrame = gui:FindFirstChild("Inventory", true) -- the bag/inventory frame
local main : Frame = inventory.Parent

local wearables : Frame = gui:FindFirstChild("Wearables", true)
local _wearableSlots = wearables:FindFirstChild("WearableSlots", true)
local wearableSlots = {
    ["Feet"] = _wearableSlots:FindFirstChild("Feet", true),
    ["Legs"] = _wearableSlots:FindFirstChild("Legs", true),
    ["Torso"] = _wearableSlots:FindFirstChild("Torso", true),
    ["Head"] = _wearableSlots:FindFirstChild("Head", true)
}

local rev_generalToolDrop = ReplicatedStorage.Tools:FindFirstChild("GeneralToolDrop", true)
local bev_signalPutOn : BindableEvent = gui:FindFirstChild("SignalPutOn", true)
local bev_signalTakeOff : BindableEvent = gui:FindFirstChild("SignalTakeOff", true)

local viewportFrame : ViewportFrame = wearables:FindFirstChildOfClass("ViewportFrame")
local hotbar : CanvasGroup = gui:FindFirstChild("Hotbar", true) -- the hotbar frame
local slotTemplate : CanvasGroup = gui:FindFirstChild("slotTemplate", true)
local inventoryBlur = game:GetService("Lighting"):FindFirstChild("inventoryBlur")
local updateLog : CanvasGroup = gui:FindFirstChild("updateLog")
local updateLogTemplate : TextLabel = updateLog:FindFirstChild("Template")

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
local hoveringInWearables : boolean = false

local hoverColor : Color3 = Color3.fromRGB(123, 0, 255)
local dragColor : Color3 = Color3.fromRGB(0, 181, 217)   
local defaultColor : Color3 = Color3.fromRGB(217, 145, 0)

inventory.MouseEnter:Connect(function()
    hoveringInInventory = true
    inventory.MouseLeave:Once(function()
        hoveringInInventory = false
    end)
end)

wearables.MouseEnter:Connect(function()
    hoveringInWearables = true
    wearables.MouseLeave:Once(function()
        hoveringInWearables = false
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
    --inventoryAndHotbarManager.toggleHotbar(true)
end)
hotbar.MouseLeave:Connect(function()
    hoveringInHotbar = false
    if main.Visible == false then
        --inventoryAndHotbarManager.toggleHotbar(false)
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

function inventoryAndHotbarManager.initializeSystem()
    gui.Enabled = true
    inventoryAndHotbarManager.toggleInventory(false)
    inventoryAndHotbarManager.toggleHotbar(true)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) --disables Roblox's default backpack
    inventoryAndHotbarManager.toggleInventoryInput(true)
    inventoryAndHotbarManager.initializeMisc()
    inventoryAndHotbarManager.initializeWearablesGui()
end

local function initSingleWearableSlot(slot)
    slot.MouseEnter:Connect(function()
        if currentSlotBeingHovered ~= nil then
            local uiStroke = currentSlotBeingHovered:FindFirstChildWhichIsA("UIStroke", true)
            if uiStroke then
                uiStroke.Color = defaultColor
            end
        end
        currentSlotBeingHovered = slot
        --print(currentSlotBeingHovered.Name)
        slot:FindFirstChildWhichIsA("UIStroke", true).Color = hoverColor
        --[[ hover info initialization
        if currentSlotBeingHovered:FindFirstChildOfClass("ObjectValue").Value ~= nil then
            --print("creating hover info")
            hoverInfoDisplay = createHoverInfoDisplay(currentSlotBeingHovered:FindFirstChildOfClass("ObjectValue").Value)
            local mouse = player:GetMouse()
            hoverInfoRunService = RunService.RenderStepped:Connect(function()
                hoverInfoDisplay.Position = UDim2.fromOffset(mouse.X, mouse.Y - hoverInfoDisplay.AbsoluteSize.Y + if gui.IgnoreGuiInset then game:GetService("GuiService"):GetGuiInset().Y else 0)
                if hoverInfoDisplay.Parent == nil then
                    hoverInfoDisplay.Parent = gui
                end        
            end)
        end
        ]]
    end)
    slot.MouseLeave:connect(function()
        local noQuickHoverChange = currentSlotBeingHovered == slot
        if noQuickHoverChange then
            currentSlotBeingHovered:FindFirstChildWhichIsA("UIStroke", true).Color = defaultColor
            currentSlotBeingHovered = nil
            --print("currentSlotBeingHovered: nil")
        end

        --[[ hover info clean up
        if hoverInfoDisplay ~= nil then
            --print("destroying hover info")
            hoverInfoDisplay:Destroy()
            hoverInfoDisplay = nil
            hoverInfoRunService:Disconnect()
            hoverInfoRunService = nil
        end
        ]]
    end)
end

function inventoryAndHotbarManager.initializeWearablesGui()
    for _, v in wearableSlots do
        initSingleWearableSlot(v)
    end
end

local function createHoverInfoDisplay(tool : Tool)
    local hoverInfoDisplay = gui:FindFirstChild("itemInfoDisplayTemplate", true):Clone()
    hoverInfoDisplay.Name = tool.Name    
    hoverInfoDisplay:FindFirstChildOfClass("TextLabel").Text = tool.Name
    hoverInfoDisplay:FindFirstChildWhichIsA("TextBox", true).Text = if tool:GetAttribute("Description") then tool:GetAttribute("Description") else "This item has no description"
    hoverInfoDisplay:FindFirstChildWhichIsA("TextBox", true).TextWrapped = true
    hoverInfoDisplay.Visible = true

    return hoverInfoDisplay
end

local function isWearableSlot(slot)
    for _, v in wearableSlots do
        if v == slot then
            return true
        end
    end
    return false
end

local function isWearableItem(slot)
    local tool = slot:FindFirstChildWhichIsA("ObjectValue").Value
    if tool ~= nil then
        if tool:GetAttribute("WearableType") ~= nil then
            return true
        end
    end
    return false
end

local function setButton(tool, imageButton : ImageButton, textButton : TextButton)
    if tool.TextureId ~= "" then
        imageButton.Image = tool.TextureId
        imageButton.Visible = true
        textButton.Visible = false
        return imageButton
    else
        textButton.Text = tool.Name
        textButton.Visible = true
        imageButton.Visible = false
        return textButton
    end
end

local function connectHoverEvents(slot)
    local hoverInfoDisplay
    local hoverInfoRunService
    local hoverStartDetection
    local hoverEndDetection
    hoverStartDetection = slot.MouseEnter:Connect(function()
        if currentSlotBeingHovered ~= nil then
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
            --print("creating hover info")
            hoverInfoDisplay = createHoverInfoDisplay(currentSlotBeingHovered:FindFirstChildOfClass("ObjectValue").Value)
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
            --print("destroying hover info")
            hoverInfoDisplay:Destroy()
            hoverInfoDisplay = nil
            hoverInfoRunService:Disconnect()
            hoverInfoRunService = nil
        end
    end)
    return hoverStartDetection, hoverEndDetection
end

local function connectDragEvents(slot, tool)
    local dragSlot
    currentSlotBeingDragged = slot  --inventoryAndHotbarManager.getSlotFromTool(tool)
    dragSlot = slot:Clone()
    slot.GroupTransparency = 0.7
    dragSlot.Parent = gui
    dragSlot.AnchorPoint = Vector2.new(0.5, 0.5)
    dragSlot:FindFirstChildWhichIsA("UIStroke", true).Color = dragColor
    dragSlot:FindFirstChild("Number", true).TextColor3 = dragColor
    dragSlot.Position = UDim2.fromOffset(slot.AbsolutePosition.X, slot.AbsolutePosition.Y + if gui.IgnoreGuiInset then game:GetService("GuiService"):GetGuiInset().Y else 0)
    --mouseTrailEffect.toggleEnabled(true)
    --[[ for drag sounds
    dragSound.Volume = 0.1 --clamp from 0.1 - 0.7
    dragSound:Play()
    oldMousePosition = UserInputService:GetMouseLocation()
    ]]
    local wearableIcon = dragSlot:FindFirstChild("Icon", true)
    if wearableIcon then
        wearableIcon.Visible = false
    end
    RunService:BindToRenderStep("DraggingSlot", 200, function()
        local mousePosInVector2 : Vector2 = UserInputService:GetMouseLocation()
        dragSlot.Position = dragSlot.Position:Lerp(UDim2.fromOffset(mousePosInVector2.X, mousePosInVector2.Y), 0.3)
        --[[ for drag sounds
        local calculatedVolume = math.sqrt(getMouseDelta().Magnitude) * 0.1
        print(calculatedVolume)
        dragSound.Volume = lerp(dragSound.Volume, math.clamp(calculatedVolume, 0.1, 0.3), 0.1)
        ]]
        local dropLabel = dragSlot:FindFirstChild("DropLabel", true)
        if not (hoveringInHotbar or hoveringInInventory or hoveringInWearables) then --this means cursor is hovering outside of inventory system
            if  not dropLabel.Visible then
                dropLabel.Visible = true
            end
        else
            if dropLabel.Visible then
                dropLabel.Visible = false
            end
        end
    end)
    local dragEndedConnection
    dragEndedConnection = UserInputService.InputEnded:Connect(function(inputObject, gameProcessed)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
            --mouseTrailEffect.toggleEnabled(false)
            --dragSound:Stop()
            dragEndedConnection:Disconnect()
            dragEndedConnection = nil
            RunService:UnbindFromRenderStep("DraggingSlot")
            if dragSlot then 
                dragSlot:Destroy() 
            end
            if isWearableSlot(currentSlotBeingDragged) then
                if currentSlotBeingDragged ~= currentSlotBeingHovered then
                    inventoryAndHotbarManager.transferOutOfWearableSlot(currentSlotBeingDragged, currentSlotBeingHovered) 
                end
            else
                if currentSlotBeingDragged and currentSlotBeingHovered then
                    if isWearableSlot(currentSlotBeingHovered) then --if player is hovering on a wearableSlot
                        --print("calling transfer to wearable slot")
                        if wearableSlots[tool:GetAttribute("WearableType")] == currentSlotBeingHovered then 
                            print("wearing item")
                            inventoryAndHotbarManager.wearItem(slot, true)--wearing via drag
                        else
                            warn("wrong wearable slot")
                        end
                    else
                        --playSound(swapSound, nil, 0)
                        print(currentSlotBeingDragged.Name .. " <-->" .. currentSlotBeingHovered.Name)
                        inventoryAndHotbarManager.swapSlots(currentSlotBeingDragged, currentSlotBeingHovered)
                    end
                elseif currentSlotBeingDragged and hoveringInInventory then
                    print("transferring to inventory")
                    --playSound(swapSound, nil, 0)
                    inventoryAndHotbarManager.transferSlotToInventory(currentSlotBeingDragged)
                elseif currentSlotBeingDragged and not (hoveringInHotbar or hoveringInInventory or hoveringInWearables) then
                    print("dropping tool")
                    rev_generalToolDrop:FireServer(tool)
                else
                    print("none")
                end
            end
            currentSlotBeingDragged.GroupTransparency = 0
            currentSlotBeingDragged = nil
        end
    end)
end


local canEquipAndUnequipViaClick = true
local function toggleEquipAndUnequipViaClick(toggle : boolean)
    canEquipAndUnequipViaClick = toggle
end

function inventoryAndHotbarManager.toggleInventoryInput(toggle : boolean)
    inventoryAndHotbarManager.toggleKeybindToHotbarSlot(toggle)
    toggleEquipAndUnequipViaClick(toggle)
end

local function initAndRunProgressBar(slot, wearTime : number, reversed : boolean)
    local iAmGoingCrazyToFixThisBug
    iAmGoingCrazyToFixThisBug = slot.DescendantAdded:Connect(function(descendant)
        if descendant.ClassName == "UICorner" then
            descendant:Destroy()
        end
    end)
    local innerFrame : Frame = slot:FindFirstChildWhichIsA("Frame", true)
    local progressBar = Instance.new("Frame")
    progressBar.BackgroundTransparency = 0.5
    slot.GroupColor3 = Color3.new(0.5, 0.5, 0.5)
    progressBar.BackgroundColor3 = Color3.new(1, 1, 1)
    progressBar.Size = if not reversed then UDim2.fromScale(innerFrame.Size.X.Scale, 0) else innerFrame.Size
    progressBar.Position = if not reversed then UDim2.fromScale(innerFrame.Position.X.Scale, 1 - innerFrame.Position.Y.Scale) else innerFrame.Position
    local ti = TweenInfo.new(wearTime, Enum.EasingStyle.Linear)
    local tweenSize = TweenService:Create(progressBar, ti, {Size = if not reversed then innerFrame.Size else UDim2.fromScale(innerFrame.Size.X.Scale, 0)})
    local tweenPosition = TweenService:Create(progressBar, ti, {Position = if not reversed then innerFrame.Position else UDim2.fromScale(innerFrame.Position.X.Scale, 1 - innerFrame.Position.Y.Scale)})
    progressBar.Parent = slot
    tweenSize.Completed:Once(function()
        slot.GroupColor3 = Color3.new(1, 1, 1)
        progressBar:Destroy()
        tweenSize:Destroy()
        tweenPosition:Destroy()
        tweenSize = nil
        tweenPosition = nil
        ti = nil
        iAmGoingCrazyToFixThisBug:Disconnect()
    end)
    tweenPosition:Play()
    tweenSize:Play()
    return tweenSize
end

function inventoryAndHotbarManager.wearItem(slot, draggedToWear)
    local tool : Tool = slot:FindFirstChildWhichIsA("ObjectValue", true).Value
    local designatedSlot = wearableSlots[tool:GetAttribute("WearableType")]

    local designatedSlotIsAlreadyOccupied = designatedSlot:FindFirstChildWhichIsA("ObjectValue", true).Value ~= nil
    if designatedSlotIsAlreadyOccupied then 
        warn("Designated slot is already occupied right now. In the future, they'll be able to")
        return 
    end

    inventoryAndHotbarManager.toggleInventoryInput(false)

    local cachedEquippedTool = character:FindFirstChildOfClass("Tool")

    local unequipped = tool.Parent:FindFirstChild("Humanoid") == nil
    local netWearTime : number = if not unequipped then tool:GetAttribute("wearTime") else tool:GetAttribute("wearTime") + tool:GetAttribute("equipTime")

    if draggedToWear then --if player didn't double click to wear
        --tool:SetAttribute("WearingViaGui", true)
        bev_signalPutOn:Fire(tool, 1)
    end

    initAndRunProgressBar(designatedSlot, netWearTime)
    table.insert(
        inventoryAndHotbarManager.DragDisabledSlots,
        designatedSlot
    )
    inventoryAndHotbarManager.transferToWearableSlot(slot, designatedSlot)

    local connection
    connection = tool:GetAttributeChangedSignal("isWearing"):Connect(function()
        if tool:GetAttribute("isWearing") == true then
            humanoid:UnequipTools()
            if cachedEquippedTool and cachedEquippedTool ~= tool then
                humanoid:EquipTool(cachedEquippedTool)
            end
            inventoryAndHotbarManager.toggleInventoryInput(true)
        end
        table.remove(inventoryAndHotbarManager.DragDisabledSlots, table.find(inventoryAndHotbarManager.DragDisabledSlots, designatedSlot))
    end)
    designatedSlot.Destroying:Once(function()
        connection:Disconnect()
        connection = nil
    end)
end

inventoryAndHotbarManager.DragDisabledSlots = {}

--[[
    Has slot use TextButton or ImageButton based on whether the tool has a TextureId property that isn't nil.
]]
local function initializeSlotFunctionality(tool : Tool, slot, worn : boolean)
    local imageButton : ImageButton = slot:FindFirstChildWhichIsA("ImageButton", true)
    local textButton : TextButton = slot:FindFirstChildWhichIsA("TextButton", true)
    local button
    local hoverStartDetection
    local hoverEndDetection
    local slotEventConnections = {}

    if tool == nil then
        imageButton.Visible = false
        textButton.Visible = false
    else
        button = setButton(tool, imageButton, textButton)
        slot.Visible = true

        --toggle equip/unequip & drag events
        local dragToggleTime : number = 0.1
        local connection

        local wearableEventConnections = {}
        if tool:GetAttribute("WearableType") ~= nil then
            table.insert(
                wearableEventConnections,
                bev_signalPutOn.Event:Connect(function(thisTool : Tool, firingDirection : number)
                    --[[
                    Firing direction key:
                    1 - from inventory to tool
                    2 - from tool to inventory
                    ]]
                    if firingDirection == 2 then
                        if thisTool == tool then
                            print("put on signal received from tool to inventory code")
                            inventoryAndHotbarManager.wearItem(slot)--wearing via double click
                        end
                    end
                end)
            )
            table.insert(
                wearableEventConnections,
                bev_signalTakeOff.Event:Connect(function(thisTool : Tool, firingDirection : number)
                    --[[
                    Firing direction key:
                    1 - from inventory to tool
                    2 - from tool to inventory
                    ]]
                    if firingDirection == 2 then
                        if thisTool == tool then
                            --print("take off signal received from tool to inventory code")
                            local wearableItemSlot = inventoryAndHotbarManager.getSlotFromTool(tool)
                            inventoryAndHotbarManager.transferOutOfWearableSlot(wearableItemSlot, nil, true)
                        end
                    end
                end)
            )
            slot.Destroying:Once(function()
                for _, thisConnection in wearableEventConnections do
                    thisConnection:Disconnect()
                end
                wearableEventConnections = nil
            end)
        end

        connection = button.MouseButton1Down:Connect(function()

            local currentTime = tick()

            if not worn then 
                --Event for toggling equip/unequip
                button.MouseButton1Up:Once(function()
                    if tick() - currentTime <= dragToggleTime then
                        if canEquipAndUnequipViaClick then
                            --toggle equip/unequip
                            --print("Toggle equip/unequip") 
                            local slotNotEmpty = slot:FindFirstChildOfClass("ObjectValue").Value ~= nil
                            if slotNotEmpty then
                                --print(slot.Name)
                                --can't used the passed parameter named slot because the button may be reparented to a different slot when slots are swapped
                                inventoryAndHotbarManager.equipSlotToggle(button:FindFirstAncestorWhichIsA("CanvasGroup")) --remember that slots are of the CanvasGroup type
                            end
                        end
                    end
                end)
            end

            --Event for dragging & reorganizing slots

            if table.find(inventoryAndHotbarManager.DragDisabledSlots, slot) == nil then
                task.spawn(function()
                    task.wait(dragToggleTime)
                    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                        connectDragEvents(slot, tool)
                    end
                end)
            else
                warn(slot.Name .. " can't be dragged.")
            end

        end)

        local objectValue = slot:FindFirstChildOfClass("ObjectValue") 
        local detectSlotEmpty  
        --disconnects events if slot becomes empty (due to tool being dropped)
        detectSlotEmpty = objectValue:GetPropertyChangedSignal("Value"):Connect(function()
            if objectValue.Value == nil then -- and currentButton == button --meaning a swap didn't occur
                --print("Associated tool changed to  nil, disconnecting associated tool's events")
                print(slot)
                print("detected slot became empty")
                print("THIS EVENT CONNECTION RIGHT HERE MIGHT BE OBSOLETE BECAUSE IT DOESN'T PRINT ANYTHING, but idk for sure & why, if so")
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

    --Changes "currentSlotBeingHovered" variable, responsible for slot border color change due to hover & display of hover info
    hoverStartDetection, hoverEndDetection = connectHoverEvents(slot)
    
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
    --inventoryAndHotbarManager.toggleHotbar(toggle)
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

    local slot : CanvasGroup = initializeSlotFunctionality(tool, slotTemplate:Clone())
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
    --this disconnects all events associated with a potentially empty hotbar slot
    local slotWithoutConnections = slot:Clone()
    slotWithoutConnections.Parent = slot.Parent
    slot:Destroy()
    slot = slotWithoutConnections
    slot.GroupTransparency = 0

    initializeSlotFunctionality(passedTool, slot)
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
    if slot then
        if toggle == true then
            Instance.new("UICorner").Parent = slot:FindFirstChild("innerFrame")
        else
            local uiCorner = slot:FindFirstChildWhichIsA("UICorner", true)
            if uiCorner then
                uiCorner:Destroy()
            end
        end
    end
end
    
function inventoryAndHotbarManager.getSlotFromTool(tool : Tool)
    local source
    if tool:GetAttribute("HotbarSlot") then 
       source = hotbar 
    elseif tool:GetAttribute("isWearing") == true then --this causes errors if the slot is a wearable and its "isWearing" attribute is false
        source = _wearableSlots
    else
        source = inventory
    end

    for _, slot in ipairs(source:GetChildren()) do
        if slot:IsA(slotTemplate.ClassName) and slot ~= slotTemplate then
            if slot:FindFirstChildOfClass("ObjectValue").Value == tool then
                return slot
            end
        end
    end
    return nil
end

local keybindConnection

inventoryAndHotbarManager.disabledInputSlots = {}

function inventoryAndHotbarManager.toggleKeybindToHotbarSlot(toggle : boolean)
    if toggle then
        --warn("enbaling keybindToHotbarSlot")
        keybindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
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
        for _, v in inventoryAndHotbarManager.disabledInputSlots do
            v.GroupTransparency = 0
        end
    else
        --warn("disabling keybindToHotbarSlot")
        keybindConnection:Disconnect()
        keybindConnection = nil
        for _, v in backpack:GetChildren() do
            if v:IsA("Tool") then
                local thisSlot = inventoryAndHotbarManager.getSlotFromTool(v)
                thisSlot.GroupTransparency = 0.5
                table.insert(inventoryAndHotbarManager.disabledInputSlots, thisSlot)
            end
        end
    end
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

function inventoryAndHotbarManager.transferSlotToInventory(slot : typeof(slotTemplate), foundCachedTool : boolean)
    --print("transferSlotToInventory()")
    local tool = slot:FindFirstChild("ObjectValue", true).Value
    if slot.Parent == hotbar then
        local emptyHotbarSlot = inventoryAndHotbarManager.createSlot(nil, "Hotbar", tonumber(slot.Name))
        emptyHotbarSlot.Parent = inventory
        inventoryAndHotbarManager.swapSlots(slot, emptyHotbarSlot) --feel like I solved a Rubik's cube with this one
        --print(emptyHotbarSlot.Name)
        tool:SetAttribute("HotbarSlot", nil)
        slot.LayoutOrder = getNumberOfInventorySlots() + 1
        slot.Name = tool.Name
        slot:FindFirstChild("Number", true).Visible = false
        return slot
    elseif slot.Parent == inventory then
        --change the slot's layout order to be +1 the greatest layout order
        slot.LayoutOrder = getNumberOfInventorySlots() + 1
        return slot
    elseif slot.Parent == _wearableSlots then
        local inventorySlot = inventoryAndHotbarManager.createSlot(tool, "Inventory")
        if not foundCachedTool then
            inventoryAndHotbarManager.toggleSlotEquippedEffect(inventorySlot, true)
        end
        return inventorySlot 
    else
        warn("unaccounted for scenario just occurred: couldn't match slot's parent")
    end 
end

function inventoryAndHotbarManager.transferToWearableSlot(passedSlot, targetSlot)
    local tool = passedSlot:FindFirstChildWhichIsA("ObjectValue").Value
    local wearableType = tool:GetAttribute("WearableType")
    if wearableType == nil then
        warn(tool.Name .. " does not have a WearableType attribute")
        return
    end

    local slotParent = passedSlot.Parent

    local designatedSlot = wearableSlots[wearableType]
    if designatedSlot ~= targetSlot then
        warn("wearable put into wrong wearable slot")
    else
        local tool = passedSlot:FindFirstChildWhichIsA("ObjectValue").Value
        designatedSlot.ObjectValue.Value = tool
        designatedSlot:FindFirstChild("Icon", true).ImageTransparency = 0.5
        initializeSlotFunctionality(tool, designatedSlot, true)
        --local button = setButton(tool, designatedSlot:FindFirstChildWhichIsA("ImageButton", true), designatedSlot:FindFirstChildWhichIsA("TextButton", true))
        if slotParent == inventory then
            passedSlot:Destroy()
        elseif slotParent == hotbar then
            inventoryAndHotbarManager.toggleSlotEquippedEffect(passedSlot, false)
            inventoryAndHotbarManager.setSlot(nil, passedSlot)
        else
            warn("something went wrong, passed slow is neither a child of hotbar nor inventory")
        end
    end
end


local storage : Folder = gui.Storage
local defaultWearableSlots = {
    Head = storage.Head,
    Torso = storage.Torso,
    Legs = storage.Legs,
    Feet = storage.Feet
}

function inventoryAndHotbarManager.transferOutOfWearableSlot(passedSlot, targetSlot, forceTransferToInventory)
    local tool = passedSlot:FindFirstChildWhichIsA("ObjectValue", true).Value
    if targetSlot == nil then
        if hoveringInInventory or forceTransferToInventory then
            print("Case 2: Create a new slot in inventory.")
            inventoryAndHotbarManager.toggleInventoryInput(false)
            bev_signalTakeOff:Fire(tool, 1)
            --[[

            ]]
            local foundCachedTool = character:FindFirstChildOfClass("Tool")
            warn(foundCachedTool)
            local lastTween = initAndRunProgressBar(passedSlot, tool:GetAttribute("wearTime"), true)
            lastTween.Completed:Once(function()
                local inventorySlot = inventoryAndHotbarManager.transferSlotToInventory(passedSlot, if foundCachedTool then true else false)
                local replacement = defaultWearableSlots[passedSlot.Name]:Clone()
                wearableSlots[replacement.Name] = replacement
                passedSlot:Destroy()
                replacement.Parent = _wearableSlots
                initSingleWearableSlot(replacement)
                inventoryAndHotbarManager.toggleInventoryInput(true)
            end)
        elseif not (hoveringInHotbar or hoveringInInventory or hoveringInWearables) then
            --print("hoveringInHotbar: " .. tostring(hoveringInHotbar) .. ", hoveringInInventory: " .. tostring(hoveringInInventory) .. ", hoveringInWearables: " .. tostring(hoveringInWearables))
            print("Case 1: Drop")
            inventoryAndHotbarManager.toggleInventoryInput(false)
            bev_signalTakeOff:Fire(tool, 1)
            local lastTween = initAndRunProgressBar(passedSlot, tool:GetAttribute("wearTime"), true)
            lastTween.Completed:Once(function()
                if tool:GetAttribute("ForceDropNow") == true then
                    tool:SetAttribute("ForceDropNow", false)
                    warn("received ForceDropNow")
                    rev_generalToolDrop:FireServer(tool)
                    local replacement = defaultWearableSlots[passedSlot.Name]:Clone()
                    wearableSlots[replacement.Name] = replacement
                    passedSlot.Destroying:Once(function()
                        replacement.Parent = _wearableSlots
                        initSingleWearableSlot(replacement)
                        inventoryAndHotbarManager.toggleInventoryInput(true)
                    end)
                end
            end)
        else
            --print("do nothing")
        end
    else
        --targetSlot exists
        local slotNotEmpty = targetSlot:FindFirstChildOfClass("ObjectValue").Value ~= nil
        if slotNotEmpty then
            if isWearableItem(targetSlot) then
                print("Case 3b: Swap wearable items' places.")
            else
                print("Case 3a: do nothing because non wearable item cannot be swapped into wearable slot")
            end
        else
            --slot is empty
            if not isWearableSlot(targetSlot) then
                print("Case 3c: intialize wearable into specified empty hotbar slot")
            end
        end
    end
end

function inventoryAndHotbarManager.initializeMisc()
    miscManager.init()
end

local numberOfEntries : number = 0
function inventoryAndHotbarManager.addToUpdateLog(addedToInventory : boolean, item)
    local tweenTime = 0.2
    local logEntry : TextLabel = updateLogTemplate:Clone()
    numberOfEntries += 1
    if type(item) == "string" then
        logEntry.Text = item
    else
        if addedToInventory then
            logEntry.Text = " + " .. item.Name --experiment w/ Rich Text Later
        else
            logEntry.Text = " - " .. item.Name
        end
    end
    logEntry.Visible = true
    logEntry.Parent = updateLog
    logEntry.Name = tostring(numberOfEntries)
    for _, entry in updateLog:GetChildren() do
        if entry ~= logEntry and entry ~= updateLogTemplate and entry:IsA("UIGradient") == false then
            local layoutOrder = numberOfEntries - tonumber(entry.Name)
            --[[
            if layoutOrder > 3 then
                task.defer(function()
                    entry:Destroy()
                end)
            elsee
                local targetPosition = UDim2.fromOffset(0, updateLogTemplate.AbsoluteSize.Y * layoutOrder)
                TweenService:Create(entry, TweenInfo.new(tweenTime), {Position = targetPosition}):Play()
            end
            ]]
            local targetPosition = UDim2.fromOffset(0, updateLogTemplate.AbsoluteSize.Y * layoutOrder)
            if targetPosition.Y.Offset > 120 then
                entry:Destroy()
            else
                TweenService:Create(entry, TweenInfo.new(tweenTime), {Position = targetPosition}):Play()
            end
        end
    end
    logEntry.Position = UDim2.fromScale(-1, 0)
    TweenService:Create(logEntry, TweenInfo.new(tweenTime), {Position = UDim2.new(0, 0, 0, 0)}):Play()
    task.spawn(function()
        task.wait(1)
        TweenService:Create(logEntry, TweenInfo.new(1), {TextTransparency = 1}):Play()
    end)
end

return inventoryAndHotbarManager