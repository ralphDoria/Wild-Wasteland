local player = game:GetService("Players").LocalPlayer
local playerGui : PlayerGui = player:FindFirstChild("PlayerGui") :: PlayerGui
local gui : ScreenGui = playerGui:WaitForChild("RevampingInventory") :: ScreenGui
local MainInventory : Frame = gui:FindFirstChild("MainInventory") :: Frame
local WearableSection : Frame = MainInventory:FindFirstChild("WearableSection") :: Frame
local ViewportCharacter = require("./ViewportCharacter")
local ViewportFrame = WearableSection:FindFirstChildWhichIsA("ViewportFrame", true)

local icons = {
    Torso = "http://www.roblox.com/asset/?id=18371557232",
    Legs = "http://www.roblox.com/asset/?id=18371557232",
    Head = "http://www.roblox.com/asset/?id=18371557232",
    Feet = "http://www.roblox.com/asset/?id=18371557232",
    Backpack = "rbxassetid://18384549702",
}

local WearableInterface = {}

function WearableInterface.initialize(character: Model)
    -- make sure character is in viewport frame first
    task.wait(0.5)
    ViewportCharacter.handleCharacter(ViewportFrame, character)

    --based off character's torso CFrame and offsets from that, 
end

return WearableInterface