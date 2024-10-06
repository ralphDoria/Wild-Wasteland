--! This is like a grandfather class if each of the item types are parent classes

--CONSTANTS
local Constants = {
    KEYBOARD_DROP_TOOL_KEY_CODE = Enum.KeyCode.X,
    ACTION_DROP_TOOL = "Dropped"
}
--LOCAL VARIABLES
local Players = game:GetService("Players")
local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
--SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
--EXTERNAL CONTROLLERS
local AnimationController = require(ReplicatedStorage:FindFirstChild("AnimationController", true))
local ViewmodelController = require(ReplicatedStorage:FindFirstChild("ViewModelController", true))
--REMOTE EVENTS
local rev_playSound = ReplicatedStorage.Tools.Shared:FindFirstChild("PlaySound", true)
local rev_dropTool = ReplicatedStorage.Tools.Shared:FindFirstChild("DropTool", true)

local ItemTemplate = {}
ItemTemplate.__index = ItemTemplate

function ItemTemplate.new(tool : Tool)
    local toolAnimsFolder = tool:WaitForChild("Anims")
    if not toolAnimsFolder then
        warn(tool.Name .. "is missing Anims Folder")
    end

    local self = {
        tool = tool,
        __type = "Item",
        animObjects = { --These are the fundamental animations, more can be added in whatever child class uses this parent class
            equip = toolAnimsFolder:FindFirstChild("equip", true),
            idle = toolAnimsFolder:FindFirstChild("idle", true),
            --activate = toolAnimsFolder:FindFirstChild("activate", true),
        },
        soundObjects = { equip = tool.BodyAttach.Sounds.equip},
        --[[
            The field variable above may not be needed because a new currentCharacterAnimationController is only controlled & destroyed
            here in this parent class
        ]]
        vmController = nil, --this will be set in the final child class, when all animations are given
        charAnimController = nil, --this will be set later when the tool is equipped/unequipped
        canActivate = false,
        equipped = false,
        connections = {}
    }

    setmetatable(self, ItemTemplate)
    --The intialize method would usually be called here, but only the final child class will call initialize
    return self
end

--[[
]]
function ItemTemplate:initialize(subclassObject)

    --[[
    The if statement block below is for the case in which this method needs to called in a child class using the child class's properties,
    but this method has been overriden in the child class.
    ]]
    if subclassObject ~= nil then
        self = subclassObject
    end

    --Since the :initialize() method is called from the final child class, these animation controllers are created using that final child class's properties
    self.charAnimController = AnimationController.new(character:FindFirstChild("Animator", true), self.animObjects)
    self.vmController = ViewmodelController.new(workspace.CurrentCamera:WaitForChild("viewModel"), self.tool, self.animObjects, hrp)


    --Event Connetions
    table.insert(
        self.connections,
        self.tool.Equipped:Connect(function()
            self:equip(self)
        end)
    )
    table.insert(
        self.connections,
        self.tool.Unequipped:Connect(function()
            self:unequip()
        end)
    )
    table.insert(
        self.connections,
        player.Character.Torso:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
            if self:isFirstPerson() then
                if self.equipped then
                    self.vmController:enable()
                end
            else
                if self.equipped then
                    self.vmController:disable()
                end
            end
        end)
    )
    table.insert(
        self.connections,
        character.Humanoid.Died:Once(function()
            print("died connection")
            --[[
            if tableOfFunctions.deathProcedure then
                tableOfFunctions.deathProcedure()
            end
            ]]
            self:unequip()
            rev_dropTool:FireServer(self.tool)
        end)
    )
end

--[[
    FINAL
    _____
    This method is final, no need to be overriden/modified in
    child classes.
]]
function ItemTemplate:isFirstPerson()
    return player.Character.Torso.LocalTransparencyModifier >= 1
end

--[[
    The equip function for every weapon is mostly the same.
]]
function ItemTemplate:equip(subclassObject, tableOfFunctions, altAnimInfo)
    --[[
    The if statement block below is for the case in which this method needs to called in a child class using the child class's properties,
    but this method has been overriden in the child class.
    ]]
    if subclassObject ~= nil then
        self = subclassObject
    end
    --STATE CHANGES:
    self.equipped = true --necessary (you'll see in a couple of lines down from here)
    self.vmController.toolEquipped = true
    self.tool:SetAttribute("canDrop", true)
    --SFX:
    rev_playSound:FireServer(self.soundObjects.equip, self.tool.BodyAttach, 0)
    --[[
    The event connection that is connected in the initialize method only detects if the play CHANGES from first person to third person or vice
    versa. Meanwhile, the if statement block below checks if AT THE MOMENT OF THIS TOOL BEING EQUIPPED, that the player is in first person, &
    futhermore if the view model tool should be shown & the actual tool be hidden.
    ]]
    if self:isFirstPerson() then
        self.vmController:enable()
    else
        self.vmController:disable()
    end
    --GET VIEW MODEL UP TO SPEED:
    self.vmController:equipTool()
            --player:GetMouse().Icon = self.tool:GetAttribute("Cursor")
    --PLAYING IDLE ANIMS:
    self.charAnimController.animationTracks.idle:Play()
    self.vmController.animationController.animationTracks.idle:Play()
    --PLAYING EQUIP ANIMATIONS & DETECTING WHEN THEY FINISH:
    if altAnimInfo == nil then
        self.charAnimController.animationTracks.equip:Play()
        self.vmController.animationController.animationTracks.equip:Play()
        self.charAnimController.animationTracks.equip.Stopped:Wait()
    else
        --print("ItemTemplate's part of wearable's :TakeOff()")
        --print(altAnimInfo.charAnimTrack.IsPlaying) --if the animation track is already playing, & you try to play in reverse speed, the animation track just stops for some reason
        altAnimInfo.charAnimTrack:Play(altAnimInfo.fadeTime, altAnimInfo.weight, altAnimInfo.speed)
        altAnimInfo.vmAnimTrack:Play(altAnimInfo.fadeTime, altAnimInfo.weight, altAnimInfo.speed)
        altAnimInfo.charAnimTrack.Stopped:Wait()
    end
    --ONCE EQUIP ANIMATION IS FINISHED:
    if self.equipped then --checking this because during the equip animation, players can unequip the tool, causing a bug
        --ALLOW PLAYER TO ACTIVE TOOL
        self.canActivate = true
        --GIVE PLAYER ABILITY TO DROP TOOL VIA PRESSING X:
        ContextActionService:BindAction(Constants.ACTION_DROP_TOOL, function(actionName, inputState, _inputObject)
            if actionName == Constants.ACTION_DROP_TOOL and inputState == Enum.UserInputState.Begin then
                if self.tool:GetAttribute("canDrop") == true then
                    self:unequip()
                    rev_dropTool:FireServer(self.tool, false)
                else
                    print("tool can't be dropped at this time")
                end
            end
        end, true, Enum.KeyCode.X)
        --ADDED FUNCTIONALITY THAT THE CHILD CLASS CAN GIVE TO THIS PARENT CLASS:
        if tableOfFunctions and tableOfFunctions.forceWear then
            tableOfFunctions.forceWear(self)
        end
    end
end

--[[
    The activate function is somewhat different for each weapon
]]
function ItemTemplate:activate()
end

--[[
    The unequip function for every weapon is mostly the same.
]]
function ItemTemplate:unequip(subclassObject)
    --IF OVERRIDDEN IN CHILD, BUT NEED ORIGINAL:
    if subclassObject ~= nil then
        self = subclassObject
    end
    --STATE CHANGES:
    self.equipped = false
    self.canActivate = false
    self.vmController.toolEquipped = false
    --TAKE AWAY PLAYER'S ABILITY TO DROP TOOL VIA PRESSING X:
    ContextActionService:UnbindAction(Constants.ACTION_DROP_TOOL)
    --RESET MOUSE ICON:
	player:GetMouse().Icon = ""
    --VIEW MODEL SHIT:
    self.vmController:disable()
    self.vmController:unequipTool()
	for _, animTrack : AnimationTrack in character.Humanoid.Animator:GetPlayingAnimationTracks() do
		for _, anim : Animation in self.animObjects do
            if animTrack.Animation == anim then
                animTrack:Stop()
            end
        end
	end
    self.vmController:stopAllViewModelAnimations()
end

function ItemTemplate:destroy()
end

return ItemTemplate