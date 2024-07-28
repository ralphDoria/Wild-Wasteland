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

main.Visible = false
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

