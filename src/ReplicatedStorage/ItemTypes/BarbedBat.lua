local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Melee = require("../Interfaces/Melee")
local Item = require("../SuperClasses/Item")
local RaycastHitbox = require(ReplicatedStorage.Packages.RaycastHitbox)


export type BarbedBatObject = Item.ItemType & {
    damage : number,
    swingSpeed : number,
    hitbox : any
}

local BarbedBat =  {}

function BarbedBat.new(tool : Tool, humanoid : Humanoid) : BarbedBatObject
    local self = Item.new(tool, humanoid)
    self.damage = 10
    self.swingSpeed = 1
    self.hitbox = RaycastHitbox.new(self.tool:FindFirstChild("BodyAttach"))
    
    BarbedBat.initialize(self)

    return self
end

local function toggleSwingBind(self : BarbedBatObject, toggle : boolean)
    local Keycodes = {
        Enum.UserInputType.MouseButton1,
        Enum.KeyCode.ButtonR2
    }

    local function foo(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject): Enum.ContextActionResult?
        if inputState == Enum.UserInputState.Begin then
            BarbedBat.swing(self)
        end
        return Enum.ContextActionResult.Sink
    end
    if toggle then
        ContextActionService:BindAction("swing", foo, true, unpack(Keycodes))
    else
        ContextActionService:UnbindAction("swing")
    end

end

function BarbedBat.initialize(self : BarbedBatObject)
    Item.initialize(
        self,
        nil,
        function()
            toggleSwingBind(self, true)
        end,
        function()
            toggleSwingBind(self, false) 
        end,
        nil)
    local swingTrack = self.animManager.animationTracks[self.tool.Name].swing
    swingTrack:GetMarkerReachedSignal("swing"):Connect(function(status : "start" | "end")
        if self.State ~= "Unequipped" then
            if status == "start" then
                self.soundManager.playSound("Server", self.soundManager.Sounds[self.tool.Name].swing :: Sound, self.tool:FindFirstChild("BodyAttach"), 0)
                self.hitbox:HitStart()
            elseif status == "end" then
                self.hitbox:HitStop()
            end 
        end
    end)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {self.humanoid.Parent, workspace.CurrentCamera:WaitForChild("viewModel")}
    params.FilterType = Enum.RaycastFilterType.Exclude
    self.hitbox.RaycastParams = params
    self.connections.OnHit = self.hitbox.OnHit:Connect(function(hit, humanoid)
        self.soundManager.playSound("Server", self.soundManager.Sounds[self.tool.Name].impact.flesh :: Sound, self.tool:FindFirstChild("BodyAttach"), 0.2)
        warn("hit ", humanoid.Parent.Name)
    end)
    --The bound action below is for testing purposes; to demonstrate how a faster swing animation somehow inadvertently increases the range
    ContextActionService:BindAction("ChangeSwingSpeed", function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject): Enum.ContextActionResult?  
        if inputState == Enum.UserInputState.Begin then
            local newSpeed = if self.swingSpeed == 2 then 0.5 else 2
            self.swingSpeed = newSpeed
            warn("Changing swingSpeed to ", newSpeed)
        end
        return Enum.ContextActionResult.Sink
    end, true, Enum.KeyCode.P)
end

function BarbedBat.swing(self : BarbedBatObject)
    if self.State == "Idle" then
        Item.ChangeState(self, "Activated")
        local swingTrack = self.animManager.animationTracks[self.tool.Name].swing
        local vmSwingTrack = self.ViewmodelManager.animManager.animationTracks[self.tool.Name].swing
        local idleTrack = self.animManager.animationTracks[self.tool.Name].idle
        local vmIdleTrack = self.ViewmodelManager.animManager.animationTracks[self.tool.Name].idle
        swingTrack:Play(0.1, 1, self.swingSpeed)
        vmSwingTrack:Play(0.1, 1, self.swingSpeed)
        idleTrack:Stop()
        vmIdleTrack:Stop()
        swingTrack.Stopped:Wait()
        idleTrack:Play()
        vmIdleTrack:Play()
        Item.ChangeState(self, "Idle")
    end
end

return BarbedBat :: Melee.MeleeType<BarbedBatObject>