--lil side quest for me

local GlitchEffect = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("GlitchEffect")
local sound : Sound = GlitchEffect:FindFirstChildOfClass("Sound")
local ImageLabel : ImageLabel = GlitchEffect.ImageLabel
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local GlitchFrameSequence : {string} = {
    "rbxassetid://87321087948285",
    "rbxassetid://88376528228965",
    "rbxassetid://128770845983214",
    "rbxassetid://118379612741936",
    "rbxassetid://73409526134008",
    "rbxassetid://132872080661385",
    "rbxassetid://122742915298171",
    "rbxassetid://98643900189107",
    "rbxassetid://71306385353704",
    "rbxassetid://75816938422999",
    "rbxassetid://126479547968159",
    "rbxassetid://100526990550070",
    "rbxassetid://87027795521140",
    "rbxassetid://127570536667563",
    "rbxassetid://98321158016048",
    "rbxassetid://133642324588810",
    "rbxassetid://99408353703292",
    "rbxassetid://118114262694756",
    "rbxassetid://135251604490633",
    "rbxassetid://76486069884964",
    "rbxassetid://99441606028651",
    "rbxassetid://137640193902737",
    "rbxassetid://107380780388493",
    "rbxassetid://139150493952808",
    "rbxassetid://88215014358928",
    "rbxassetid://112059187580807",
    "rbxassetid://105860418565594"
}

local delayBetweenFrames : number = 0.1
local ignoreDelay : boolean = false

ContextActionService:BindAction("GlitchEffect", function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject): Enum.ContextActionResult?  
    if inputState == Enum.UserInputState.Begin then
        local connection
    local timeAccumulated = 0
    sound:Play()
    local count = 1
    delayBetweenFrames = sound.TimeLength/#GlitchFrameSequence
    ignoreDelay = false
    connection = RunService.RenderStepped:Connect(function(dt: number)
        timeAccumulated = math.clamp(timeAccumulated + dt, 0, delayBetweenFrames)
        if count < 28 then
            if ignoreDelay or timeAccumulated == delayBetweenFrames then
                ImageLabel.Image = GlitchFrameSequence[count]
                count += 1
                timeAccumulated = 0
            end
        else
            connection:Disconnect()
            ImageLabel.Image = "ImageLabel.Image"
            count = 1
        end
    end)
    end
    return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.Q)