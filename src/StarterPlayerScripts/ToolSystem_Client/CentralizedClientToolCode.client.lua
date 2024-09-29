local CollectionService = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")

local toolTags = {
     ["Night Vision Goggles"] = require(RS:FindFirstChild("NVGogglesClass", true))--the tool tag is just going to be the name of the tool
}

local function handleTaggedInstances(instance, class)
    print("From CCTC - handling tagged instance")
    if not instance:IsA("Tool") then
        warn("tagged instance is not a tool")
    end
    class.new(instance)
end

for tag, class in toolTags do
    for _, taggedInstance in CollectionService:GetTagged(tag) do
        handleTaggedInstances(taggedInstance, class)
    end
    CollectionService:GetInstanceAddedSignal(tag):Connect(function(taggedInstance)
        handleTaggedInstances(taggedInstance, class)
    end)
end