local Wearable = require("./Wearable")
local SlotGroup = require(game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.SlotGroup)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local bindables = {
    DropToolBindable = ToolSystem_Storage.Shared.Bindables.DropToolBindable,
}
type StorageWearableObject = Wearable.WearableType & {
    Space: number, -- number of storage slots it'll the wearer
    ItemGroup: SlotGroup.ItemGroupObject?,
    objValue: ObjectValue
}

local StorageWearable = {}

function StorageWearable.new(tool: Tool, humanoid: Humanoid)
    local self = Wearable.new(tool, humanoid)
    self.Space = tool:GetAttribute("Space")

    self.objValue = Instance.new("ObjectValue")
    self.objValue.Name = "AssociatedItemGroup"
    self.objValue.Parent = tool

    StorageWearable._initialize(self)

    return self
end

function StorageWearable._initialize(self: StorageWearableObject)
    Wearable.initialize(
        self, 
        function() -- onWearing
            self.soundManager.playSound("Client", self.soundManager.Sounds[self.tool.Name].wear :: Sound, self.tool:FindFirstChild("BodyAttach", true), 0)
        end,
        function() -- onUnwearing
            self.soundManager.playSound("Client", self.soundManager.Sounds[self.tool.Name].unwear :: Sound, self.tool:FindFirstChild("BodyAttach", true), 0.1)
        end,
        function() -- appyWornEffects 
            self.ItemGroup = SlotGroup.new(self.tool.Name, self.Space)
            if self.ItemGroup then
                self.objValue.Value = self.ItemGroup._itself
            end
        end, 
        function() -- removeWornEffects
            if self.ItemGroup then
                for _, v in self.ItemGroup.ItemSlots do
                    if not v._isEmpty then
                        bindables.DropToolBindable:Fire(v.tool)
                    end
                end
                SlotGroup.Destroy(self.ItemGroup)
                self.objValue.Value = nil
            end
        end
    )
end

function StorageWearable.Destroy()
end

return StorageWearable