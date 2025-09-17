local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RaycastHitbox = require(ReplicatedStorage.Packages.RaycastHitbox)

export type HitboxManager = {
    RaycastHitbox : any,
    connections : {RBXScriptConnection}
}

local HitboxManager = {}

function HitboxManager.new(tool: Tool, descendantsToIgnore: {Instance}) : HitboxManager
    local bodyAttach = tool:FindFirstChild("BodyAttach", true)
    print(bodyAttach)
    assert(bodyAttach)
    local self : HitboxManager = {
        RaycastHitbox = RaycastHitbox.new(bodyAttach),
        connections = {}
    }
    print(self.RaycastHitbox)

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = descendantsToIgnore
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

function HitboxManager.Destroy(self: HitboxManager)
    self.RaycastHitbox:Destroy()
    for _, v in self.connections do
        v:Disconnect()
    end
    table.clear(self)
end

return HitboxManager