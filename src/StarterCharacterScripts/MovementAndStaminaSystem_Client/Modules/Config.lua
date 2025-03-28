type speed = {[string]: number}
type toggle = {[string]: boolean?}
type cooldownTime = {[string]: number?}
type config = {speed: speed, toggle: toggle, cooldownTime: cooldownTime}

local config: config = {
    speed = {
        ["Sprint"] = 20,
        ["Crouch"] = 3,
        ["Default"] = game:GetService("StarterPlayer").CharacterWalkSpeed
    },
    toggle = {
        ["Jump"] = nil, -- If toggle[actionName] == nil, then the button's behavior is set to hold.
        ["Sprint"] = false, -- If toggle[actionName] ~= nil, then its setting the intial toggle state.
        ["Crouch"] = false 
    },
    cooldownTime = {
        ["Jump"] = 1,
    }
}

return config