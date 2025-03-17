local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bindables : {[string] : BindableEvent} = {
    toggleEquip = ReplicatedStorage.ToolSystem_Storage.Shared:FindFirstChild("toggleEquip", true)
}

local Melee = require("../Interfaces/Melee")
local Item = require("../SuperClasses/Item")

export type BarbedBatObject = Item.ItemType & {
    damage : number,
    swingSpeed : number,
    connections : {[string] : RBXScriptConnection}
}

local BarbedBat =  {}

function BarbedBat.new(tool : Tool, humanoid : Humanoid) : BarbedBatObject
    local self = Item.new(tool, humanoid)
    self.damage = 10
    self.swingSpeed = 1
    self.connections = {
    } 

    BarbedBat.initialize(self)

    return self
end

function BarbedBat.initialize(self : BarbedBatObject)
    self.connections.togglEquip = Bindables.toggleEquip.Event:Connect(function(key : Tool)
        if key == self.tool then
            if self.State == "Unequipping" or self.State == "Unequipped" then
                Item.equip(self)
            elseif self.State == "Equipping" or self.State == "Idle" then
                Item.unequip(self) 
            end
        end
    end)
end

function BarbedBat.swing(self : BarbedBatObject)
    if self.State == "Idle" then
        self.State = "Activated"
        local swingTrack = self.animManager.animationTracks[self.tool.Name].swing
        swingTrack:Play()
        swingTrack.Stopped:Wait()
        self.State = "Idle"
    end
end

return BarbedBat :: Melee.MeleeType<BarbedBatObject> --figure out why the type is being underlined here, and why the generic isn't fillin in.