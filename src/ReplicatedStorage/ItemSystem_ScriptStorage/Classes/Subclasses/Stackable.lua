local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_ItemSystem = require(ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.References_ItemSystem)
local Type_Item = require(ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.Classes.Components.Shared.Type_Item)

local Item = require("../Superclasses/Item")

export type StackableObject = Item.ItemObject & {

}

local Stackable =  {}

function Stackable.new(tool : Tool) : StackableObject
    local self = Item.new(tool)

    Stackable.initialize(self)
    return self
end

function Stackable.initialize(self : StackableObject)
    Item.initialize(
        self,
        function()  --onEquipping
        end, 
        function() --onEquipped
        end,
        function() --onUnequipping
        end,
        function() --onUnequipped()
        end, 
        function() --onDropping()
        end,
        function() --onDropped()
        end
    )

    self.trove:Add(
        self.tool.Destroying:Once(function()
            print("Calling stackable destroy")
            Stackable.Destroy(self)
        end)
    )


end

function Stackable.Destroy(self: StackableObject)
    Item.Destroy(self, function()  
    end)
end

return Stackable