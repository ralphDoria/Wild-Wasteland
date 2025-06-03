--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
----
local Slot = require("./Components/Slot")
local HotbarManager = require("./Components/Hotbar")
local WearableInterface = require("./Components/WearableInterface")
local RobloxStateMachine = require("../../../../ReplicatedStorage/Packages/RobloxStateMachine") :: any
local ItemGroup = require("./Components/ItemGroup")
local Config = require("./Config")
local ItemMovementTracker = require("./Components/ItemMovementTracker")
----
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local playerGui : PlayerGui = player:FindFirstChild("PlayerGui") :: PlayerGui
local character = player.Character or player.CharacterAdded:Wait()
local backpack : Backpack = player:FindFirstChild("Backpack") :: Backpack
----
local gui : ScreenGui = playerGui:WaitForChild("RevampingInventory") :: ScreenGui
local ForModal : GuiButton = gui:FindFirstChild("ForModal") :: GuiButton
local UserInputService = game:GetService("UserInputService")
local Hotbar : CanvasGroup = gui:FindFirstChild("Hotbar") :: CanvasGroup
local MainInventory : Frame = gui:FindFirstChild("MainInventory") :: Frame
local StoreSection : ScrollingFrame = MainInventory:FindFirstChild("StoreSection") :: ScrollingFrame
local WearableSection : Frame = MainInventory:FindFirstChild("WearableSection") :: Frame
----
local Templates : Folder = gui:FindFirstChild("Templates") :: Folder
local SlotTemplate : Frame = Templates:FindFirstChild("SlotTemplate") :: Frame
local ItemGroupTemplate : Frame = Templates:FindFirstChild("ItemGroupTemplate") :: Frame
local InventoryState = require("./Components/InventoryState")
----

local InventorySystem = {}

function InventorySystem.init()
	-- warn("initializing revamped inventory")
	gui.Enabled = true
	Hotbar.Visible = true
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) --disables Roblox's default backpack

	HotbarManager.init(SlotTemplate, Hotbar)
	WearableInterface.initialize(character)
	MainInventory.Visible = false

	ItemMovementTracker(
		function(tool) --onAdded
			-- warn("calling onAdded")
			local emptyHotbarslot : Slot.SlotType? =  HotbarManager.findMinimumEmptyHotbarSlot()
			if emptyHotbarslot ~= nil then
				Slot.FillSlot(emptyHotbarslot, tool, tool:GetAttribute("Type") :: string)
			end
		end,
		function(tool) --onEquipping
			--highlight slot
		end,
		function(tool) --onUnequipped
			if not tool:GetAttribute("IsWorn") then
				-- do what you need to do
			else
				-- print("doing nothing because this is a worn slot")
			end
			--unhighlight slot
		end,
		function(tool) --onDropped
			--empty slot
			Slot.EmptySlot(Slot.GetSlotFromTool(tool) ::  Slot.SlotType)
		end
	)

	ContextActionService:BindAction(
		"Inventory", 
		function(actionName, inputState, _inputObject)
			if actionName == "Inventory" and inputState == Enum.UserInputState.Begin then
				InventorySystem.toggleInventoryVisibility(if MainInventory.Visible then false else true)
			end
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.KeyCode.Tab
	)
	local TouchBackpackSlot = Hotbar:FindFirstChild("TouchBackpackSlot") :: Frame
	local button = TouchBackpackSlot:FindFirstChildWhichIsA("TextButton", true)
	if button then
		button.MouseButton1Click:Connect(function()  
			print("touch tap input registered")
			InventorySystem.toggleInventoryVisibility(if MainInventory.Visible then false else true)
		end)
	else
		warn("button not found")
	end
end

--[[
	This function for now seems to be complicating a simple thing, but it's here for in the future when I implement animations to show/hide the main inventory
]]
function InventorySystem.toggleInventoryVisibility(toggle : boolean)
	MainInventory.Visible = toggle
	ForModal.Modal = toggle
	if toggle then
		game:GetService("RunService"):BindToRenderStep("OverrideCameraModeCursorLock", 201, function()
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end)
	else
		game:GetService("RunService"):UnbindFromRenderStep("OverrideCameraModeCursorLock")
	end
	
end

return InventorySystem