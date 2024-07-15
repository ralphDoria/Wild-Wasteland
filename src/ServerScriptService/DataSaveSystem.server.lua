local Players = game:GetService("Players")

local DataStoreService = game:GetService("DataStoreService")
local DATA_CAPS = "PlayerCaps"
local PlayerCaps = DataStoreService:GetDataStore(DATA_CAPS)

Players.PlayerRemoving:Connect(function(player)
    print("checkpoint 1")
    if player:GetAttribute("Caps") then
        print("checkpoint 2")
        local wasSuccess, errorMessage = pcall(function()
            PlayerCaps:SetAsync(player.UserId, player:GetAttribute("Caps"))
        end)
        if not wasSuccess then
            print(errorMessage)
        else
            print("saved successfully")
        end 
    end
end)  