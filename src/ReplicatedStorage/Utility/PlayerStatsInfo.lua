local PlayerStatsInfo = {
    ATTRIBUTE_CAPS = {
        name = "Caps",
        icon = "rbxassetid://18384549702"
    },
    ATTRIBUTE_LIGHT_BULLETS = {
        name = "LightBullets", --this is for getting/setting a player's attribute & the name of the DataStore
        icon = "http://www.roblox.com/asset/?id=18506827412"
    },
    ATTRIBUTE_MEDIUM_BULLETS = {
        name = "MediumBullets",
        icon = "http://www.roblox.com/asset/?id=18506830649"
    },
    ATTRIBUTE_HEAVY_BULLETS = {
        name = "HeavyBullets",
        icon = "http://www.roblox.com/asset/?id=18506834591"
    },
    ATTRIBUTE_SHELLS = {
        name = "Shells",
        icon = "http://www.roblox.com/asset/?id=18506837756"
    },
    ATTRIBUTE_ENERGY_AMMO = {
        name = "EnergyAmmo",
        icon = "http://www.roblox.com/asset/?id=18507047762"
    },
    -- Progression stat (XPService) — persisted like the others but NOT a world pickup,
    -- so it is deliberately absent from getAll()/getAmmo() (no icon, no pickup wiring).
    ATTRIBUTE_XP = {
        name = "XP"
    }
}

function PlayerStatsInfo.getAll()
    return {
        PlayerStatsInfo.ATTRIBUTE_CAPS,
        PlayerStatsInfo.ATTRIBUTE_LIGHT_BULLETS,
        PlayerStatsInfo.ATTRIBUTE_MEDIUM_BULLETS,
        PlayerStatsInfo.ATTRIBUTE_HEAVY_BULLETS,
        PlayerStatsInfo.ATTRIBUTE_SHELLS,
        PlayerStatsInfo.ATTRIBUTE_ENERGY_AMMO
    }
end

-- Every stat DataSaveSystem persists: the pickup stats plus progression-only stats.
function PlayerStatsInfo.getPersisted()
    local stats = PlayerStatsInfo.getAll()
    table.insert(stats, PlayerStatsInfo.ATTRIBUTE_XP)
    return stats
end

function PlayerStatsInfo.getAmmo()
    return {
        PlayerStatsInfo.ATTRIBUTE_LIGHT_BULLETS,
        PlayerStatsInfo.ATTRIBUTE_MEDIUM_BULLETS,
        PlayerStatsInfo.ATTRIBUTE_HEAVY_BULLETS,
        PlayerStatsInfo.ATTRIBUTE_SHELLS,
        PlayerStatsInfo.ATTRIBUTE_ENERGY_AMMO
    }
end

return PlayerStatsInfo