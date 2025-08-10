local TweenService = game:GetService("TweenService")
local Promise = require(game:GetService("ReplicatedStorage").Packages.Promise)
local RunService = game:GetService("RunService")
local player = game:GetService("Players").LocalPlayer

local CameraCutsceneManager = {}

function CameraCutsceneManager.CreateCutsceneCameraPositions(modelOfCameraPlaceholders: Model): {CFrame}
    local cameraPositions = {}
    for _, v in modelOfCameraPlaceholders:GetChildren() do
        print(v)
        if v:IsA("BasePart") then
            local nameToNumber = tonumber(v.Name)
            assert(nameToNumber, `{v.Name} is not a valid number and cannot be converted to an index in cameraPositions array.`)
            cameraPositions[nameToNumber] = v.CFrame
            v.Transparency = 1
            local surfaceGui = v:FindFirstChildOfClass("ScreenGui")
            if surfaceGui then
                -- surfaceGui:Destroy()
            end
        end
    end
    warn(cameraPositions)
    return cameraPositions
end

local function playTweenAndCancelIfTweenCancels(tween: Tween, onCancel)
    tween:Play()
    local RenderStepBindName = "MainMenuCutScene"
    RunService:BindToRenderStep(RenderStepBindName, 200, function(delta: number)  
        if tween.PlaybackState == Enum.PlaybackState.Cancelled then
            onCancel()
        elseif tween.PlaybackState == Enum.PlaybackState.Completed then
            RunService:UnbindFromRenderStep(RenderStepBindName)
        end
    end)
end

local studsPerSecond = 16
function CameraCutsceneManager.PlayCutscene(camera: Camera, cameraPositions: {CFrame})
    return Promise.new(function(resolve, reject, onCancel)
        local tweens: {Tween} = {}
        for i = 1, #cameraPositions - 1, 1 do
            local distanceToNextPoint = math.abs((cameraPositions[i + 1].Position - cameraPositions[i].Position).Magnitude)
            local time = (1/studsPerSecond)*distanceToNextPoint
            table.insert(tweens, TweenService:Create(camera, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = cameraPositions[i + 1]}))

            player:RequestStreamAroundAsync(cameraPositions[i].Position)
        end
        for i = 1, #tweens - 1, 1 do
            tweens[i].Completed:Once(function()
               playTweenAndCancelIfTweenCancels(tweens[i + 1], onCancel)
            end)
        end
        
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = cameraPositions[1]
        playTweenAndCancelIfTweenCancels(tweens[1], onCancel)
    end)
end

return CameraCutsceneManager