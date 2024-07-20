local ReplicatedStorage = game:GetService("ReplicatedStorage")
local rev_initializeShopGui : RemoteEvent = ReplicatedStorage:FindFirstChild("InitializeShopGui", true)
local rfn_getToolModel : RemoteFunction = ReplicatedStorage:FindFirstChild("GetToolModel", true)

local RunService = game:GetService("RunService")
local ViewportModel = require(ReplicatedStorage:FindFirstChild("ViewportModel", true)) --credit to EgoMoose

local shopUI : ScreenGui = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("ShopUI")

rev_initializeShopGui.OnClientEvent:Connect(function(textButton : TextButton)

    if textButton.Parent:IsA("ScrollingFrame") then
        --for TextButtons in the Catalog frame; items to be selected & placed in the viewport frame

        local uiStroke : UIStroke = textButton:FindFirstChildOfClass("UIStroke")
        --options frame
        local purchaseButton : TextButton = shopUI:FindFirstChild("Purchase", true)
        local priceLabel : TextLabel = shopUI:FindFirstChild("Price", true)

        textButton.Activated:Connect(function()
            if uiStroke.Transparency == 0 then return end --this means the item is already selected

            --visuals
            for _, v in textButton.Parent:GetChildren() do
                if v:IsA("TextButton") then
                    v:FindFirstChildOfClass("UIStroke").Transparency = 1
                end
            end
            uiStroke.Transparency = 0
            priceLabel.Text = tostring(textButton:GetAttribute("Price")) .. " Caps"
            purchaseButton.TextTransparency = 0

            --functionality
            local viewportFrame : ViewportFrame = shopUI:FindFirstChildOfClass("ViewportFrame")
            local toolModel : Model = rfn_getToolModel:InvokeServer(textButton.Name)

                --resetting viewport frame
            RunService:UnbindFromRenderStep("revolvingViewportObject")
            for _, v in viewportFrame:GetChildren() do
                v:Destroy()
            end

                --initializing the new viewport object
            toolModel.Parent = viewportFrame
            local camera = Instance.new("Camera")
            camera.FieldOfView = 70
            camera.Parent = viewportFrame
            viewportFrame.CurrentCamera = camera

                --viewport functionality
            local vpfModel = ViewportModel.new(viewportFrame, camera)
            local cf, size = toolModel:GetBoundingBox()
            vpfModel:SetModel(toolModel)
            local theta = 0
            local orientation = CFrame.new()
            local distance = vpfModel:GetFitDistance(cf.Position)
            RunService:BindToRenderStep("revolvingViewportObject", 200, function(dt)
                theta = theta + math.rad(20 * dt)
                orientation = CFrame.fromEulerAnglesYXZ(math.rad(-20), theta, 0)
                camera.CFrame = CFrame.new(cf.Position) * orientation * CFrame.new(0, 0, distance)
            end)

        end)
    else
        --for TextButtons in the TypeTab frame for filtering items by type

        local itemCatalog : ScrollingFrame = shopUI:FindFirstChild("Catalog", true)
        local uiGradient : UIGradient = textButton.Parent:FindFirstChildWhichIsA("UIGradient", true)

        textButton.Activated:Connect(function(inputObject : InputObject)
            if textButton.BackgroundTransparency == 0.5 then return end --this means that the tab is already selected
    
            --visuals
            uiGradient.Parent.BackgroundTransparency = 1
            uiGradient.Parent = textButton
            textButton.BackgroundTransparency = 0.5
    
            local function setVisibilityOfAllItemOptions(isVisible : boolean)
                for _, v in itemCatalog:GetChildren() do
                    if v:IsA("TextButton") and v.Name ~= "Template" then
                        v.Visible = isVisible
                    end
                end
            end
    
            --functionality
            if textButton.Name == "All" then
                setVisibilityOfAllItemOptions(true)
            else
                setVisibilityOfAllItemOptions(false)
                for _, v in itemCatalog:GetChildren() do
                    if v:IsA("TextButton") and v:GetAttribute("Type") == textButton.Name then
                        v.Visible = true
                    end
                end
            end
        end)
    end
end)

for _, v in game:GetService("CollectionService"):GetTagged("Shop") do
    assert(v:IsA("ProximityPrompt"), v.Name .. " has the Shop tag but isn't a proximity prompt")

    v.Triggered:Connect(function()
        if not shopUI.Enabled then
            shopUI.Enabled = true
            v.Enabled = false

            shopUI:FindFirstChild("Exit", true).Activated:Once(function()
                print("exitting")
                if shopUI.Enabled then
                    shopUI.Enabled = false
                    v.Enabled = true
                end
            end)

        end
    end)
end