--!strict

local RS = game:GetService("ReplicatedStorage")
local References_Inventory = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)

-- Sections
local ScriptStorage = RS.RojoManaged_RS.InventorySystem_ScriptStorage
local CharacterSection = require(ScriptStorage.CharacterSection.Main_CharacterSection)
local HotbarSection = require(ScriptStorage.HotbarSection.Main_HotbarSection)
local LootingSection = require(ScriptStorage.LootingSection.Main_LootingSection)
local SlotRegistry = require(ScriptStorage.Components.Slot.SlotRegistry)


local EmptySlotFinder = require(ScriptStorage.Components.Slot.EmptySlotFinder)

-- Universal Inventory Components
local Slot = require("./Components/Slot/Slot")

-- Misc
local ItemMovementTracker = require("./Components/Misc/ItemMovementTracker")
local InventoryToggle = require(ScriptStorage.Components.InventoryToggle)

local character = References_Inventory.player.Character or References_Inventory.player.CharacterAdded:Wait()
character:WaitForChild("Humanoid").Died:Connect(function()
    error("TODO: Come back to this script to implement death procedures")
end)

local InventorySystem = {
	Connections = {}
}

local function preInitSetup()
	References_Inventory.InventoryScreenGui.Enabled = true
	References_Inventory.Hotbar.Visible = true
	References_Inventory.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) --disables Roblox's default backpack
end

function InventorySystem.init()
	warn("initializing revamped inventory")
	preInitSetup()

	CharacterSection.init()
	HotbarSection.init(References_Inventory.TemplateSlot, References_Inventory.Hotbar)
	InventoryToggle.ChangeForm("Closed")
	LootingSection.init()
	
	ItemMovementTracker(
		function(tool) --onAdded
			-- warn("calling onAdded")

			if tool:HasTag("Looted") then
				warn("has loot tag, not filling slot here")
				-- fire a remote back to the server to remove the tag
				return
			end

			local emptySlot : Slot.SlotObject? =  EmptySlotFinder.any()
			if emptySlot then
				Slot.FillSlot(emptySlot, tool)
			end
		end,
		function(tool) --onEquipping
		end,
		function(tool) --onUnequipped
			if not tool:GetAttribute("IsWorn") then
				-- do what you need to do
			else
				-- print("doing nothing because this is a worn slot")
			end
		end,
		function(tool) --onDropped
			--empty slot
			Slot.EmptySlot(Slot.toolToObjectMap[tool])
		end
	)

	table.insert(
		InventorySystem.Connections,
		References_Inventory.InventoryScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(InventorySystem.ResizeGui)
	)

	InventoryToggle.Bind()
end

local cachedScreenSize = {
	width = nil,
	height = nil
}
function InventorySystem.ResizeGui()
	local screenWidth = References_Inventory.InventoryScreenGui.AbsoluteSize.X

	local screenHeight = References_Inventory.InventoryScreenGui.AbsoluteSize.Y
	local HotbarHeight = References_Inventory.Hotbar.AbsoluteSize.Y
	References_Inventory.MainInventory.Size = UDim2.new(1, 0, 0, screenHeight - HotbarHeight)

	CharacterSection.ResizeGui()

	if screenWidth ~= cachedScreenSize.width then
		cachedScreenSize.width = screenWidth
		LootingSection.ResizeGui()
	end

	local characterSectionHeight = References_Inventory.CharacterSection.AbsoluteSize.Y
	local fifthSection = characterSectionHeight/5
	if  fifthSection < 50 then
		for instance, object: Slot.SlotObject in Slot.instanceToObjectMap do
			local slotInstanceSize = UDim2.fromOffset(fifthSection, fifthSection)

			local itemsFrameOfSlotgroup = instance.Parent
			if itemsFrameOfSlotgroup then
				local uiGridLayout = itemsFrameOfSlotgroup:FindFirstChildOfClass("UIGridLayout")
				if uiGridLayout and uiGridLayout.CellSize ~= slotInstanceSize then
					uiGridLayout.CellSize = slotInstanceSize
				else
					instance.Size = slotInstanceSize
				end
			end
		end
		References_Inventory.TouchBackpackSlot.Size = UDim2.fromOffset(fifthSection, fifthSection)
	end
end



return InventorySystem