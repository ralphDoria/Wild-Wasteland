local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local masterSG : SoundGroup = SoundService:WaitForChild("0 - Master")
local musicSG : SoundGroup = masterSG:WaitForChild("Music"):: SoundGroup
local gameSG : SoundGroup = masterSG:WaitForChild("Game"):: SoundGroup
local ambienceSG : SoundGroup = gameSG:WaitForChild("Ambience"):: SoundGroup
local interfaceSG : SoundGroup = masterSG:WaitForChild("Interface"):: SoundGroup
local menuSG : SoundGroup = masterSG:WaitForChild("Menu"):: SoundGroup
local SoundGroupManager = {}

type SoundGroups<T> = {
	master: T,
	music: T,
	ambience: T,
	game: T,
	interface: T,
	menu: T
}

SoundGroupManager.config = {
	master = {
		Volume = masterSG.Volume
	},	
	music = {
		Volume = musicSG.Volume
	},	
	ambience = {
		Volume = ambienceSG.Volume
	},	
	game = {
		Volume = gameSG.Volume
	},	
	interface = {
		Volume = interfaceSG.Volume
	},	
	menu = {
		Volume = menuSG.Volume
	},	
}:: SoundGroups<{Volume: number}>

SoundGroupManager.soundGroups = {
	master = masterSG,
	music = musicSG,
	ambience = ambienceSG,
	game = gameSG,
	interface = interfaceSG,
	menu = menuSG
}:: SoundGroups<SoundGroup>

function SoundGroupManager.volumeToDefault(tweenTime: number)
	for key, v in SoundGroupManager.soundGroups do
		if v == masterSG then continue end
		TweenService:Create(v:: SoundGroup, TweenInfo.new(tweenTime), {Volume = SoundGroupManager.config[key].Volume}):Play()
	end
end

function SoundGroupManager.muteAllExcept(exemptedSoundGroup: SoundGroup)
	for _, v in SoundGroupManager.soundGroups do
		if v == exemptedSoundGroup or v == masterSG then continue end
		v.Volume = 0
	end
end

return SoundGroupManager