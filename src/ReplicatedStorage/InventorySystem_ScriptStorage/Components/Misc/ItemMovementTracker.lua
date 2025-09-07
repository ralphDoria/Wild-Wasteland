--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)
local LootItemsHolding: Folder = ReplicatedStorage.LootingSystem_Storage.LootItemsHolding

export type ItemMovementTracker = {
	cachedTools: {Tool},
	trove: any
}

local ItemMovementTracker = {}

local addedToCacheEvent = Instance.new("BindableEvent")
local removedFromCacheEvent = Instance.new("BindableEvent")
ItemMovementTracker.added = addedToCacheEvent.Event:: RBXScriptSignal
ItemMovementTracker.removed = removedFromCacheEvent.Event:: RBXScriptSignal


function ItemMovementTracker.new(
	character: Model, 
	backpack: Backpack,
	onAdded : (tool : Tool) -> (),
	onEquipping : (tool : Tool) -> (), 
	onUnequipped : (tool : Tool) -> (), 
	onDropped : (tool : Tool) -> ()
): ItemMovementTracker

	local self: ItemMovementTracker = {
		cachedTools = {},
		trove = Trove.new(),
	}

	ItemMovementTracker._init(
		self,
		character, 
		backpack,
		onAdded,
		onEquipping, 
		onUnequipped, 
		onDropped
	)

	return self
end

function ItemMovementTracker._init(
	self: ItemMovementTracker,
	character: Model, 
	backpack: Backpack,
	onAdded : (tool : Tool) -> (),
	onEquipping : (tool : Tool) -> (), 
	onUnequipped : (tool : Tool) -> (), 
	onDropped : (tool : Tool) -> ()
)
    self.trove:Connect(backpack.ChildAdded, function(child: Instance)
		if not child:IsA("Tool") then return end
		if table.find(self.cachedTools, child) then
			--print(child.Name .. " unequipped")
            onUnequipped(child)
		else
			-- print(child.Name .. " was added to inventory")
            ItemMovementTracker._addToCachedTools(self, child)
		end
	end)
	
	self.trove:Connect(backpack.ChildRemoved, function(child: Instance)
		if not child:IsA("Tool") then return end
	
		if child.Parent == character then
			--print(child.Name .. " equipped")
            onEquipping(child)
		elseif child.Parent == workspace or child:FindFirstAncestor(LootItemsHolding.Name) or child.Parent == nil then
			--print(child.Name .. " dropped from gui")
            ItemMovementTracker._removeFromCachedTools(self, child)
		end
	end)
	
	self.trove:Connect(character.ChildRemoved, function(child: Instance)
		if not child:IsA("Tool") then return end
	
		if child.Parent == workspace or child:FindFirstAncestor(LootItemsHolding.Name) or child.Parent == nil then
			--print(child.Name .. " dropped from equip")
            ItemMovementTracker._removeFromCachedTools(self, child)
		end
	end)

	self.trove:Connect(ItemMovementTracker.added, function(tool: Tool)
		onAdded(tool)
	end)

	self.trove:Connect(ItemMovementTracker.removed, function(tool: Tool)
		onDropped(tool)	
	end)

	-- Initial Check (Placed after all events are connected to prevent any race conditions where initial check happens,
	-- then tools are added to backpack, then events are connecting, causing this file to miss tools)
	for _, v in backpack:GetChildren() do
		if v:IsA("Tool") then
            ItemMovementTracker._addToCachedTools(self, v)
		end
	end
	local equippedTool = character:FindFirstChildOfClass("Tool")
	if equippedTool then
		ItemMovementTracker._addToCachedTools(self, equippedTool)
	end
end

function ItemMovementTracker._addToCachedTools(self: ItemMovementTracker, tool: Tool)
	if table.find(self.cachedTools, tool) then return end
	table.insert(self.cachedTools, tool)
	addedToCacheEvent:Fire(tool)
end

function ItemMovementTracker._removeFromCachedTools(self: ItemMovementTracker, tool: Tool)
	local i = table.find(self.cachedTools, tool)
	if i then
		task.defer(function() -- task.defer is to prevent index shifts from affecting the for loop in the ItemMovementTracker.Destroy()
			table.remove(self.cachedTools, i)		
		end)
		removedFromCacheEvent:Fire(tool)
	else
		warn(`{tool} not found in cachedTools`)
	end
end

function ItemMovementTracker.Destroy(self: ItemMovementTracker)
	for i, v in self.cachedTools do
		ItemMovementTracker._removeFromCachedTools(self, v)
	end
	task.defer(function()
		table.clear(self.cachedTools)
		self.trove:Destroy()
		table.clear(self)
	end)
end

return ItemMovementTracker