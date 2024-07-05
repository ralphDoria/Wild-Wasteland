local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local rfn_getShirtTemplateId :RemoteFunction = ReplicatedStorage:WaitForChild("getShirtTemplateId")

rfn_getShirtTemplateId.OnServerInvoke = function(player, shirtAssetId)
    local model = InsertService:LoadAsset(shirtAssetId)
    local shirtTemplateId = model:FindFirstChildOfClass("Shirt").ShirtTemplate
    model:Destroy()
    return shirtTemplateId
end