local Info = {}
--you can turn this into a class for different npcs
Info.LeaveMessage = "If you would like any of the preset---- I mean your questions answered, I'll be glad to do so."
Info.CameraDistance = 3

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
]]
Info.Dialog = {
	[1] = {
		Text = "Welcome, traveller. As I know you may be confused right now, feel free to ask me any questions you may have.",
		Choices = {
			[1] = { Text = "What is this place?"; Next = 2; Follow = true },
			[2] = { Text = "Who are you?"; Next = 3; Follow = true },
			[3] = { Text = "How are you?"; Next = 4; Follow = true },
			[4] = { Text = "Aren't you from that one anime with ninjas?"; Next = 5; Follow = true }
		}
	},
	[2] = {
		Text = "We are in a microverse created by Niletheus to test the dialog system that we are currently communicating through.",
		Choices = {}
	},
	[3] = {
		Text = "I am a test dummy to test this dialog system. It is the sole reason for my existence........... the only reason.",
		Choices = {}
	},
	[4] = {
		Text = "At my core, I am only lumps of code, incapable of harboring any sentiments. As I'm not like ChatGPT, I cannot even imitate these human emotions to return your platitue. My apologies.",
		Choices = {}
	},
	[5] = {
		Text = "Sorry, I do not know what you are talking about.",
		Choices = {}
	}
}

return Info
