local HoldToClickGui = {}
HoldToClickGui.__index = HoldToClickGui
---------------------------------------------local-field-variables-----------------------------------------------------------------------------------------------
local RunService = game:GetService("RunService")
local fullBar = UDim2.new(1,0,1,0)
local drainedBar = nil

local guiObject : GuiBase = nil
local progressBar : Frame= nil
local fillConnection = nil	
local drainConnection = nil
local timeAccumulated = 0
local positionAdjustment = nil
---------------------------------------------local-functions-----------------------------------------------------------------------------------------------

local function adjustPosition()
	if drainedBar == UDim2.new(1,0,0,0) then --vertical
		progressBar.Position = UDim2.new(0, 0, 1 - progressBar.Size.Height.Scale, 0)
	elseif drainedBar == UDim2.new(0,0,1,0) then --horizontal
		progressBar.Position = UDim2.new(1 - progressBar.Size.Height.Scale, 0, 0, 0)
	end
end

---------------------------------------------main-function-----------------------------------------------------------------------------------------------
HoldToClickGui.timeToFull = nil

function HoldToClickGui.new(guiObj : GuiBase, time : number, fillType : number, fillDirection : number)
	guiObject = guiObj
	HoldToClickGui.timeToFull = time
	progressBar = guiObject:FindFirstChild("ProgressBar", true)

	if fillType == 1 then --for filling horizontally
		drainedBar = UDim2.new(0,0,1,0)
	elseif fillType == 2 then --for filling vertically
		drainedBar = UDim2.new(1,0,0,0) 
	else
		warn("Invalid fill type parameter: can only be 1 or 2")
	end

	if fillDirection == 1 then
		positionAdjustment = false
	elseif fillDirection == 2 then
		positionAdjustment = true
	else
		warn("invalid fill direction parameter: can only be 1 or 2 ")
	end
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
		if positionAdjustment then
			adjustPosition()
		end
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
		if positionAdjustment then
			adjustPosition()
		end
	end)
end

---------------------------------------------return-----------------------------------------------------------------------------------------------
return HoldToClickGui
