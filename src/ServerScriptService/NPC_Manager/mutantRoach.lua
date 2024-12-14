local mutantRoach = {}
mutantRoach.__index = mutantRoach

local humanoidFinder = require(script.Parent.humanoidFinder)
print("running it 2 ")
humanoidFinder.findHumanoids(workspace)
local untargetableHumanoids = {}
local detectedHumanoidsInRange = {}

function mutantRoach.new(roachModel)
    local object = {}
    object.model = roachModel
    object.humanoid = roachModel:FindFirstChild("Humanoid")
    object.range = 30
    object._on = false

    if object.model == nil or object.humanoid == nil then
        warn(debug.traceback("One or more vital properties is nil"))
    end

    setmetatable(object, mutantRoach)
    return object
end


function mutantRoach:checkHumanoidInRange(targetHumanoid)
    if table.find(untargetableHumanoids, targetHumanoid) then
        print("found in untargetableHumanoid table")
        return
    end

    local targetTorso = targetHumanoid.Parent:FindFirstChild("Torso")

    if targetTorso == nil then
        table.insert(untargetableHumanoids, targetHumanoid)
        return
    end

    local distance = (self.model.Torso.Position - targetTorso.Position).Magnitude
    if distance <= self.range then
        table.insert(detectedHumanoidsInRange, targetHumanoid)
        return true
    else
        table.remove(detectedHumanoidsInRange, table.find(detectedHumanoidsInRange, targetHumanoid))
        return false
    end
end

function mutantRoach:turnOn()
    if self._on == false then
        self._on = true
        while self._on do
            for _, hum in humanoidFinder.humanoidTable do
                if hum == self.humanoid then
                    continue
                end
                local inRange : boolean = self:checkHumanoidInRange(hum)
                print(detectedHumanoidsInRange) --!!!!! THIS IS THE BOOKMARK, FIND A WAY TO TRANSFORM TABLES
            end
            --[[
            print("calling moveTo")
            self.humanoid:MoveTo(targetPart.Position, targetPart)
            ]]
            task.wait(1)
        end
    else
        warn(debug.traceback("This roach is already on"))
    end
end

function mutantRoach:turnOff()
    self._on = false
end


return mutantRoach