local KEY_BIND_INVENTORY = Enum.KeyCode.Tab

----[[VARIABLES]]----
local Players = game:GetService("Players") 
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")

local rev_statChangeSound = ReplicatedStorage:FindFirstChild("StatChangeSound", true)
local playSound = require(ReplicatedStorage:FindFirstChild("PlaySoundUtil", true))
local SoundService = game:GetService("SoundService")
local coinCollectSound : Sound = SoundService:FindFirstChild("Coins ka-ching", true)
local ammoCollectSound : Sound = SoundService:FindFirstChild("Ammo pickup", true)

local inventoryAndHotbarManager = require(script.Parent:FindFirstChild("inventoryAndHotbarManager"))

local player = Players.LocalPlayer 
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character.Humanoid
local backpack = player.Backpack -- the player's backpack (used to store all tools by default)

local gui : ScreenGui = player.PlayerGui:WaitForChild("InventoryAndHotbar")
local updateMisc : BindableEvent = gui:FindFirstChildWhichIsA("BindableEvent", true)
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
		local slot = inventoryAndHotbarManager.getSlotFromTool(child)
		--print(if slot then slot.Parent else "nil")
		inventoryAndHotbarManager.toggleSlotEquippedEffect(slot, false)
	else
		--print(child.Name .. " was added to inventory")
		inventoryAndHotbarManager.addToUpdateLog(true, child)
		local emptyHotbarSlot = inventoryAndHotbarManager.findMinimumEmptyHotbarSlot()
		if emptyHotbarSlot then
			--adding item to hotbar
			inventoryAndHotbarManager.setSlot(child, emptyHotbarSlot)
			--flashHotbar()
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
	inventoryAndHotbarManager.setSlot(nil, inventoryAndHotbarManager.getSlotFromTool(droppedTool)) --this errors if the slot is a wearable and its "isWearing" attribute is false
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

updateMisc.Event:Connect(function(statName : string, amountGained : number)
	local sign
	if amountGained > 0 then 
		sign = " + " 
	else 
		sign = ""
	end
	inventoryAndHotbarManager.addToUpdateLog(nil,  sign .. tostring(amountGained) .. " " .. statName)
end)

rev_statChangeSound.OnClientEvent:Connect(function(tagName : string)
    if tagName == "DroppedCurrency" then
        playSound(coinCollectSound, nil, 0)
    elseif tagName == "DroppedAmmo" then
        playSound(ammoCollectSound, nil, 0)
    else
        warn("parameter passed does not match any existing stat name")
    end
end)


if player:GetAttribute("inTitleScreen") == false then
	inventoryAndHotbarManager.initializeSystem()
else
	local connection
	connection = player:GetAttributeChangedSignal("inTitleScreen"):Connect(function()
		if player:GetAttribute("inTitleScreen") == false then
			inventoryAndHotbarManager.initializeSystem()
			connection:Disconnect()
		end
	end)
end
