local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemSystem_ScriptStorage = ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage

local ClientReceivers = require(ItemSystem_ScriptStorage.PlayerScripts.ClientReceivers)

ClientReceivers()