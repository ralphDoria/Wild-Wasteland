local SoundService = game:GetService("SoundService")
local masterSG : SoundGroup = SoundService:WaitForChild("0 - Master")
local musicSG : SoundGroup = masterSG:WaitForChild("Music"):: SoundGroup
local gameSG : SoundGroup = masterSG:WaitForChild("Game"):: SoundGroup
local ambienceSG : SoundGroup = gameSG:WaitForChild("Ambience"):: SoundGroup
local interfaceSG : SoundGroup = masterSG:WaitForChild("Interface"):: SoundGroup
local menuSG : SoundGroup = masterSG:WaitForChild("Menu"):: SoundGroup
local SoundGroupManager = {}

SoundGroupManager.soundGroups = {
	master = masterSG,
	music = musicSG,
	ambience = ambienceSG,
	game = gameSG,
	interface = interfaceSG,
	menu = menuSG
}

function SoundGroupManager.muteAllExcept(exemptedSoundGroup: SoundGroup)
	for _, v in SoundGroupManager.soundGroups do
		if v ~= exemptedSoundGroup and v ~= masterSG then
			v.Volume = 0
		end
	end
end

return SoundGroupManager