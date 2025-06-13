local playerGui : PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui") :: PlayerGui
local gui : ScreenGui = playerGui:WaitForChild("RevampingInventory") :: ScreenGui
local MainInventory : Frame = gui:FindFirstChild("MainInventory") :: Frame
local StoreSection : ScrollingFrame = MainInventory:FindFirstChild("StoreSection") :: ScrollingFrame
local SearchTools = StoreSection:FindFirstChild("SearchTools")
local WearableSection : Frame = MainInventory:FindFirstChild("WearableSection") :: Frame
local ExternalStoreSection = MainInventory:FindFirstChild("ExternalStoreSection"):: Frame
local ExternalLabel = MainInventory:FindFirstChild("ExternalLabel"):: TextLabel
local PlayerLabel = MainInventory:FindFirstChild("PlayerLabel"):: TextLabel
local closeArea: Frame = gui:FindFirstChild("DropArea", true):: Frame
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ToggleOVerrideCamModeCursorLock = require(game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage.Components.ToggleOverrideCamModeCursorLock)

local LootingGuiManager = {}

local ClickedOutsideBindable = Instance.new("BindableEvent")
LootingGuiManager.ClickedOutside = ClickedOutsideBindable.Event

local function inCloseArea(): boolean
    local mousePos = UIS:GetMouseLocation()
    local guis = playerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y - GuiService:GetGuiInset().Y)
    local filteredGuis = {}

    for _, v in guis do 
        if v.Parent == gui and v.Name ~= "innerFrame" then
            table.insert(filteredGuis, v)
        end
    end

    if filteredGuis[1] == closeArea then 
        return true
    else
        return false
    end
end

local function inputAndAreaChecks(inputObject: InputObject)
    return (inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch) and inCloseArea()
end

local connection = UIS.InputBegan:Connect(function(io1: InputObject)  
    if inputAndAreaChecks(io1) then
        UIS.InputEnded:Once(function(io2: InputObject, a1: boolean)  
            if inputAndAreaChecks(io2) then
                ClickedOutsideBindable:Fire()
            end
        end)
    end
end)

LootingGuiManager.toggled = false

function LootingGuiManager.toggle(toggle: boolean, externalStoreName: string?)

    if LootingGuiManager.toggled == toggle then return end

    LootingGuiManager.toggled = toggle
    WearableSection.Visible = not toggle
    ExternalStoreSection.Visible = toggle
    ExternalLabel.Text = if externalStoreName then externalStoreName else ""
    ExternalLabel.Visible = toggle
    PlayerLabel.Visible = toggle
    SearchTools.Visible = not toggle
    MainInventory.Visible = toggle
    ToggleOVerrideCamModeCursorLock(toggle)
end

return LootingGuiManager