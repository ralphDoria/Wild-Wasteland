local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local guiSystems = {
    --[[
    system1 = test1,
    system2 = test2
    ]]
}
for _, v in guiSystems do
    v.init()
end
--[[
--maybe use metamethod __newindex for when a respawnGui's index is replaced and it's init function has to be called again
]]

local function handleRespawnGuis(character)
    --[[
    guiSystem[system3] = blah:WaitForChild("test3")
    guiSystem[system3].init()
    ]]
end

local initialCharacter = player.Character --for if character loads in before player.CharacterAdded is connected
player.CharacterAdded:Connect(function(character)
    --for guis that are supposed to be controlled by scripts in StarterPlayerScripts
    handleRespawnGuis(character)
end)