-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Promise = require(ReplicatedStorage:FindFirstChild("Promise", true))

-- Promise.new(function(resolve : (string) -> (), reject :  (string) -> (), onCancel :  () -> ())

--     local success = false

--     if success then
--         resolve("Example result when promise resolves")
--     else
--         reject("Example result when promise rejects")
--     end

-- end):andThen(function(result)
--         warn("promise resolved: ", result)
--     end)
--     :andThen(function(result)
--         warn("on to the next chain in the promise if resolved")
--     end)
--     :catch(function(result)
--         warn("promise rejected: ", result)
--     end)
--     :finally(function()
--         warn("This runs no matter the result of the promise")
--     end)


