local HoldToClickGui = {}
HoldToClickGui.__index = HoldToClickGui
---------------------------------------------local-field-variables-----------------------------------------------------------------------------------------------
local RunService = game:GetService("RunService")
local fullBar = UDim2.new(1,0,1,0)
local drainedBar = UDim2.new(0,0,1,0)
local guiObject : GuiBase = nil

local progressBar = guiObject:FindFirstChildWhichIsA("Frame")
local fillConnection = nil
local drainConnection = nil
local timeAccumulated = 0
---------------------------------------------local-functions-----------------------------------------------------------------------------------------------

---------------------------------------------main-function-----------------------------------------------------------------------------------------------
HoldToClickGui.timeToFull = nil

function HoldToClickGui.new(guiObj : GuiBase, time : number)
	guiObject = guiObj
	HoldToClickGui.timeToFull = time
end

function HoldToClickGui:Start()
	if drainConnection ~= nil then
		drainConnection:Disconnect()
		drainConnection = nil
	end
	fillConnection = RunService.RenderStepped:Connect(function(dt)
		if timeAccumulated >= 1 then
			fillConnection:Disconnect()
			fillConnection = nil
			task.defer(function()
				timeAccumulated = 0
				progressBar.Size = drainedBar
			end)
		end
		timeAccumulated = math.clamp(timeAccumulated + (dt/HoldToClickGui.timeToFull), 0, 1)
		progressBar.Size = drainedBar:Lerp(fullBar, timeAccumulated)
	end)
end

function HoldToClickGui:End()
	if fillConnection ~= nil then
		fillConnection:Disconnect()
		fillConnection = nil
	end
	drainConnection = RunService.RenderStepped:Connect(function(dt)
		if timeAccumulated <= 0 then
			drainConnection:Disconnect()
			drainConnection = nil
		end
		timeAccumulated = math.clamp(timeAccumulated - (dt/HoldToClickGui.timeToFull), 0, 1)
		progressBar.Size = drainedBar:Lerp(fullBar, timeAccumulated)
	end)
end

---------------------------------------------return-----------------------------------------------------------------------------------------------
return HoldToClickGui
