local player = game:GetService("Players").LocalPlayer
local playerGui = player.PlayerGui
--[[
The purpose of this function is to get the values of the hardware insets, which modern mobile devices often have.
]]
local function getHardwareSafeAreaInsets(): (number, number) -- in the order of {leftInset, rightInset} 
    -- Fullscreen covers the entire screen (ignoring safe areas)
    local fullscreenGui = playerGui:FindFirstChild("_FullscreenTestGui"):: ScreenGui?
    if not fullscreenGui then
        fullscreenGui = Instance.new("ScreenGui")
        fullscreenGui.Name = "_FullscreenTestGui"
        fullscreenGui.Parent = playerGui
        fullscreenGui.ScreenInsets = Enum.ScreenInsets.None

        local leftTestFrame = Instance.new("Frame")
        leftTestFrame.Name = "leftTestFrame"
        local rightTestFrame = Instance.new("Frame")
        rightTestFrame.Name = "rightTestFrame"
        rightTestFrame.AnchorPoint = Vector2.new(1, 0)
        rightTestFrame.Position = UDim2.fromOffset(1, 0)
        leftTestFrame.Parent = fullscreenGui
        rightTestFrame.Parent = fullscreenGui
    end

    -- DeviceInset GUI respects the device's safe area
    local deviceGui = playerGui:FindFirstChild("_DeviceTestGui"):: ScreenGui?
    if not deviceGui then
        deviceGui = Instance.new("ScreenGui")
        deviceGui.Name = "_DeviceTestGui"
        deviceGui.Parent = playerGui
        deviceGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets

        local leftTestFrame = Instance.new("Frame")
        leftTestFrame.Name = "leftTestFrame"
        local rightTestFrame = Instance.new("Frame")
        rightTestFrame.Name = "rightTestFrame"
        rightTestFrame.Position = UDim2.fromOffset(1, 0)
        rightTestFrame.AnchorPoint = Vector2.new(1, 0)
        leftTestFrame.Parent = deviceGui
        rightTestFrame.Parent = deviceGui
    end

    local leftInset = math.abs(fullscreenGui.leftTestFrame.AbsolutePosition.X - deviceGui.leftTestFrame.AbsolutePosition.X)
    local rightInset = math.abs(fullscreenGui.rightTestFrame.AbsolutePosition.X - deviceGui.rightTestFrame.AbsolutePosition.X)

    return leftInset, rightInset
end

return getHardwareSafeAreaInsets