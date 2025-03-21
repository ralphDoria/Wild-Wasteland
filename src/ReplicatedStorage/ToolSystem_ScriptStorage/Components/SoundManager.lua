export type SoundManager = {
    playSound : (networkSide : "Client" | "Server", sound : Sound, soundParent : any, delayCorrection : number) -> (),
    storeSounds : (toolName : string, soundObjects : {[string] : Sound | {[string] : Sound}}) -> (),
    Sounds : {[string] : {[string] : Sound | {[string] : Sound}}}
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaySoundUtil = require("../../Utility/PlaySoundUtil")
local remotes: {[string] : RemoteEvent} = {
    PlaySound = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true).Shared.Remotes.PlaySound
}
local SoundManager = {}

SoundManager.Sounds = {}

function SoundManager.storeSounds(toolName : string, soundObjects : {[string] : Sound | {[string] : Sound}})
    if SoundManager.Sounds[toolName] == nil then
        SoundManager.Sounds[toolName] = {}
        for key, v in soundObjects do
            SoundManager.Sounds[toolName][key] = v
        end
    end
end

function SoundManager.playSound(networkSide : "Client" | "Server", sound : Sound, soundParent : any, delayCorrection : number)
    if networkSide == "Client" then
        PlaySoundUtil(sound, soundParent, delayCorrection)
    elseif networkSide == "Server" then
        remotes.PlaySound:FireServer(sound, soundParent, delayCorrection)
    end
end


return SoundManager :: SoundManager