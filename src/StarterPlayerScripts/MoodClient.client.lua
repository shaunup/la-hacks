-- MoodClient: orchestrates all screens, visual transitions, and game flow
-- Flow: StartScreen → LoadingScreen → MoodReveal → GameScreen → PostGame → (loop)

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local Lighting          = game:GetService("Lighting")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ─── Remotes (server creates these) ─────────────────────────────────────────
local AnalyzeMood            = ReplicatedStorage:WaitForChild("AnalyzeMood", 30)
local GetPersonalizedContent = ReplicatedStorage:WaitForChild("GetPersonalizedContent", 30)
local GetPostGameMessage     = ReplicatedStorage:WaitForChild("GetPostGameMessage", 30)
local GetDailyChallenge      = ReplicatedStorage:WaitForChild("GetDailyChallenge", 30)

-- ─── Modules ─────────────────────────────────────────────────────────────────
local Modules      = ReplicatedStorage:WaitForChild("Modules")
local MoodConfig   = require(Modules:WaitForChild("MoodConfig"))
local AmbientLayer = require(Modules:WaitForChild("AmbientLayer"))
local Games        = ReplicatedStorage:WaitForChild("Games")

-- ─── Global state ────────────────────────────────────────────────────────────
local currentMood       = nil
local currentGame       = nil
local bgMusic           = nil
local ambientLayer      = nil
local currentGradTop    = Color3.fromRGB(20, 20, 60)
local currentGradBottom = Color3.fromRGB(60, 30, 90)

-- ─── Shared helpers ──────────────────────────────────────────────────────────

local function tweenProps(obj, props, duration, style, dir)
	if not (obj and obj.Parent) then return end
	TweenService:Create(obj,
		TweenInfo.new(duration or 0.4,
			style or Enum.EasingStyle.Quad,
			dir   or Enum.EasingDirection.Out),
		props
	):Play()
end

local function makeRound(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = parent
	return c
end

local function makeShadow(parent)
	local s = Instance.new("ImageLabel")
	s.Size               = UDim2.new(1, 24, 1, 24)
	s.Position           = UDim2.new(0, -10, 0, 8)
	s.BackgroundTransparency = 1
	s.Image              = "rbxassetid://5028857084"
	s.ImageColor3        = Color3.fromRGB(0, 0, 0)
	s.ImageTransparency  = 0.72
	s.ZIndex             = (parent.ZIndex or 5) - 1
	s.ScaleType          = Enum.ScaleType.Slice
	s.SliceCenter        = Rect.new(24, 24, 276, 276)
	s.Parent             = parent
	return s
end

local function makeStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color     = color or Color3.new(1,1,1)
	s.Thickness = thickness or 1.5
	s.Transparency = 0.6
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

-- ─── Master ScreenGui ─────────────────────────────────────────────────────────

local masterGui = Instance.new("ScreenGui")
masterGui.Name           = "WellnessGui"
masterGui.ResetOnSpawn   = false
masterGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
masterGui.IgnoreGuiInset = true
masterGui.Parent         = playerGui

-- Full-screen gradient background
local bgFrame = Instance.new("Frame")
bgFrame.Name             = "Background"
bgFrame.Size             = UDim2.new(1, 0, 1, 0)
bgFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
bgFrame.BorderSizePixel  = 0
bgFrame.ZIndex           = 0
bgFrame.Parent           = masterGui

local bgGrad = Instance.new("UIGradient")
bgGrad.Color    = ColorSequence.new({
	ColorSequenceKeypoint.new(0, currentGradTop),
	ColorSequenceKeypoint.new(1, currentGradBottom),
})
bgGrad.Rotation = 135
bgGrad.Parent   = bgFrame

-- ─── Lighting / atmosphere ────────────────────────────────────────────────────

local function applyLighting(theme)
	local lt  = theme.lighting
	local dur = MoodConfig.TransitionTime

	tweenProps(Lighting, {
		Ambient           = lt.Ambient,
		Brightness        = lt.Brightness,
		ColorShift_Bottom = lt.ColorShift_Bottom,
		ColorShift_Top    = lt.ColorShift_Top,
		OutdoorAmbient    = lt.OutdoorAmbient,
		FogEnd            = lt.FogEnd,
		FogColor          = lt.FogColor,
	}, dur)

	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atm then
		atm = Instance.new("Atmosphere")
		atm.Parent = Lighting
	end
	local at = theme.atmosphere
	tweenProps(atm, { Density = at.Density, Offset = at.Offset, Glare = at.Glare, Haze = at.Haze }, dur)
	task.delay(dur * 0.5, function()
		if atm.Parent then
			atm.Color = at.Color
			atm.Decay = at.Decay
		end
	end)
end

-- ─── Background gradient transition ──────────────────────────────────────────

local function transitionBackground(theme)
	local startTop    = currentGradTop
	local startBottom = currentGradBottom
	local duration    = MoodConfig.TransitionTime
	local elapsed     = 0
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		local a = math.clamp(elapsed / duration, 0, 1)
		local function lerp(c1, c2, t)
			return Color3.new(
				c1.R + (c2.R - c1.R) * t,
				c1.G + (c2.G - c1.G) * t,
				c1.B + (c2.B - c1.B) * t
			)
		end
		bgGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, lerp(startTop,    theme.topColor,    a)),
			ColorSequenceKeypoint.new(1, lerp(startBottom, theme.bottomColor, a)),
		})
		if a >= 1 then
			currentGradTop    = theme.topColor
			currentGradBottom = theme.bottomColor
			conn:Disconnect()
		end
	end)
end

-- ─── Music ───────────────────────────────────────────────────────────────────

local function playMusic(theme)
	if bgMusic then
		local old = bgMusic
		TweenService:Create(old, TweenInfo.new(1.2), { Volume = 0 }):Play()
		task.delay(1.3, function() if old.Parent then old:Destroy() end end)
	end
	local snd = Instance.new("Sound")
	snd.SoundId  = theme.music
	snd.Volume   = 0
	snd.Looped   = true
	snd.RollOffMaxDistance = 1e9
	snd.Parent   = SoundService
	snd:Play()
	TweenService:Create(snd, TweenInfo.new(2.5), { Volume = 0.55 }):Play()
	bgMusic = snd
end

-- ─── Ambient particles ────────────────────────────────────────────────────────

local function startAmbient(theme)
	if ambientLayer then ambientLayer:Stop() end
	ambientLayer = AmbientLayer.new(bgFrame, theme)
end

-- ─── Apply full theme ──────────────────────────────────────────────────────────

local function applyTheme(theme)
	transitionBackground(theme)
	applyLighting(theme)
	playMusic(theme)
	startAmbient(theme)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCREEN 1: Start / Mood Input
-- ═══════════════════════════════════════════════════════════════════════════════

-- Forward declaration
local buildStartScreen_entry

local function buildStartScreen()
	-- Neutral ambient for start screen
	startAmbient({
		ambient = {
			style  = "snowflake",
			count  = 16,
			shapes = {"✦","·","⋆","○","✧"},
			color  = Color3.fromRGB(180, 190, 255),
		}
	})

	local screen = Instance.new("Frame")
	screen.Name              = "StartScreen"
	screen.Size              = UDim2.new(1, 0, 1, 0)
	screen.BackgroundTransparency = 1
	screen.ZIndex            = 5
	screen.Parent            = masterGui

	-- Frosted card
	local card = Instance.new("Frame")
	card.Name               = "Card"
	card.Size               = UDim2.new(0, 500, 0, 350)
	card.AnchorPoint        = Vector2.new(0.5, 0.5)
	card.Position           = UDim2.new(0.5, 0, 0.6, 0)
	card.BackgroundColor3   = Color3.fromRGB(255, 255, 255)
	card.BackgroundTransparency = 0.1
	card.BorderSizePixel    = 0
	card.ZIndex             = 8
	card.Parent             = screen
	makeRound(card, 30)
	makeShadow(card)

	local overlay = Instance.new("UIGradient")
	overlay.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(230, 240, 255)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
	})
	overlay.Rotation = 130
	overlay.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.06),
		NumberSequenceKeypoint.new(1, 0.0),
	})
	overlay.Parent = card

	-- Title
	local title = Instance.new("TextLabel")
	title.Size               = UDim2.new(1, -40, 0, 52)
	title.Position           = UDim2.new(0, 20, 0, 20)
	title.BackgroundTransparency = 1
	title.Text               = "✨  Wellness World"
	title.TextColor3         = Color3.fromRGB(40, 30, 80)
	title.TextSize           = 32
	title.Font               = Enum.Font.GothamBold
	title.TextXAlignment     = Enum.TextXAlignment.Center
	title.ZIndex             = 9
	title.Parent             = card

	-- Subtitle
	local sub = Instance.new("TextLabel")
	sub.Size               = UDim2.new(1, -60, 0, 34)
	sub.Position           = UDim2.new(0, 30, 0, 78)
	sub.BackgroundTransparency = 1
	sub.Text               = "How are you feeling today?"
	sub.TextColor3         = Color3.fromRGB(80, 60, 130)
	sub.TextSize           = 21
	sub.Font               = Enum.Font.GothamSemibold
	sub.TextXAlignment     = Enum.TextXAlignment.Center
	sub.ZIndex             = 9
	sub.Parent             = card

	-- Input
	local inputBG = Instance.new("Frame")
	inputBG.Size               = UDim2.new(1, -60, 0, 54)
	inputBG.Position           = UDim2.new(0, 30, 0, 124)
	inputBG.BackgroundColor3   = Color3.fromRGB(245, 245, 255)
	inputBG.BackgroundTransparency = 0.05
	inputBG.BorderSizePixel    = 0
	inputBG.ZIndex             = 9
	inputBG.Parent             = card
	makeRound(inputBG, 27)

	local ring = Instance.new("UIStroke")
	ring.Thickness = 0
	ring.Color     = Color3.fromRGB(120, 100, 255)
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Parent    = inputBG

	local inputField = Instance.new("TextBox")
	inputField.Size               = UDim2.new(1, -24, 1, 0)
	inputField.Position           = UDim2.new(0, 12, 0, 0)
	inputField.BackgroundTransparency = 1
	inputField.Text               = ""
	inputField.PlaceholderText    = "e.g.  I'm feeling a bit anxious today…"
	inputField.PlaceholderColor3  = Color3.fromRGB(160, 150, 200)
	inputField.TextColor3         = Color3.fromRGB(40, 30, 70)
	inputField.TextSize           = 17
	inputField.Font               = Enum.Font.Gotham
	inputField.ZIndex             = 10
	inputField.ClearTextOnFocus   = false
	inputField.MultiLine          = false
	inputField.Parent             = inputBG

	inputField.Focused:Connect(function()
		tweenProps(ring, { Thickness = 3 }, 0.2)
	end)
	inputField.FocusLost:Connect(function()
		tweenProps(ring, { Thickness = 0 }, 0.2)
	end)

	-- Submit button
	local btn = Instance.new("TextButton")
	btn.Size               = UDim2.new(1, -60, 0, 54)
	btn.Position           = UDim2.new(0, 30, 0, 196)
	btn.BackgroundColor3   = Color3.fromRGB(100, 80, 220)
	btn.BorderSizePixel    = 0
	btn.Text               = "✦  Explore My World"
	btn.TextColor3         = Color3.fromRGB(255, 255, 255)
	btn.TextSize           = 20
	btn.Font               = Enum.Font.GothamBold
	btn.AutoButtonColor    = false
	btn.ZIndex             = 9
	btn.Parent             = card
	makeRound(btn, 27)

	btn.MouseEnter:Connect(function()
		tweenProps(btn, { BackgroundColor3 = Color3.fromRGB(130, 110, 255), Size = UDim2.new(1,-54,0,56), Position = UDim2.new(0,27,0,195) }, 0.14)
	end)
	btn.MouseLeave:Connect(function()
		tweenProps(btn, { BackgroundColor3 = Color3.fromRGB(100, 80, 220), Size = UDim2.new(1,-60,0,54), Position = UDim2.new(0,30,0,196) }, 0.14)
	end)
	btn.MouseButton1Down:Connect(function()
		tweenProps(btn, { BackgroundColor3 = Color3.fromRGB(70, 55, 180) }, 0.08)
	end)

	-- Hint
	local hint = Instance.new("TextLabel")
	hint.Size               = UDim2.new(1, -40, 0, 30)
	hint.Position           = UDim2.new(0, 20, 0, 264)
	hint.BackgroundTransparency = 1
	hint.Text               = "Powered by Gemini AI  ·  Your feelings are heard 💛"
	hint.TextColor3         = Color3.fromRGB(140, 130, 180)
	hint.TextSize           = 13
	hint.Font               = Enum.Font.Gotham
	hint.TextXAlignment     = Enum.TextXAlignment.Center
	hint.ZIndex             = 9
	hint.Parent             = card

	-- Animate in
	card.BackgroundTransparency = 1
	tweenProps(card, { Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 0.1 }, 0.75, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	return screen, inputField, btn
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCREEN 2: Loading
-- ═══════════════════════════════════════════════════════════════════════════════

local function buildLoadingScreen(labelText)
	local screen = Instance.new("Frame")
	screen.Name              = "LoadingScreen"
	screen.Size              = UDim2.new(1, 0, 1, 0)
	screen.BackgroundTransparency = 1
	screen.ZIndex            = 25
	screen.Parent            = masterGui

	local lbl = Instance.new("TextLabel")
	lbl.Size               = UDim2.new(0, 360, 0, 60)
	lbl.AnchorPoint        = Vector2.new(0.5, 0.5)
	lbl.Position           = UDim2.new(0.5, 0, 0.5, -20)
	lbl.BackgroundTransparency = 1
	lbl.Text               = labelText or "Reading your mood…"
	lbl.TextColor3         = Color3.fromRGB(220, 220, 255)
	lbl.TextSize           = 26
	lbl.Font               = Enum.Font.GothamBold
	lbl.ZIndex             = 26
	lbl.Parent             = screen

	local dotsFrame = Instance.new("Frame")
	dotsFrame.Size               = UDim2.fromOffset(88, 24)
	dotsFrame.AnchorPoint        = Vector2.new(0.5, 0)
	dotsFrame.Position           = UDim2.new(0.5, 0, 0.5, 28)
	dotsFrame.BackgroundTransparency = 1
	dotsFrame.ZIndex             = 26
	dotsFrame.Parent             = screen

	local dots = {}
	for i = 1, 3 do
		local d = Instance.new("Frame")
		d.Size               = UDim2.fromOffset(15, 15)
		d.Position           = UDim2.new(0, (i-1)*36, 0.5, -7)
		d.BackgroundColor3   = Color3.fromRGB(180, 160, 255)
		d.BorderSizePixel    = 0
		d.ZIndex             = 27
		d.Parent             = dotsFrame
		makeRound(d, 50)
		dots[i] = d
	end

	local dotTime = 0
	local dotConn = RunService.Heartbeat:Connect(function(dt)
		dotTime += dt
		for i, d in ipairs(dots) do
			if d.Parent then
				d.Position = UDim2.new(0, (i-1)*36, 0.5, -7 + math.sin(dotTime * 4 + (i-1)*1.2) * 7)
			end
		end
	end)

	return screen, dotConn, lbl
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCREEN 3: Mood Reveal  (now uses Gemini personalised content)
-- ═══════════════════════════════════════════════════════════════════════════════

local function buildMoodReveal(mood, personalised, onPlay)
	local theme = MoodConfig.Themes[mood]

	local screen = Instance.new("Frame")
	screen.Name              = "MoodReveal"
	screen.Size              = UDim2.new(1, 0, 1, 0)
	screen.BackgroundTransparency = 1
	screen.ZIndex            = 20
	screen.Parent            = masterGui

	local card = Instance.new("Frame")
	card.Size               = UDim2.new(0, 500, 0, 440)
	card.AnchorPoint        = Vector2.new(0.5, 0.5)
	card.Position           = UDim2.new(0.5, 0, 0.5, 0)
	card.BackgroundColor3   = theme.cardColor
	card.BackgroundTransparency = 0.12
	card.BorderSizePixel    = 0
	card.ZIndex             = 21
	card.Parent             = screen
	makeRound(card, 30)
	makeShadow(card)
	makeStroke(card, theme.accentColor, 1.5)

	-- Emoji
	local emoji = Instance.new("TextLabel")
	emoji.Size               = UDim2.fromOffset(80, 80)
	emoji.AnchorPoint        = Vector2.new(0.5, 0)
	emoji.Position           = UDim2.new(0.5, 0, 0, 22)
	emoji.BackgroundTransparency = 1
	emoji.Text               = theme.emoji
	emoji.TextSize           = 58
	emoji.Font               = Enum.Font.GothamBold
	emoji.ZIndex             = 22
	emoji.Parent             = card

	-- "You seem…" label
	local moodLbl = Instance.new("TextLabel")
	moodLbl.Size               = UDim2.new(1, -40, 0, 44)
	moodLbl.AnchorPoint        = Vector2.new(0.5, 0)
	moodLbl.Position           = UDim2.new(0.5, 0, 0, 108)
	moodLbl.BackgroundTransparency = 1
	moodLbl.Text               = "You seem " .. theme.label .. "  " .. theme.emoji
	moodLbl.TextColor3         = theme.textColor
	moodLbl.TextSize           = 28
	moodLbl.Font               = Enum.Font.GothamBold
	moodLbl.TextXAlignment     = Enum.TextXAlignment.Center
	moodLbl.ZIndex             = 22
	moodLbl.Parent             = card

	-- Gemini tagline (personalised)
	local tagline = personalised and personalised.tagline or theme.tagline
	local tag = Instance.new("TextLabel")
	tag.Size               = UDim2.new(1, -60, 0, 56)
	tag.AnchorPoint        = Vector2.new(0.5, 0)
	tag.Position           = UDim2.new(0.5, 0, 0, 158)
	tag.BackgroundTransparency = 1
	tag.Text               = tagline
	tag.TextColor3         = theme.textColor
	tag.TextSize           = 18
	tag.Font               = Enum.Font.GothamSemibold
	tag.TextWrapped        = true
	tag.TextXAlignment     = Enum.TextXAlignment.Center
	tag.ZIndex             = 22
	tag.Parent             = card

	-- Gemini tip chip
	local tipText = personalised and personalised.tip or ""
	if tipText ~= "" then
		local tipBG = Instance.new("Frame")
		tipBG.Size               = UDim2.new(0.88, 0, 0, 44)
		tipBG.AnchorPoint        = Vector2.new(0.5, 0)
		tipBG.Position           = UDim2.new(0.5, 0, 0, 222)
		tipBG.BackgroundColor3   = theme.accentColor
		tipBG.BackgroundTransparency = 0.35
		tipBG.BorderSizePixel    = 0
		tipBG.ZIndex             = 22
		tipBG.Parent             = card
		makeRound(tipBG, 22)

		local tipLbl = Instance.new("TextLabel")
		tipLbl.Size               = UDim2.new(1, -16, 1, 0)
		tipLbl.Position           = UDim2.new(0, 8, 0, 0)
		tipLbl.BackgroundTransparency = 1
		tipLbl.Text               = "💡  " .. tipText
		tipLbl.TextColor3         = theme.textColor
		tipLbl.TextSize           = 15
		tipLbl.Font               = Enum.Font.Gotham
		tipLbl.TextWrapped        = true
		tipLbl.ZIndex             = 23
		tipLbl.Parent             = tipBG
	end

	-- Game chip
	local gameInfo = MoodConfig.GameInfo[theme.game]
	local chip = Instance.new("Frame")
	chip.Size               = UDim2.new(0.8, 0, 0, 44)
	chip.AnchorPoint        = Vector2.new(0.5, 0)
	chip.Position           = UDim2.new(0.5, 0, 0, 278)
	chip.BackgroundColor3   = theme.accentColor
	chip.BackgroundTransparency = 0.2
	chip.BorderSizePixel    = 0
	chip.ZIndex             = 22
	chip.Parent             = card
	makeRound(chip, 22)

	local chipLbl = Instance.new("TextLabel")
	chipLbl.Size               = UDim2.new(1, -16, 1, 0)
	chipLbl.Position           = UDim2.new(0, 8, 0, 0)
	chipLbl.BackgroundTransparency = 1
	chipLbl.Text               = gameInfo.icon .. "  Today's activity: " .. gameInfo.name
	chipLbl.TextColor3         = theme.textColor
	chipLbl.TextSize           = 17
	chipLbl.Font               = Enum.Font.GothamSemibold
	chipLbl.ZIndex             = 23
	chipLbl.Parent             = chip

	-- Play button
	local playBtn = Instance.new("TextButton")
	playBtn.Size               = UDim2.new(0.65, 0, 0, 52)
	playBtn.AnchorPoint        = Vector2.new(0.5, 0)
	playBtn.Position           = UDim2.new(0.5, 0, 0, 338)
	playBtn.BackgroundColor3   = theme.accentColor
	playBtn.BorderSizePixel    = 0
	playBtn.Text               = "Let's Go! →"
	playBtn.TextColor3         = theme.textColor
	playBtn.TextSize           = 20
	playBtn.Font               = Enum.Font.GothamBold
	playBtn.AutoButtonColor    = false
	playBtn.ZIndex             = 22
	playBtn.Parent             = card
	makeRound(playBtn, 26)

	playBtn.MouseEnter:Connect(function()
		tweenProps(playBtn, { BackgroundTransparency = 0.2, Size = UDim2.new(0.67, 0, 0, 54) }, 0.12)
	end)
	playBtn.MouseLeave:Connect(function()
		tweenProps(playBtn, { BackgroundTransparency = 0, Size = UDim2.new(0.65, 0, 0, 52) }, 0.12)
	end)

	playBtn.MouseButton1Click:Connect(function()
		tweenProps(card, { BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.34, 0) }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.45, function()
			screen:Destroy()
			onPlay()
		end)
	end)

	-- Animate in
	card.Size               = UDim2.new(0, 200, 0, 200)
	card.BackgroundTransparency = 1
	tweenProps(card, { Size = UDim2.new(0, 500, 0, 440), BackgroundTransparency = 0.12 }, 0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	task.delay(0.5, function()
		if emoji.Parent then
			tweenProps(emoji, { Position = UDim2.new(0.5, 0, 0, 12) }, 0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
			task.delay(0.35, function()
				if emoji.Parent then tweenProps(emoji, { Position = UDim2.new(0.5, 0, 0, 22) }, 0.3) end
			end)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCREEN 5: Post-Game  (Continue / Replay / New Game / Home)
-- ═══════════════════════════════════════════════════════════════════════════════

local function buildPostGameScreen(mood, gameName, postMsg, challenge, onReplay, onAlternate, onHome)
	local theme = MoodConfig.Themes[mood]

	local screen = Instance.new("Frame")
	screen.Name              = "PostGameScreen"
	screen.Size              = UDim2.new(1, 0, 1, 0)
	screen.BackgroundTransparency = 1
	screen.ZIndex            = 30
	screen.Parent            = masterGui

	local card = Instance.new("Frame")
	card.Size               = UDim2.new(0, 480, 0, 0)
	card.AnchorPoint        = Vector2.new(0.5, 0.5)
	card.Position           = UDim2.new(0.5, 0, 0.5, 0)
	card.BackgroundColor3   = theme.cardColor
	card.BackgroundTransparency = 0.1
	card.BorderSizePixel    = 0
	card.ZIndex             = 31
	card.Parent             = screen
	makeRound(card, 28)
	makeShadow(card)
	makeStroke(card, theme.accentColor, 1.5)

	local y = 24

	-- Big emoji celebration
	local confetti = Instance.new("TextLabel")
	confetti.Size               = UDim2.fromOffset(60, 60)
	confetti.AnchorPoint        = Vector2.new(0.5, 0)
	confetti.Position           = UDim2.new(0.5, 0, 0, y)
	confetti.BackgroundTransparency = 1
	confetti.Text               = "🎉"
	confetti.TextSize           = 44
	confetti.Font               = Enum.Font.GothamBold
	confetti.ZIndex             = 32
	confetti.Parent             = card
	y += 68

	-- Post-game message (Gemini)
	local msgLbl = Instance.new("TextLabel")
	msgLbl.Size               = UDim2.new(1, -50, 0, 0)
	msgLbl.AnchorPoint        = Vector2.new(0.5, 0)
	msgLbl.Position           = UDim2.new(0.5, 0, 0, y)
	msgLbl.BackgroundTransparency = 1
	msgLbl.Text               = postMsg or "Great job! You did amazing."
	msgLbl.TextColor3         = theme.textColor
	msgLbl.TextSize           = 19
	msgLbl.Font               = Enum.Font.GothamBold
	msgLbl.TextWrapped        = true
	msgLbl.TextXAlignment     = Enum.TextXAlignment.Center
	msgLbl.AutomaticSize      = Enum.AutomaticSize.Y
	msgLbl.ZIndex             = 32
	msgLbl.Parent             = card
	y += 68

	-- Daily challenge chip
	if challenge then
		local chalBG = Instance.new("Frame")
		chalBG.Size               = UDim2.new(0.9, 0, 0, 0)
		chalBG.AnchorPoint        = Vector2.new(0.5, 0)
		chalBG.Position           = UDim2.new(0.5, 0, 0, y)
		chalBG.BackgroundColor3   = theme.accentColor
		chalBG.BackgroundTransparency = 0.3
		chalBG.BorderSizePixel    = 0
		chalBG.ZIndex             = 32
		chalBG.AutomaticSize      = Enum.AutomaticSize.Y
		chalBG.Parent             = card
		makeRound(chalBG, 14)

		local chalPad = Instance.new("UIPadding")
		chalPad.PaddingLeft   = UDim.new(0, 12)
		chalPad.PaddingRight  = UDim.new(0, 12)
		chalPad.PaddingTop    = UDim.new(0, 8)
		chalPad.PaddingBottom = UDim.new(0, 8)
		chalPad.Parent        = chalBG

		local chalTitle = Instance.new("TextLabel")
		chalTitle.Size               = UDim2.new(1, 0, 0, 22)
		chalTitle.BackgroundTransparency = 1
		chalTitle.Text               = "✦  Today's Wellness Challenge"
		chalTitle.TextColor3         = theme.textColor
		chalTitle.TextSize           = 13
		chalTitle.Font               = Enum.Font.GothamBold
		chalTitle.ZIndex             = 33
		chalTitle.Parent             = chalBG

		local chalLbl = Instance.new("TextLabel")
		chalLbl.Size               = UDim2.new(1, 0, 0, 0)
		chalLbl.Position           = UDim2.new(0, 0, 0, 24)
		chalLbl.BackgroundTransparency = 1
		chalLbl.Text               = challenge
		chalLbl.TextColor3         = theme.textColor
		chalLbl.TextSize           = 15
		chalLbl.Font               = Enum.Font.Gotham
		chalLbl.TextWrapped        = true
		chalLbl.AutomaticSize      = Enum.AutomaticSize.Y
		chalLbl.ZIndex             = 33
		chalLbl.Parent             = chalBG

		y += 90
	end

	y += 12

	-- ─── Buttons ────────────────────────────────────────────────────────────

	local function makeBtn(label, bgCol, fgCol, yPos, action)
		local b = Instance.new("TextButton")
		b.Size               = UDim2.new(0.78, 0, 0, 50)
		b.AnchorPoint        = Vector2.new(0.5, 0)
		b.Position           = UDim2.new(0.5, 0, 0, yPos)
		b.BackgroundColor3   = bgCol
		b.BorderSizePixel    = 0
		b.Text               = label
		b.TextColor3         = fgCol
		b.TextSize           = 17
		b.Font               = Enum.Font.GothamBold
		b.AutoButtonColor    = false
		b.ZIndex             = 32
		b.Parent             = card
		makeRound(b, 25)

		b.MouseEnter:Connect(function()
			tweenProps(b, { BackgroundTransparency = 0.2 }, 0.12)
		end)
		b.MouseLeave:Connect(function()
			tweenProps(b, { BackgroundTransparency = 0 }, 0.12)
		end)
		b.MouseButton1Click:Connect(function()
			tweenProps(card, { BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.35, 0) }, 0.35)
			task.delay(0.4, function()
				screen:Destroy()
				action()
			end)
		end)
		return b
	end

	makeBtn("↺  Play Again",                    theme.accentColor, theme.textColor, y,      onReplay)
	y += 60
	local altInfo = MoodConfig.GameInfo[MoodConfig.Themes[mood].alternateGame]
	makeBtn(altInfo.icon .. "  Try " .. altInfo.name, theme.cardColor, theme.textColor, y, onAlternate)
	y += 60
	makeBtn("🏠  Return Home",                  Color3.fromRGB(80, 80, 120), Color3.fromRGB(220, 220, 255), y, onHome)
	y += 66

	-- Expand card to fit
	tweenProps(card, { Size = UDim2.new(0, 480, 0, y) }, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	-- Bounce confetti
	task.delay(0.4, function()
		if confetti.Parent then
			tweenProps(confetti, { Position = UDim2.new(0.5, 0, 0, 10) }, 0.25, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
			task.delay(0.3, function()
				if confetti.Parent then tweenProps(confetti, { Position = UDim2.new(0.5, 0, 0, 24) }, 0.2) end
			end)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCREEN 4: Game Screen
-- ═══════════════════════════════════════════════════════════════════════════════

local function launchGame(mood, gameName)
	local theme    = MoodConfig.Themes[mood]
	local gameInfo = MoodConfig.GameInfo[gameName]

	local screen = Instance.new("Frame")
	screen.Name              = "GameScreen"
	screen.Size              = UDim2.new(1, 0, 1, 0)
	screen.BackgroundTransparency = 1
	screen.ZIndex            = 10
	screen.Parent            = masterGui

	-- Top bar
	local topBar = Instance.new("Frame")
	topBar.Size               = UDim2.new(1, 0, 0, 56)
	topBar.BackgroundColor3   = theme.cardColor
	topBar.BackgroundTransparency = 0.18
	topBar.BorderSizePixel    = 0
	topBar.ZIndex             = 12
	topBar.Parent             = screen

	local topGrad = Instance.new("UIGradient")
	topGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, theme.accentColor),
		ColorSequenceKeypoint.new(1, theme.cardColor),
	})
	topGrad.Rotation = 90
	topGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.0),
		NumberSequenceKeypoint.new(1, 0.3),
	})
	topGrad.Parent = topBar

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size               = UDim2.new(1, -110, 1, 0)
	titleLbl.Position           = UDim2.new(0, 14, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text               = gameInfo.icon .. "  " .. gameInfo.name
	titleLbl.TextColor3         = theme.textColor
	titleLbl.TextSize           = 21
	titleLbl.Font               = Enum.Font.GothamBold
	titleLbl.ZIndex             = 13
	titleLbl.Parent             = topBar

	local backBtn = Instance.new("TextButton")
	backBtn.Size               = UDim2.fromOffset(88, 34)
	backBtn.AnchorPoint        = Vector2.new(1, 0.5)
	backBtn.Position           = UDim2.new(1, -10, 0.5, 0)
	backBtn.BackgroundColor3   = theme.accentColor
	backBtn.BackgroundTransparency = 0.35
	backBtn.BorderSizePixel    = 0
	backBtn.Text               = "↩  Menu"
	backBtn.TextColor3         = theme.textColor
	backBtn.TextSize           = 15
	backBtn.Font               = Enum.Font.GothamSemibold
	backBtn.AutoButtonColor    = false
	backBtn.ZIndex             = 13
	backBtn.Parent             = topBar
	makeRound(backBtn, 17)

	-- Description strip
	local descLbl = Instance.new("TextLabel")
	descLbl.Size               = UDim2.new(1, 0, 0, 30)
	descLbl.Position           = UDim2.new(0, 0, 0, 56)
	descLbl.BackgroundColor3   = theme.accentColor
	descLbl.BackgroundTransparency = 0.55
	descLbl.BorderSizePixel    = 0
	descLbl.Text               = gameInfo.description
	descLbl.TextColor3         = theme.textColor
	descLbl.TextSize           = 14
	descLbl.Font               = Enum.Font.Gotham
	descLbl.TextXAlignment     = Enum.TextXAlignment.Center
	descLbl.ZIndex             = 12
	descLbl.Parent             = screen

	-- Game container
	local gameContainer = Instance.new("Frame")
	gameContainer.Name              = "GameContainer"
	gameContainer.Size              = UDim2.new(1, 0, 1, -86)
	gameContainer.Position          = UDim2.new(0, 0, 0, 86)
	gameContainer.BackgroundTransparency = 1
	gameContainer.ZIndex            = 11
	gameContainer.Parent            = screen

	-- Slide in
	screen.Position = UDim2.new(0, 0, 1, 0)
	tweenProps(screen, { Position = UDim2.new(0, 0, 0, 0) }, 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	-- onComplete callback: show post-game screen
	local function onGameComplete()
		-- Fetch Gemini post-game message + daily challenge in parallel
		local postMsg   = nil
		local challenge = nil
		local loadScr, lConn, lLbl = buildLoadingScreen("Getting your results…")

		task.spawn(function()
			local ok1, r1 = pcall(function()
				return GetPostGameMessage:InvokeServer(mood, gameName)
			end)
			if ok1 then postMsg = r1 end

			local ok2, r2 = pcall(function()
				return GetDailyChallenge:InvokeServer(mood)
			end)
			if ok2 then challenge = r2 end

			lConn:Disconnect()
			tweenProps(loadScr, { BackgroundTransparency = 1 }, 0.3)
			task.delay(0.35, function()
				if loadScr.Parent then loadScr:Destroy() end
				if currentGame then currentGame:Stop() end
				screen:Destroy()

				buildPostGameScreen(
					mood,
					gameName,
					postMsg,
					challenge,
					function() launchGame(mood, gameName) end,             -- Replay
					function() launchGame(mood, MoodConfig.Themes[mood].alternateGame) end, -- Alt
					function() buildStartScreen_entry() end                 -- Home
				)
			end)
		end)
	end

	-- Back button goes to post-game (same flow)
	backBtn.MouseButton1Click:Connect(function()
		if currentGame then currentGame:Stop() end
		onGameComplete()
	end)

	-- Load module
	local modInst = Games:FindFirstChild(gameName)
	if modInst then
		local ok, GameModule = pcall(require, modInst)
		if ok then
			local g = GameModule.new()
			g:Start(gameContainer, theme, onGameComplete)
			currentGame = g
		else
			warn("[MoodClient] Failed to require", gameName, ":", GameModule)
		end
	else
		local fb = Instance.new("TextLabel")
		fb.Size               = UDim2.new(1, 0, 1, 0)
		fb.BackgroundTransparency = 1
		fb.Text               = "🎮  " .. gameName .. " — coming soon!"
		fb.TextColor3         = theme.textColor
		fb.TextSize           = 26
		fb.Font               = Enum.Font.GothamBold
		fb.ZIndex             = 11
		fb.Parent             = gameContainer
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- MAIN FLOW
-- ═══════════════════════════════════════════════════════════════════════════════

function buildStartScreen_entry()
	currentGame = nil
	local screen, inputField, btn = buildStartScreen()

	local submitted = false
	local function submit()
		if submitted then return end
		local text = inputField.Text:match("^%s*(.-)%s*$")
		if text == "" then
			-- Shake
			local origPos = inputField.Parent.Position
			for i = 1, 4 do
				task.delay(i * 0.06, function()
					if inputField.Parent and inputField.Parent.Parent then
						inputField.Parent.Position = origPos + UDim2.fromOffset((i%2==0 and 7 or -7), 0)
					end
				end)
			end
			task.delay(0.3, function()
				if inputField.Parent and inputField.Parent.Parent then
					inputField.Parent.Position = origPos
				end
			end)
			return
		end

		submitted = true
		tweenProps(screen, { BackgroundTransparency = 0 }, 0.25)
		screen.BackgroundColor3 = Color3.fromRGB(10, 10, 30)
		task.delay(0.25, function() tweenProps(screen, { BackgroundTransparency = 1 }, 0.3) end)
		task.delay(0.5, function()
			if screen.Parent then screen:Destroy() end

			-- Loading screen
			local loadScr, dotConn, loadLbl = buildLoadingScreen("Reading your mood…")

			task.spawn(function()
				-- Step 1: classify mood
				local mood = "neutral"
				local ok1, r1 = pcall(function()
					return AnalyzeMood:InvokeServer(text)
				end)
				if ok1 and r1 then mood = r1 end

				-- Step 2: personalised content (parallel with theme apply)
				loadLbl.Text = "Crafting your experience…"
				local personalised = nil
				local ok2, r2 = pcall(function()
					return GetPersonalizedContent:InvokeServer(text, mood)
				end)
				if ok2 then personalised = r2 end

				-- Apply theme
				applyTheme(MoodConfig.Themes[mood])
				currentMood = mood

				-- Dismiss loading
				dotConn:Disconnect()
				tweenProps(loadScr, { BackgroundTransparency = 1 }, 0.4)
				task.delay(0.45, function()
					if loadScr.Parent then loadScr:Destroy() end
					buildMoodReveal(mood, personalised, function()
						launchGame(mood, MoodConfig.Themes[mood].game)
					end)
				end)
			end)
		end)
	end

	btn.MouseButton1Click:Connect(submit)
	inputField.FocusLost:Connect(function(enter) if enter then submit() end end)
end

-- Boot
buildStartScreen_entry()
