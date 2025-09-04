local pbrPartsFolder: Folder = workspace["Sci Fi Building"].TexturePallete

for _, part in pbrPartsFolder:GetChildren() do
    if not part:IsA("BasePart") then continue end
    local materialVariant = part.MaterialVariant
    part.Material = Enum.Material.Metal
    part.MaterialVariant = materialVariant
end
