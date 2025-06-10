-- local CollectionService = game:GetService("CollectionService")
-- local RS = game:GetService("ReplicatedStorage")

-- local toolTags = {
--      ["Night Vision Goggles"] = require(RS:FindFirstChild("NVGogglesClass", true)),--the tool tag is just going to be the name of the tool
--      ["Raider Axe"] = require(RS:FindFirstChild("MeleeController", true)),
--      ["Healing Injection"] = require(RS:FindFirstChild("ConsumableController", true)),
--      ["Beretta"] = require(RS:FindFirstChild("GunController", true))
-- }

-- local function handleTaggedInstances(instance, class)
--     if not instance:IsA("Tool") then
--         warn("tagged instance is not a tool")
--     end
--     warn("creating new Instance of " .. instance.Name)
--     class.new(instance)
-- end

-- for tag, class in toolTags do
--     for _, taggedInstance in CollectionService:GetTagged(tag) do
--         if not taggedInstance:HasTag("vmTool") then
--             handleTaggedInstances(taggedInstance, class)
--         end
--     end
--     CollectionService:GetInstanceAddedSignal(tag):Connect(function(taggedInstance)
--         if not taggedInstance:HasTag("vmTool") then
--             handleTaggedInstances(taggedInstance, class)
--         end
--     end)
-- end