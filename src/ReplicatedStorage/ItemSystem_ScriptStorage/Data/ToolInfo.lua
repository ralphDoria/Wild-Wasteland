--!strict

export type ToolInfo = {
    animObjects : {[string] : Animation},
    soundObjects : {any}
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
local m9 = ToolCatalog["M9"]

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
    [lightBullets.Name] = {
        animObjects = {
            equip = lightBullets.Anims.equip,
            idle = lightBullets.Anims.idle,
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
    [m9.Name] = {
        animObjects = {
            equip = m9.Anims.equip,
            idle = m9.Anims.idle,
            sprint = m9.Anims.sprint,
            reload = m9.Anims.reload,
            hipfire = m9.Anims.hipfire,
            viewmodelFire = m9.Anims.viewmodelFire,
            ADS_transition = m9.Anims.ADS_transition,
            ADS_idle = m9.Anims.ADS_idle,
            ADS_shoot = m9.Anims.ADS_shoot,
            ADS_viewmodelShoot = m9.Anims.ADS_viewmodelShoot,
        },
        soundObjects = {
            unequip = m9.Sounds.unequip,
            shoot = m9.Sounds.shoot,
            dryFire = m9.Sounds.dryFire,
            ADS_in = m9.Sounds.ADS_in,
            ADS_out = m9.Sounds.ADS_out,
            reload = {
                magIn = m9.Sounds.reload.magIn,
                magOut = m9.Sounds.reload.magIn,
                magTap = m9.Sounds.reload.magTap,
                slideBack = m9.Sounds.reload.slideBack,
                slideRelease = m9.Sounds.reload.slideRelease,
            },
            bulletImpact = {
                flesh = { -- array
                    m9.Sounds.bulletImpact.flesh.variant1,
                    m9.Sounds.bulletImpact.flesh.variant2,
                    m9.Sounds.bulletImpact.flesh.variant3,
                    m9.Sounds.bulletImpact.flesh.variant4,
                },
                hardSurface = {
                    m9.Sounds.bulletImpact.hardSurface.variant1,
                    m9.Sounds.bulletImpact.hardSurface.variant2,
                    m9.Sounds.bulletImpact.hardSurface.variant3,
                    m9.Sounds.bulletImpact.hardSurface.variant4,
                }
            },
            drop = {
                hard = healingInjection.Sounds.drop.hard,
                soft = healingInjection.Sounds.drop.soft
            }
        }
    }
}

function ToolInfo.get(toolName : string) : ToolInfo
    for key, v in catalog do
        if key == toolName then
            return v
        end
    end
    error(toolName .. " not found in ToolInfo catalog")
end

function ToolInfo.soundSearch(soundTable: {any}, targetSoundName: string): Sound?
    for index, v in soundTable do
        if typeof(v) == "Instance" and v:IsA("Sound") and v.Name == targetSoundName then
            return v
        elseif typeof(v) == "table" then
            local found = ToolInfo.soundSearch(v, targetSoundName)
            if found then
                return found
            else
                continue
            end
        end
    end
    return nil
end

function ToolInfo.getSound(toolName: string, soundName: string): Sound?
    local toolFolder = ToolCatalog:FindFirstChild(toolName)
    if toolFolder then
        local soundsFolder = toolFolder:FindFirstChild("Sounds")
        if soundsFolder then
            local targetSound = soundsFolder:FindFirstChild(soundName, true)
            return targetSound
        else
            warn(`Couldn't find {soundName} of {toolName}: soundsFolder not found.`)
            return nil
        end
    else
        warn(`Couldn't find {soundName} of {toolName}: {toolName} not found in ToolCatalog.`)
        return nil
    end
end

return ToolInfo