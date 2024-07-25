local DialogInfo : Folder = script.Parent:FindFirstChild("DialogInfo")

return function(characterName : string)
    return DialogInfo[characterName]
end