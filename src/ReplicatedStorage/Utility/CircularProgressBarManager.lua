local RunService = game:GetService("RunService")
local ProgressBarTemplate: Frame = game:GetService("ReplicatedStorage").ProgressBar
local connections: {[Frame]: RBXScriptConnection} = {}
local completedEvents: {[Frame]: BindableEvent} = {}

local CircularProgressBarManager = {}

function CircularProgressBarManager.CreateProgressBar(parent: Instance, color: Color3): RBXScriptConnection
    local progressBar = ProgressBarTemplate:Clone()
    completedEvents[progressBar] = Instance.new("BindableEvent")
    local progress: NumberValue = progressBar.Progress
    progressBar.Parent = parent
    local leftProgressBarImage: ImageLabel = progressBar.LeftGradient.ProgressBarImage
    local rightProgressBarImage: ImageLabel = progressBar.RightGradient.ProgressBarImage
    leftProgressBarImage.ImageColor3 = color
    rightProgressBarImage.ImageColor3 = color
    local leftGradient: UIGradient = leftProgressBarImage:FindFirstChildOfClass("UIGradient"):: UIGradient
    local rightGradient: UIGradient = rightProgressBarImage:FindFirstChildOfClass("UIGradient"):: UIGradient
    progressBar.Destroying:Connect(function()  
        if completedEvents[progressBar] then
            completedEvents[progressBar]:Destroy()
            completedEvents[progressBar] = nil
        end
    end)
    return progress.Changed:Connect(function(value)
        local angle = math.clamp(value * 360, 0, 360)
        leftGradient.Rotation = math.clamp(angle, 180, 360)
        rightGradient.Rotation = math.clamp(angle, 0, 180)
    end)
end

--[[
    This is a nearly identical function to CreateProgressBar, but the use case for this is when
    there is already a progress bar created.
]]
function CircularProgressBarManager.InitializeProgressBar(progressBar): RBXScriptConnection
    completedEvents[progressBar] = Instance.new("BindableEvent")
    local progress: NumberValue = progressBar.Progress
    local leftProgressBarImage: ImageLabel = progressBar.LeftGradient.ProgressBarImage
    local rightProgressBarImage: ImageLabel = progressBar.RightGradient.ProgressBarImage
    local leftGradient: UIGradient = leftProgressBarImage:FindFirstChildOfClass("UIGradient"):: UIGradient
    local rightGradient: UIGradient = rightProgressBarImage:FindFirstChildOfClass("UIGradient"):: UIGradient
    progressBar.Destroying:Connect(function()  
        if completedEvents[progressBar] then
            completedEvents[progressBar]:Destroy()
            completedEvents[progressBar] = nil
        end
    end)
    return progress.Changed:Connect(function(value)
        local angle = math.clamp(value * 360, 0, 360)
        leftGradient.Rotation = math.clamp(angle, 180, 360)
        rightGradient.Rotation = math.clamp(angle, 0, 180)
    end)
end

function CircularProgressBarManager.ResetProgressBar(progressBar: Frame)
    local progress: NumberValue = progressBar:FindFirstChild("Progress") :: NumberValue
    local connection: RBXScriptConnection? = connections[progressBar]
    if connection then
        connection:Disconnect()
        connection = nil
    end
    progress.Value = 0
end

function CircularProgressBarManager.PlayProgressBar(progressBar: Frame, direction: "Fill" | "Drain", time: number): RBXScriptSignal
    local completed: RBXScriptSignal = completedEvents[progressBar].Event
    local progress: NumberValue = progressBar:FindFirstChild("Progress") :: NumberValue
    CircularProgressBarManager.ResetProgressBar(progressBar)
    if direction == "Fill" then
        progress.Value = 0
        local timeAccumulated = 0
        connections[progressBar] = RunService.RenderStepped:Connect(function(dt: number)
            if time == timeAccumulated then
                --cooldown timer ended
                if connections[progressBar] then
                    connections[progressBar]:Disconnect() 
                    connections[progressBar] = nil
                end 
                progress.Value = 0
                completedEvents[progressBar]:Fire()
            end
            timeAccumulated = math.clamp(timeAccumulated + dt, 0, time)
            progress.Value = timeAccumulated/time
        end)
    elseif direction == "Drain" then
        progress.Value = 1
        local timeAccumulated = 0
        connections[progressBar] = RunService.RenderStepped:Connect(function(dt: number)
            if time == timeAccumulated then
                --cooldown timer ended
                if connections[progressBar] then
                   connections[progressBar]:Disconnect() 
                   connections[progressBar] = nil
                end 
                progress.Value = 0
                completedEvents[progressBar]:Fire()
            end
            timeAccumulated = math.clamp(timeAccumulated + dt, 0, time)
            progress.Value = 1 - (timeAccumulated/time)
        end)
    end
    return completed
end

return CircularProgressBarManager