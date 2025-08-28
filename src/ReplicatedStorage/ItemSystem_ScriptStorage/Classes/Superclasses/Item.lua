--!strict
local References_ItemSystem = require(game:GetService("ReplicatedStorage").RojoManaged_RS.ItemSystem_ScriptStorage.References_ItemSystem)

type state = "Equipping" | "Idle" | "Unequipping" | "Unequipped" | "Activated" 
    | "Wearing" | "Unwearing" | "Worn"
    | "Dropping" | "Dropped" 
    | "Destroying" | "UpdatingCharacter"

export type ItemType = {
    tool : Tool,
    bodyAttach: BasePart,
    soundObjects: any,
    actionNames: {[string]: string},
    State : state,
    dropEquippedToolOnDeath: RBXScriptConnection?,
    trove: any
}

local Item = {}

--[[
    Makes this tool usable for the humanoid's current character
]]
function Item.new(tool : Tool) : ItemType
    local self : ItemType = {
        tool = tool,
        bodyAttach = tool:FindFirstChild("BodyAttach", true):: BasePart,
        soundObjects = References_ItemSystem.ToolInfo.get(tool.Name).soundObjects, -- For ergonomics; Only a pointer to an existing data table, so doesn't take that much memory
        actionNames = {},
        State = "Unequipped",
        dropEquippedToolOnDeath = nil,
        trove = References_ItemSystem.Trove.new()
    }

    self.actionNames.dropItem = "Drop Item" 
    Item.ChangeState(self, "Unequipped")
    local toolAnims = References_ItemSystem.ToolInfo.get(tool.Name).animObjects
    References_ItemSystem.ToolAnimationManager.LoadAnimations(References_ItemSystem.animationManagerObject, tool, toolAnims)
    References_ItemSystem.ViewmodelManager.AddTool(References_ItemSystem.viewmodelManagerObject, tool, toolAnims)

    -- warn(`SUCCESSFULLY INSTANTIATED {tool}`)
    return self
end

function Item.initialize(self : ItemType, equipping: () -> ()?, equipped: () -> ()?, unequipping: () -> ()?, unequipped: () -> ()?, onDropping : () -> ()?, onDropped : () -> ()?)

    local equipTrack : AnimationTrack = References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].equip
    Item.TrackAnimTrack(self, equipTrack, "Equip")

    self.trove:Connect(References_ItemSystem.bindables.ToggleEquip.Event, function(key : Tool, toggle: boolean)
        if key == self.tool then
            if toggle then
                Item.equip(self, equipping, equipped, onDropping, onDropped)
            else
                Item.unequip(self, unequipping, unequipped) 
            end 
        end
    end)
    
    self.trove:Connect(self.tool.AncestryChanged, function(child: Instance, parent: Instance?)  
        if parent and parent:FindFirstChildOfClass("Humanoid") then
            References_ItemSystem.remotes.ToggleToolCanCollide:FireServer(self.tool:FindFirstChild("ToolModel"), false)
        else
            References_ItemSystem.remotes.ToggleToolCanCollide:FireServer(self.tool:FindFirstChild("ToolModel"), true)
            References_ItemSystem.ViewmodelManager.toggleViewmodelToolVisibility(References_ItemSystem.viewmodelManagerObject, self.tool, false)
            --Proximity Prompt and highlight
        end
    end)
    
    self.trove:Connect(References_ItemSystem.bindables.OnPickUp.Event, function(key: Tool)  
        if key == self.tool then
            Item.ChangeState(self, "Unequipped")
        end
    end)
    
    self.trove:Connect(References_ItemSystem.bindables.DropToolBindable.Event, function(key: Tool) 
        if key == self.tool then
            -- print("Dropping")
            Item.drop(self)
        end
    end)
    
    self.trove:Connect(References_ItemSystem.bindables.ImmediateUnequip.Event, function(key: Tool)  
        if key == self.tool then
            Item.immediateUnequip(self)
        end
    end)
end

--[[
    WARNING: THIS FUNCTION MAY YIELD. 
    This will create and update custom attributes of the tool called [trackName]Length 
    and [trackName]TimePosition. 
]]
function Item.TrackAnimTrack(self: ItemType, animTrack: AnimationTrack, trackName: string)
    while animTrack.Length == 0 do
        task.wait()
    end
    self.tool:SetAttribute(trackName .. "Length", animTrack.Length)
    self.tool:SetAttribute(trackName .. "TimePosition", animTrack.TimePosition)

    self.trove:Connect(References_ItemSystem.RunService.Heartbeat, function(a0: number)  
        if not animTrack.IsPlaying then return end

        if self.State ~= "Unequipped" and self.State ~= "Worn" then
            self.tool:SetAttribute(trackName .. "TimePosition", animTrack.TimePosition)
        end
    end)
end

function Item.equip(self: ItemType, equipping: () -> ()?, equipped: () -> ()?, onDropping : () -> ()?, onDropped : () -> ()?)
    Item.ChangeState(self, "Equipping")
    self.dropEquippedToolOnDeath = References_ItemSystem.humanoid.Died:Once(function(...: any)  
        -- warn("NOT DROPPING EQUIPPED TOOL BECAUSE THIS IS BUGGED: TOOL WOULD FALL THROUGH FLOOR")
        References_ItemSystem.remotes.ToggleToolCanCollide:FireServer(self.tool:FindFirstChild("ToolModel"), true)
        Item.drop(self)
    end)
    References_ItemSystem.ItemHUD.setTool(self.tool)
    References_ItemSystem.ItemHUD.show()
    References_ItemSystem.humanoid:EquipTool(self.tool)
    References_ItemSystem.remotes.PlaySound:FireServer(self.soundObjects.equip :: Sound, self.bodyAttach, 0)
    local equipTrack : AnimationTrack = References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].equip
    equipTrack.Priority = Enum.AnimationPriority.Action2
    local vmEquipTrack : AnimationTrack = References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].equip
    Item.toggleDropBind(self, true, onDropping, onDropped)
    if equipping then equipping() end
    if equipTrack.IsPlaying then
        equipTrack:AdjustSpeed(1)
        vmEquipTrack:AdjustSpeed(1)
    else
        equipTrack:Play(0.1, 1, 1)
        vmEquipTrack:Play(0.1, 1, 1)
    end
    equipTrack.Stopped:Wait()
    if self.State == "Equipping" then
        Item.ChangeState(self, "Idle")
        References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].idle:Play()
        References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].idle:Play()
        if equipped then equipped() end
    end
end

function Item.unequip(self: ItemType, unequipping: () -> ()?, unequipped: () -> ()?)
    Item.ChangeState(self, "Unequipping")
    if self.dropEquippedToolOnDeath then
        self.dropEquippedToolOnDeath:Disconnect()
    end
    Item.toggleDropBind(self, false)
    References_ItemSystem.ItemHUD.hide()
    References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].idle:Stop()
    References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].idle:Stop()
    local unequipSFX: Sound? = self.soundObjects.unequip:: Sound
    References_ItemSystem.remotes.PlaySound:FireServer(if unequipSFX then unequipSFX else self.soundObjects.equip :: Sound, self.bodyAttach, 0)
    local equipTrack : AnimationTrack = References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].equip
    equipTrack.Priority = Enum.AnimationPriority.Action
    local vmEquipTrack : AnimationTrack = References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].equip
    if unequipping then unequipping() end
    if equipTrack.IsPlaying then
        equipTrack:AdjustSpeed(-1)
        vmEquipTrack:AdjustSpeed(-1)
    else
        equipTrack:Play(0.1, 1, -1)
        vmEquipTrack:Play(0.1, 1, -1)
    end
    equipTrack.Stopped:Wait()
    equipTrack:Stop(0)
    if self.State == "Unequipping" or self.State == "Dropping" then
        References_ItemSystem.humanoid:UnequipTools()
        Item.toggleDropBind(self, false)
        if unequipped then unequipped() end
        Item.ChangeState(self, "Unequipped")
    end
end

function Item.immediateUnequip(self: ItemType)
    if self.State == "Unequipped" then return end
    
    for _, v in self.actionNames do
        if References_ItemSystem.ActionManager.isBinded(v) then
            References_ItemSystem.ActionManager.unbindAction(v)
        end 
    end
    References_ItemSystem.ToolAnimationManager.StopAllAnimsForTool(References_ItemSystem.animationManagerObject, self.tool)
    References_ItemSystem.ToolAnimationManager.StopAllAnimsForTool(References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject, self.tool)
    Item.ChangeState(self, "Unequipped")
    References_ItemSystem.ItemHUD.hide()
end

function Item.ChangeState(self: ItemType, state: state)
    self.tool:SetAttribute("State", state)
    self.State = state
end

function Item.drop(self : ItemType, onDropping: () -> ()?, onDropped : () -> ()?)
    if self.State == "Idle" or self.State == "Equipping" or self.State == "Unequipped" or self.State == "Wearing" or self.State == "Unwearing" then
        Item.ChangeState(self, "Dropping")
        for _, v in self.actionNames do
            if References_ItemSystem.ActionManager.isBinded(v) then
                References_ItemSystem.ActionManager.unbindAction(v)
            end 
        end
        if onDropping then
            onDropping()
        end
        if self.State ~= "Unequipped" then
            References_ItemSystem.ToolAnimationManager.StopAllAnimsForTool(References_ItemSystem.animationManagerObject, self.tool)
            References_ItemSystem.ToolAnimationManager.StopAllAnimsForTool(References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject, self.tool)
        end
        References_ItemSystem.remotes.DropTool:FireServer(self.tool)
        Item.ChangeState(self, "Dropped")
        if onDropped then
            onDropped()
        end
        References_ItemSystem.ItemHUD.hide()
        -- warn(`DROPPED ITEM`)
    end
end

function Item.toggleDropBind(self : ItemType, toggle : boolean, onDropping: () -> ()?, onDropped : () -> ()?)
    if toggle then
        References_ItemSystem.ActionManager.bindAction(
            self.actionNames.dropItem, 
            function(): (() -> (), () -> (), () -> ())  
                local function onActivated()
                end

                local function onDeactivated()
                    Item.drop(self, onDropping, onDropped)
                end

                local function onUnbind()
                    
                end

                return onActivated, onDeactivated, onUnbind
            end, 
            Enum.KeyCode.X, 
            Enum.KeyCode.ButtonX, 
            4, 
            nil, 
            nil, 
            "rbxassetid://108041751673485")
    else
        References_ItemSystem.ActionManager.unbindAction(self.actionNames.dropItem)
    end
end

function Item.Destroy(self : ItemType, childObjectCleanupMethod: () -> ())
    Item.ChangeState(self, "Unequipped")
    childObjectCleanupMethod()
    --animManager internal data
    local humanoid: Humanoid = References_ItemSystem.humanoid
    if not (humanoid:GetState() == Enum.HumanoidStateType.Dead) then
        References_ItemSystem.ToolAnimationManager.RemoveTool(References_ItemSystem.animationManagerObject, self.tool)
        References_ItemSystem.ViewmodelManager.removeTool(References_ItemSystem.viewmodelManagerObject, self.tool)
    else
        -- warn("At humanoid death, ToolAnimationManager and ViewmodelManager is handled by References module")
    end
    task.defer(function()
        self.trove:Destroy()
        table.clear(self)
        -- warn(`DESTROYED ITEM`)
    end)
end

return Item