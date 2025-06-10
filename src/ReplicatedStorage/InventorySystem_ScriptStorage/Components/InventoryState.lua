export type InventoryState = "SwappingSlots" | "Idle"

local InventoryState = {}

local InventoryStateChangedBindable: BindableEvent = Instance.new("BindableEvent")
InventoryState.Changed = InventoryStateChangedBindable.Event

InventoryState.State = "Idle"

function InventoryState.GetState(): InventoryState
    return InventoryState.State
end

function InventoryState.ChangeState(state: InventoryState)
    if state ~= InventoryState.State then
        InventoryState.State = state
        InventoryStateChangedBindable:Fire(state)
    end
end

return InventoryState