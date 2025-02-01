local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playSound = require(ReplicatedStorage:FindFirstChild("PlaySoundUtil", true))

local tag = "UISlider"
local barIncrements : number = nil

local function truncateToWholeNumber(value: number): string
    return value-value%1
end

--[[replaces any numbers in the textbox with an empty string]]
local function stripNonNumbers(textBox : TextBox)
	textBox.Text = textBox.Text:gsub("%D","")
end

local function handleTaggedInstance(taggedInstance)
    local bar : TextButton = taggedInstance:FindFirstChild("Bar")
    local fill : Frame = bar:FindFirstChild("Fill")
    local valueBox : TextBox = taggedInstance:FindFirstChild("ValueBox")
    local sliderChangeSFX : Sound = taggedInstance:FindFirstChildOfClass("Sound")
    local pitch : PitchShiftSoundEffect = sliderChangeSFX:FindFirstChildOfClass("PitchShiftSoundEffect")
    local renderStepBindName = "sliderRenderStepBind"

    local originalValue : number = 100 --in practice, this will use the value of the item it is associated with
    barIncrements = originalValue
    local proportion : number = 0
    local dropAmount : number = proportion*originalValue
    fill.Size = UDim2.fromScale(proportion, 1)
    valueBox.Text = dropAmount

    valueBox:GetPropertyChangedSignal("Text"):Connect(function()
        stripNonNumbers(valueBox)
    end)

    valueBox.FocusLost:Connect(function()
        if string.len(valueBox.Text) ~= 0 and tonumber(valueBox.Text) <= originalValue then
            --valid input
            dropAmount = valueBox.Text
            proportion = valueBox.Text / originalValue
            fill.Size = UDim2.fromScale(proportion, 1)
        else
            --invalid input
            valueBox.Text = dropAmount
        end
    end)

    bar.MouseButton1Down:Connect(function()
        RunService:BindToRenderStep(renderStepBindName, 200, function()
            proportion = 
                math.round(
                    math.clamp(
                        (UserInputService:GetMouseLocation().X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
                        0,
                        1
                    ) 
                    * barIncrements
                ) / barIncrements
            local newAmount = truncateToWholeNumber(proportion * originalValue)
            if newAmount ~= dropAmount then
                --only change these when the proportion changes
                dropAmount = newAmount
                valueBox.Text = dropAmount
                fill.Size = UDim2.fromScale(proportion, 1)
                if pitch ~= nil then
                    pitch.Octave = 0.5 + (2-0.5) * proportion 
                end
                playSound(sliderChangeSFX, sliderChangeSFX.Parent)
            end

            if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                RunService:UnbindFromRenderStep(renderStepBindName)
            end
        end)
    end)
end

----------------------------------------------------------------------------------------------------------------------------------------------

for _, taggedInstance in CollectionService:GetTagged(tag) do
    handleTaggedInstance(taggedInstance)
end

CollectionService:GetInstanceAddedSignal(tag):Connect(function(taggedInstance)
    handleTaggedInstance(taggedInstance)
end)