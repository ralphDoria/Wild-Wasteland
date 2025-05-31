local Wearable = require("./../../Subclasses/Wearable")

type NVGogglesObject = Wearable.WearableType & {

}

local NVGoggles = {}

function NVGoggles.new(tool: Tool, humanoid: Humanoid): NVGogglesObject
    local self = Wearable.new(tool, humanoid)

    NVGoggles._initialize(self)

    return self
end

function NVGoggles._initialize(self: NVGogglesObject)
    Wearable.initialize(
        self, 
        function() -- appyWornEffects 

        end, 
        function() -- removeWornEffects
            
        end
    )
end

return NVGoggles