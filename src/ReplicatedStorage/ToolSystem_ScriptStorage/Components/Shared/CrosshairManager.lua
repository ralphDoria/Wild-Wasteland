local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

export type CrosshairObject = {
    hitmarker : CanvasGroup,
    hitmarkerScaleTween : Tween,
    hitmarkerTransparencyTween : Tween,
    enabled : boolean,
    connections : {RBXScriptConnection}
}

local crosshairGui = PlayerGui:WaitForChild("CrosshairGui") :: ScreenGui

local CrosshairManager = {}

function CrosshairManager.new()

	crosshairGui.Enabled = false

	local scaleTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local transparencyTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local hitmarker = crosshairGui:FindFirstChild("Hitmarker")
	local hitmarkerScaleTween = TweenService:Create(hitmarker.UIScale, scaleTweenInfo, { Scale = 1 })
	local hitmarkerTransparencyTween =
		TweenService:Create(hitmarker, transparencyTweenInfo, { GroupTransparency = 1 })

    local self = {
        hitmarker = hitmarker,
		hitmarkerScaleTween = hitmarkerScaleTween,
		hitmarkerTransparencyTween = hitmarkerTransparencyTween,
		enabled = false,
		connections = {}
	}

    CrosshairManager.initialize(self)

    return self
end

function CrosshairManager.initialize(self : CrosshairObject)
    
end

function CrosshairManager.toggleCrosshairLines(self : CrosshairObject, toggle : boolean)
    for _, v in crosshairGui.Reticle:GetChildren() do
        if v.Name == "Frame" then
            v.Visible = toggle
        end
    end
end

function CrosshairManager.showHitmarker(self : CrosshairObject, playHitmarkerSound : () -> ())
	-- Slightly delay the hitmarker sound so it doesn't overlap the shooting sound
	task.delay(0.1, function()
        playHitmarkerSound()
	end)

	if self.hitmarkerScaleTween.PlaybackState == Enum.PlaybackState.Playing then
		self.hitmarkerScaleTween:Cancel()
	end
	if self.hitmarkerTransparencyTween.PlaybackState == Enum.PlaybackState.Playing then
		self.hitmarkerTransparencyTween:Cancel()
	end

	self.hitmarker.GroupTransparency = 0
    local UIScale = self.hitmarker:FindFirstChildOfClass("UIScale") :: UIScale
	UIScale.Scale = 2

	self.hitmarkerScaleTween:Play()
	self.hitmarkerTransparencyTween:Play()
end

local function enable()
    if crosshairGui.Enabled then
		return
	end
    crosshairGui.Enabled = true
	UserInputService.MouseIconEnabled = false
end

local function disable()
    if not crosshairGui.Enabled then
		return
	end
	crosshairGui.Enabled = false
	UserInputService.MouseIconEnabled = true
end

local function toggleEnable()
    if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
        enable()
    else
        disable()
    end
end

function CrosshairManager.toggleEnable(self : CrosshairObject)
	toggleEnable()
    if #self.connections ~= 0 then
        for _, v in self.connections do
            v:Disconnect()
            v = nil
        end
    end
    table.insert(
        self.connections,
        UserInputService:GetPropertyChangedSignal("MouseBehavior"):Connect(function(...: any)
            toggleEnable()
        end)
    )
end

function CrosshairManager.ForceDisable(self : CrosshairObject)
	disable()
    for _, v in self.connections do
        v:Disconnect()
        v = nil
    end
end

return CrosshairManager