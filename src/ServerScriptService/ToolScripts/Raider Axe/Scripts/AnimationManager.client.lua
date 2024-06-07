local tool = script.Parent.Parent
local player = nil
local character = nil
local swingDebounce = false

--bindable events
local Events = tool:WaitForChild("Events")
local BindableEvents = Events:WaitForChild("BindableEvents")
local bev_ForwardSwing = BindableEvents:WaitForChild("ForwardSwing")
local bev_UpdateCurrentCharacter = BindableEvents:WaitForChild("UpdateCurrentCharacter")

local animObjects = {
	idle = tool:WaitForChild("Anims"):WaitForChild("idle"),
	swing = tool:WaitForChild("Anims"):WaitForChild("swing")
}

local soundObjects = {
	equip = tool:WaitForChild("SFX_part"):WaitForChild("Shing Ringy 2 (SFX)"),
	swing = tool:WaitForChild("SFX_part"):WaitForChild("Sword Swing Metal Heavy")
}

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

local function onActivated()
	if swingDebounce == false then
		swingDebounce = true
		local swingAnimTrack : AnimationTrack = doAnimation(animObjects.swing, true)
		swingAnimTrack:GetMarkerReachedSignal("ForwardSwing"):Connect(function()
			print("firing forward swing")
			bev_ForwardSwing:Fire(true)
			soundObjects.swing:Play()
		end)
		swingAnimTrack:GetMarkerReachedSignal("EndSwing"):Connect(function()
			bev_ForwardSwing:Fire(false)
		end)
		swingAnimTrack.Stopped:Wait()
		swingDebounce = false
	end
	
end

local function onEquipped()
	player = game:GetService("Players").LocalPlayer
	character = player.Character or player.CharacterAdded:Wait()
	bev_UpdateCurrentCharacter:Fire(character)
	soundObjects.equip:Play()
	doAnimation(animObjects.idle, true)
end

local function onUnequipped()
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

tool.Equipped:Connect(onEquipped)
tool.Unequipped:Connect(onUnequipped)

tool.Activated:Connect(onActivated)