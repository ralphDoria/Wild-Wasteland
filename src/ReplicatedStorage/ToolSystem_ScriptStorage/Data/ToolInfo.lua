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
            activate = nvGoggles.Sounds.activate,
            offSwitch = nvGoggles.Sounds.offSwitch,
            onSwitch = nvGoggles.Sounds.onSwitch,
            equip = nvGoggles.Sounds.equip,
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

return ToolInfo