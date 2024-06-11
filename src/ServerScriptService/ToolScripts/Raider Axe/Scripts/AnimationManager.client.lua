local tool = script.Parent.Parent
local player = nil
local character = nil
local canSwing = false

--bindable events
local Events = tool:WaitForChild("Events")
local BindableEvents = Events:WaitForChild("BindableEvents")
local RemoteEvents = Events:WaitForChild("RemoteEvents")
local bev_ForwardSwing = BindableEvents:WaitForChild("ForwardSwing")
local bev_UpdateCurrentCharacter = BindableEvents:WaitForChild("UpdateCurrentCharacter")
local rev_dropped : RemoteEvent = RemoteEvents:WaitForChild("Dropped")

local animObjects = {
	equip = tool:WaitForChild("Anims"):WaitForChild("equip"),
	idle = tool:WaitForChild("Anims"):WaitForChild("idle"),
	swing = tool:WaitForChild("Anims"):WaitForChild("swing")
}

local soundObjects = {
	equip = tool:WaitForChild("SFX_part"):WaitForChild("Shing Ringy 2 (SFX)"),
	swing = tool:WaitForChild("SFX_part"):WaitForChild("Sword Swing Metal Heavy")
}

--[[
	If an animator is found,  each animation object in the animObjects dictionary will be loaded onto the animator. This fixed the glitch of
	the equip to idle animation not blending because after the equip animation track had completed, the idle animation track hadn't loaded yet,
	so there would be an unsmooth transition due to the equip animation track visibly ending
]]
local function loadAllAnimationsOntoAnimator()
	local animator = character:FindFirstChild("Animator", true)
	if animator == nil then
		warn("Animator not found, cannot load animations")
	else
		for _, anim in animObjects do
			animator:LoadAnimation(anim)
		end
	end
end

--[[
	
]]
local function doAnimation(anim : Animation, shouldPlay : boolean)
	local humanoid = character:WaitForChild("Humanoid")
	local animator : Animator = humanoid:WaitForChild("Animator")
	
	if shouldPlay then
		local animTrackFound = false
		for _, animTrack : AnimationTrack in animator:GetPlayingAnimationTracks() do
			if animTrack.Animation == anim then
				animTrackFound = true
				animTrack:Play()
				return animTrack
			end
			--if the specified animation hasn't already been loaded, then this function will create one
			local newAnimTrack : AnimationTrack = animator:LoadAnimation(anim)
			newAnimTrack:Play()
			return newAnimTrack
		end
	else
		for _, animTrack : AnimationTrack in animator:GetPlayingAnimationTracks() do
			if animTrack.Animation == anim then
				animTrack:Stop()
				return animTrack
			end
		end
	end
end

local function isEquipped()
	if tool.Parent:FindFirstChild("Humanoid") then
		return true 
	else
		return false
	end
end

local function onEquipped()
	player = game:GetService("Players").LocalPlayer
	character = player.Character or player.CharacterAdded:Wait()
	if character:GetAttribute(string.gsub(tool.Name, " ", "") .. "AnimsLoaded") == nil then
		character:SetAttribute(string.gsub(tool.Name, " ", "") .. "AnimsLoaded", true)
		loadAllAnimationsOntoAnimator()
	end
	local mouse = player:GetMouse()
	mouse.Icon = script.Parent.Parent:WaitForChild("Cursor").Texture
	bev_UpdateCurrentCharacter:Fire(character)
	soundObjects.equip:Play()
	local equipAnimTrack = doAnimation(animObjects.equip, true)
	equipAnimTrack.Stopped:Wait()
	if isEquipped() then --checking this because during the equip animation, players can unequip the tool, causing a bug
		doAnimation(animObjects.idle, true)
		canSwing = true
	end
end

local function onActivated()
	if canSwing then
		canSwing = false
		local swingAnimTrack : AnimationTrack = doAnimation(animObjects.swing, true)
		swingAnimTrack:GetMarkerReachedSignal("ForwardSwing"):Connect(function()
			bev_ForwardSwing:Fire(true)
			soundObjects.swing:Play()
		end)
		swingAnimTrack:GetMarkerReachedSignal("EndSwing"):Connect(function()
			bev_ForwardSwing:Fire(false)
		end)
		swingAnimTrack.Stopped:Wait()
		if isEquipped() then
			canSwing = true
		end
	end
	
end

local function onUnequipped()
	local mouse = player:GetMouse()
	mouse.Icon = ""
	canSwing = false
	doAnimation(animObjects.idle, false)
	bev_ForwardSwing:Fire(false) --this turns off the raycast -- I know the event name is a bit misleading
	for _, animTrack : AnimationTrack in character:WaitForChild("Humanoid"):WaitForChild("Animator"):GetPlayingAnimationTracks() do
		for _, anim : Animation in animObjects do
			if animTrack.Animation == anim then
				animTrack:Stop()
			end
		end
	end
	bev_UpdateCurrentCharacter:Fire(nil)
end

rev_dropped.OnClientEvent:Connect(function(player)
	onUnequipped()
end)

tool.Equipped:Connect(onEquipped)
tool.Activated:Connect(onActivated)
tool.Unequipped:Connect(onUnequipped)