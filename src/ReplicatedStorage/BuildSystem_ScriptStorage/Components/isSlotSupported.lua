--!strict
--[[
	The "no floating structures" rule, shared by the client preview (red ghost) and the
	server authority (placement rejection): a slot is supported when the piece's box —
	expanded by groundContactMargin on every side — touches map geometry, terrain, or
	another placed structure.

	Characters do NOT count as support (otherwise jumping while placing creates floating
	pieces): anything inside a Model owning a Humanoid (players, NPCs, corpses) is
	filtered out of the contact set. The preview ghost is CanQuery = false, so spatial
	queries never see it, and the piece being placed doesn't exist yet — so a fresh
	placement can't support itself.

	Terrain is invisible to GetPartBoundsInBox, so it gets a separate voxel-occupancy
	probe over the box's AABB (water doesn't count as support).
]]

local Workspace = game:GetService("Workspace")

local BuildConfig = require(script.Parent.Parent.Data.BuildConfig)
local BuildMath = require(script.Parent.Parent.Sim.BuildMath)

local overlapParams = OverlapParams.new()
overlapParams.MaxParts = 32

local function isCharacterPart(part: BasePart): boolean
	local model = part:FindFirstAncestorOfClass("Model")
	return model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function touchesTerrain(cframe: CFrame, probeSize: Vector3): boolean
	local terrain = Workspace.Terrain
	-- AABB of the oriented probe box, expanded to the 4-stud voxel grid.
	local rotation = cframe.Rotation
	local half = probeSize / 2
	local reach = rotation.XVector:Abs() * half.X
		+ rotation.YVector:Abs() * half.Y
		+ rotation.ZVector:Abs() * half.Z
	local region = Region3.new(cframe.Position - reach, cframe.Position + reach):ExpandToGrid(4)
	local materials, occupancies = terrain:ReadVoxels(region, 4)
	local size = materials.Size
	for x = 1, size.X do
		for y = 1, size.Y do
			for z = 1, size.Z do
				local material = materials[x][y][z]
				if occupancies[x][y][z] > 0 and material ~= Enum.Material.Air and material ~= Enum.Material.Water then
					return true
				end
			end
		end
	end
	return false
end

local function isSlotSupported(slot: BuildMath.Slot): boolean
	local cframe = BuildMath.slotToCFrame(BuildConfig, slot)
	local probeSize = BuildMath.slotSize(BuildConfig, slot) + Vector3.one * (BuildConfig.groundContactMargin * 2)

	local parts = Workspace:GetPartBoundsInBox(cframe, probeSize, overlapParams)
	for _, part in parts do
		if not isCharacterPart(part) then
			return true
		end
	end
	return touchesTerrain(cframe, probeSize)
end

return isSlotSupported
