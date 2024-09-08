local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rev_singleSpawn = ReplicatedStorage:FindFirstChild("SingleSpawn", true)

local playSound = require(ReplicatedStorage:FindFirstChild("PlaySoundUtil", true))
local SoundService = game:GetService("SoundService")
local droppedAmmoBoxSound : Sound = SoundService:FindFirstChild("droppedAmmoBox", true)
local droppedCoinsSound : Sound = SoundService:FindFirstChild("droppedCoins", true)

local TAG_CURRENCY = "DroppedCurrency"
local TAG_AMMO = "DroppedAmmo"

local lootCatalog = {
    ammoCan = {
        model = ReplicatedStorage:FindFirstChild("ammoCan", true),
        tag = TAG_AMMO
    },
    bottleCapPile = {
        model = ReplicatedStorage:FindFirstChild("bottleCapPile", true),
        tag = TAG_CURRENCY
    }
}
local lootArray = {lootCatalog.ammoCan, lootCatalog.bottleCapPile}

--Add their tags after they get added to workspace

local spawnArea : BasePart = workspace:FindFirstChild("SpawnArea", true)
local origin : BasePart = spawnArea.Origin

local xAxis = {
    min = origin.Position.X,
    max = origin.Position.X + (spawnArea.Size.X - origin.Size.X)
}
local zAxis = {
    min = origin.Position.Z,
    max = origin.Position.Z + (spawnArea.Size.Z - origin.Size.Z)
}

--[[ local functions for debugging raycast
]]
local function visualizeRay(originPosition : Vector3, endPosition : Vector3)
    local distance = (endPosition - originPosition).Magnitude
    local p = Instance.new("Part")
    p.Anchored = true
    p.CanCollide = false
    p.Size = Vector3.new(0.5, 0.5, distance)
    p.Color = Color3.new(0, 1, 0)
    p.CFrame = CFrame.lookAt(originPosition, endPosition)*CFrame.new(0, 0, -distance/2)
    p.Parent = workspace
end

local function visualizePosition(position : Vector3)
    local y = Instance.new("Part")
    y.Size = Vector3.new(1, 1, 1)
    y.Anchored = true
    y.Color = Color3.new(1, 0, 0)
    y.Position = position
    y.Parent = workspace
end

local raycastParams = RaycastParams.new()
--[[
local blacklistedParts = {}
raycastParams.FilterDescendantsInstances = blacklistedParts
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true
]]

local function castRay()
    local randomHorizontalPosition : Vector3 = Vector3.new(math.random(xAxis.min, xAxis.max), spawnArea.Position.Y, math.random(zAxis.min, zAxis.max))

    local rayMaxDistance : number = 250
    local originPosition : Vector3 = randomHorizontalPosition
    local targetPosition : Vector3 = originPosition + Vector3.new(0, -rayMaxDistance, 0)
    local rayDirection : Vector3 = (targetPosition - originPosition).Unit * rayMaxDistance

    local raycastResult : RaycastResult = workspace:Raycast(originPosition, rayDirection, raycastParams)

    --[[
    visualizeRay(originPosition, raycastResult.Position)
    visualizePosition(raycastResult.Position)   
    ]]

    return raycastResult
end

for count = 0, 500, 1 do
    local raycastResult = castRay()
    local spawnLocation : CFrame
    if raycastResult then
        spawnLocation = CFrame.lookAlong(raycastResult.Position, raycastResult.Normal) * CFrame.Angles(math.rad(-   90), 0, 0)
    else
        print("Raycast didn't hit anything")
    end

    local randomLoot = lootArray[math.random(1, #lootArray)]
    local model : Model = randomLoot.model:Clone()
    CollectionService:AddTag(model, randomLoot.tag)
    model:PivotTo(spawnLocation + (spawnLocation.UpVector * (model.PrimaryPart.Size.Y/2)))
    model.Parent = spawnArea.Parent
end

local function visualizeCFrame(cframe : CFrame)
    local part = Instance.new("Part")
    part.Anchored = true
    part.Color = Color3.new(1, 0.231372, 0.231372)
    part.Size = Vector3.new(0.5, 0.5, 0.5)
    part.CFrame = cframe
    part.Parent = workspace
end

rev_singleSpawn.OnServerEvent:Connect(function(player, position : Vector3, normal : Vector3, tagName : string, amount : number)
    print("received request to spawn " .. amount .. " " .. tagName)
    player:SetAttribute(tagName, player:GetAttribute(tagName) - amount)
    local spawnLocation : CFrame = CFrame.lookAlong(position, normal) * CFrame.Angles(math.rad(-   90), 0, 0)
    --visualizeCFrame(spawnLocation)
    local model : Model = if tagName == "Caps" then lootCatalog.bottleCapPile.model:Clone() else lootCatalog.ammoCan.model:Clone()
    model:SetAttribute("Amount", amount)
    CollectionService:AddTag(model, tagName)
    model:PivotTo(spawnLocation + (spawnLocation.UpVector * (model.PrimaryPart.Size.Y/2)))
    model.Parent = workspace

    local partInModel = model:FindFirstChildWhichIsA("BasePart") or model:FindFirstChildOfClass("MeshPart")
    print(partInModel.Name)
    if tagName == "Caps" then
        playSound(droppedCoinsSound, partInModel, 0.1)
    else
        playSound(droppedAmmoBoxSound, partInModel, 0.3)
    end
end)