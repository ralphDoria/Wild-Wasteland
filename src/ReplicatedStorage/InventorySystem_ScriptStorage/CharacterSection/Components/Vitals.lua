local References_CharacterSection = require("./../Components/References_CharacterSection")
local VitalsGui = References_CharacterSection.Vitals
local Template = VitalsGui.VitalTemplate:: Frame
Template.Visible = false

local VitalsData = {
    Health = {
        ImageId = "http://www.roblox.com/asset/?id=6410367133",
        LayoutOrder = 1
    },
    Hunger = {
        ImageId = "rbxassetid://138629315774962",
        LayoutOrder = 2
    },
    Stamina = {
        ImageId = "rbxassetid://108702203360050",
        LayoutOrder = 3
    },
    Thirst = {
        ImageId = "http://www.roblox.com/asset/?id=13492318033",
        LayoutOrder = 4
    }
}

local currentVitalGuis: {Frame} = {}

local Vitals = {}

Vitals.initialized = false

function Vitals.init()
    for vitalName, v in VitalsData do
        local vital = Template:Clone()
        vital.TextDisplay.Text = vitalName
        vital.Visible = true
        local Icon = vital:FindFirstChild("Icon", true):: ImageLabel
        Icon.Image = v.ImageId
        vital.Parent = VitalsGui
        currentVitalGuis[vitalName] = vital
    end
    Vitals.initialized = true
    Vitals.ResizeGui()
end


function Vitals.ResizeGui()
    assert(Vitals.initialized, "Vitals needs to be initialized first before calling this function.")
    for key, v in currentVitalGuis do
        local viewportWidth = References_CharacterSection.Viewport.AbsoluteSize.X
        local equipmentSlotsWidth = References_CharacterSection.EquipmentSlots.AbsoluteSize.X
        local width = viewportWidth - equipmentSlotsWidth

        local viewportHeight = References_CharacterSection.Viewport.AbsoluteSize.Y
        local height = viewportHeight * 1/3

        VitalsGui.Size = UDim2.fromOffset(width, height)
        local individualVitalSize: UDim2 = UDim2.fromOffset(width/2, height/2 - 5)

        --apply new size
        v.Size = individualVitalSize

        --resize and reposition TextDisplay
        local ProgressBarAndIcon = v.ProgressBarAndIcon
        v.TextDisplay.Position = 
            UDim2.fromOffset(ProgressBarAndIcon.AbsoluteSize.X, 0)
        v.TextDisplay.Size = 
            UDim2.new(0, VitalsGui.AbsoluteSize.X - ProgressBarAndIcon.AbsoluteSize.X, 1, 0)


        --apply new position
        local layoutOrder = VitalsData[key].LayoutOrder
        if layoutOrder == 1 then
            v.Position = UDim2.fromScale(0, 0)
        elseif layoutOrder == 2 then
            v.Position = UDim2.fromScale(0.5, 0)
        elseif layoutOrder == 3 then
            v.Position = UDim2.fromScale(0, 0.5) + UDim2.fromOffset(0, 5)
        elseif layoutOrder== 4 then
            v.Position = UDim2.fromScale(0.5, 0.5) + UDim2.fromOffset(0, 5)
        end
    end
end

return Vitals