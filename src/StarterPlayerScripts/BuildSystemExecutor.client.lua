--[[
	One-time init for the client build mode (temporary TempBuildButton entry; the future
	dedicated build item will drive BuildModeManager the same way a tool drives its binds).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.RojoManaged_RS.BuildSystem_ScriptStorage.BuildModeManager).init()
