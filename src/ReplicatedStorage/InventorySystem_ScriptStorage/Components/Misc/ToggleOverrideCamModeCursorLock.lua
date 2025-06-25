local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local isOverriding: boolean = false

return function(toggle: boolean)
  if isOverriding == toggle then return end

  isOverriding = toggle
  if toggle then
    RunService:BindToRenderStep("OverrideCameraModeCursorLock", 201, function()
      UIS.MouseBehavior = Enum.MouseBehavior.Default
    end)
  else
    RunService:UnbindFromRenderStep("OverrideCameraModeCursorLock")
  end
end
