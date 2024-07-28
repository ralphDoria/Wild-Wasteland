local Info = {}
--you can turn this into a class for different npcs

Info.angered = false
Info.known = false

Info.Name = script.Name

Info.getLeaveMessage = function()
	--[[
		Can't just do 
			Info.LeaveMessage = if Info.angered == false then "*Eyes suspiciously*" else "Get out of my vicinity."
		because I think it does not update during run time since it's a variable that gets its value set upon compiling.
	]]
	return if Info.angered == false then "*nods your way*" else "Get out of my face."
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
		Text = function()
			if not Info.angered then
				return "What business do you have in approaching me, stranger?"
			else
				return "I don't vibe with you."
			end
		end,
		Choices = {
			[1] = function()
				if Info.angered then
					return nil
				else
					return { Text = "I was just passing by."; Next = 2 }
				end
			end,
			[2] = function()
				if Info.angered then
					return nil
				else
					return { Text = "I have some questions as to where we are."; Next = 3 }
				end
			end,
			[3] = function()
				if Info.angered then
					return nil
				else
					return { Text = "It's none of your business to know my business."; Next = 4, Consequence = function() Info.angered = true end }
				end
			end,
			[4] = function()
				if Info.angered then
					return nil
				else
					return { Text = "I would like to know your name."; Next = 5, Consequence = function() Info.known = true end }
				end
			end
		}
	},
	[2] = {
		Text = "I wish you luck & safety on your journeys, then.",
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
	},
	[5] = {
		Text = "Hmmm, why is it that you ask? Has someone sent you to take me out of this world? Or is it that you're a bounty hunter? Those questions were all rhetorical, I do not actually care for your reasons or your being. I proudly proclaim that I am Murdoc Wright, leader of the Rust Knights.",
		Choices = {
			[1] = { Text = "Can I join the Rust Knights?"; Next = 6 },
			[2] = { Text = "You need to get your ego checked."; Next = 7 }
		}
	},
	[6] = {
		Text = "You will need to prove your worthiness",
		Choices = {}
	},
	[7] = {
		Text = "I assure you that you do not want the smoke with me.",
		Choices = {}
	}
}

return Info
