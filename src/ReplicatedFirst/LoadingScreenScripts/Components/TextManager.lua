local TextManager = {initialized = false}

local Percentage: TextLabel
local Timer: TextLabel
local Message: TextLabel

function TextManager.init(_Percentage: TextLabel, _Timer: TextLabel, _Message: Message)
    Percentage = _Percentage
    Timer = _Timer
    Message = _Message

    TextManager.initialized = true
end

function TextManager.setDisplayMessage(msg: string)
    assert(TextManager.initialized, "TextManager not initialized!")
    Message.Text = msg
end

function TextManager.setDisplayPercentage(percentage)
    assert(TextManager.initialized, "TextManager not initialized!")
    Percentage.Text = `{percentage}%`
end

function TextManager.setDisplayTime(timeInSeconds: number)
    assert(TextManager.initialized, "TextManager not initialized!")
    local minutes = math.floor(timeInSeconds/60)
    local seconds = math.floor(timeInSeconds%60) 
    Timer.Text = `{string.format("%02d:%02d", minutes, seconds)}`
end

return TextManager