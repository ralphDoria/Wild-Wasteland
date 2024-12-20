local humanoidFinder = {}

humanoidFinder.humanoidTable = {}

--[[
    !!ONLY RUN THIS ONCE TO AVOID CONNECTING MULTIPLE EVENTS. THIS FUNCTIONS CONNECTS AN EVENT THAT'LL ADD ALL HUMANOIDS THAT ARE 
    ADDED AFTER IT CHECKS WORKSPACE.
]]
function humanoidFinder.findHumanoids(parent)
    for _, child in ipairs(parent:GetDescendants()) do
        local humanoid = child:FindFirstChildWhichIsA("Humanoid", true)
        table.insert(humanoidFinder.humanoidTable, humanoid) -- Add the humanoid to the table
    end

    workspace.ChildAdded:Connect(function(child)
        if child:IsA("Model") and child:FindFirstChild("Humanoid") then
            local humanoid = child:FindFirstChild("Humanoid")
            if humanoid then
                --print("adding " .. child.Name .. "'s humanoid to the table")
                table.insert(humanoidFinder.humanoidTable, humanoid) -- Add the humanoid to the table
            end
        end
    end)
end

return humanoidFinder