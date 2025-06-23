local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)

local ScriptStorage = game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage
local ToggleOVerrideCamModeCursorLock = require(ScriptStorage.Components.Misc.ToggleOverrideCamModeCursorLock)

local touchBackpackSlotConnection: RBXScriptConnection?
local InventoryToggle = {}

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(0.2)
local InventoryBlur = Instance.new("BlurEffect")
InventoryBlur.Size = 0
local baseSize = 0
local targetSize = 30
InventoryBlur.Parent = Lighting
local InventoryCC = Instance.new("ColorCorrectionEffect")
local baseTint = Color3.fromRGB(255, 255, 255)
local targetTint = Color3.fromRGB(152, 152, 152)
InventoryCC.Parent = Lighting
local cachedToggle: boolean

export type InventoryForms = "Closed" | "InventoryForm" | "LootingForm"
InventoryToggle.currentForm = "Closed":: InventoryForms
local InventoryFormChangedBindable = Instance.new("BindableEvent")
InventoryToggle.InventoryFormChanged = InventoryFormChangedBindable.Event

local function toggleInventoryLightingFX(toggle: boolean)
	if cachedToggle ~= toggle then
		cachedToggle = toggle

		if toggle then
			TweenService:Create(InventoryBlur, tweenInfo, {Size = targetSize}):Play()
			TweenService:Create(InventoryCC, tweenInfo, {TintColor = targetTint}):Play()
		else
			TweenService:Create(InventoryBlur, tweenInfo, {Size = baseSize}):Play()
			TweenService:Create(InventoryCC, tweenInfo, {TintColor = baseTint}):Play()
		end
		local parent = if toggle then Lighting else nil
		InventoryBlur.Parent = parent
		InventoryCC.Parent = parent
	end
end

function InventoryToggle.ChangeForm(form: InventoryForms)

    if form == InventoryToggle.currentForm then return end

    InventoryToggle.currentForm = form
    InventoryFormChangedBindable:Fire()

    if form == "Closed" then
        toggleInventoryLightingFX(false)
	    ToggleOVerrideCamModeCursorLock(false)
        local tween = TweenService:Create(References_Inventory.MainInventory, tweenInfo, {Size = UDim2.fromScale(1, 0)})
		tween:Play()
		tween.Completed:Once(function(a0: Enum.PlaybackState)  
			if References_Inventory.MainInventory.Size.Y.Scale == 0 then
				References_Inventory.MainInventory.Visible = false
			end
		end)
    elseif form == "InventoryForm" or form == "LootingForm" then
        toggleInventoryLightingFX(true)
	    ToggleOVerrideCamModeCursorLock(true)
        References_Inventory.MainInventory.Visible = true
        local screenHeight = References_Inventory.InventoryScreenGui.AbsoluteSize.Y
        local HotbarHeight = References_Inventory.Hotbar.AbsoluteSize.Y
		TweenService:Create(References_Inventory.MainInventory, tweenInfo, {Size = UDim2.new(1, 0, 0, screenHeight - HotbarHeight)}):Play()
    end

    References_Inventory.LootingSection.Visible = if form == "LootingForm" then true else false
end

local function inventoryStateMachine(form: InventoryForms): InventoryForms
    if InventoryToggle.currentForm:: InventoryForms == "Closed" then
        return "InventoryForm"
    else
        return "Closed"
    end
end

function InventoryToggle.Bind()
    References_Inventory.ContextActionService:BindAction(
        "Inventory", 
        function(actionName, inputState, _inputObject)
            if actionName == "Inventory" and inputState == Enum.UserInputState.Begin then
                InventoryToggle.ChangeForm(inventoryStateMachine(InventoryToggle.currentForm))
            end
            return Enum.ContextActionResult.Sink
        end,
        false,
        Enum.KeyCode.Tab
    )
    local button = References_Inventory.TouchBackpackSlot:FindFirstChildWhichIsA("TextButton", true)
    if button then
        touchBackpackSlotConnection = button.MouseButton1Click:Connect(function()  
            print("touch tap input registered")
            InventoryToggle.ChangeForm(inventoryStateMachine(InventoryToggle.currentForm))
        end)
    else
        warn("button not found")
    end
end

function InventoryToggle.connectOnCloseAreaClicked(callback: () -> ()): RBXScriptConnection

    local function _inCloseArea(): boolean
        local mousePos = References_Inventory.UserInputService:GetMouseLocation()
        local guis = References_Inventory.PlayerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y - References_Inventory.GuiService:GetGuiInset().Y)
        warn(guis)
        local filteredGuis = {}

        for _, v in guis do 
            if v == References_Inventory.CharacterSection
                or v == References_Inventory.InventorySection
                or v == References_Inventory.LootingSection then
                table.insert(filteredGuis, v)
            end
        end

        if #filteredGuis == 0 then 
            return true
        else
            return false
        end
    end

    local function _inputAndAreaChecks(inputObject: InputObject)
        return (inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch) and _inCloseArea()
    end

    return References_Inventory.UserInputService.InputBegan:Connect(function(io1: InputObject)  
        if _inputAndAreaChecks(io1) then
            References_Inventory.UserInputService.InputEnded:Once(function(io2: InputObject, a1: boolean)  
                if _inputAndAreaChecks(io2) then
                    callback()
                end
            end)
        end
    end)

end

function InventoryToggle.Unbind()
    References_Inventory.ContextActionService:UnbindAction("Inventory")
    if touchBackpackSlotConnection then
        touchBackpackSlotConnection:Disconnect()
        touchBackpackSlotConnection = nil
    end
    if outsideClickCheck then
        outsideClickCheck:Disconnect()
        outsideClickCheck = nil
    end
end

return InventoryToggle