--Credit to Zack Williams (@BoatBomber) for the original script (https://devforum.roblox.com/t/rendering-the-character-with-a-viewportframe/241369/31?u=niletheus)
--Edited for use in Wild Wasteland by @Niletheus

--[=[
	Character Viewport
	Realtime viewing oneself in a GUI window, including tools

	boatbomber, 2/17/19 (Updated: 6/13/2021)
--]=]

-- Services
local RunService = game:GetService("RunService")

local ValidClasses = {
	["MeshPart"] = true; ["Part"] = true; ["Accoutrement"] = true; ["UnionOperation"] = true;
	["Pants"] = true; ["Shirt"] = true;
	["Humanoid"] = true;
}

export type vpCharObj = {
    Viewport: ViewportFrame,
    Camera: Camera,
	CameraRadius: CFrame,
	CameraPosition: CFrame,
	Viewmodel: Model,
    RenderObjects: {},
    Connections: {RBXScriptConnection}
}

local ViewportCharacter = {}

function ViewportCharacter._RemoveObject(self: vpCharObj, Object: Instance)
	local Clone = self.RenderObjects[Object]
	if not Clone then return end

	self.RenderObjects[Object] = nil
	if Clone.Parent:IsA("Accoutrement") then
		Clone.Parent:Destroy()
	else
		Clone:Destroy()
	end

	--print("Removed",Object)
end

function ViewportCharacter._AddObject(self: vpCharObj, Object: Instance)
	if not ValidClasses[Object.ClassName] then
		return nil
	end

	-- Create clone, regardless of Archivable
	local a = Object.Archivable
	Object.Archivable = true
	local RenderClone = Object:Clone()
	Object.Archivable = a

	if Object.ClassName == "MeshPart" or Object.ClassName == "Part" or Object.ClassName == "UnionOperation" then
		self.RenderObjects[Object] = RenderClone

	elseif Object:IsA("Accoutrement") then
		self.RenderObjects[Object.Handle] = RenderClone.Handle

	elseif Object.ClassName == "Humanoid" then
		--Disable all states. We only want it for clothing wrapping.
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.FallingDown,			false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Running,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,	false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Climbing,			false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,	false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.GettingUp,			false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Jumping,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Landed,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Flying,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Freefall,			false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Seated,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,	false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Dead,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Swimming,			false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Physics,				false)
		RenderClone.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	--print("Added",Object)

	return RenderClone
end

--Render the character
function ViewportCharacter.handleCharacter(Viewport: ViewportFrame, character: Model): vpCharObj
    --warn("Handle char")

    -- Object
    local self: vpCharObj = {
        Viewport = Viewport,
        Camera = Instance.new("Camera"),
		CameraRadius = CFrame.new(0, 0, -7),
		CameraPosition = CFrame.new(0, 0, -7), -- can be modified later
        RenderObjects = table.create(25),
		Viewmodel = nil,
        Connections = {}
    }
    Viewport.CurrentCamera	= self.Camera

	Viewport:ClearAllChildren()

	local Viewmodel = Instance.new("Model")
	self.Viewmodel = Viewmodel
	Viewmodel.Name = "PlayerViewmodel"
	Viewmodel.Parent = Viewport

	local CharObjects = character:GetDescendants()
	for i, Object in pairs(CharObjects) do
		local RenderClone = ViewportCharacter._AddObject(self, Object)
		if RenderClone then
			RenderClone.Parent = Viewmodel
		end
	end

	table.insert(
        self.Connections, 
        character.DescendantAdded:Connect(function(NewObject)
            local RenderClone = ViewportCharacter._AddObject(self, NewObject)
            if RenderClone then
                RenderClone.Parent = Viewmodel
            end
        end)
    )

	table.insert(
        self.Connections,
        character.DescendantRemoving:Connect(function(OldObject)
            ViewportCharacter._RemoveObject(self, OldObject)
        end)
    )

    table.insert(
        self.Connections,
        RunService.Stepped:Connect(function()
            if (not character:FindFirstChild("HumanoidRootPart")) or (not Viewport.Visible) then
                return
            end

            -- Update camera
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                self.Camera.CFrame = CFrame.new(hrp.CFrame:ToWorldSpace(self.CameraPosition).Position, hrp.Position)
            else
                warn("HumanoidRootPart not found, can't position viewport camera")
            end

            -- Update objects
            for Original, Clone in pairs(self.RenderObjects) do
                if Original and Original.Parent then
                    Clone.CFrame = Original.CFrame
                else
                    ViewportCharacter._RemoveObject(self, Original)
                end
            end
        end)
    )

    return self
end

function ViewportCharacter.stopHandling(self: vpCharObj)
    for _, v in self.Connections do
        v:Disconnect()
    end
    self.Camera:Destroy()
    table.clear(self.RenderObjects)
	self.Viewport:ClearAllChildren()
    table.clear(self)
end

return ViewportCharacter

