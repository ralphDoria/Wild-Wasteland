--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
----
local Slot = require("./Components/Slot")
local HotbarManager = require("./Components/Hotbar")
local RobloxStateMachine = require("../../../../ReplicatedStorage/Packages/RobloxStateMachine") :: any
local ItemGroup = require("./Components/ItemGroup")
local Config = require("./Config")
local ItemMovementTracker = require("./Components/ItemMovementTracker")
----
local player = Players.LocalPlayer
local playerGui : PlayerGui = player:FindFirstChild("PlayerGui") :: PlayerGui
local character = player.Character or player.CharacterAdded:Wait()
local backpack : Backpack = player:FindFirstChild("Backpack") :: Backpack
----
local gui : ScreenGui = playerGui:WaitForChild("RevampingInventory") :: ScreenGui
local ForModal : GuiButton = gui:FindFirstChild("ForModal") :: GuiButton
local Hotbar : CanvasGroup = gui:FindFirstChild("Hotbar") :: CanvasGroup
local MainInventory : Frame = gui:FindFirstChild("MainInventory") :: Frame
local StoreSection : ScrollingFrame = MainInventory:FindFirstChild("StoreSection") :: ScrollingFrame
local WearableSection : Frame = MainInventory:FindFirstChild("WearableSection") :: Frame
----
local Templates : Folder = gui:FindFirstChild("Templates") :: Folder
local SlotTemplate : Frame = Templates:FindFirstChild("SlotTemplate") :: Frame
local ItemGroupTemplate : Frame = Templates:FindFirstChild("ItemGroupTemplate") :: Frame
----

local InventorySystem = {}

function InventorySystem.init()
	warn("initializing revamped inventory")
	gui.Enabled = true
	Hotbar.Visible = true
	MainInventory.Visible = false
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) --disables Roblox's default backpack

	HotbarManager.init(SlotTemplate, Hotbar)

	ItemMovementTracker(
		function(tool) --onAdd
			print("calling onadd")
			local emptyHotbarslot : Slot.SlotType? =  HotbarManager.findMinimumEmptyHotbarSlot()
			if emptyHotbarslot ~= nil then
				Slot.FillSlot(emptyHotbarslot, tool, tool:GetAttribute("Type") :: string)
			end
		end,
		function(tool) --onEquip
			
		end,
		function(tool) --onUnequip
			
		end,
		function(tool) --onDrop

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
		true,
		Enum.KeyCode.Tab
	)
end

--[[
	This function for now seems to be complicating a simple thing, but it's here for in the future when I implement animations to show/hide the main inventory
]]
function InventorySystem.toggleInventoryVisibility(toggle : boolean)
	MainInventory.Visible = toggle
	ForModal.Modal = toggle
end

return InventorySystem