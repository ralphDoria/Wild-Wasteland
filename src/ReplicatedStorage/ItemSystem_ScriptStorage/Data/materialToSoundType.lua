local EnumSoundTypes = {
    Hard = "Hard",
    Soft = "Soft",
}

local materialToSoundType = {
	-- Hard Materials (metallic, stone-like, rigid surfaces)
	[Enum.Material.Brick] = EnumSoundTypes.Hard,
	[Enum.Material.Cobblestone] = EnumSoundTypes.Hard,
	[Enum.Material.Concrete] = EnumSoundTypes.Hard,
	[Enum.Material.CorrodedMetal] = EnumSoundTypes.Hard,
	[Enum.Material.DiamondPlate] = EnumSoundTypes.Hard,
	[Enum.Material.Foil] = EnumSoundTypes.Hard,
	[Enum.Material.Glass] = EnumSoundTypes.Hard,
	[Enum.Material.Granite] = EnumSoundTypes.Hard,
	[Enum.Material.Ice] = EnumSoundTypes.Hard,
	[Enum.Material.Marble] = EnumSoundTypes.Hard,
	[Enum.Material.Metal] = EnumSoundTypes.Hard,
	[Enum.Material.Neon] = EnumSoundTypes.Hard,
	[Enum.Material.Plastic] = EnumSoundTypes.Hard,
	[Enum.Material.Rock] = EnumSoundTypes.Hard,
	[Enum.Material.Slate] = EnumSoundTypes.Hard,
	[Enum.Material.SmoothPlastic] = EnumSoundTypes.Hard,

	-- Soft Materials (organic, flexible, or dampening surfaces)
	[Enum.Material.Fabric] = EnumSoundTypes.Soft,
	[Enum.Material.Grass] = EnumSoundTypes.Soft,
	[Enum.Material.Ground] = EnumSoundTypes.Soft,
	[Enum.Material.LeafyGrass] = EnumSoundTypes.Soft,
	[Enum.Material.Mud] = EnumSoundTypes.Soft,
	[Enum.Material.Pebble] = EnumSoundTypes.Soft,
	[Enum.Material.Sand] = EnumSoundTypes.Soft,
	[Enum.Material.Snow] = EnumSoundTypes.Soft,
	[Enum.Material.Wood] = EnumSoundTypes.Soft,
	[Enum.Material.WoodPlanks] = EnumSoundTypes.Soft,
}

return materialToSoundType