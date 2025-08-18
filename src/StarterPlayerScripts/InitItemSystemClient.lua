local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolSystem_ScriptStorage = ReplicatedStorage.RojoManaged_RS.ToolSystem_ScriptStorage

local ClientReceivers = require(ToolSystem_ScriptStorage.PlayerScripts.ClientReceivers)

ClientReceivers()