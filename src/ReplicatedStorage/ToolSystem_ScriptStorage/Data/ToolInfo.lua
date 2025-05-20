--!strict

export type ToolInfo = {
    animObjects : {[string] : Animation},
    soundObjects : {[string] : (Sound | {[string] : Sound})}
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local source = ReplicatedStorage:FindFirstChild("ToolCatalog", true)

local barbedBat = source["Barbed Bat"]
local healingInjection = source["Healing Injection"]

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