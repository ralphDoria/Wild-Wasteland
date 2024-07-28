local player = game:GetService("Players").LocalPlayer
local dialogGui : ScreenGui = player.PlayerGui:WaitForChild("DialogGui" )
local subtitle : TextLabel = dialogGui:FindFirstChild("Subtitle", true)
local name : TextLabel = dialogGui:FindFirstChild("Name", true)
local choices : ScrollingFrame = dialogGui:FindFirstChild("Choices", true)
local choiceTemplate : Textbutton = dialogGui:FindFirstChild("Template", true)
local dialogSound : Sound = dialogGui:FindFirstChild("bong", true)

local playSound = require(game:GetService("ReplicatedStorage"):FindFirstChild("PlaySoundUtil", true))

--[[
	The reason I made this function is because #table in lua doesn't return the actual lenth of an array if the indexes aren't consecutive.
	For example, (the specific problem I was having) if you have an array with the first index being 3 & try to get the length of the array
	w/ #table, 0 will be returned because the array doesn't start with index 1 and go up to 3.
]]
local function getArrayLength(tbl : {[any] : any})
	local length = 0
	for _, _ in tbl do
		length +=1
	end
	return length
end

local function switchToChoices(yes : boolean)
    if yes then
        subtitle.Visible = false
        name.Visible = false
        choices.Visible = true
    else
        choices.Visible = false
        subtitle.Visible = true
        name.Visible = true
    end
end

local currentNpc = nil
local storedChoices = {}

local function emptyChoicesFrame()
	for _, child in pairs(choices:GetChildren()) do
		if child:IsA("TextButton") then
			if child.Name ~= "Template" then
				child:Destroy()
			end
		end
	end
end

local function typeWrite(text : string, label : TextLabel)
	label.Text = ""
	switchToChoices(false)
	local breakLoop = false
	local skipEvent
	
	skipEvent = subtitle.InputBegan:Connect(function(inputObject)
		if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
			breakLoop = true
			skipEvent:Disconnect()
			skipEvent = nil
		end
	end)

	local longPause = {".", "!", "?"}
	local basePauseTime : number = 0.05

	for i = 1, #text, 1 do
		if not breakLoop then
			--task.wait(1) this is for testing the skip feature
			playSound(dialogSound, nil, 0)
			label.Text = string.sub(text, 1, i)
			local currentCharacter = string.sub(text, i, i)
			task.wait(
				if #text == i then
					0
				elseif table.find(longPause, currentCharacter) then
					basePauseTime * 8
				elseif currentCharacter == "," then
					basePauseTime * 4
				else
					basePauseTime
			)
		else
			label.Text = text
			break
		end
	end
	
	if skipEvent then
		skipEvent:Disconnect()
		skipEvent = nil
	end
	task.wait(0.5)
end

--[[
	This function displays the leave message & closes the dialog GUI.
		@param {DialogInfo module table} info
	Process:
	1. Empties the choices frame.
	2. Typewrites the leave message of the DialogInfo module table (that's been passed as na argument) into the specified textlabel.
	3. Waits half of a second to re-enable the current npc (that the player is talking to)'s proximity prompt & gives player control back over their camera.
	4. Tweens the dialog Gui off screen & resets it's text properties & makes it invisible.
	5. makes the current NPC nil ***(might have to change this because the lua garabge collector deletes variables that store nothing)
	6. Fires the TalkEvent server-side, which will allow the player to control their character again.
]]
local function endDialog(info, prompt : ProximityPrompt)
	emptyChoicesFrame()

	typeWrite(info.getLeaveMessage(), subtitle)

	dialogGui.Enabled = false
	name.Text = ""
	subtitle.Text = ""
	storedChoices = {}

	--[[ Talk Event
	TalkEvent:FireServer(currentNpc)
	if currentNpc.Name == "Franklin" then
		local pianochord = game:GetService("SoundService"):WaitForChild("Piano Short 53 (b)")
		pianochord:Play()
	end
	]]

	currentNpc = nil
	prompt.Enabled = true
end

local function createChoice(text : string)
	local clone = choiceTemplate:Clone()
	clone.Visible = true
	clone.Name = text
	clone.Text = text
	clone.Parent = choices
	return clone
end

local function getNPCText(dialogPath)
	if typeof(dialogPath.Text) == "function" then
		local variableText = dialogPath.Text()
		return variableText
	else
		return dialogPath.Text
	end
end

local function getChoiceValue(choiceOption)
	if typeof(choiceOption) == "function" then
		local variableChoiceOption = choiceOption()
		return variableChoiceOption
	else
		return choiceOption
	end
end

--[[
	This is a recursive function.
		@param {DialogInfo module table} info
		@param {choice table} lastChoice
	Process (You need to see the DialogInfo module for this to make sense):
	1. It starts with emptying the choices frame.
	2. Checks if the 2nd parameter, lastChoice, exists. If it is nil, then that means this is the first call to the "nextDialog" method in the recursion chain, which means the dialog has just
	started. 
	3a. If the argument, lastChoice, is nil, then the dialog variable (which is local to the nextDialog method), is set to the first key in the DialogInfo module table (the one passed as the 1st
	argument)
	3b. If the argument, lastchoice, is exists, then the dialog checks if the lastChoice has a follow up, which is contained in a possible key called "next".
	3ba. If the lastChoice table has a "next" key, then the dialog variable goes to the dialog in the DialogInfo module table keyed as lastChoice.Next
	3bbX. If the lastChoice table does not have a "next" key, then the endDialog method will be called, which will end the callback function here.
	4. The key named Text of the dialog variable, which stores an index of the DialogInfo module table, will be typewritten.
	5.
	6.
	7.
]]
local function nextDialog(info, lastChoice, prompt : ProximityPrompt)
	local cancelDialogConnection : RBXScriptConnection
	cancelDialogConnection = player:GetAttributeChangedSignal("CancelDialog"):Connect(function()
		if player:GetAttribute("CancelDialog") == true then
			cancelDialogConnection:Disconnect()
			cancelDialogConnection = nil
			player:SetAttribute("CancelDialog", false)
			dialogGui.Enabled = false
			subtitle.Text = ""
			emptyChoicesFrame()
			prompt.Enabled = true
			return
		end
	end)

	subtitle.Text = ""
	emptyChoicesFrame()

	local dialog
	if lastChoice then
		lastChoice = getChoiceValue(lastChoice)
		if lastChoice.Next then
			dialog = info.Dialog[lastChoice.Next]
		else
			endDialog(info, prompt)
		end
	else
		--opening dialog
		print("Know npc's name" .. tostring(info.known))
		player:SetAttribute("CancelDialog", false)
		prompt.Enabled = false
		dialogGui.Enabled = true
		dialog = info.Dialog[1]
	end

	if not dialog then return end

	typeWrite(getNPCText(dialog), subtitle)

	if dialog.Choices and (#dialog.Choices > 0 or getArrayLength(storedChoices) > 0) then
		switchToChoices(true)
		for i, choice in pairs(storedChoices) do
			local clone = createChoice(choice.Text)

			clone.MouseButton1Click:Connect(function()
				if choice.Consequence then
					choice.Consequence()
				end
				storedChoices[i] = nil
				nextDialog(info, choice, prompt)
			end)
		end

		for i, value in dialog.Choices do
			local choice = getChoiceValue(value)
			if choice ~= nil then
				local clone = createChoice(choice.Text)

				if choice.Follow == true then
					storedChoices[i] = choice
				end

				clone.MouseButton1Click:Connect(function()
					if choice.Consequence then
						choice.Consequence()
					end
					storedChoices[i] = nil
					nextDialog(info, choice, prompt)
				end)
			end
		end

		local leave = createChoice("<Leave Dialog>")

		leave.MouseButton1Click:Once(function()
			endDialog(info, prompt)
			prompt.Enabled = true
		end)
	else
		task.wait(1)

		if dialog.Next then
			nextDialog(info, dialog, prompt)
		else
			endDialog(info, prompt)
			prompt.Enabled = true
		end
	end
end

return nextDialog