local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Constants = require(script.Parent.Parent.Constants)
local lerp = math.lerp

local camera = Workspace.CurrentCamera

local recoil = Vector2.new()
local zoom = 0

local function onRenderStepped(deltaTime: number)
	camera.CFrame *= CFrame.Angles(recoil.Y * deltaTime, recoil.X * deltaTime, 0)
	camera.FieldOfView = Constants.RECOIL_DEFAULT_FOV + zoom
	recoil = recoil:Lerp(Vector2.zero, math.min(deltaTime * Constants.RECOIL_STOP_SPEED, 1))
	zoom = lerp(zoom, 0, math.min(deltaTime * Constants.RECOIL_ZOOM_RETURN_SPEED, 1))
end

local CameraRecoiler = {}

function CameraRecoiler.recoil(recoilAmount: Vector2)
	zoom = 1
	recoil += recoilAmount
end

RunService:BindToRenderStep(Constants.RECOIL_BIND_NAME, Enum.RenderPriority.Camera.Value + 1, onRenderStepped)

return CameraRecoiler
