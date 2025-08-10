local Players = game:GetService("Players")

local function handleCharacter(char: Model)
    if not char then
        return --end function here because CharacterAdded connection will handle it from here 
    end
    local humanoid: Humanoid = char:WaitForChild("Humanoid"):: Humanoid
    local hrp = char:WaitForChild("HumanoidRootPart")
    humanoid.Died:Once(function()  
    end)        
end

local player = Players.LocalPlayer

player:LoadCharacter()