local ReplicatedStorage = game:GetService("ReplicatedStorage")
local rev_initializeShopGui : RemoteEvent = ReplicatedStorage:FindFirstChild("InitializeShopGui", true)
local rfn_getToolModel : RemoteFunction = ReplicatedStorage:FindFirstChild("GetToolModel", true)
local rev_giveItem : RemoteEvent = ReplicatedStorage:FindFirstChild("GiveItem", true)

local player = game:GetService("Players").LocalPlayer

local UIManager = require(ReplicatedStorage:FindFirstChild("UIManager", true))

local RunService = game:GetService("RunService")
local ViewportModel = require(ReplicatedStorage:FindFirstChild("ViewportModel", true)) --credit to EgoMoose

local playSound = require(ReplicatedStorage:FindFirstChild("PlaySoundUtil", true))

local shopGuiSFX : SoundGroup = game:GetService("SoundService").SoundStorage:FindFirstChild("Shop", true)
local menuOpen : Sound = shopGuiSFX["Synth Sparkle Tone High Pitch Tone Burst 4 (SFX)"]
local menuClose : Sound = shopGuiSFX["Synth Sparkle Tone High Pitch Tone Burst Din (SFX)"]
local itemSelect : Sound = shopGuiSFX["Button Click"]
local tabSelect : Sound = shopGuiSFX["GuiClick"]
local hover : Sound = shopGuiSFX["UI Hover"]
local purchaseError : Sound = shopGuiSFX.Error
local purchaseSuccess : Sound = shopGuiSFX["purchase/cashRegister"]

local shopUI : ScreenGui = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("ShopUI")
local itemFrame : ScrollingFrame = shopUI:FindFirstChild("Catalog", true)
local purchaseButton : TextButton = shopUI:FindFirstChild("Purchase", true)
local priceLabel : TextLabel = shopUI:FindFirstChild("Price", true)
local viewportFrame : ViewportFrame = shopUI:FindFirstChildWhichIsA("ViewportFrame", true)

local currentlySelectedItem : TextButton

local function setViewportObject(object : Model)
    local BIND_NAME = "revolvingViewportObject"

    local function resetViewportFrame()
        --resetting viewport frame
        RunService:UnbindFromRenderStep(BIND_NAME)
        for _, v in viewportFrame:GetChildren() do
            v:Destroy()
        end
    end

    if object == nil then
        resetViewportFrame()
    else
        resetViewportFrame()
            --initializing the new viewport object
        object.Parent = viewportFrame
        local camera = Instance.new("Camera")
        camera.FieldOfView = 70
        camera.Parent = viewportFrame
        viewportFrame.CurrentCamera = camera

            --viewport functionality
        local vpfModel = ViewportModel.new(viewportFrame, camera)
        local cf, size = object:GetBoundingBox()
        vpfModel:SetModel(object)
        local theta = 0
        local orientation = CFrame.new()
        local distance = vpfModel:GetFitDistance(cf.Position)
        RunService:BindToRenderStep(BIND_NAME, 200, function(dt)
            theta = theta + math.rad(20 * dt)
            orientation = CFrame.fromEulerAnglesYXZ(math.rad(-20), theta, 0)
            camera.CFrame = CFrame.new(cf.Position) * orientation * CFrame.new(0, 0, distance)
        end)
    end
end

local function singleSelectEffect(textButton : TextButton)
    local uiStroke : UIStroke = textButton:FindFirstChildOfClass("UIStroke")

    if uiStroke.Transparency == 0 then return end --this means the item is already selected

    for _, v in textButton.Parent:GetChildren() do
        if v:IsA("TextButton") then
            v:FindFirstChildOfClass("UIStroke").Transparency = 1
            v.BackgroundTransparency = 1
        end
    end
    uiStroke.Transparency = 0
    priceLabel.Text = tostring(textButton:GetAttribute("Price")) .. " Caps"
    purchaseButton.TextTransparency = 0
    textButton.BackgroundTransparency = 0.9
end

rev_initializeShopGui.OnClientEvent:Connect(function(param1 : TextButton | string)
    if param1 == "Completed" then
        local firstItemButton : TextButton = itemFrame:FindFirstChildOfClass("TextButton")
        currentlySelectedItem = firstItemButton
        singleSelectEffect(firstItemButton)
        local toolModel : Model = rfn_getToolModel:InvokeServer(firstItemButton.Name)
        setViewportObject(toolModel)
    else
        if param1.Parent:IsA("ScrollingFrame") then
            --for TextButtons in the Catalog frame; items to be selected & placed in the viewport frame
            param1.MouseButton1Down:Connect(function()
                if param1:FindFirstChildOfClass("UIStroke").Transparency == 0 then return end
                currentlySelectedItem = param1
                singleSelectEffect(param1)
                local toolModel : Model = rfn_getToolModel:InvokeServer(param1.Name)
                setViewportObject(toolModel)
            end)
        else
            --for TextButtons in the TypeTab frame for filtering items by type
    
            local itemCatalog : ScrollingFrame = shopUI:FindFirstChild("Catalog", true)
            local uiGradient : UIGradient = param1.Parent:FindFirstChildWhichIsA("UIGradient", true)
    
            param1.MouseButton1Down:Connect(function(inputObject : InputObject)
                if param1.BackgroundTransparency == 0.5 then return end --this means that the tab is already selected
        
                --visuals
                uiGradient.Parent.BackgroundTransparency = .9
                uiGradient.Parent = param1
                param1.BackgroundTransparency = 0.5
        
                local function setVisibilityOfAllItemOptions(isVisible : boolean)
                    for _, v in itemCatalog:GetChildren() do
                        if v:IsA("TextButton") and v.Name ~= "Template" then
                            v.Visible = isVisible
                        end
                    end
                end
        
                --functionality
                if param1.Name == "All" then
                    setVisibilityOfAllItemOptions(true)
                else
                    setVisibilityOfAllItemOptions(false)
                    for _, v in itemCatalog:GetChildren() do
                        if v:IsA("TextButton") and v:GetAttribute("Type") == param1.Name then
                            v.Visible = true
                        end
                    end
                end
            end)
        end
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

                local ableToBuy = player:GetAttribute("Caps") >= currentlySelectedItem:GetAttribute("Price")

                if ableToBuy then
                    playSound(purchaseSuccess, nil, 0)
                    rev_giveItem:FireServer(currentlySelectedItem.Name)
                else
                    playSound(purchaseError, nil, 0)
                    if priceLabel.TextColor3 == Color3.new(1, 0, 0) == false then
                        priceLabel.TextColor3 = Color3.new(1, 0, 0)
                        task.wait(0.1)
                        priceLabel.TextColor3 = Color3.new(1, 1, 1)
                    end
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
local exit : TextButton = shopUI:FindFirstChild("Exit", true)

local function handleShopTag(instance)
    print("shop tag detected")
    assert(instance:IsA("ProximityPrompt"), instance.Name .. " has the Shop tag but isn't a proximity prompt")

    instance.Triggered:Connect(function()
        if not shopUI.Enabled then
            shopUI.Enabled = true
            menuOpen:Play()
            instance.Enabled = false
            exit.Modal = true

            exit.MouseButton1Down:Once(function()
                if shopUI.Enabled then
                    shopUI.Enabled = false
                    menuClose:Play()
                    instance.Enabled = true
                    exit.Modal = false
                end
            end)

        end
    end)
end

local SHOP_TAG = "Shop"

local CollectionService = game:GetService("CollectionService")

for _, v in CollectionService:GetTagged(SHOP_TAG) do
    handleShopTag(v)
end

CollectionService:GetInstanceAddedSignal(SHOP_TAG):Connect(function(instance)
    handleShopTag(instance)
end)
