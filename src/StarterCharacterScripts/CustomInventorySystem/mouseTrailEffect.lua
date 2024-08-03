local RunService = game:GetService("RunService")
local gui = Instance.new("ScreenGui")
local player = game:GetService("Players").LocalPlayer
gui.Parent = player.PlayerGui

local mouse = player:GetMouse()

local mouseTrailIcon : Decal = game:GetService("ReplicatedStorage"):FindFirstChild("MouseTrailIcon", true)
local rate : number = 0.01
local cloneCount : number = 12
local lastUpdate : number = 0
local cursorClones : {[any] : any} = {}

local cursor = Instance.new("ImageLabel")
cursor.Parent = gui
cursor.Size = UDim2.fromOffset(20, 20)
cursor.Image = mouseTrailIcon.Texture
cursor.BorderSizePixel = 0

local mouseTrailEffect = {}

function mouseTrailEffect.toggleEnabled(toggle : boolean)
    if toggle then
        RunService:BindToRenderStep("MouseTrailEffect", 200, function(dt)
            local now = os.clock()
            local guiInset = if gui.IgnoreGuiInset then game:GetService("GuiService"):GetGuiInset() else Vector2.zero
            local mousePosition = UDim2.fromOffset(mouse.X + guiInset.X, mouse.Y + guiInset.Y)
            cursor.Position = mousePosition
        end)
    else
        RunService:UnbindFromRenderStep("MouseTrailEffect")
    end
end

return mouseTrailEffect