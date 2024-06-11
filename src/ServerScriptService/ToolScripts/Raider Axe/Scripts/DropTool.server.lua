local tool = script.Parent.Parent

--Remote Events
local Events = tool:WaitForChild("Events")
local RemoteEvents = Events:WaitForChild("RemoteEvents")
local rev_dropped : RemoteEvent = RemoteEvents:WaitForChild("Dropped")

rev_dropped.OnServerEvent:Connect(function(player)
    tool.Parent = game.Workspace
end)
