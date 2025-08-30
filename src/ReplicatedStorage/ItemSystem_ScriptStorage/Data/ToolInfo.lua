--!strict

export type ToolInfo = {
    animObjects : {[string] : Animation},
    soundObjects : {[string] : (Sound | {[string] : Sound})}
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolCatalog = ReplicatedStorage:FindFirstChild("ToolCatalog", true)

local barbedBat = ToolCatalog["Barbed Bat"]
local healingInjection = ToolCatalog["Healing Injection"]
local nvGoggles = ToolCatalog["NV Goggles"]
local raiderAxe = ToolCatalog["Raider Axe"]
local bloxyColaCaps = ToolCatalog["Bloxy Cola Caps"]
local backpack = ToolCatalog["Backpack"]
local lightBullets = ToolCatalog["Light Bullets"]

local ToolInfo = {}

local catalog : {[string] : ToolInfo} = {
    [barbedBat.Name] = {
        animObjects = {
            equip = barbedBat.Anims.equip,
            idle = barbedBat.Anims.idle,
            swing = barbedBat.Anims.swing
        },
        soundObjects = {
            swing = barbedBat.Sounds.swing,
            equip = barbedBat.Sounds.equip,
            drop = {
                hard = barbedBat.Sounds.drop.hard,
                soft = barbedBat.Sounds.drop.soft
            },
            impact = {
                flesh = barbedBat.Sounds.impact.flesh,
                metal = barbedBat.Sounds.impact.metal
            }
        }
    },
    [healingInjection.Name] = {
        animObjects = {
            equip = healingInjection.Anims.equip,
            idle = healingInjection.Anims.idle,
            activate = healingInjection.Anims.activate   
        },
        soundObjects = {
            equip = healingInjection.Sounds.equip,
            drop = {
                hard = healingInjection.Sounds.drop.hard,
                soft = healingInjection.Sounds.drop.soft
            },
            needle = {
                inject = healingInjection.Sounds.needle.inject,
                insert = healingInjection.Sounds.needle.insert,
                remove = healingInjection.Sounds.needle:FindFirstChild("remove")
            },
            singleHeartbeat = healingInjection.Sounds.singleHeartbeat
        }
    },
    [nvGoggles.Name] = {
        animObjects = {
            equip = nvGoggles.Anims.equip,
            idle = nvGoggles.Anims.idle,
            wear = nvGoggles.Anims.wear
        },
        soundObjects = {
            nightVision = nvGoggles.Sounds.activate,
            offSwitch = nvGoggles.Sounds.offSwitch,
            onSwitch = nvGoggles.Sounds.onSwitch,
            equip = nvGoggles.Sounds.equip,
            drop = {
                hard = healingInjection.Sounds.drop.hard,
                soft = healingInjection.Sounds.drop.soft
            }
        }
    },
    [raiderAxe.Name] = {
        animObjects = {
            equip = raiderAxe.Anims.equip,
            idle = raiderAxe.Anims.idle,
            swing = raiderAxe.Anims.swing
        },
        soundObjects = {
            swing = raiderAxe.Sounds.swing,
            equip = raiderAxe.Sounds.equip,
            drop = {
                hard = raiderAxe.Sounds.drop.hard,
                soft = raiderAxe.Sounds.drop.soft
            },
            impact = {
                flesh = raiderAxe.Sounds.impact.flesh,
                metal = raiderAxe.Sounds.impact.metal,
                dirt = raiderAxe.Sounds.impact.dirt
            }
        }
    },
    [bloxyColaCaps.Name] = {
        animObjects = {
            equip = bloxyColaCaps.Anims.equip,
            idle = bloxyColaCaps.Anims.idle,
        },
        soundObjects = {
            equip = bloxyColaCaps.Sounds.equip,
            unequip = bloxyColaCaps.Sounds.unequip,
            move = {
                ["1"] = bloxyColaCaps.Sounds.move.move1,
                ["2"] = bloxyColaCaps.Sounds.move.move2,
                ["3"] = bloxyColaCaps.Sounds.move.move3,
                ["4"] = bloxyColaCaps.Sounds.move.move4

            },
            drop = {
                hard = bloxyColaCaps.Sounds.unequip,
                soft = bloxyColaCaps.Sounds.unequip
            },
        }
    },
    [backpack.Name] = {
        animObjects = {
            equip = backpack.Anims.equip,
            idle = backpack.Anims.idle,
            wear = backpack.Anims.wear
        },
        soundObjects = {
            equip = backpack.Sounds.equip,
            unequip = backpack.Sounds.unequip,
            wear = backpack.Sounds.wear,
            unwear = backpack.Sounds.unwear,
            drop = {
                hard = backpack.Sounds.drop,
                soft = backpack.Sounds.drop
            },
            openLootable = backpack.Sounds.openLootable,
            closeLootable = backpack.Sounds.closeLootable
        }
    },
    -- [lightBullets.Name] = {
    --     animObjects = {
    --         equip = capStash.Anims.equip,
    --         idle = capStash.Anims.idle,
    --     },
    --     soundObjects = {
    --         equip = lightBullets.Sounds.equip,
    --         unequip = lightBullets.Sounds.unequip,
    --         drop = {
    --             hard = lightBullets.Sounds.unequip,
    --             soft = lightBullets.Sounds.unequip
    --         },
    --     }
    -- }
}

function ToolInfo.get(toolName : string) : ToolInfo
    for key, v in catalog do
        if key == toolName then
            return v
        end
    end
    error(toolName .. " not found in ToolInfo catalog")
end

return ToolInfo