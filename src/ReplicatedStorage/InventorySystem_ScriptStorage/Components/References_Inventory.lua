local References_Inventory = {}

-- General Player References
References_Inventory.player = game:GetService("Players").LocalPlayer
References_Inventory.PlayerGui = References_Inventory.player.PlayerGui
References_Inventory.ReplicatedStorage = game:GetService("ReplicatedStorage")
References_Inventory.StarterGui = game:GetService("StarterGui")
References_Inventory.ContextActionService = game:getService("ContextActionService")
References_Inventory.UserInputService = game:GetService("UserInputService")
References_Inventory.RunService = game:GetService("RunService")
References_Inventory.TweenService = game:GetService("TweenService")
References_Inventory.GuiService = game:GetService("GuiService")

-- Utility
References_Inventory.PlaySound = require(References_Inventory.ReplicatedStorage.RojoManaged_RS.Utility.PlaySoundUtil)

-- Top Level Inventory Refernces
References_Inventory.Storage = References_Inventory.ReplicatedStorage.InventorySystem_Storage
References_Inventory.InventoryScreenGui = References_Inventory.PlayerGui:WaitForChild("Inventory"):: ScreenGui
References_Inventory.MainInventory = References_Inventory.InventoryScreenGui:WaitForChild("MainInventory"):: Frame
References_Inventory.DropArea = References_Inventory.InventoryScreenGui:FindFirstChild("DropArea", true):: Frame

-- Hotbar
References_Inventory.Hotbar = References_Inventory.InventoryScreenGui:WaitForChild("Hotbar"):: CanvasGroup
References_Inventory.TouchBackpackSlot = References_Inventory.Hotbar:WaitForChild("TouchBackpackSlot"):: Frame

-- Character Section
References_Inventory.CharacterSection = References_Inventory.MainInventory:WaitForChild("CharacterSection"):: Frame
References_Inventory.Vitals = References_Inventory.CharacterSection:WaitForChild("Vitals"):: Frame
References_Inventory.Viewport = References_Inventory.CharacterSection:WaitForChild("ViewportFrame"):: ViewportFrame
References_Inventory.CharacterEquipmentSlots = References_Inventory.CharacterSection:WaitForChild("EquipmentSlots"):: Frame
    -- Vitals
    References_Inventory.Vitals = References_Inventory.CharacterSection:WaitForChild("Vitals"):: Frame
    References_Inventory.TemplateVital = References_Inventory.Vitals:WaitForChild("TemplateVital"):: Frame


-- Inventory Section
References_Inventory.InventorySection = References_Inventory.MainInventory:WaitForChild("InventorySection")
References_Inventory.SearchTools = References_Inventory.InventorySection:WaitForChild("SearchTools")
References_Inventory.InventoryScrollingFrame = References_Inventory.InventorySection:WaitForChild("ScrollingFrame"):: ScrollingFrame

-- Looting Section
References_Inventory.LootingSection = References_Inventory.MainInventory:WaitForChild("LootingSection"):: Frame
References_Inventory._frame = References_Inventory.LootingSection:WaitForChild("Frame"):: Frame
References_Inventory.LootingScrollingFrame = References_Inventory._frame:WaitForChild("ScrollingFrame"):: ScrollingFrame
References_Inventory.LootingEquipmentSlots = References_Inventory._frame:WaitForChild("EquipmentSlots"):: Frame

-- Templates
References_Inventory.Templates = References_Inventory.InventoryScreenGui:WaitForChild("Templates")
References_Inventory.TemplateSlotGroup = References_Inventory.Templates:WaitForChild("SlotGroupTemplate")
References_Inventory.TemplateSlot = References_Inventory.Templates:WaitForChild("SlotTemplate")
References_Inventory.TemplateItemInfoDisplay = References_Inventory.Templates:WaitForChild("ItemInfoDisplayTemplate")

return References_Inventory