local Players = game:GetService("Players")

local DataStoreService = game:GetService("DataStoreService")

local DATA_CAPS = "PlayerCaps"
local PlayerCaps = DataStoreService:GetDataStore(DATA_CAPS)

local ATTRIBUTE_LIGHT_BULLETS = "LightBullets"
local ATTRIBUTE_MEDIUM_BULLETS = "MediumBullets"
local ATTRIBUTE_HEAVY_BULLETS = "HeavyBullets"
local ATTRIBUTE_SHELLS = "Shells"
local ATTRIBUTE_ENERGY_AMMO = "EnergyAmmo"
local ammoAttributes = {ATTRIBUTE_LIGHT_BULLETS, ATTRIBUTE_MEDIUM_BULLETS, ATTRIBUTE_HEAVY_BULLETS, ATTRIBUTE_SHELLS, ATTRIBUTE_ENERGY_AMMO}

local DATA_LIGHT_BULLETS = "PlayerLightBullets"
local DATA_MEDIUM_BULLETS = "PlayerMediumBullets"
local DATA_HEAVY_BULLETS = "PlayerHeavyBullets"
local DATA_SHELLS = "PlayerShells"
local DATA_ENERGY_AMMO = "PlayerEnergyAmmo"
local DataStores = {
    [ATTRIBUTE_LIGHT_BULLETS] = DataStoreService:GetDataStore(DATA_LIGHT_BULLETS), 
    [ATTRIBUTE_MEDIUM_BULLETS] = DataStoreService:GetDataStore(DATA_MEDIUM_BULLETS), 
    [ATTRIBUTE_HEAVY_BULLETS] = DataStoreService:GetDataStore(DATA_HEAVY_BULLETS),
    [ATTRIBUTE_SHELLS] = DataStoreService:GetDataStore(DATA_SHELLS), 
    [ATTRIBUTE_ENERGY_AMMO] = DataStoreService:GetDataStore(DATA_ENERGY_AMMO)
}

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
            print("--- saved caps successfully")
        end 
    end

    for _, attribute in ammoAttributes do
        if player:GetAttribute(attribute) then
            print("Found" .. attribute .. " stat to save")
            local wasSuccess, errorMessage = pcall(function()
                DataStores[attribute]:SetAsync(player.UserId, player:GetAttribute(attribute))
            end)
            if not wasSuccess then
                print(errorMessage)
            else
                print("--- saved" .. attribute .. " successfully")
            end 
        end
    end
end)  