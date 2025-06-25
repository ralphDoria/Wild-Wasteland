local References_Inventory_Client = {}

-- General Player References
References_Inventory_Client.player = game:GetService("Players").LocalPlayer
References_Inventory_Client.PlayerGui = References_Inventory_Client.player.PlayerGui
References_Inventory_Client.ReplicatedStorage = game:GetService("ReplicatedStorage")
References_Inventory_Client.StarterGui = game:GetService("StarterGui")
References_Inventory_Client.ContextActionService = game:getService("ContextActionService")
References_Inventory_Client.UserInputService = game:GetService("UserInputService")
References_Inventory_Client.RunService = game:GetService("RunService")
References_Inventory_Client.TweenService = game:GetService("TweenService")
References_Inventory_Client.GuiService = game:GetService("GuiService")

-- Utility
References_Inventory_Client.PlaySound = require(References_Inventory_Client.ReplicatedStorage.RojoManaged_RS.Utility.PlaySoundUtil)

-- Top Level Inventory Refernces
References_Inventory_Client.Storage = References_Inventory_Client.ReplicatedStorage.InventorySystem_Storage
References_Inventory_Client.InventoryScreenGui = References_Inventory_Client.PlayerGui:WaitForChild("Inventory"):: ScreenGui
References_Inventory_Client.MainInventory = References_Inventory_Client.InventoryScreenGui:WaitForChild("MainInventory"):: Frame
References_Inventory_Client.DropArea = References_Inventory_Client.InventoryScreenGui:FindFirstChild("DropArea", true):: Frame

-- Hotbar
References_Inventory_Client.Hotbar = References_Inventory_Client.InventoryScreenGui:WaitForChild("Hotbar"):: CanvasGroup
References_Inventory_Client.TouchBackpackSlot = References_Inventory_Client.Hotbar:WaitForChild("TouchBackpackSlot"):: Frame

-- Character Section
References_Inventory_Client.CharacterSection = References_Inventory_Client.MainInventory:WaitForChild("CharacterSection"):: Frame
References_Inventory_Client.Vitals = References_Inventory_Client.CharacterSection:WaitForChild("Vitals"):: Frame
References_Inventory_Client.Viewport = References_Inventory_Client.CharacterSection:WaitForChild("ViewportFrame"):: ViewportFrame
References_Inventory_Client.CharacterEquipmentSlots = References_Inventory_Client.CharacterSection:WaitForChild("CharacterEquipmentSlots"):: Frame
    -- Vitals
    References_Inventory_Client.Vitals = References_Inventory_Client.CharacterSection:WaitForChild("Vitals"):: Frame
    References_Inventory_Client.TemplateVital = References_Inventory_Client.Vitals:WaitForChild("TemplateVital"):: Frame


-- Inventory Section
References_Inventory_Client.InventorySection = References_Inventory_Client.MainInventory:WaitForChild("InventorySection")
References_Inventory_Client.SearchTools = References_Inventory_Client.InventorySection:WaitForChild("SearchTools")
References_Inventory_Client.InventoryScrollingFrame = References_Inventory_Client.InventorySection:WaitForChild("InventoryScrollingFrame"):: ScrollingFrame

-- Looting Section
References_Inventory_Client.LootingSection = References_Inventory_Client.MainInventory:WaitForChild("LootingSection"):: Frame
References_Inventory_Client._frame = References_Inventory_Client.LootingSection:WaitForChild("Frame"):: Frame
References_Inventory_Client.LootingSectionTitle = References_Inventory_Client.LootingSection:WaitForChild("SectionTitle"):: TextLabel
References_Inventory_Client.LootingScrollingFrame = References_Inventory_Client._frame:WaitForChild("LootingScrollingFrame"):: ScrollingFrame
References_Inventory_Client.LootingEquipmentSlots = References_Inventory_Client._frame:WaitForChild("LootingEquipmentSlots"):: Frame

-- Templates
References_Inventory_Client.Templates = References_Inventory_Client.InventoryScreenGui:WaitForChild("Templates")
References_Inventory_Client.TemplateSlotGroup = References_Inventory_Client.Templates:WaitForChild("SlotGroupTemplate")
References_Inventory_Client.TemplateSlot = References_Inventory_Client.Templates:WaitForChild("SlotTemplate")
References_Inventory_Client.TemplateItemInfoDisplay = References_Inventory_Client.Templates:WaitForChild("ItemInfoDisplayTemplate")

return References_Inventory_Client