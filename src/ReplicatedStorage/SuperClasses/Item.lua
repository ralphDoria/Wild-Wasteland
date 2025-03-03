--!strict

export type ItemType = {
    tool : Tool,
    sounds : { Sound? },
    viewmodelController : ModuleScript?,
    animController : ModuleScript?,
    finiteStateMachine : ModuleScript?,
    connections : { RBXScriptConnection? },
    State : "Equipping" | "Equipped" |"Unequipping" | "Unequipped"
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
--EXTERNAL CONTROLLERS
local AnimationController = require(ReplicatedStorage:FindFirstChild("AnimationController", true))
local ViewmodelController = require(ReplicatedStorage:FindFirstChild("ViewModelController", true))
local RobloxStateMachine = require(ReplicatedStorage:FindFirstChild("robloxstatemachine", true)) 

local remotes = {
    playSound = ReplicatedStorage.Tools.Shared:FindFirstChild("PlaySound", true),
    drop = ReplicatedStorage.Tools.Shared:FindFirstChild("DropTool", true)
}

local Item = {}

function Item.new(tool : Tool) : ItemType
    local self : ItemType = {
        tool = tool,
        sounds = {},
        viewmodelController = ViewmodelController, --viewmodelController will handle viewmodel instance reference
        animController = AnimationController, --animController will handle animObjects array within its scope
        finiteStateMachine = RobloxStateMachine,
        connections = {},
        State = "Unequipped"
    }



    return self
end

function Item.equip(item : ItemType)
    item.State = "Equipping"
    
end

function Item.unequip(item : ItemType)
end

function Item.drop(item : ItemType)
end

function Item.destroy(item : ItemType)
end

return Item