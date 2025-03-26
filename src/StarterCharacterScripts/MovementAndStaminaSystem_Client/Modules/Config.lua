return {
    actionNames = {
        "Sprint",
        "Crouch"
    },
    keycodes = {
        sprint = {
            Enum.KeyCode.LeftShift,
            Enum.KeyCode.ButtonL3
        },
        crouch = {
            Enum.KeyCode.C,
            Enum.KeyCode.ButtonB
        }
    },
    speeds = {
        walk = game:GetService("StarterPlayer").CharacterWalkSpeed,
        sprint = 16,
        crouch = 3
    },
    toggle = {
        sprint = false,
        crouch = false
    }
}