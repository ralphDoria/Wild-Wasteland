--!strict

local player = game:GetService("Players").LocalPlayer
local character : Model = player.Character or player.CharacterAdded:Wait() :: Model
local backpack : Backpack = player:FindFirstChild("Backpack") :: Backpack
local LootItemsHolding: Folder = game:GetService("ReplicatedStorage").LootingSystem_Storage.LootItemsHolding

local cachedItems = {}

local function addToCachedItems(item: Tool)
	table.insert(cachedItems, item)
end

local function removeFromCachedItems(item: Tool)
	local i = table.find(cachedItems, item)
	if i then
		table.remove(cachedItems, i)		
	end
end

return function
    (
        onAdded : (tool : Tool) -> (),
        onEquipping : (tool : Tool) -> (), 
        onUnequipped : (tool : Tool) -> (), 
        onDropped : (tool : Tool) -> ()
    )
    backpack.ChildAdded:Connect(function(child)
		if not child:IsA("Tool") then return end
		if table.find(cachedItems, child) then
			--print(child.Name .. " unequipped")
            onUnequipped(child)
		else
			-- print(child.Name .. " was added to inventory")
            addToCachedItems(child)
            onAdded(child)
		end
	end)
	
	backpack.ChildRemoved:Connect(function(child)
		if not child:IsA("Tool") then return end
	
		if child.Parent == character then
			--print(child.Name .. " equipped")
            onEquipping(child)
		elseif child.Parent == workspace or child:FindFirstAncestor(LootItemsHolding.Name) then
			--print(child.Name .. " dropped from gui")
            removeFromCachedItems(child)
            onDropped(child)
		end
	end)
	
	character.ChildRemoved:Connect(function(child)
		if not child:IsA("Tool") then return end
	
		if child.Parent == workspace or child:FindFirstAncestor(LootItemsHolding.Name) then
			--print(child.Name .. " dropped from equip")
            removeFromCachedItems(child)
            onDropped(child)
		end
	end)

	-- Initial Check (Placed after all events are connected to prevent any race conditions where initial check happens,
	-- then tools are added to backpack, then events are connecting, causing this file to miss tools)
	for _, v in backpack:GetChildren() do
		if v:IsA("Tool") then
			addToCachedItems(v)	
			onAdded(v)
		end
	end
	local equippedTool = character:FindFirstChildOfClass("Tool")
	if equippedTool then
		addToCachedItems(equippedTool)
		onAdded(equippedTool)
	end
end
