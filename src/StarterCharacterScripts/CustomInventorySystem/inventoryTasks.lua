local module = {}

local UIS = game:GetService("UserInputService")

local slotsToNums = {
	["SLOT1"] = 1,
	["SLOT2"] = 2,
	["SLOT3"] = 3,
	["SLOT4"] = 4,
	["SLOT5"] = 5
}

currentFrameBeingHoveredOn = nil
currentItemSelected = nil
isDraggingItem = false

--[[
    Updates the variable, currentFrameBeingHoveredOn, which
]]
function module.HoverFrameChange(toggle, frame)
	if toggle == true then
		currentFrameBeingHoveredOn = frame
	else
		currentFrameBeingHoveredOn = nil
	end
end


function module.BagLoad(bag, backpack, itemTemplate)
    --make each slot in the scrolling frame visible
	for _, frame in pairs(bag.ScrollingFrame:GetChildren()) do
		if frame:IsA("Frame") then
			frame.Visible = false
		end
	end

	for _, item in pairs(backpack:GetChildren()) do
		if item:IsA("Tool") and item.slotIn.Value == 0 then --if item is unequipped & not in the hotbar then...
			if not bag.ScrollingFrame:FindFirstChild(item.Name) then --if item isn't already in the inventory scrolling frame then...

				--initialize a new gui slot for it (including connecting events)
                local newItemFrame = itemTemplate:Clone()
				newItemFrame.Name = item.Name
				newItemFrame.itemImage.Image = item.TextureId
				newItemFrame.Visible = true
				newItemFrame.Parent = bag.ScrollingFrame


				newItemFrame.MouseEnter:Connect(function()
					module.HoverFrameChange(true, newItemFrame)
				end)

				newItemFrame.MouseLeave:Connect(function()
					if isDraggingItem == false then
						module.HoverFrameChange(false)
					end
				end)
                --

			elseif bag.ScrollingFrame:FindFirstChild(item.Name) then --if item is already in the inventory scrolling frame then...
				bag.ScrollingFrame:FindFirstChild(item.Name).Visible = true --make it's slot visible, which was already done above, so this line seems redundant???

                --connect hover events
				bag.ScrollingFrame:FindFirstChild(item.Name).MouseEnter:Connect(function()
					module.HoverFrameChange(true, bag.ScrollingFrame:FindFirstChild(item.Name))
				end)

				bag.ScrollingFrame:FindFirstChild(item.Name).MouseLeave:Connect(function()
					if isDraggingItem == false then
						module.HoverFrameChange(false)
					end
				end)
                --

			end
		end
	end
end

--[[
    Loops through each unequipped tool (any tool in the player's backpack) that has a slotIn value that's not zero (meaning it belongs in
    the hotbar) and sets that slot's item image to the tool's image
]]
function module.HotbarLoad(hotbar, backpack)
	for _, item in pairs(backpack:GetChildren()) do
		if item:IsA("Tool") and item.slotIn.Value ~= 0 then
			hotbar:FindFirstChild("SLOT"..tostring(item.slotIn.Value)).itemImage.Image = item.TextureId
		end
	end
end

function module.MouseDown(currentMousePos, slotDragger, backpack, bag, hotbar, itemTemplate)
	if isDraggingItem == false and currentFrameBeingHoveredOn then
		if currentFrameBeingHoveredOn:IsDescendantOf(bag) == true then
			isDraggingItem = true
			slotDragger.itemImage.Image = currentFrameBeingHoveredOn.itemImage.Image
			slotDragger.Visible = true
			currentFrameBeingHoveredOn.Visible = false

			for _, item in pairs(backpack:GetChildren()) do
				if item:IsA("Tool") then
					if item.Name == currentFrameBeingHoveredOn.Name then
						currentItemSelected = item
					end
				end
			end

			print(currentFrameBeingHoveredOn.Name)

			while isDraggingItem == true do
				currentMousePos = UIS:GetMouseLocation()
				slotDragger.Position = UDim2.fromOffset(currentMousePos.X, currentMousePos.Y)
				task.wait()
			end
			module.BagLoad(bag, backpack, itemTemplate)
		elseif currentFrameBeingHoveredOn:IsDescendantOf(hotbar) == true then
			for _, item in pairs(backpack:GetChildren()) do
				if item:IsA("Tool") then
					if item.slotIn.Value == slotsToNums[currentFrameBeingHoveredOn.Name] then
						currentItemSelected = item
						break
					else
						currentItemSelected = nil
					end
				end
			end

			if currentItemSelected then
				isDraggingItem = true
				slotDragger.itemImage.Image = currentFrameBeingHoveredOn.itemImage.Image
				slotDragger.Visible = true
				currentFrameBeingHoveredOn.itemImage.Image = ""

				while isDraggingItem == true do
					currentMousePos = UIS:GetMouseLocation()
					slotDragger.Position = UDim2.fromOffset(currentMousePos.X, currentMousePos.Y)
					task.wait()
				end
			end
		end
	end
end

function module.MouseUp(slotDragger, hotbar, bag, backpack, itemTemplate)
	isDraggingItem = false

	if currentItemSelected and currentFrameBeingHoveredOn then
		if currentFrameBeingHoveredOn:IsDescendantOf(hotbar) == true then
			for _, otherItem in pairs(backpack:GetChildren()) do
				if otherItem:IsA("Tool") and otherItem ~= currentItemSelected and otherItem.slotIn.Value == slotsToNums[currentFrameBeingHoveredOn.Name] then
					if currentItemSelected.slotIn.Value == 0 and otherItem.slotIn.Value ~= 0 then
						hotbar:FindFirstChild("SLOT"..tostring(otherItem.slotIn.Value)).itemImage.Image = ""
					end
					otherItem.slotIn.Value = currentItemSelected.slotIn.Value
				end
			end
			currentItemSelected.slotIn.Value = slotsToNums[currentFrameBeingHoveredOn.Name]
		elseif currentFrameBeingHoveredOn == bag then
			currentItemSelected.slotIn.Value = 0
		end
	end

	module.BagLoad(bag, backpack, itemTemplate)
	module.HotbarLoad(hotbar, backpack)

	slotDragger.Visible = false
	currentItemSelected = nil
end

function module.ItemEquip(item, hum, hotbar)
	hum:EquipTool(item)
	hotbar:FindFirstChild("SLOT"..tostring(item.slotIn.Value)).UIStroke.Color = Color3.fromRGB(255, 255, 255)
end

function module.ItemUnequip(hum, hotbar)
	hum:UnequipTools()

	for _, slot in pairs(hotbar:GetChildren()) do
		if slot:IsA("Frame") then
			slot.UIStroke.Color = Color3.fromRGB(20, 20, 20)
		end
	end
end

return module