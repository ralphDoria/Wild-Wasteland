--Credit to QweekerTom

local ModuleLoader = {}
local CachedModules = {}

function ModuleLoader.Get<T>(name: string): T
    return CachedModules[name]
end

function ModuleLoader._Init(scripts)
    for _, modscript in scripts do
        if not modscript:IsA("ModuleScript") then continue end
        local mod = require(modscript)
        CachedModules[modscript.Name] = mod
    end
end

function ModuleLoader._Start()
    for _, module in CachedModules do
        if module.start then
            module.start()
        end
    end
end

-- Make Get available globally
shared.Get = ModuleLoader.Get

return ModuleLoader