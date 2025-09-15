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
    local reticle = crosshairGui:WaitForChild("Reticle")

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

    CrosshairManager._initialize(self)

    return self
end

function CrosshairManager._initialize(self : CrosshairObject)
    table.insert(
        self.connections,
        UserInputService:GetPropertyChangedSignal("MouseBehavior"):Connect(function(...: any)
            CrosshairManager.toggleEnabled(UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter)
        end)
    )
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

function CrosshairManager.toggleEnabled(toggle: boolean)
    if toggle then
        enable()
    else
        disable()
    end
end

function CrosshairManager.toggleReticle(toggle: boolean)
    reticle.Visible = toggle
end

function CrosshairManager.destroy(self: CrosshairObject)
    if #self.connections ~= 0 then
        for _, v in self.connections do
            v:Disconnect()
            v = nil
        end
    end
end

return CrosshairManager