local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RaycastHitbox = require(ReplicatedStorage.Packages.RaycastHitbox)

-- RaycastHitboxV4 binds each hitbox to its tool via the "_RaycastHitboxV4Managed"
-- CollectionService tag and auto-destroys the hitbox when that tag is removed.
-- The tag is added here on the CLIENT, but tools are server-replicated: any
-- server-side reparent (e.g. moving a tool into ReplicatedStorage.LootItemsHolding
-- when stored in a loot crate) re-syncs the authoritative state and strips the
-- client-only tag, which tears the hitbox down underneath us. After teardown the
-- RaycastHitbox object is left as a metatable-less, cleared table, so calling
-- :HitStart()/:HitStop() throws "missing method".
--
-- This manager is therefore self-healing: it remembers what it needs to rebuild
-- the hitbox and lazily recreates it whenever it detects the underlying object
-- has been torn down.
local MANAGED_TAG = "_RaycastHitboxV4Managed"

export type HitboxManager = {
    RaycastHitbox : any,
    connections : {RBXScriptConnection},
    _tool : Tool,
    _raycastParams : RaycastParams,
    _onHitCallbacks : {(hit: BasePart, humanoid: Humanoid, raycastResult: RaycastResult) -> ()},
}

local HitboxManager = {}

-- A hitbox is unusable once RaycastHitboxV4's Heartbeat cleanup has run on it
-- (it clears the table and strips the metatable), or once it is flagged pending
-- removal (which happens the instant the tag is lost, before the cleanup frame).
local function isDead(raycastHitbox: any): boolean
    return getmetatable(raycastHitbox) == nil or raycastHitbox.HitboxPendingRemoval == true
end

local function rebuild(self: HitboxManager)
    -- Drop any connections to the dead hitbox's OnHit signal.
    for _, connection in self.connections do
        connection:Disconnect()
    end
    table.clear(self.connections)

    -- If a dead/pending hitbox still holds the tag, RaycastHitbox.new would try to
    -- reuse it (and _FindHitbox skips pending-removal ones, returning nil). Force a
    -- clean slate so we always get a fresh, fully-initialized hitbox.
    if CollectionService:HasTag(self._tool, MANAGED_TAG) then
        CollectionService:RemoveTag(self._tool, MANAGED_TAG)
    end

    local raycastHitbox = RaycastHitbox.new(self._tool)
    raycastHitbox.RaycastParams = self._raycastParams
    for _, onHit in self._onHitCallbacks do
        table.insert(self.connections, raycastHitbox.OnHit:Connect(onHit))
    end
    self.RaycastHitbox = raycastHitbox
end

local function ensureAlive(self: HitboxManager)
    if isDead(self.RaycastHitbox) then
        rebuild(self)
    end
end

function HitboxManager.new(tool: Tool, descendantsToIgnore: {Instance}) : HitboxManager
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = descendantsToIgnore
    params.FilterType = Enum.RaycastFilterType.Exclude

    local self : HitboxManager = {
        RaycastHitbox = RaycastHitbox.new(tool),
        connections = {},
        _tool = tool,
        _raycastParams = params,
        _onHitCallbacks = {},
    }
    self.RaycastHitbox.RaycastParams = params

    return self
end

function HitboxManager.ConnectOnHit(self: HitboxManager, OnHit: (hit: BasePart, humanoid: Humanoid, raycastResult: RaycastResult) -> ())
    table.insert(self._onHitCallbacks, OnHit)
    if isDead(self.RaycastHitbox) then
        rebuild(self) -- reconnects every stored callback (including the one just added)
    else
        table.insert(self.connections, self.RaycastHitbox.OnHit:Connect(OnHit))
    end
end

function HitboxManager.HitStart(self: HitboxManager, seconds: number?)
    ensureAlive(self)
    self.RaycastHitbox:HitStart(seconds)
end

function HitboxManager.HitStop(self: HitboxManager)
    ensureAlive(self)
    self.RaycastHitbox:HitStop()
end

function HitboxManager.Destroy(self: HitboxManager)
    if not isDead(self.RaycastHitbox) then
        self.RaycastHitbox:Destroy()
    end
    for _, v in self.connections do
        v:Disconnect()
    end
    table.clear(self)
end

return HitboxManager
