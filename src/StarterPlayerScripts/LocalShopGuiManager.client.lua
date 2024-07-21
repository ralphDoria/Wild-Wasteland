local ReplicatedStorage = game:GetService("ReplicatedStorage")
local rev_initializeShopGui : RemoteEvent = ReplicatedStorage:FindFirstChild("InitializeShopGui", true)
local rfn_getToolModel : RemoteFunction = ReplicatedStorage:FindFirstChild("GetToolModel", true)

local player = game:GetService("Players").LocalPlayer

local RunService = game:GetService("RunService")
local ViewportModel = require(ReplicatedStorage:FindFirstChild("ViewportModel", true)) --credit to EgoMoose

local playSound = require(ReplicatedStorage:FindFirstChild("PlaySoundUtil", true))

local shopGuiSFX : SoundGroup = game:GetService("SoundService").ShopGuiSFX
local menuOpen : Sound = shopGuiSFX["Synth Sparkle Tone High Pitch Tone Burst 4 (SFX)"]
local menuClose : Sound = shopGuiSFX["Synth Sparkle Tone High Pitch Tone Burst Din (SFX)"]
local itemSelect : Sound = shopGuiSFX["Button Click"]
local tabSelect : Sound = shopGuiSFX["GuiClick"]
local hover : Sound = shopGuiSFX["UI Hover"]
local purchaseError : Sound = shopGuiSFX.Error
local purchaseSuccess : Sound = shopGuiSFX["purchase/cashRegister"]

local shopUI : ScreenGui = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("ShopUI")
local purchaseButton : TextButton = shopUI:FindFirstChild("Purchase", true)
local priceLabel : TextLabel = shopUI:FindFirstChild("Price", true)

rev_initializeShopGui.OnClientEvent:Connect(function(textButton : TextButton)

    if textButton.Parent:IsA("ScrollingFrame") then
        --for TextButtons in the Catalog frame; items to be selected & placed in the viewport frame

        local uiStroke : UIStroke = textButton:FindFirstChildOfClass("UIStroke")
        --options frame

        textButton.MouseButton1Down:Connect(function()
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

        textButton.MouseButton1Down:Connect(function(inputObject : InputObject)
            if textButton.BackgroundTransparency == 0.5 then return end --this means that the tab is already selected
    
            --visuals
            uiGradient.Parent.BackgroundTransparency = .9
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

--connecting gui sound effects
for _, v in shopUI:GetDescendants() do
    if v:IsA("TextButton") then
        v.MouseEnter:Connect(function()
            playSound(hover, nil, 0)
        end)

        if v.Parent:IsA("ScrollingFrame") then
            v.MouseButton1Down:Connect(function()
                playSound(itemSelect, nil, 0)
            end)
        elseif v.Name == "Purchase" then
            v.MouseButton1Down:Connect(function()

                local ableToBuy = false --for testing purposes

                if ableToBuy then
                    playSound(purchaseSuccess, nil, 0)
                else
                    playSound(purchaseError, nil, 0)
                end
            end)
        else
            v.MouseButton1Down:Connect(function()
                playSound(tabSelect, nil, 0)
            end)
        end
    end
end

shopUI.Enabled = false
for _, v in game:GetService("CollectionService"):GetTagged("Shop") do
    assert(v:IsA("ProximityPrompt"), v.Name .. " has the Shop tag but isn't a proximity prompt")

    v.Triggered:Connect(function()
        if not shopUI.Enabled then
            shopUI.Enabled = true
            menuOpen:Play()
            v.Enabled = false

            shopUI:FindFirstChild("Exit", true).MouseButton1Down:Once(function()
                print("exitting")
                if shopUI.Enabled then
                    shopUI.Enabled = false
                    menuClose:Play()
                    v.Enabled = true
                end
            end)

        end
    end)
end