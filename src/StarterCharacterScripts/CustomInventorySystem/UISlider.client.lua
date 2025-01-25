local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local tag = "UISlider"
local barIncrements : number = 100

print(math.round(5.8))
print(math.round(55.0000001))

local function truncator(chance: number): string
end

local function handleTaggedInstance(taggedInstance)
    local bar : TextButton = taggedInstance:FindFirstChild("Bar")
    local fill : Frame = bar:FindFirstChild("Fill")
    local valueBox : TextBox = taggedInstance:FindFirstChild("ValueBox")
    valueBox.Text = 100 --in practice, this will use the value of the item it is associated with

    local renderStepBindName = "sliderRenderStepBind"



    bar.MouseButton1Down:Connect(function()
        RunService:BindToRenderStep(renderStepBindName, 200, function()
            local proportion : number = 
            math.round(
                math.clamp(
                    (UserInputService:GetMouseLocation().X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
                    0,
                    1
                ) 
                * barIncrements
            ) / barIncrements
            valueBox.Text = proportion * 100
            fill.Size = UDim2.fromScale(proportion, 1)

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