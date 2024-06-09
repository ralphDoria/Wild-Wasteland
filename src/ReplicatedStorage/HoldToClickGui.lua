local HoldToClickGui = {}
local MT = {}
MT.__index = HoldToClickGui
---------------------------------------------local-field-variables-----------------------------------------------------------------------------------------------
local RunService = game:GetService("RunService")
---------------------------------------------local-functions-----------------------------------------------------------------------------------------------

local function adjustPosition(object)
	if typeof(object) ~= "table" or object.__type ~= "HoldToClickGui" then
		error("Incorrect value passed to adjustPostion function")
	end
	if object.drainedBar == UDim2.new(1,0,0,0) then --vertical
		object.progressBar.Position = UDim2.new(0, 0, 1 - object.progressBar.Size.Height.Scale, 0)
	elseif object.drainedBar == UDim2.new(0,0,1,0) then --horizontal
		object.progressBar.Position = UDim2.new(1 - object.progressBar.Size.Height.Scale, 0, 0, 0)
	end
end

---------------------------------------------main-function-----------------------------------------------------------------------------------------------

function HoldToClickGui.new(pb : Frame, time : number, fillType : number, fillDirection : number)
	local self = {}
	setmetatable(self, MT)

	self.progressBar = pb
	self.fullBar = UDim2.new(1, 0, 1, 0)
	if fillType == 1 then --for filling horizontally
		self.drainedBar = UDim2.new(0,0,1,0)
	elseif fillType == 2 then --for filling vertically
		self.drainedBar = UDim2.new(1,0,0,0) 
	else
		warn("Invalid fill type parameter: can only be 1 or 2")
	end
	self.fillConnection = nil
	self.holdDuration = time
	self.timeAccumulated = 0
	if fillDirection == 1 then
		self.positionAdjustment = false
	elseif fillDirection == 2 then
		self.positionAdjustment = true
	else
		warn("invalid fill direction parameter: can only be 1 or 2 ")
	end
	self.__type = "HoldToClickGui"

	return self
end

function HoldToClickGui:Start()
	self.fillConnection = RunService.RenderStepped:Connect(function(dt)
		if self.timeAccumulated >= 1 then
			self.fillConnection:Disconnect()
			self.fillConnection = nil
			task.defer(function()
				self.timeAccumulated = 0
				self.progressBar.Size = self.drainedBar
			end)
		end
		self.timeAccumulated = math.clamp(self.timeAccumulated + (dt/self.holdDuration), 0, 1)
		self.progressBar.Size = self.drainedBar:Lerp(self.fullBar, self.timeAccumulated)
		if self.positionAdjustment then
			adjustPosition(self)
		end
	end)
end

function HoldToClickGui:End()
	if self.fillConnection ~= nil then
		self.fillConnection:Disconnect()
		self.fillConnection = nil
	end
	self.timeAccumulated = 0
	self.progressBar.Size = self.drainedBar:Lerp(self.fullBar, self.timeAccumulated)
	adjustPosition(self)
end

---------------------------------------------return-----------------------------------------------------------------------------------------------
return HoldToClickGui
