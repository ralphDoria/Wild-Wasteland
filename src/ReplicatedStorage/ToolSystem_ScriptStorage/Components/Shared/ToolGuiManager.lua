local UserInputService = game:GetService("UserInputService")
local player = game:GetService("Players").LocalPlayer
local playerGui = player.PlayerGui

local ToolGui = playerGui:WaitForChild("ToolGui")
local Controls : Frame = ToolGui.Frame.Controls
local Storage : Folder = Controls:FindFirstChild("Storage") :: Folder
local toolLabel : TextLabel = ToolGui.Frame.ToolName

local InputGui = require("./InputGui")

export type ToolGuiManager = {
    gui : ScreenGui,
    inputDevice : "KeyboardAndMouse" | "Mobile" | "Gamepad",
    InputGuis : {[string] : {[string] : InputGui.InputGuiObject}},
    connections : {RBXScriptConnection}
    --Probably should create gui instances first in Roblox Studio before trying to code in their functionality.
}

local ToolGuiManager = {}

function ToolGuiManager.new() : ToolGuiManager
    local self : ToolGuiManager = {
        gui = ToolGui,
        inputDevice = InputGui.getDevice(),
        InputGuis = {},
        connections = {}
    }

    self.gui.Enabled = false

    ToolGuiManager.initialize(self)
    return self
end

function ToolGuiManager.initialize(self: ToolGuiManager)
    table.insert(
        self.connections,
        UserInputService.LastInputTypeChanged:Connect(function(a0: Enum.UserInputType)  
            local currentInputDevice = InputGui.getDevice()
            if currentInputDevice ~= self.inputDevice then
                warn("Updating InputGui icons to match changed input device.")
                for _, v : {[string] : InputGui.InputGuiObject} in self.InputGuis do
                    for _, v2 : InputGui.InputGuiObject in v do
                        InputGui.setImage(v2)
                    end
                end
            end
        end)
    )
    table.insert(
        self.connections,
        Storage.ChildAdded:Connect(function(child: Instance)  
            if child:IsA("CanvasGroup") then
                child.GroupTransparency = 1
            end
        end)
    )
    table.insert(
        self.connections,
        Storage.ChildRemoved:Connect(function(child: Instance)  
            if child:IsA("CanvasGroup") then
                child.GroupTransparency = 0
            end
        end)
    )
end



function ToolGuiManager.CreateInputGui(self: ToolGuiManager, tool : Tool, actionName: string, keycodes: {Enum.UserInputType | Enum.KeyCode}, layoutOrder : number)
    if self.InputGuis[tool.Name] == nil then
        self.InputGuis[tool.Name] = {}
        self.InputGuis[tool.Name][actionName] = InputGui.new(actionName, keycodes)
        self.InputGuis[tool.Name][actionName].Instance.LayoutOrder = layoutOrder
    else
        if self.InputGuis[tool.Name][actionName] == nil then
            self.InputGuis[tool.Name][actionName] = InputGui.new(actionName, keycodes)
            self.InputGuis[tool.Name][actionName].Instance.LayoutOrder = layoutOrder
        end
    end
end

function ToolGuiManager.cooldown(self : ToolGuiManager, actionName : string, tool : Tool, cooldownTime : number)
    for _, v in self.InputGuis[tool.Name] do
        if v.ActionLabel.Text == actionName then
            InputGui.Cooldown(v, cooldownTime)
        end
    end
end

function ToolGuiManager.toggleControlsVisibility(self : ToolGuiManager, toggle : boolean)
    Controls.Visible = toggle
end

local flickerOn : thread
function ToolGuiManager.toggleToolGuiVisibility(self : ToolGuiManager, tool : Tool, toggle : boolean)
    if toggle then
        toolLabel.Text = tool.Name
        for _, v : {[string] : InputGui.InputGuiObject} in self.InputGuis do
            for _, v2 : InputGui.InputGuiObject in v do
                v2.Instance.Parent = Controls
            end
        end

        if flickerOn  then
            task.cancel(flickerOn)
        end
        flickerOn = task.spawn(function()
            for i = 1, 10, 1 do
                --task.wait(math.clamp(math.random(), 0, 0.5))
                if i%2 == 0 then
                    ToolGui.Enabled = true
                else
                    ToolGui.Enabled = false
                end
                task.wait(math.random(5, 10)/100)
            end
        end)
    else
        if flickerOn  then
            task.cancel(flickerOn)
        end
        ToolGui.Enabled = toggle
        for _, v : {[string] : InputGui.InputGuiObject} in self.InputGuis do
            for _, v2 : InputGui.InputGuiObject in v do
                InputGui.resetCooldown(v2)
                v2.Instance.Parent = Storage
            end
        end
    end
end

return ToolGuiManager