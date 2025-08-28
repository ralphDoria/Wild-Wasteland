--!strict

local RS = game:GetService("ReplicatedStorage")
local References_Inventory = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)

-- Sections
local ScriptStorage = RS.RojoManaged_RS.InventorySystem_ScriptStorage
local CharacterSection = require(ScriptStorage.CharacterSection.CharacterSectionManager)
local HotbarSection = require(ScriptStorage.HotbarSection.Main_HotbarSection)
local LootingSection = require(ScriptStorage.LootingSection.Main_LootingSection)
local SlotRegistry = require(ScriptStorage.Components.Slot.SlotRegistry)

local EmptySlotFinder = require(ScriptStorage.Components.Slot.EmptySlotFinder)

-- Universal Inventory Components
local Slot = require("./Components/Slot/Slot")

-- Misc
local ItemMovementTracker = require("./Components/Misc/ItemMovementTracker")
local InventoryToggle = require(ScriptStorage.Components.InventoryToggle)
local LootedTagReplicatedToClient: RemoteEvent = RS.LootingSystem_Storage.Remotes.LootedTagReplicatedToClient

export type InventoryManager = {
	itemMovementTrackerObject: ItemMovementTracker.ItemMovementTracker,
	characterSectionObject: CharacterSection.CharacterSectionObject,
	hotbarSectionObject: HotbarSection.HotbarObject,
	resizeInventoryConnection: RBXScriptConnection?
}

local InventoryManager = {}

function InventoryManager.new(onToolAdded: (tool: Tool) -> (), onToolRemoved: (tool: Tool) -> ()): InventoryManager
	References_Inventory.update()

	References_Inventory.InventoryScreenGui.Enabled = true
	References_Inventory.Hotbar.Visible = true

	local self: InventoryManager = {
		characterSectionObject = CharacterSection.new(),
		hotbarSectionObject = HotbarSection.new(References_Inventory.Hotbar),
		itemMovementTrackerObject = ItemMovementTracker.new(
			References_Inventory.character,
			References_Inventory.backpack,	
			function(tool) --onAdded
				onToolAdded(tool)

				if tool:HasTag("Looted") then
					-- warn("has loot tag, not filling slot here")
					LootedTagReplicatedToClient:FireServer(tool)
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
				--@Notice: a bit inconsistent how I use the function below for emptying slots but not these two middle functions for anything. Might have to change later
			end,
			function(tool) --onDropped/onRemovedFromInventory
				onToolRemoved(tool)
				Slot.EmptySlot(SlotRegistry.toolToObjectMap[tool])
			end
		),
		resizeInventoryConnection = nil
	}

	InventoryToggle.ChangeForm("Closed")
	-- warn("LOOTING SECTION IS CURRENTLY DISABLED")
	LootingSection.init() -- responsible for cleaning up inventory. May want to change organization of that so that main functionality is more obvious here since this file is supposed to be the "main hub"
	
	self.resizeInventoryConnection = References_Inventory.InventoryScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()  
		InventoryManager.ResizeGui(self)
	end)

	InventoryToggle.Bind()
 
	warn("INITIALIZED INVENTORY SYSTEM")
	return self
end

function InventoryManager.Destroy(self: InventoryManager)
	CharacterSection.Destroy(self.characterSectionObject)
	ItemMovementTracker.Destroy(self.itemMovementTrackerObject)
	HotbarSection.Destroy(self.hotbarSectionObject)

	-- LootingSection.Destroy(self.lootin) Looting section does not need to be destroyed because it only connects a signel connection w/ once, which is the humanoid.died connection
end

local cachedScreenSize = {
	width = nil,
	height = nil
}
function InventoryManager.ResizeGui(self: InventoryManager)
	local screenWidth = References_Inventory.InventoryScreenGui.AbsoluteSize.X

	local screenHeight = References_Inventory.InventoryScreenGui.AbsoluteSize.Y
	local HotbarHeight = References_Inventory.Hotbar.AbsoluteSize.Y
	References_Inventory.MainInventory.Size = UDim2.new(1, 0, 0, screenHeight - HotbarHeight)

	CharacterSection.ResizeGui(self.characterSectionObject)

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

return InventoryManager