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


ContextActionService:BindAction(
	"Inventory", 
	function(actionName, inputState, _inputObject)
		if actionName == "Inventory" and inputState == Enum.UserInputState.Begin then
			inventoryAndHotbarManager.toggleInventory(not main.Visible)
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

backpack.ChildAdded:Connect(function(child)
	if not child:IsA("Tool") then return end

	--create a slot in the hotbar if the hotbar's not full, or else, create a slot in the inventory
	if table.find(cachedItems, child) then
		--print(child.Name .. " unequipped")
		inventoryAndHotbarManager.toggleSlotEquippedEffect(inventoryAndHotbarManager.getSlotFromTool(child), false)
	else
		--print(child.Name .. " was added to inventory")
		local emptyHotbarSlot = inventoryAndHotbarManager.findMinimumEmptyHotbarSlot()
		if emptyHotbarSlot then
			--adding item to hotbar
			inventoryAndHotbarManager.setSlot(child, emptyHotbarSlot)
		else
			--adding item to inventory
			inventoryAndHotbarManager.createSlot(child, "Inventory")
		end
	end
	updateCachedItems()
end)

backpack.ChildRemoved:Connect(function(child)
	if not child:IsA("Tool") then return end

	if child.Parent == character then
		--print(child.Name .. " equipped")	
		inventoryAndHotbarManager.toggleSlotEquippedEffect(inventoryAndHotbarManager.getSlotFromTool(child), true)
	elseif child.Parent == workspace then
		--print(child.Name .. " dropped from gui")
		updateCachedItems()
		inventoryAndHotbarManager.toggleSlotEquippedEffect(inventoryAndHotbarManager.getSlotFromTool(child), false)
	end
end)

character.ChildRemoved:Connect(function(child)
	if not child:IsA("Tool") then return end

	if child.Parent == workspace then
		--print(child.Name .. " dropped from equip")
		updateCachedItems()
		inventoryAndHotbarManager.toggleSlotEquippedEffect(inventoryAndHotbarManager.getSlotFromTool(child), false)
		inventoryAndHotbarManager.setSlot(nil, inventoryAndHotbarManager.getSlotFromTool(child))
	end
end)

repeat
	task.wait()
	--print("Waiting for hotbar to initialize")
until hotbar:GetAttribute("Initialized")
inventoryAndHotbarManager.toggleInventory(false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) --disables Roblox's default backpack
inventoryAndHotbarManager.initializeKeybindToHotbarSlot()

