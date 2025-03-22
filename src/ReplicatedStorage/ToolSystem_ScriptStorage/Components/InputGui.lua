export type InputGuiObject = {
    InputGui : Frame,
    ActionLabel : TextLabel
}

local InputGui = {}

function InputGui.new(inputGui : Frame, actionName: string, keycodes: {Enum.UserInputType | Enum.KeyCode})
    local self : InputGuiObject = {
        InputGui = inputGui,
        ActionLabel = inputGui:FindFirstChild("ActionName")
    }
    self.InputGui.Visible = true
    self.ActionLabel.Text = actionName



    return self
end

function InputGui.initialize()
    
end

function InputGui.Cooldown(self : InputGuiObject, cooldownTime : number)
    
end

return InputGui