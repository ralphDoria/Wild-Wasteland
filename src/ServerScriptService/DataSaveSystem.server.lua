local Players = game:GetService("Players")

local DataStoreService = game:GetService("DataStoreService")
local DATA_CAPS = "PlayerCaps"
local PlayerCaps = DataStoreService:GetDataStore(DATA_CAPS)

Players.PlayerRemoving:Connect(function(player)
    print("Detected that " .. player.Name .. " is leaving")
    if player:GetAttribute("Caps") then
        print("Found Caps stat to save")
        local wasSuccess, errorMessage = pcall(function()
            PlayerCaps:SetAsync(player.UserId, player:GetAttribute("Caps"))
        end)
        if not wasSuccess then
            print(errorMessage)
        else
            print("saved caps successfully")
        end 
    end
end)  