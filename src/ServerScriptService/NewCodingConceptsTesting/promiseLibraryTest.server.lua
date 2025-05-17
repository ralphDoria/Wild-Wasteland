-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Promise = require(ReplicatedStorage:FindFirstChild("Promise", true))

-- local promise = Promise.new(function(resolve : (number?) -> (), reject :  (string?) -> (), onCancel :  () -> ())
--     local success, result = pcall(function()  
--         local coinflip : number = math.random(0, 2)
--         if coinflip == 0 then
--             error("coinflip 0 error")
--         else
--             warn("coinflip 1 success")
--             return 10
--         end
--     end)

--     if success then
--         resolve(result)
--     else
--         reject(result)
--     end
-- end)

-- promise
--     :andThen(function(result)
--         warn("promise resolved: ", result)
--     end)
--     :catch(function(result)
--         warn("promise rejected: ", result)
--     end)
