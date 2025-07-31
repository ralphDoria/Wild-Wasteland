local Type_Slot = require("./../../Components/Slot/Type_Slot")

type x = {
    slot: Type_Slot.SlotObject, 
    circle: ImageLabel, 
    line: ImageLabel, 
    image: string,
    torsoOffset: CFrame,
    uiOffsetMultiplier: number,
    LayoutOrder: number
}

local slotInfo: {[string]: x} = {
    ["Head"] = {
        slot = nil, 
        image = "rbxassetid://18790572259",
        torsoOffset = CFrame.new(0, 1.5, 0),
        uiOffsetMultiplier = 1,
        LayoutOrder = 1,
        circle = nil, -- will be assigned in WearableInterface during initialize()
        line = nil -- will be assigned in WearableInterface during initialize()
    },
    ["Torso"] = {
        slot = nil,
        image = "rbxassetid://18790580783",
        torsoOffset = CFrame.new(0, 0.3, 0),
        uiOffsetMultiplier = 1,
        LayoutOrder = 2,
        circle = nil, -- will be assigned in WearableInterface during initialize()
        line = nil -- will be assigned in WearableInterface during initialize()
    },
    ["Backpack"] = {
        slot = nil, 
        image = "rbxassetid://109883323088072",
        torsoOffset = CFrame.new(0, 0, 0.5),
        uiOffsetMultiplier = -1,
        LayoutOrder = 3,
        circle = nil, -- will be assigned in WearableInterface during initialize()
        line = nil -- will be assigned in WearableInterface during initialize()
    },
    ["Legs"] = {
        slot = nil, 
        image = "rbxassetid://18790582567",
        torsoOffset = CFrame.new(0, -2, 0),
        uiOffsetMultiplier = -1,
        LayoutOrder = 4,
        circle = nil, -- will be assigned in WearableInterface during initialize()
        line = nil -- will be assigned in WearableInterface during initialize()
    },
    ["Feet"] = {
        slot = nil, 
        image = "rbxassetid://18790584454",
        torsoOffset = CFrame.new(0, -3, 0),
        uiOffsetMultiplier = 1,
        LayoutOrder = 5,
        circle = nil, -- will be assigned in WearableInterface during initialize()
        line = nil -- will be assigned in WearableInterface during initialize()
    },
}

return slotInfo