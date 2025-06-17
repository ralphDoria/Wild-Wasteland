local References_Inventory = {}

References_Inventory.player = game:GetService("Players").LocalPlayer
References_Inventory.PlayerGui = References_Inventory.player.PlayerGui
References_Inventory.ReplicatedStorage = game:GetService("ReplicatedStorage")
References_Inventory.InventoryScreenGui = References_Inventory.PlayerGui:WaitForChild("Inventory"):: ScreenGui
References_Inventory.CharacterSection = References_Inventory.InventoryScreenGui.MainInventory:WaitForChild("CharacterSection")

return References_Inventory