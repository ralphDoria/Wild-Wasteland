local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local RaycastHitbox = require(ReplicatedStorage.Packages.RaycastHitbox)

export type HitboxManager = {
    RaycastHitbox : any,
    connections : {RBXScriptConnection}
}

local HitboxManager = {}

function HitboxManager.new(tool: Tool) : HitboxManager
    local self : HitboxManager = {
        RaycastHitbox = RaycastHitbox.new(tool:FindFirstChild("BodyAttach", true)),
        connections = {}
    }

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {character, workspace.CurrentCamera:WaitForChild("viewModel")}
    params.FilterType = Enum.RaycastFilterType.Exclude
    self.RaycastHitbox.RaycastParams = params

    return self
end

function HitboxManager.ConnectOnHit(self, OnHit: (hit: BasePart, humanoid: Humanoid, raycastResult: RaycastResult) -> ())
    table.insert(
        self.connections,
        self.RaycastHitbox.OnHit:Connect(OnHit)
    )
end

function HitboxManager.Destroy()
    
end

return HitboxManager