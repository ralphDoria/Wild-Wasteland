--!strict
local References_ItemSystem = {}

-- General Services and Player References
local ReplicatedStorage = game:GetService("ReplicatedStorage")
References_ItemSystem.RunService = game:GetService("RunService")
References_ItemSystem.player = game:GetService("Players").LocalPlayer
local ItemSystem_ScriptStorage = ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage
References_ItemSystem.ItemSystem_ScriptStorage = ItemSystem_ScriptStorage
local ItemSystem_Storage = ReplicatedStorage.ItemSystem_Storage
References_ItemSystem.ItemSystem_Storage = ItemSystem_Storage
local SharedComponents = ItemSystem_ScriptStorage.Classes.Components.Shared

-- per client fields
References_ItemSystem.ToolInfo = require(ItemSystem_ScriptStorage.Data.ToolInfo)
References_ItemSystem.ItemHUD = require(SharedComponents.ItemHUD)
References_ItemSystem.ActionManager = require(ReplicatedStorage.RojoManaged_RS.ActionManagerSystem.ActionManager)
References_ItemSystem.CrosshairGuiManager = require(SharedComponents.CrosshairManager)
    References_ItemSystem.crosshairGuiObject = References_ItemSystem.CrosshairGuiManager.new()
    References_ItemSystem.CrosshairGuiManager.toggleCrosshairLines(References_ItemSystem.crosshairGuiObject, false)
References_ItemSystem.Trove = require(ReplicatedStorage.Packages.Trove)
References_ItemSystem.playSound = require(ReplicatedStorage.RojoManaged_RS.Utility.PlaySoundUtil) -- remote event version of this is below under the networking section

-- per item modules
References_ItemSystem.ToolPromptManager = require(SharedComponents.ToolPromptManager)

-- Networking (bindables & Remotes)
    -- bindables
local bindables = ItemSystem_Storage.Shared.Bindables
References_ItemSystem.bindables = {
    ToggleEquip = bindables.ToggleEquip:: BindableEvent,
    OnPickUp = bindables.OnPickUp:: BindableEvent,
    DropToolBindable = bindables.DropToolBindable:: BindableEvent,
    ImmediateUnequip = bindables.ImmediateUnequip:: BindableEvent,
}
    -- remotes
local remotes = ItemSystem_Storage.Shared.Remotes
References_ItemSystem.remotes = {
    ToggleToolCanCollide = remotes.ToggleToolCanCollide:: RemoteEvent,
    DropTool = remotes.DropTool:: RemoteEvent,
    PlaySound = ItemSystem_Storage.Shared.Remotes.PlaySound:: RemoteEvent
}

-- per character modules
References_ItemSystem.character = nil:: any
References_ItemSystem.humanoid = nil:: any
local ToolAnimationManager = require(SharedComponents.ToolAnimationManager)
References_ItemSystem.ToolAnimationManager = ToolAnimationManager
local ViewmodelManaer = require(SharedComponents.ViewmodelManager)
References_ItemSystem.ViewmodelManager = ViewmodelManaer
References_ItemSystem.animationManagerObject = nil:: ToolAnimationManager.AnimationManager
References_ItemSystem.viewmodelManagerObject = nil:: ViewmodelManaer.ViewmodelManager


local updatedEvent = Instance.new("BindableEvent")
References_ItemSystem.updated = updatedEvent.Event:: RBXScriptSignal

function References_ItemSystem.update(character: Model)
    References_ItemSystem.character = character
    References_ItemSystem.humanoid = character:WaitForChild("Humanoid")
    References_ItemSystem.animator = References_ItemSystem.humanoid:WaitForChild("Animator")
    References_ItemSystem.animationManagerObject = References_ItemSystem.ToolAnimationManager.new(character)
    References_ItemSystem.viewmodelManagerObject = References_ItemSystem.ViewmodelManager.new(workspace.CurrentCamera:WaitForChild("Viewmodel"))

    References_ItemSystem.humanoid.Died:Once(function()
        -- Destroy animationManager & viewmodelManager objects
        References_ItemSystem.ToolAnimationManager.Destroy(References_ItemSystem.animationManagerObject)
        References_ItemSystem.ViewmodelManager.Destroy(References_ItemSystem.viewmodelManagerObject)
    end)

    updatedEvent:Fire()
end

return References_ItemSystem