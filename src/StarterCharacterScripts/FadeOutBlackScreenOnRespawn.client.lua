local TransitionBlackScreenManager = require(game:GetService("ReplicatedStorage").RojoManaged_RS.Utility.UI.TransitionBlackScreenManager)

if TransitionBlackScreenManager.getTransparency() == 0 then
    TransitionBlackScreenManager.fadeOut(5)
end