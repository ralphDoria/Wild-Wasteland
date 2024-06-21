------------------------------------------------------------------------<<<PLAYER SPECIFICS>>>
local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

------------------------------------------------------------------------<<<LOCAL VARIABLES>>>
local M6Ds = {
    waist : Motor6D
    rightHip : Motor6D
    leftHip : Motor6D
    rightShoulder : Motor6D
    leftShoulder : Motor6D
    neck : Motor6D
}

--mapping function for 
--|
--|
--|
--V

local c0Origin = {} --this is so we know the default positions for each Motor6D

------------------------------------------------------------------------<<<ROBLOX LIBRARIES>>>
local RunService = game:GetService("RunService")
