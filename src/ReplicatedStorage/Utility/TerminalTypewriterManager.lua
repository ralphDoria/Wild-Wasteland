--!strict
--[[
	Terminal-typewriter text effect (StarterGui.IndicatorBannerGui.TerminalTypewriter):
	types an arbitrary message character-by-character toward the center of the screen,
	with a blinking block cursor — built for the level-up moment, callable with any text.

	API (client-only):
		TerminalTypewriterManager.play("LEVEL 7")

	Geometry (set by the place UI, discovered at runtime): `cursor` and `TemplateLetter`
	are right-anchored 14px cells; the cursor's FINAL position is UDim2.new(1, 0, 0, 0)
	(right edge of the frame, just left of screen center). Letters are laid out leftward
	from there: letter k of n sits at UDim2.new(1, -(n - k + 1) * cellWidth, 0, 0), so
	the last letter is one cell left of the final cursor. All letters are cloned from
	TemplateLetter up front (invisible), the cursor starts ON letter 1's cell, and each
	tick reveals a letter and moves the cursor one cell right — discrete jumps, no
	tweens — until it rests at (1, 0). The cursor is SOLID while typing and only blinks
	once the line is complete (idle), like a real terminal.

	A new play() cancels any run in progress. Teardown default: hold, then fade out.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local playSound = require(script.Parent.PlaySoundUtil)

local TYPE_INTERVAL = 0.07 -- seconds per character
local BLINK_INTERVAL = 0.4 -- cursor solid/hidden phase length
local HOLD_SECONDS = 2.5 -- time the finished line stays before fading
local FADE_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local TerminalTypewriterManager = {}

local frame: Frame? = nil
local cursor: TextLabel? = nil
local templateLetter: TextLabel? = nil
local keystrokeSound: Sound? = nil -- played locally per letter reveal (optional)

local letters: { TextLabel } = {}
local generation = 0 -- bumped by every play()/cancel; stale threads see it and stop

local function getGui(): (Frame?, TextLabel?, TextLabel?)
	if frame and frame.Parent then
		return frame, cursor, templateLetter
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = playerGui:WaitForChild("IndicatorBannerGui", 10)
	if not gui then
		warn("[TerminalTypewriterManager] IndicatorBannerGui missing — typewriter disabled")
		return nil, nil, nil
	end
	frame = gui:WaitForChild("TerminalTypewriter") :: Frame
	cursor = frame:WaitForChild("cursor") :: TextLabel
	templateLetter = frame:WaitForChild("TemplateLetter") :: TextLabel
	keystrokeSound = frame:FindFirstChild("TerminalKeyboardSingleKeystroke") :: Sound?
	if not keystrokeSound then
		warn("[TerminalTypewriterManager] TerminalKeyboardSingleKeystroke missing — typing will be silent")
	end
	-- Idle state: nothing visible until the first play().
	templateLetter.Visible = false
	cursor.Visible = false
	return frame, cursor, templateLetter
end

local function clearLetters()
	for _, letter in letters do
		letter:Destroy()
	end
	table.clear(letters)
end

-- Blinks the cursor by toggling its background until this generation ends.
local function startBlink(cursorLabel: TextLabel, myGeneration: number)
	task.spawn(function()
		while generation == myGeneration do
			cursorLabel.BackgroundTransparency = 0
			task.wait(BLINK_INTERVAL)
			if generation ~= myGeneration then
				break
			end
			cursorLabel.BackgroundTransparency = 1
			task.wait(BLINK_INTERVAL)
		end
	end)
end

--[[
	Type `message` out toward the screen center. Cancels and replaces any message
	already playing or fading.
]]
function TerminalTypewriterManager.play(message: string)
	local twFrame, cursorLabel, template = getGui()
	if not twFrame or not cursorLabel or not template then
		return
	end

	generation += 1
	local myGeneration = generation
	clearLetters()

	-- Split into display characters (utf8-safe; Zekton is latin but don't crash on more).
	local chars: { string } = {}
	for first, last in utf8.graphemes(message) do
		table.insert(chars, message:sub(first, last))
	end
	local n = #chars
	if n == 0 then
		cursorLabel.Visible = false
		return
	end

	local cellWidth = cursorLabel.Size.X.Offset
	local function cellPosition(k: number): UDim2 -- letter k's cell (right-edge anchored)
		return UDim2.new(1, -(n - k + 1) * cellWidth, 0, 0)
	end

	-- Build the whole line invisibly first, so every cell (and the cursor's start) is known.
	for k, ch in chars do
		local letter = template:Clone()
		letter.Name = `Letter{k}`
		letter.Text = ch
		letter.TextTransparency = 0
		letter.Position = cellPosition(k)
		letter.Visible = false
		letter.Parent = twFrame
		table.insert(letters, letter)
	end

	-- Cursor starts SOLID on the first character's cell and stays solid while typing —
	-- a real terminal cursor only blinks when idle.
	cursorLabel.Position = cellPosition(1)
	cursorLabel.BackgroundTransparency = 0
	cursorLabel.Visible = true

	task.spawn(function()
		for k, letter in letters do
			task.wait(TYPE_INTERVAL)
			if generation ~= myGeneration then
				return
			end
			letter.Visible = true
			-- One cell right; after the last letter this is exactly UDim2.new(1, 0, 0, 0).
			cursorLabel.Position = UDim2.new(1, -(n - k) * cellWidth, 0, 0)
			if keystrokeSound then
				playSound(keystrokeSound, nil, 0.05)
			end
		end

		-- Typing done -> idle: now the cursor blinks, for the whole hold.
		startBlink(cursorLabel, myGeneration)

		task.wait(HOLD_SECONDS)
		if generation ~= myGeneration then
			return
		end

		-- Teardown: stop the blink (own the cursor's transparency), fade everything out.
		generation += 1
		for _, letter in letters do
			TweenService:Create(letter, FADE_INFO, { TextTransparency = 1 }):Play()
		end
		TweenService:Create(cursorLabel, FADE_INFO, { BackgroundTransparency = 1 }):Play()
		task.wait(FADE_INFO.Time)
		if generation ~= myGeneration + 1 then
			return -- a new play() took over mid-fade; it owns the cleanup now
		end
		clearLetters()
		cursorLabel.Visible = false
	end)
end

return TerminalTypewriterManager
