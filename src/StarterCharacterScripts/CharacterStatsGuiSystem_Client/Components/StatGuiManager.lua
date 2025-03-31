local CircularProgressBarManager = require(game:GetService("ReplicatedStorage").RojoManaged_RS.Utility.CircularProgressBarManager)
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

export type StatGui = {
    statName: string,
    statGui: CanvasGroup,
    progressBar: Frame,
    progress: NumberValue,
    textLabel: TextLabel,
    color: Color3,
    percentageChangeEffect: thread?
}

local connections: {RBXScriptConnection} = {}

local StatGuiManager = {}

function StatGuiManager.new(StatGui, statName: string, color: Color3)
    local progressBar = StatGui.ProgressBar
    local progress: NumberValue = progressBar.Progress
    local textLabel: TextLabel = StatGui.TextLabel
    table.insert(
        connections,
        CircularProgressBarManager.InitializeProgressBar(progressBar)
    )

    local self: StatGui = {
        statName = statName,
        statGui = StatGui,
        progressBar = progressBar,
        progress = progress,
        textLabel = textLabel,
        color = color,
        percentageChangeEffect = nil
    }

    return self
end

function StatGuiManager.SetStatValue(self: StatGui, proportion: number)
    local currentProportion: number = self.progress.Value
    if currentProportion == proportion then
        warn("Doing nothing: currentProportion == proportion")
        return
    end
    local valueTween = TweenService:Create(self.progress, TweenInfo.new(0.2), {Value = proportion})
    local colorTween = TweenService:Create(
        self.statGui, 
        TweenInfo.new(0.1, Enum.EasingStyle.Circular, Enum.EasingDirection.Out, 0, true), 
        {GroupColor3 = self.color})
    colorTween:Play()
    valueTween:Play()

    if self.percentageChangeEffect then
        task.cancel(self.percentageChangeEffect)
        self.percentageChangeEffect = nil
    end
    local currentPercent: number = math.round(currentProportion * 100)
    local targetPercent: number = math.round(proportion * 100)
    self.percentageChangeEffect = task.spawn(function()
        local gap = targetPercent - currentPercent
        local increment = gap/math.abs(gap)
        for currentPercent = currentPercent, targetPercent, increment do
            task.wait()
            -- self.textLabel.Text = "Health<br/>100%"
            self.textLabel.Text = self.statName .. "<br/>" .. tostring(currentPercent) .. "%"
        end
        self.percentageChangeEffect = nil
    end)
end

return StatGuiManager