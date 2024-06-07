-- << Initial Setup >> 
local tool = script.Parent.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RaycastHitBox = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("RaycastHitboxV4"))
local currentCharacter : Model = nil

--config
local config = require(tool:WaitForChild("Scripts"):WaitForChild("config"))

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
newHitBox.OnHit:Connect(function(hit, humanoid)
	if humanoid.Parent.Name ~= currentCharacter.Name then
		rev_Hit:FireServer(humanoid, hit)
	end
end)

bev_ForwardSwing.Event:Connect(function(shouldStartHit : boolean)
	if shouldStartHit then
		newHitBox:HitStart()
	else
		newHitBox:HitStop()
	end

end)

bev_UpdateCurrentCharacter.Event:Connect(function(character)
	currentCharacter = character
end)