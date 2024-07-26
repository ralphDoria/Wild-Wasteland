local Info = {}
--you can turn this into a class for different npcs
local known = false

Info.Name = if known then script.Name else ""
Info.angered = false

function Info.getLeaveMessage()
	--[[
		Can't just do 
			Info.LeaveMessage = if Info.angered == false then "*Eyes suspiciously*" else "Get out of my vicinity."
		because I think it does not update during run time since it's a variable that gets its value set upon compiling.
	]]
	return if Info.angered == false then "*Eyes suspiciously*" else "Get out of my face."
end

--[[
	In lua & its derivative, luau, you can have tables inside tables inside tables...
	
	There are two ways to end the dialog: 1) do not assign a Next key in a dialog choice or 2) leave the Choices talbe blank.
	However, if there are any stored choices, this will prevent the dialog from ending in the case the the choice box is supposed to be empty.
	
	-Dialog[#] are the different dialog pathways.
	-Dialog[#].Text is what the NPC will appear to say.
	-Dialog[#].Choices contains the choices that the user can respond with.
	-Dialog[#].Choices.Next decides what the next Dialog pathway will be. If it is nil, then the Dialog will end after that choice is chosen.
	-Dialog[#].Choices.Follow will put this choice into save this choice in a storedChoices array. If the choice is chosen, then it is removed from the storedChoices array. If it isn't & the
	chosen dialog choice has a key named next, then the choice will be pulled from the storedChoices array & be displayed.
	-Dialog[#].Choices.Callback will run that function when that choice is picked.
]]
Info.Dialog = {
	[1] = {
		Text = "What business do you have in approaching me, stranger?",
		Choices = {
			[1] = { Text = "I was just passing by."; Next = 2 },
			[2] = { Text = "I have some questions as to where we are."; Next = 3 },
			[3] = { Text = "It's none of your business to know my business."; Next = 4, Callback = function() Info.angered = true end }
		}
	},
	[2] = {
		Text = "Why's your butt still over here then?!",
		Choices = {}
	},
	[3] = {
		Text = "I'm willing to hear what you have.",
		Choices = {

		}
	},
	[4] = {
		Text = "Oh, so we have a Mr. Sassy Pants over here.",
		Choices = {}
	}
}

return Info
