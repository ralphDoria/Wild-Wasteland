------------------------------------------------------------------------<<<ROBLOX LIBRARIES>>>
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------<<<LOCAL VARIABLES>>>
local tool = script.Parent.Parent
local player = nil
local character = nil
local canSwing = false
local ACTION_DROP_TOOL = "Dropped"

------------------------------------------------------------------------<<<REMOTE & BINDABLE EVENTS>>>
local Events = tool:WaitForChild("Events")
local BindableEvents = Events:WaitForChild("BindableEvents")
local RemoteEvents = Events:WaitForChild("RemoteEvents")
local bev_ForwardSwing = BindableEvents:WaitForChild("ForwardSwing")
local bev_UpdateCurrentCharacter = BindableEvents:WaitForChild("UpdateCurrentCharacter")
local rev_dropped : RemoteEvent = RemoteEvents:WaitForChild("Dropped")
local rev_playSound = RemoteEvents:WaitForChild("PlaySound")

------------------------------------------------------------------------<<<Modules (Classes, Data Package, Utility, Functional)>>>
local AnimationManagerClass = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Classes"):WaitForChild("AnimationManagerClass"))

------------------------------------------------------------------------<<<STUFF FOR ANIMATIONS>>>
local animObjects = {
	equip = tool:WaitForChild("Anims"):WaitForChild("equip"),
	idle = tool:WaitForChild("Anims"):WaitForChild("idle"),
	swing = tool:WaitForChild("Anims"):WaitForChild("swing")
}

local currentAnimationManager = nil

------------------------------------------------------------------------<<<SFX>>>
--********maybe make a SoundsManager?
local SFX_part = tool:WaitForChild("SFX_part")
local soundObjects = {
	equip = SFX_part:WaitForChild("Shing Ringy 2 (SFX)"),
	swing = SFX_part:WaitForChild("Sword Swing Metal Heavy")
}

local function isEquipped()
	if tool.Parent:FindFirstChild("Humanoid") then
		return true 
	else
		return false
	end
end

local function onUnequipped()
	ContextActionService:UnbindAction(ACTION_DROP_TOOL)
	local mouse = player:GetMouse()
	mouse.Icon = ""
	canSwing = false
	bev_ForwardSwing:Fire(false) --this turns off the raycast just in case the player unequips mid swing -- I know the event name is a bit misleading
	for _, animTrack : AnimationTrack in pairs(currentAnimationManager.animationTracks) do
		if animTrack.isPlaying then
			animTrack:Stop()
		end
	end
	currentAnimationManager:destroy()
	character:SetAttribute(string.gsub(tool.Name, " ", "") .. "AnimsLoaded", nil)
	bev_UpdateCurrentCharacter:Fire(nil)
end

local function dropped()
	onUnequipped()
	rev_dropped:FireServer()
end

local function handleAction(actionName, inputState, _inputObject)
	if actionName == ACTION_DROP_TOOL and inputState == Enum.UserInputState.Begin then
		dropped()
	end
end

rev_dropped.OnClientEvent:Connect(function(player)
	onUnequipped()
end)

local function onEquipped()
	player = game:GetService("Players").LocalPlayer
	character = player.Character or player.CharacterAdded:Wait()
	if character:GetAttribute(string.gsub(tool.Name, " ", "") .. "AnimsLoaded") == nil then
		character:SetAttribute(string.gsub(tool.Name, " ", "") .. "AnimsLoaded", true)
		currentAnimationManager = AnimationManagerClass.new(character:FindFirstChild("Animator", true), animObjects)
	end
	local mouse = player:GetMouse()
	mouse.Icon = script.Parent.Parent:WaitForChild("Cursor").Texture
	bev_UpdateCurrentCharacter:Fire(character)
	rev_playSound:FireServer(soundObjects.equip, 0, SFX_part)
	currentAnimationManager.animationTracks.equip:Play()
	currentAnimationManager.animationTracks.equip.Stopped:Wait()
	if isEquipped() then --checking this because during the equip animation, players can unequip the tool, causing a bug
		currentAnimationManager.animationTracks.idle:Play()
		ContextActionService:BindAction(ACTION_DROP_TOOL, handleAction, true, Enum.KeyCode.X)
		canSwing = true
	end
end

local function onActivated()
	if canSwing then
		canSwing = false
		currentAnimationManager.animationTracks.swing:Play()
		currentAnimationManager.animationTracks.swing:GetMarkerReachedSignal("ForwardSwing"):Once(function()
			bev_ForwardSwing:Fire(true)
			rev_playSound:FireServer(soundObjects.swing, 0, SFX_part)
		end)
		currentAnimationManager.animationTracks.swing:GetMarkerReachedSignal("EndSwing"):Once(function()
			bev_ForwardSwing:Fire(false)
		end)
		currentAnimationManager.animationTracks.swing.Stopped:Wait()
		if isEquipped() then
			canSwing = true
		end
	end
end

tool.Equipped:Connect(onEquipped)
tool.Activated:Connect(onActivated)
tool.Unequipped:Connect(onUnequipped)