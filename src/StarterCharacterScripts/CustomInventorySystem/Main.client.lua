local KEY_BIND_INVENTORY = Enum.KeyCode.Tab

----[[VARIABLES]]----
local Players = game:GetService("Players") 
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")

local inventoryAndHotbarManager = require(script.Parent:FindFirstChild("inventoryAndHotbarManager"))

local player = Players.LocalPlayer 
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character.Humanoid
local backpack = player.Backpack -- the player's backpack (used to store all tools by default)

local gui : ScreenGui = player.PlayerGui:WaitForChild("InventoryAndHotbar")
local inventory : ScrollingFrame = gui:FindFirstChild("Inventory", true) -- the bag/inventory frame
local main : Frame = inventory.Parent
local hotbar : CanvasGroup = gui:FindFirstChild("Hotbar", true) -- the hotbar frame

local toggle = false

ContextActionService:BindAction(
	"Inventory", 
	function(actionName, inputState, _inputObject)
		if actionName == "Inventory" and inputState == Enum.UserInputState.Begin then
			toggle = not toggle
			inventoryAndHotbarManager.toggleInventory(toggle)
		end
	end,
	true,
	Enum.KeyCode.Tab
)

inventoryAndHotbarManager.intitializeHotbar()

local cachedItems = backpack:GetChildren()

local function updateCachedItems()
	cachedItems = backpack:GetChildren()
	local equippedTool = character:FindFirstChildOfClass("Tool")
	if equippedTool then
		table.insert(cachedItems, equippedTool)
	end
end

local function flashHotbar()
	--print(hotbar.GroupTransparency)
	inventoryAndHotbarManager.toggleHotbar(true)
	task.spawn(function()
		task.wait(1)
		--print(hotbar.GroupTransparency)
		if hotbar.GroupTransparency == 0 and not main.Visible then
			inventoryAndHotbarManager.toggleHotbar(false)
		end
	end)
end

backpack.ChildAdded:Connect(function(child)
	if not child:IsA("Tool") then return end

	--create a slot in the hotbar if the hotbar's not full, or else, create a slot in the inventory
	if table.find(cachedItems, child) then
		--print(child.Name .. " unequipped")
		inventoryAndHotbarManager.toggleSlotEquippedEffect(inventoryAndHotbarManager.getSlotFromTool(child), false)
	else
		--print(child.Name .. " was added to inventory")
		inventoryAndHotbarManager.addToUpdateLog(true, child)
		local emptyHotbarSlot = inventoryAndHotbarManager.findMinimumEmptyHotbarSlot()
		if emptyHotbarSlot then
			--adding item to hotbar
			print("empty hotbar slot: " .. emptyHotbarSlot.Name)
			inventoryAndHotbarManager.setSlot(child, emptyHotbarSlot)
			flashHotbar()
		else
			--adding item to inventory
			inventoryAndHotbarManager.createSlot(child, "Inventory")
		end
	end
	updateCachedItems()
end)

local function updateGuiAfterDroppedTool(droppedTool : Tool)
	updateCachedItems()
	inventoryAndHotbarManager.toggleSlotEquippedEffect(inventoryAndHotbarManager.getSlotFromTool(droppedTool), false)
	inventoryAndHotbarManager.setSlot(nil, inventoryAndHotbarManager.getSlotFromTool(droppedTool))
end

backpack.ChildRemoved:Connect(function(child)
	if not child:IsA("Tool") then return end

	if child.Parent == character then
		--print(child.Name .. " equipped")	
		inventoryAndHotbarManager.toggleSlotEquippedEffect(inventoryAndHotbarManager.getSlotFromTool(child), true)
	elseif child.Parent == workspace then
		--print(child.Name .. " dropped from gui")
		inventoryAndHotbarManager.addToUpdateLog(false, child)
		updateGuiAfterDroppedTool(child)
	end
end)

character.ChildRemoved:Connect(function(child)
	if not child:IsA("Tool") then return end

	if child.Parent == workspace then
		--print(child.Name .. " dropped from equip")
		inventoryAndHotbarManager.addToUpdateLog(false, child)
		updateGuiAfterDroppedTool(child)
	end
end)

repeat
	task.wait()
	--print("Waiting for hotbar to initialize")
until hotbar:GetAttribute("Initialized")

gui.Enabled = true
inventoryAndHotbarManager.toggleInventory(false)
inventoryAndHotbarManager.toggleHotbar(false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) --disables Roblox's default backpack
inventoryAndHotbarManager.initializeKeybindToHotbarSlot()
inventoryAndHotbarManager.initializeWearablesGui()
inventoryAndHotbarManager.initializeMisc()
