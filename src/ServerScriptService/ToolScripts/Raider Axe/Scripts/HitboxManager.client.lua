-- << Initial Setup >> 
local tool = script.Parent.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RaycastHitBox = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("RaycastHitboxV4"))
local trail : Trail = tool:WaitForChild("Hitbox"):WaitForChild("Trail")
local currentCharacter : Model = nil

--constructing a new hitbox
local newHitBox = RaycastHitBox.new(tool:WaitForChild("Hitbox"))

--bindable/remote events
local Events = tool:WaitForChild("Events")
local BindableEvents = Events:WaitForChild("BindableEvents")
local RemoteEvents = Events:WaitForChild("RemoteEvents")
local bev_ForwardSwing = BindableEvents:WaitForChild("ForwardSwing")
local bev_UpdateCurrentCharacter = BindableEvents:WaitForChild("UpdateCurrentCharacter")
local rev_Hit = RemoteEvents:WaitForChild("Hit")

--event listeners
newHitBox.OnHit:Connect(function(hit, humanoid, raycastResult : RaycastResult)
	if humanoid.Parent.Name ~= currentCharacter.Name then
		rev_Hit:FireServer(humanoid, CFrame.new(raycastResult.Position, raycastResult.Normal))
	end
end)

bev_ForwardSwing.Event:Connect(function(shouldStartHit : boolean)
	if shouldStartHit then
		newHitBox:HitStart()
		trail.Enabled = true
	else
		newHitBox:HitStop()
		trail.Enabled = false
	end

end)

bev_UpdateCurrentCharacter.Event:Connect(function(character)
	currentCharacter = character
end)