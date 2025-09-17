local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Constants = require(script.Parent.Parent.Parent.Constants)
local ItemSystem_Storage = ReplicatedStorage.ItemSystem_Storage
local SharedImpactTemplates = ItemSystem_Storage.Shared.Instances.Weapons.ImpactTemplates
local impactTemplates = {
	Blood = SharedImpactTemplates.BloodImpact,
	Energy = SharedImpactTemplates.EnergyImpact,
	Smoke = SharedImpactTemplates.SmokeImpact,
	Sparks = SharedImpactTemplates.SparksImpact,
	BulletHole = ItemSystem_Storage.Gun.Instances.BulletHoleTemplate
}

local sparkMaterials = {Enum.Material.Metal, Enum.Material.CorrodedMetal, Enum.Material.Foil}

--[[
	TODO: TO BE IMPLEMENTED
]]
local function getImpactSound(tool: Tool, impactType)
	-- Use ToolInfo
end

local function createBulletHole(hitPosition: Vector3, normal: Vector3)
	local hole = impactTemplates.BulletHole:Clone()
	hole.Anchored = true
	hole.CFrame = CFrame.lookAlong(hitPosition, normal)
	hole.Parent = workspace
	Debris:AddItem(hole, 60)
end

local function impactEffect(position: Vector3, normal: Vector3, isCharacter: boolean, hitMaterial: Enum.Material, tool: Tool)
	local impact

	if isCharacter then
		impact = impactTemplates.Blood:Clone()
		impact.CFrame = CFrame.lookAlong(position, normal)
		impact.Parent = Workspace

	else
		if tool:HasTag("Gun") then
			if tool:GetAttribute(Constants.AMMO_TYPE_ATTRIBUTE) == "Energy Cores" then 
				impact = impactTemplates.Energy 
			elseif table.find(sparkMaterials, hitMaterial) then 
				impact = impactTemplates.Sparks:Clone()
			else
				impact = impactTemplates.Smoke:Clone()
			end
			impact.CFrame = CFrame.lookAlong(position, normal)
			impact.Parent = Workspace

			createBulletHole(position, normal)
		-- elseif tool:HasTag("Melee") then -- TODO
		-- 	createBulletHole(position, normal)
		end
	end

	task.spawn(function()
        task.wait(0.2)
		for _, v in impact:GetChildren() do
			if v:IsA("ParticleEmitter") then
				v.Enabled = false
			end
		end
        --wait for the particles to fade out with Debris
        Debris:AddItem(impact, 1)
    end)
end

return impactEffect