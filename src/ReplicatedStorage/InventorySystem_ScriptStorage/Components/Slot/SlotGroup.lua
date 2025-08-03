--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)

local ScriptStorage = game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage
local Slot = require(ScriptStorage.Components.Slot.Slot)
local Types_LootSystem = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components.Types_LootSystem)
local Type_SlotGroup = require(ScriptStorage.Components.Slot.Type_SlotGroup)
local SlotGroupRegistry = require(ScriptStorage.Components.Slot.SlotGroupRegistry)
local SlotRegistry = require(ScriptStorage.Components.Slot.SlotRegistry)


export type object = Type_SlotGroup.object

local SlotGroup = {}
SlotGroup.instancetoObjectMap = SlotGroupRegistry.instanceToObjectMap

function SlotGroup.new(name: string, space: number, filledSlotsData: Types_LootSystem.StandardFilledSlotsData, parent: Instance?): Type_SlotGroup.object
    local clone = References_Inventory.TemplateSlotGroup:Clone()
    local slotsFrame = clone:FindFirstChildOfClass("Frame"):: Frame
    local self: Type_SlotGroup.object = {
        _itself = clone,
        State = "Empty",
        SlotsFrame = slotsFrame,
        Space = space,
        Name = name,
        _numberOfFilledSlots = 0,
        slotInstanceToObjectMap = {},
        Connections = {}
    }

    SlotGroup._initialize(self, filledSlotsData, parent)
    
    SlotGroup.instancetoObjectMap[self._itself] = self
    return self
end

function SlotGroup._initialize(self: Type_SlotGroup.object, filledSlotsData: Types_LootSystem.StandardFilledSlotsData, parent: Instance?)

    local num = 0
    for i = 1, self.Space, 1 do
        local slot = Slot.new("Inventory")
        self.slotInstanceToObjectMap[slot._itself] = slot
        slot._itself.LayoutOrder = i

        local tool = filledSlotsData[tostring(i)]
        if tool then
            Slot.FillSlot(slot, tool)
            num += 1
        end
        
        slot._itself.Parent = self._itself:FindFirstChildOfClass("Frame")
    end
    SlotGroup._SetFilledSlots(self, num)
    
    local textLabel = self._itself:FindFirstChildOfClass("TextLabel"):: TextLabel
    textLabel.Text = self.Name
    self._itself.Visible = true
    self._itself.Parent = if parent then parent else References_Inventory.InventoryScrollingFrame

    if parent ~= References_Inventory.LootingScrollingFrame then
        table.insert(
            self.Connections,
            self.SlotsFrame.ChildAdded:Connect(function(child: Instance)  
                assert(child:IsA("Frame"))
                local slotObject = Slot.instanceToObjectMap[child]:: Slot.SlotObject
                self.slotInstanceToObjectMap[child] = slotObject
                if slotObject.tool then
                    -- print(`Slot in {self.Name} slot group was filled`)
                    SlotGroup._SetFilledSlots(self, self._numberOfFilledSlots + 1)
                end
            end)
        )
        table.insert(
            self.Connections,
            self.SlotsFrame.ChildRemoved:Connect(function(child: Instance)  
                assert(child:IsA("Frame"))
                local slotObject = self.slotInstanceToObjectMap[child]
                if slotObject.tool then
                    print(`Slot in {self.Name} slot group was emptied`)
                    SlotGroup._SetFilledSlots(self, self._numberOfFilledSlots - 1)
                end
                self.slotInstanceToObjectMap[child] = nil
            end)
        )
        table.insert(
            self.Connections,
            Slot.StateChanged:Connect(function(slot: Slot.SlotObject, state: Slot.State)
                local slotGroupInstance = if slot._itself.Parent and slot._itself.Parent.Parent then slot._itself.Parent.Parent else nil
                if slotGroupInstance == self._itself then
                    if state == "Filling" then
                        -- warn(`Slot in {self.Name} slot group is {state}`)
                        SlotGroup._SetFilledSlots(self, self._numberOfFilledSlots + 1)
                    elseif state == "Emptying" then
                        warn(`Slot in {self.Name} slot group is {state}`)
                        SlotGroup._SetFilledSlots(self, self._numberOfFilledSlots - 1)
                    end
                end
            end)
        ) 
    end
end

function SlotGroup._SetFilledSlots(self: Type_SlotGroup.object, num: number)
    self._numberOfFilledSlots = num
    local instance = self._itself
    -- print(`_numberOfFilledSlots: {self._numberOfFilledSlots}`)
    instance:SetAttribute("FilledSlotCounter_Client", `{self._numberOfFilledSlots}/{self.Space}`)
end

function SlotGroup.Destroy(self: Type_SlotGroup.object)
    SlotGroup.instancetoObjectMap[self._itself] = nil

    for _, v in self.Connections do
        v:Disconnect()
    end
    task.defer(function() -- have to defer because Empty Slot will be called, and we need that to run before we call destroy on the slots
        -- for _, v in self.slotInstanceToObjectMap do
        --     Slot.destroy(v)
        -- end
        table.clear(self.Connections)
        self._itself:Destroy()
        table.clear(self)
    end)
end

return SlotGroup