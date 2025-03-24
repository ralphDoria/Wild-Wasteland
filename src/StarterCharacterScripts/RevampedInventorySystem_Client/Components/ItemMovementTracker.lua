--!strict

local player = game:GetService("Players").LocalPlayer
local character : Model = player.Character or player.CharacterAdded:Wait() :: Model
local backpack : Backpack = player:FindFirstChild("Backpack") :: Backpack

local cachedItems = {}
local function updateCacheditems()
   cachedItems = backpack:GetChildren()
	local equippedTool = character:FindFirstChildOfClass("Tool")
	if equippedTool then
		table.insert(cachedItems, equippedTool)
	end
end

return function
    (
        onAdd : (tool : Tool) -> (),
        onEquip : (tool : Tool) -> (), 
        onUnequip : (tool : Tool) -> (), 
        onDrop : (tool : Tool) -> ()
    )
    backpack.ChildAdded:Connect(function(child)
		if not child:IsA("Tool") then return end

		if table.find(cachedItems, child) then
			--print(child.Name .. " unequipped")
            onUnequip(child)
		else
			--print(child.Name .. " was added to inventory")
            updateCacheditems()
            onAdd(child)
		end
	end)
	
	backpack.ChildRemoved:Connect(function(child)
		if not child:IsA("Tool") then return end
	
		if child.Parent == character then
			--print(child.Name .. " equipped")
            onEquip(child)
		elseif child.Parent == workspace then
			--print(child.Name .. " dropped from gui")
            updateCacheditems()
            onDrop(child)
		end
	end)
	
	character.ChildRemoved:Connect(function(child)
		if not child:IsA("Tool") then return end
	
		if child.Parent == workspace then
			--print(child.Name .. " dropped from equip")
            updateCacheditems()
            onDrop(child)
		end
	end)
end
