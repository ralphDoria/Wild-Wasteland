local module = {}

local value = 5

local valueChangedEvent: BindableEvent = Instance.new("BindableEvent")
module.valueChanged = valueChangedEvent.Event :: RBXScriptSignal

function module.incrementValue()
    value += 1
    valueChangedEvent:Fire()
end

function module.getValue(): number
    return value
end


return module