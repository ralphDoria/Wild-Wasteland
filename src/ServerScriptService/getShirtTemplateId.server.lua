local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local rfn_getShirtTemplateId :RemoteFunction = ReplicatedStorage:WaitForChild("getShirtTemplateId")

rfn_getShirtTemplateId.OnServerInvoke = function(player, shirtAssetId)
    local model = InsertService:LoadAsset(shirtAssetId)
    model.Parent = workspace
    local shirtTemplateId = model:FindFirstChildOfClass("Shirt").ShirtTemplate
    return shirtTemplateId
end