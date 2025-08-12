local Catalog = {}

-- One problem in the future I see is that if there are many effects that affect the same thing, then this snapshot system may not work as intended
local snapshots = {

}

Catalog.Buffs = {
    Invincibility = function(char: Model)

    end,
    Invisibility = function(char: Model)
        if not snapshots[char] then
            snapshots[char] = nil
        end

        for _, v in char:GetDescendants() do
            if v:IsA("BasePart") or v:IsA("Decal") then
                v.Transparency = 1
            end
        end
    end
}

Catalog.Debuffs = {

}

return Catalog