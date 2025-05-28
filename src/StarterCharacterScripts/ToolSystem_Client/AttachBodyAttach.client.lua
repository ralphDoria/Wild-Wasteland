--[[
    !!!
    Let me not speak too soon, but this should fix the teleporting tool bug.
    This happens on the server to, this is just necessary for visual effects to prevent what's states above.
]]

local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

character.ChildAdded:Connect(function(child)
    if child:IsA("Tool") and child:FindFirstChild("BodyAttach", true) then
		local bodyAttachJoint : Motor6D = character:FindFirstChild("BodyAttachJoint", true)
        local bodyAttach : BasePart = child:FindFirstChild("BodyAttach", true)
        if bodyAttachJoint and bodyAttach then
            bodyAttachJoint.Part1 = bodyAttach
        else
            warn("Unable to attach tool to character: BodyAttachJoint or BodyAttach not found")
        end
	end
end)