local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_ActionHandlers = require(script.Parent.Parent.References_ActionHandlers)
local types_and_enums = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.Drag.types_and_enums)
local Utility = require(script.Parent.Parent.Utility)

local function P_EQUIPMENT__DROP(characterEquipmentSlotData: types_and_enums.SlotData, changeSlotState: types_and_enums.changeSlotState, fillSlot, emptySlot)
    local characterEquipmentSlot = characterEquipmentSlotData.slotObject

    local tweens: {Tween} = {}
    References_ActionHandlers.ToolStateMachine.SetTargets(characterEquipmentSlot, "Idle", 
        function(estimatedPathsTime: number) -- onValidated
            changeSlotState(characterEquipmentSlot, "BeingSwapped")

            table.insert(tweens, Utility.loadSlot(characterEquipmentSlot, estimatedPathsTime))
            for _, v in tweens do
                v:Play()
            end
        end,
        function() -- onCancelled
            for _, v in tweens do
                if v.PlaybackState == Enum.PlaybackState.Playing then
                    v:Cancel()                        
                end
            end
            warn("Cancelled")
        end,
        function() --onResolved
            -- warn("resolved characterEquipment_drop")
            References_ActionHandlers.bindables.DropToolBindable:Fire(characterEquipmentSlot.tool)
        end,
        function(status: string)
            changeSlotState(characterEquipmentSlot, "Idle")
        end
    )
end

return P_EQUIPMENT__DROP
