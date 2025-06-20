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

function InventoryToggle.Visible(toggle: boolean)
    if toggle then
		References_Inventory.MainInventory.Visible = true
        local screenHeight = References_Inventory.InventoryScreenGui.AbsoluteSize.Y
        local HotbarHeight = References_Inventory.Hotbar.AbsoluteSize.Y
		TweenService:Create(References_Inventory.MainInventory, tweenInfo, {Size = UDim2.new(1, 0, 0, screenHeight - HotbarHeight)}):Play()
	else
		local tween = TweenService:Create(References_Inventory.MainInventory, tweenInfo, {Size = UDim2.fromScale(1, 0)})
		tween:Play()
		tween.Completed:Once(function(a0: Enum.PlaybackState)  
			if References_Inventory.MainInventory.Size.Y.Scale == 0 then
				References_Inventory.MainInventory.Visible = false
			end
		end)
	end
	toggleInventoryLightingFX(toggle)
	ToggleOVerrideCamModeCursorLock(toggle)
end

function InventoryToggle.Bind()
    References_Inventory.ContextActionService:BindAction(
        "Inventory", 
        function(actionName, inputState, _inputObject)
            if actionName == "Inventory" and inputState == Enum.UserInputState.Begin then
                InventoryToggle.Visible(if References_Inventory.MainInventory.Visible then false else true)
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
            InventoryToggle.Visible(if References_Inventory.MainInventory.Visible then false else true)
        end)
    else
        warn("button not found")
    end
end

function InventoryToggle.Unbind()
    References_Inventory.ContextActionService:UnbindAction("Inventory")
    if touchBackpackSlotConnection then
        touchBackpackSlotConnection:Disconnect()
        touchBackpackSlotConnection = nil
    end
end

return InventoryToggle