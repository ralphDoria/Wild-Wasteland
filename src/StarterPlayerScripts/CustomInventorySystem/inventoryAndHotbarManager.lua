local KEY_BIND_INVENTORY = Enum.KeyCode.Tab

----[[ SERVICES ]]----
local Players = game:GetService("Players") 
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

----[[ STANDARD PLAYER SPECIFIC VARIABLES ]]----
local player = Players.LocalPlayer 
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character.Humanoid
local backpack = player.Backpack -- the player's backpack (used to store all tools by default)

----[[ GUI VARIABLES ]]----
local gui : ScreenGui = player.PlayerGui:WaitForChild("InventoryAndHotbar")
local forModal : Textbutton = gui:FindFirstChild("ForModal")
local inventory : ScrollingFrame = gui:FindFirstChild("Inventory", true) -- the bag/inventory frame
local main : Frame = inventory.Parent
local wearables : Frame = gui:FindFirstChild("Wearables", true)
local hotbar : CanvasGroup = gui:FindFirstChild("hotbar", true) -- the hotbar frame
local slotTemplate : CanvasGroup = gui:FindFirstChild("slotTemplate", true)

local slotToKeybind = {
	[1] = Enum.KeyCode.One,
	[2] = Enum.KeyCode.Two,
	[3] = Enum.KeyCode.Three,
	[4] = Enum.KeyCode.Four,
	[5] = Enum.KeyCode.Five,
	[6] = Enum.KeyCode.Six,
    [7] = Enum.KeyCode.Seven,
    [8] = Enum.KeyCode.Seven,
    [9] = Enum.KeyCode.Seven,
    [10] = Enum.KeyCode.Zero --there is no tenth number key on most keyboards, so the tenth slot is usually binded to 0
}

local inventoryAndHotbarManager = {}

function inventoryAndHotbarManager.toggleInventory(toggle : boolean)
    forModal.Modal = toggle
    main.Visible = toggle
end

--[[
    Has slot use TextButton or ImageButton based on whether the tool has a TextureId property that isn't nil.
]]
local function initializeSlotIcon(tool : Tool, slot)
    slot.Visible = true
    local imageButton : ImageButton = slot:FindFirstChildWhichIsA("ImageButton", true)
    local textButton : TextButton = slot:FindFirstChildWhichIsA("TextButton", true)
    if tool.TextureId or tool == nil then
        imageButton.Image = if tool == nil then nil else tool.TextureId
        imageButton.Visible = true
        textButton.Visible = false
    else
        textButton.Text = tool.Name
        textButton.Visible = true
        imageButton.Visible = false
    end

    return slot
end

local function getNumberOfHotbarSlots()
    local count = 0
    for _, v in pairs(hotbar:GetChildren()) do
        if v:IsA(typeof(slotTemplate)) then
            count += 1
        end
    end
    return count
end

local function getNumberOfInventorySlots()
    local count = 0
    for _, v in pairs(inventory:GetChildren()) do
        if v:IsA(typeof(slotTemplate)) then
            count += 1
        end
    end
    return count
end

local function findMinimumEmptyHotbarSlotNumber()
    if getNumberOfHotbarSlots() == 0 then
        return 1
    end
    local emptySlots = table.clone(slotToKeybind)
    for _, v in pairs(hotbar:GetChildren()) do
        if v:IsA(typeof(slotTemplate)) then
            if emptySlots[tonumber(v.Name)] then
                table.remove(emptySlots, tonumber(v.Name)) --remember that removing an index
            end
        end
    end
    
    return if emptySlots[1] then table.find(slotToKeybind, emptySlots[1]) else nil
end

function inventoryAndHotbarManager.createSlot(hotbarOrInventory : string, tool : Tool)
    assert(hotbarOrInventory == "Hotbar" or hotbarOrInventory == "Inventory", hotbarOrInventory .. " is an invalid argument for this function")
    
    local slot : CanvasGroup = initializeSlotIcon(tool, slotTemplate:Clone())
    local slotNumber : TextLabel = slot:FindFirstChild("Number", true)
    if hotbarOrInventory == "Hotbar" then
        local hotbarSlotNumber = findMinimumEmptyHotbarSlotNumber()
        slot.LayoutOrder = hotbarSlotNumber
        slotNumber.Text = hotbarSlotNumber
        slotNumber.Visible = true
        slot.Name = tostring(hotbarSlotNumber)
        slot.Parent = hotbar
    elseif hotbarOrInventory == "Inventory" then
        local inventorySlotNumber = getNumberOfInventorySlots() + 1
        slot.LayoutOrder = inventorySlotNumber
        slotNumber.Visible = false
        slot.Name = tool.Name
        slot.Parent = inventory
    end

end

function inventoryAndHotbarManager.intitializeHotbar()
    for i = 1, 10, 1 do
        inventoryAndHotbarManager.createSlot("Hotbar", nil)
    end
end

return inventoryAndHotbarManager