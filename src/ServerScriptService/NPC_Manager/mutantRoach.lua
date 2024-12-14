local mutantRoach = {}
mutantRoach.__index = mutantRoach

local humanoidFinder = require(script.Parent.humanoidFinder)
humanoidFinder.findHumanoids(workspace)
local untargetableHumanoids = {}
local detectedHumanoids = {}
local correspondingDistances = {}

function mutantRoach.new(roachModel)
    local object = {}
    object.model = roachModel
    object.humanoid = roachModel:FindFirstChild("Humanoid")
    object.range = 30
    object._on = false
    object.targetObject = nil

    if object.model == nil or object.humanoid == nil then
        warn(debug.traceback("One or more vital properties is nil"))
    end

    setmetatable(object, mutantRoach)
    return object
end


function mutantRoach:checkHumanoidInRange(targetHumanoid)
    if table.find(untargetableHumanoids, targetHumanoid) then
        return
    end

    local targetTorso = targetHumanoid.Parent:FindFirstChild("Torso")

    if targetTorso == nil then
        table.insert(untargetableHumanoids, targetHumanoid)
        return
    end

    local distance = (self.model.Torso.Position - targetTorso.Position).Magnitude
    if distance <= self.range then
        return true, distance
    else
        return false
    end
end

function mutantRoach.addToDetectedTable(humanoid, distance)
    if not table.find(detectedHumanoids, humanoid) then
        table.insert(detectedHumanoids, humanoid)
        table.insert(correspondingDistances, distance)
        Instance.new("Highlight", humanoid.Parent)
    end
end

function mutantRoach.removeFromDetectedTable(humanoid)
    if table.find(detectedHumanoids, humanoid) then
        table.remove(detectedHumanoids, table.find(detectedHumanoids, humanoid))
        table.insert(correspondingDistances, table.find(detectedHumanoids, humanoid))
        local potentialHighlight = humanoid.Parent:FindFirstChildWhichIsA("Highlight", true)
        if potentialHighlight then
            potentialHighlight:Destroy()
        end
    end
end

function mutantRoach.findClosestHumanoidAmongDetected()
    if #correspondingDistances == 0 then
        warn("none in detected")
        return nil
    end
    local smallestDistance = math.huge
    local index = nil
    for i, distance in correspondingDistances do
        if distance < smallestDistance then
            smallestDistance = distance
            index = i
        end
    end
    return detectedHumanoids[index]
end

function mutantRoach:turnOn()
    if self._on == false then
        self._on = true
        while self._on do
            for _, hum in humanoidFinder.humanoidTable do
                if hum == self.humanoid then
                    continue
                end
                local inRange : boolean, distance : number = self:checkHumanoidInRange(hum)
                if inRange then
                    mutantRoach.addToDetectedTable(hum, distance)
                else
                    mutantRoach.removeFromDetectedTable(hum)
                end
            end
            local closest : Humanoid = mutantRoach.findClosestHumanoidAmongDetected()
            if closest ~= nil then
                self.targetObject = closest.Parent.Torso
                self.humanoid:MoveTo(self.targetObject.Position, self.targetObject)
            else
                self.targetObject = nil
            end
            print("targeting: " .. if self.targetObject then self.targetObject.Parent.Name else tostring(nil))
            task.wait(0.5)
        end
    else
        warn(debug.traceback("This roach is already on"))
    end
end

function mutantRoach:turnOff()
    self._on = false
end


return mutantRoach