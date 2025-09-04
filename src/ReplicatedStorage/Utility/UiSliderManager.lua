local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)

local playSound = require(ReplicatedStorage:FindFirstChild("PlaySoundUtil", true))
local SliderSounds = game:GetService("SoundService").SoundStorage.Interface.Slider
local sounds = {
    sliderMoved = SliderSounds.Click,
    invalid = SliderSounds.Error
}


--[[replaces any numbers in the textbox with an empty string]]
local function stripNonNumbers(textBox : TextBox)
	textBox.Text = textBox.Text:gsub("%D","")
end

export type UiSliderObject = {
    minQuantity: number,
    maxQuantity: number,
    _internalValue: number,
    _internalProportion: number,
    _internalValueChangedBindable: BindableEvent,
    internalValueChanged: RBXScriptSignal,

    textBox: TextBox,
    bar: TextButton,
    fill: Frame,
    slidingConnection: RBXScriptConnection?,
    trove: any
}

local UiSliderManager = {}

function UiSliderManager.new(textBox: TextBox, bar: TextButton, fill: Frame)
    local _internalValueChangedBindable = Instance.new("BindableEvent")
    local internalValueChanged = _internalValueChangedBindable.Event
    
    local initialMaxValue = 2
    local initialProportion = 0.5

    local self: UiSliderObject = {
        minQuantity = 0,
        maxQuantity = initialMaxValue,
        _internalProportion = initialProportion,
        _internalValue = initialMaxValue * initialProportion,
        _internalValueChangedBindable = _internalValueChangedBindable,
        internalValueChanged = internalValueChanged,

        textBox = textBox,
        bar = bar,
        fill = fill,
        slidingConnection = nil,
        trove = Trove.new(),
    }

    UiSliderManager._initialize(self)
    return self
end

function UiSliderManager._initialize(self: UiSliderObject)
    local pitch = sounds.sliderMoved:FindFirstChildOfClass("PitchShiftSoundEffect")

    -- TEXT BOX FUNCTIONALITY
        -- strips non numbers when changing textBox text
    self.trove:Connect(self.textBox:GetPropertyChangedSignal("Text"), function()
        stripNonNumbers(self.textBox)
    end)

        -- updates internal value when text box focus lost
    self.trove:Connect(self.textBox.FocusLost, function()
        local textBoxValue = self.textBox.Text
        if string.len(textBoxValue) ~= 0 then
            --valid input
            if tonumber(textBoxValue) == self._internalValue then return end

            UiSliderManager.setValue(self, tonumber(textBoxValue):: number)
            self._internalValueChangedBindable:Fire(self._internalValue)
        else
            --invalid input
            playSound(sounds.invalid, nil)
            UiSliderManager._pulseTextRed(self)
            self.textBox.Text = tostring(self._internalValue)
        end
    end)

    -- SLIDER FUNCTIONALITY
    self.trove:Connect(self.bar.MouseButton1Down, function()
        if self.slidingConnection then
            self.slidingConnection:Disconnect()
        end

        local oldProportion = self._internalProportion

        self.slidingConnection = RunService.RenderStepped:Connect(function()  
            -- find out how to make this shit noncontiunous
            -- aka a snap to tick
            -- TODO
            local rawProportion = (UserInputService:GetMouseLocation().X - self.bar.AbsolutePosition.X) / self.bar.AbsoluteSize.X
            local processedProportion = UiSliderManager._roundAndClampProportionToHundrethsPlace(self, rawProportion) -- process to see if it's the same as the cached _internalPropotion
            local isNewAmountWithinFrame: boolean = processedProportion ~= self._internalProportion
            if isNewAmountWithinFrame then
                UiSliderManager.setProportion(self, processedProportion) -- keep in mind that this sets the _internalProportion
                if pitch ~= nil then
                    pitch.Octave = 0.5 + (2-0.5) * self._internalProportion 
                end
                playSound(sounds.sliderMoved, nil)
            end

            if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                if self.slidingConnection then
                    self.slidingConnection:Disconnect()

                    local isNewAmountWithinSliderInteraction = oldProportion ~= processedProportion
                    if isNewAmountWithinSliderInteraction then 
                        self._internalValueChangedBindable:Fire(self._internalValue)
                    end
                end
            end
        end)
    end)
end

function UiSliderManager.setProportion(self: UiSliderObject, proportion: number)
    proportion = UiSliderManager._roundAndClampProportionToHundrethsPlace(self, proportion)
    self._internalProportion = math.clamp(proportion, 0, 1)
    self._internalValue = math.clamp(math.round(self._internalProportion *self.maxQuantity), self.minQuantity, self.maxQuantity)

    self.textBox.Text = tostring(self._internalValue)
    self.fill.Size = UDim2.fromScale(self._internalProportion, 1)
end

function UiSliderManager.forceToZero(self: UiSliderObject)
    self._internalValue = 0
    self._internalProportion = 0

    self.textBox.Text = tostring(self._internalValue)
    self.fill.Size = UDim2.fromScale(self._internalProportion, 1)
end

function UiSliderManager.setValue(self: UiSliderObject, value: number)
    self._internalValue = math.clamp(math.round(value), self.minQuantity, self.maxQuantity)
    self._internalProportion = UiSliderManager._roundAndClampProportionToHundrethsPlace(self, value/self.maxQuantity)

    self.textBox.Text = tostring(self._internalValue)
    self.fill.Size = UDim2.fromScale(self._internalProportion, 1)
end

function UiSliderManager.setSliderRange(self: UiSliderObject, minQuantity: number, maxQuantity: number)
    self.minQuantity = minQuantity
    self.maxQuantity = maxQuantity
end

function UiSliderManager._roundAndClampProportionToHundrethsPlace(self: UiSliderObject, rawProportion: number)
    local processedProportion = math.round(
        math.clamp(
            rawProportion,
            0,
            1
        ) 
        * self.maxQuantity -- converts proportion into percentage toround
    ) / self.maxQuantity -- converts percentage back into proportion

    processedProportion = if processedProportion == 0 then 1/self.maxQuantity else processedProportion

    return processedProportion
end

local ti = TweenInfo.new(0.3)
function UiSliderManager._pulseTextRed(self: UiSliderObject)
    self.textBox.TextColor3 = Color3.new(1, 0, 0)
    TweenService:Create(self.textBox, ti, {TextColor3 = Color3.new(1, 1, 1)}):Play()
end

function UiSliderManager.Destroy(self: UiSliderObject)
    if self.trove then
        self.trove:Destroy()
    end
    if self.slidingConnection then
        self.slidingConnection:Disconnect()
    end
    table.clear(self)
end

return UiSliderManager