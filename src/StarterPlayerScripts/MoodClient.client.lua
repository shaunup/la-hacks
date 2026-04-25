-- MoodClient: orchestrates all screens and visual transitions
-- Flow: StartScreen → LoadingScreen → MoodReveal → GameScreen

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local Lighting          = game:GetService("Lighting")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")
local UserInputService  = game:GetService("UserInputService")

local player     = Players.LocalPlayer
local playerGui  = player:WaitForChild("PlayerGui")

-- Wait for server-created RemoteFunction
local AnalyzeMood = ReplicatedStorage:WaitForChild("AnalyzeMood", 30)

-- Modules
local MoodConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MoodConfig"))
local Games      = ReplicatedStorage:WaitForChild("Games")

-- ─── State ────────────────────────────────────────────────────────────────
local currentMood      = nil
local currentGame      = nil
local bgMusic          = nil
local ambientParticles = {}

-- ─── Utility helpers ──────────────────────────────────────────────────────

local function tweenProps(obj, props, duration, style, dir)
	style    = style or Enum.EasingStyle.Quad
	dir      = dir   or Enum.EasingDirection.Out
	duration = duration or 0.4
	TweenService:Create(obj, TweenInfo.new(duration, style, dir), props):Play()
end

local function makeRound(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = parent
	return c
end

local function makeShadow(parent)
	local s = Instance.new("ImageLabel")
	s.Name               = "Shadow"
	s.Size               = UDim2.new(1, 20, 1, 20)
	s.Position           = UDim2.new(0, -8, 0, 6)
	s.BackgroundTransparency = 1
	s.Image              = "rbxassetid://5028857084"  -- soft shadow
	s.ImageColor3        = Color3.fromRGB(0, 0, 0)
	s.ImageTransparency  = 0.7
	s.ZIndex             = parent.ZIndex - 1
	s.ScaleType          = Enum.ScaleType.Slice
	s.SliceCenter        = Rect.new(24, 24, 276, 276)
	s.Parent             = parent
	return s
end

-- ─── Lighting / Sky transition ─────────────────────────────────────────────

local function applyLighting(theme)
	local lt = theme.lighting
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
	tweenProps(atm, {
		Density = at.Density,
		Offset  = at.Offset,
		Glare   = at.Glare,
		Haze    = at.Haze,
	}, dur)
	-- Color and Decay can't be tweened natively, so set directly after a short wait
	task.delay(dur * 0.5, function()
		if atm.Parent then
			atm.Color = at.Color
			atm.Decay = at.Decay
		end
	end)
end

-- ─── Background music ──────────────────────────────────────────────────────

local function playMusic(theme)
	if bgMusic then
		TweenService:Create(bgMusic, TweenInfo.new(1), { Volume = 0 }):Play()
		task.delay(1.1, function() if bgMusic then bgMusic:Destroy() end end)
	end

	local snd = Instance.new("Sound")
	snd.SoundId  = theme.music
	snd.Volume   = 0
	snd.Looped   = true
	snd.RollOffMaxDistance = 1e9
	snd.Parent   = SoundService

	snd:Play()
	TweenService:Create(snd, TweenInfo.new(2), { Volume = 0.55 }):Play()
	bgMusic = snd
end

-- ─── Animated background particles ────────────────────────────────────────

local function clearParticles()
	for _, p in ipairs(ambientParticles) do
		if p and p.Parent then p:Destroy() end
	end
	ambientParticles = {}
end

local function spawnAmbientParticles(screenGui, theme)
	clearParticles()
	for i = 1, 18 do
		local dot = Instance.new("Frame")
		dot.Name               = "AmbientDot"..i
		dot.Size               = UDim2.fromOffset(math.random(6, 18), math.random(6, 18))
		dot.Position           = UDim2.new(math.random(), 0, math.random(), 0)
		dot.BackgroundColor3   = theme.accentColor
		dot.BackgroundTransparency = math.random(40, 70) / 100
		dot.BorderSizePixel    = 0
		dot.ZIndex             = 1
		dot.Parent             = screenGui
		makeRound(dot, 50)

		local speedY = math.random(15, 50) / 100  -- fraction per second
		local drift  = (math.random() - 0.5) * 0.04
		local phase  = math.random() * math.pi * 2
		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if not dot.Parent then conn:Disconnect() return end
			local p = dot.Position
			local ny = p.Y.Scale - speedY * dt * 0.05
			if ny < -0.05 then ny = 1.05 end
			dot.Position = UDim2.new(p.X.Scale + drift * dt, 0, ny, 0)
			phase += dt * 1.2
			dot.BackgroundTransparency = 0.4 + math.sin(phase) * 0.25
		end)
		table.insert(ambientParticles, dot)
		-- store connection to disconnect on clear
		dot.AncestryChanged:Connect(function()
			conn:Disconnect()
		end)
	end
end

-- ─── Master ScreenGui ─────────────────────────────────────────────────────

local masterGui = Instance.new("ScreenGui")
masterGui.Name              = "WellnessGui"
masterGui.ResetOnSpawn      = false
masterGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
masterGui.IgnoreGuiInset    = true
masterGui.Parent            = playerGui

-- Full-screen gradient background
local bgFrame = Instance.new("Frame")
bgFrame.Name               = "Background"
bgFrame.Size               = UDim2.new(1, 0, 1, 0)
bgFrame.BackgroundColor3   = Color3.fromRGB(20, 20, 40)
bgFrame.BorderSizePixel    = 0
bgFrame.ZIndex             = 0
bgFrame.Parent             = masterGui

local bgGrad = Instance.new("UIGradient")
bgGrad.Color    = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 60)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 30, 90)),
})
bgGrad.Rotation  = 135
bgGrad.Parent    = bgFrame
local currentGradTop    = Color3.fromRGB(20, 20, 60)
local currentGradBottom = Color3.fromRGB(60, 30, 90)

local function transitionBackground(theme)
	-- Interpolate gradient colours over TransitionTime
	local startTop    = currentGradTop
	local startBottom = currentGradBottom
	local duration    = MoodConfig.TransitionTime
	local elapsed     = 0
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		local a = math.clamp(elapsed / duration, 0, 1)
		local t = Color3.new(
			startTop.R + (theme.topColor.R - startTop.R) * a,
			startTop.G + (theme.topColor.G - startTop.G) * a,
			startTop.B + (theme.topColor.B - startTop.B) * a
		)
		local b = Color3.new(
			startBottom.R + (theme.bottomColor.R - startBottom.R) * a,
			startBottom.G + (theme.bottomColor.G - startBottom.G) * a,
			startBottom.B + (theme.bottomColor.B - startBottom.B) * a
		)
		bgGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, t),
			ColorSequenceKeypoint.new(1, b),
		})
		if a >= 1 then
			currentGradTop    = theme.topColor
			currentGradBottom = theme.bottomColor
			conn:Disconnect()
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SCREEN 1: Start / Mood Input
-- ═══════════════════════════════════════════════════════════════════════════

local function buildStartScreen()
	local screen = Instance.new("Frame")
	screen.Name              = "StartScreen"
	screen.Size              = UDim2.new(1, 0, 1, 0)
	screen.BackgroundTransparency = 1
	screen.ZIndex            = 5
	screen.Parent            = masterGui

	-- Particle background
	spawnAmbientParticles(screen, {
		accentColor = Color3.fromRGB(160, 180, 255)
	})

	-- Card container
	local card = Instance.new("Frame")
	card.Name               = "Card"
	card.Size               = UDim2.new(0, 480, 0, 320)
	card.AnchorPoint        = Vector2.new(0.5, 0.5)
	card.Position           = UDim2.new(0.5, 0, 0.5, 30)
	card.BackgroundColor3   = Color3.fromRGB(255, 255, 255)
	card.BackgroundTransparency = 0.08
	card.BorderSizePixel    = 0
	card.ZIndex             = 8
	card.Parent             = screen
	makeRound(card, 28)
	makeShadow(card)

	-- Frosted glass gradient overlay
	local overlay = Instance.new("UIGradient")
	overlay.Color    = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 230, 255)),
	})
	overlay.Rotation  = 120
	overlay.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 0.12),
	})
	overlay.Parent = card

	-- Title
	local title = Instance.new("TextLabel")
	title.Size               = UDim2.new(1, -40, 0, 48)
	title.Position           = UDim2.new(0, 20, 0, 22)
	title.BackgroundTransparency = 1
	title.Text               = "✨  Wellness World"
	title.TextColor3         = Color3.fromRGB(40, 30, 80)
	title.TextSize           = 30
	title.Font               = Enum.Font.GothamBold
	title.TextXAlignment     = Enum.TextXAlignment.Center
	title.ZIndex             = 9
	title.Parent             = card

	-- Subtitle
	local sub = Instance.new("TextLabel")
	sub.Size               = UDim2.new(1, -60, 0, 36)
	sub.Position           = UDim2.new(0, 30, 0, 76)
	sub.BackgroundTransparency = 1
	sub.Text               = "How are you feeling today?"
	sub.TextColor3         = Color3.fromRGB(80, 60, 120)
	sub.TextSize           = 20
	sub.Font               = Enum.Font.GothamSemibold
	sub.TextXAlignment     = Enum.TextXAlignment.Center
	sub.ZIndex             = 9
	sub.Parent             = card

	-- Input field
	local inputBG = Instance.new("Frame")
	inputBG.Size               = UDim2.new(1, -60, 0, 52)
	inputBG.Position           = UDim2.new(0, 30, 0, 122)
	inputBG.BackgroundColor3   = Color3.fromRGB(245, 245, 255)
	inputBG.BackgroundTransparency = 0.05
	inputBG.BorderSizePixel    = 0
	inputBG.ZIndex             = 9
	inputBG.Parent             = card
	makeRound(inputBG, 26)

	local inputField = Instance.new("TextBox")
	inputField.Size               = UDim2.new(1, -24, 1, 0)
	inputField.Position           = UDim2.new(0, 12, 0, 0)
	inputField.BackgroundTransparency = 1
	inputField.Text               = ""
	inputField.PlaceholderText    = "e.g. I'm feeling a bit anxious today…"
	inputField.PlaceholderColor3  = Color3.fromRGB(160, 150, 190)
	inputField.TextColor3         = Color3.fromRGB(40, 30, 70)
	inputField.TextSize           = 17
	inputField.Font               = Enum.Font.Gotham
	inputField.ZIndex             = 10
	inputField.ClearTextOnFocus   = false
	inputField.MultiLine          = false
	inputField.Parent             = inputBG

	-- Glow ring when focused
	local ring = Instance.new("UIStroke")
	ring.Thickness   = 0
	ring.Color       = Color3.fromRGB(120, 100, 255)
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Parent      = inputBG

	inputField.Focused:Connect(function()
		tweenProps(ring, { Thickness = 2.5 }, 0.2)
	end)
	inputField.FocusLost:Connect(function()
		tweenProps(ring, { Thickness = 0 }, 0.2)
	end)

	-- Submit button
	local btn = Instance.new("TextButton")
	btn.Size               = UDim2.new(1, -60, 0, 52)
	btn.Position           = UDim2.new(0, 30, 0, 192)
	btn.BackgroundColor3   = Color3.fromRGB(100, 80, 220)
	btn.BorderSizePixel    = 0
	btn.Text               = "✦  Explore My World"
	btn.TextColor3         = Color3.fromRGB(255, 255, 255)
	btn.TextSize           = 19
	btn.Font               = Enum.Font.GothamBold
	btn.AutoButtonColor    = false
	btn.ZIndex             = 9
	btn.Parent             = card
	makeRound(btn, 26)

	-- Hover / press effects
	btn.MouseEnter:Connect(function()
		tweenProps(btn, { BackgroundColor3 = Color3.fromRGB(130, 110, 255) }, 0.15)
		tweenProps(btn, { Size = UDim2.new(1, -54, 0, 54), Position = UDim2.new(0, 27, 0, 191) }, 0.12)
	end)
	btn.MouseLeave:Connect(function()
		tweenProps(btn, { BackgroundColor3 = Color3.fromRGB(100, 80, 220) }, 0.15)
		tweenProps(btn, { Size = UDim2.new(1, -60, 0, 52), Position = UDim2.new(0, 30, 0, 192) }, 0.12)
	end)
	btn.MouseButton1Down:Connect(function()
		tweenProps(btn, { BackgroundColor3 = Color3.fromRGB(70, 55, 180) }, 0.08)
	end)

	-- Hint
	local hint = Instance.new("TextLabel")
	hint.Size               = UDim2.new(1, -40, 0, 28)
	hint.Position           = UDim2.new(0, 20, 0, 256)
	hint.BackgroundTransparency = 1
	hint.Text               = "Powered by Gemini AI  ·  Your feelings are heard 💛"
	hint.TextColor3         = Color3.fromRGB(140, 130, 180)
	hint.TextSize           = 13
	hint.Font               = Enum.Font.Gotham
	hint.TextXAlignment     = Enum.TextXAlignment.Center
	hint.ZIndex             = 9
	hint.Parent             = card

	-- Animate card in
	card.Position = UDim2.new(0.5, 0, 0.6, 30)
	card.BackgroundTransparency = 1
	tweenProps(card, { Position = UDim2.new(0.5, 0, 0.5, 30), BackgroundTransparency = 0.08 }, 0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	-- Return submit action
	return screen, inputField, btn
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SCREEN 2: Loading / Analysis
-- ═══════════════════════════════════════════════════════════════════════════

local function buildLoadingScreen()
	local screen = Instance.new("Frame")
	screen.Name              = "LoadingScreen"
	screen.Size              = UDim2.new(1, 0, 1, 0)
	screen.BackgroundTransparency = 1
	screen.ZIndex            = 15
	screen.Visible           = false
	screen.Parent            = masterGui

	local lbl = Instance.new("TextLabel")
	lbl.Name               = "LoadLabel"
	lbl.Size               = UDim2.new(0, 340, 0, 60)
	lbl.AnchorPoint        = Vector2.new(0.5, 0.5)
	lbl.Position           = UDim2.new(0.5, 0, 0.5, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text               = "Reading your mood…"
	lbl.TextColor3         = Color3.fromRGB(220, 220, 255)
	lbl.TextSize           = 26
	lbl.Font               = Enum.Font.GothamBold
	lbl.ZIndex             = 16
	lbl.Parent             = screen

	-- Three bouncing dots
	local dotsFrame = Instance.new("Frame")
	dotsFrame.Size               = UDim2.fromOffset(80, 24)
	dotsFrame.AnchorPoint        = Vector2.new(0.5, 0)
	dotsFrame.Position           = UDim2.new(0.5, 0, 0.5, 46)
	dotsFrame.BackgroundTransparency = 1
	dotsFrame.ZIndex             = 16
	dotsFrame.Parent             = screen

	local dots = {}
	for i = 1, 3 do
		local d = Instance.new("Frame")
		d.Size               = UDim2.fromOffset(14, 14)
		d.Position           = UDim2.new(0, (i-1)*33, 0.5, -7)
		d.BackgroundColor3   = Color3.fromRGB(180, 160, 255)
		d.BorderSizePixel    = 0
		d.ZIndex             = 17
		d.Parent             = dotsFrame
		makeRound(d, 50)
		dots[i] = d
	end

	-- Animate dots
	local dotTime = 0
	local dotConn = RunService.Heartbeat:Connect(function(dt)
		dotTime += dt
		for i, d in ipairs(dots) do
			if d.Parent then
				local offset = math.sin(dotTime * 4 + (i-1) * 1.2) * 6
				d.Position = UDim2.new(0, (i-1)*33, 0.5, -7 + offset)
			end
		end
	end)

	return screen, dotConn
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SCREEN 3: Mood Reveal
-- ═══════════════════════════════════════════════════════════════════════════

local function buildMoodReveal(mood, onPlay)
	local theme = MoodConfig.Themes[mood]

	local screen = Instance.new("Frame")
	screen.Name              = "MoodReveal"
	screen.Size              = UDim2.new(1, 0, 1, 0)
	screen.BackgroundTransparency = 1
	screen.ZIndex            = 20
	screen.Parent            = masterGui

	-- Card
	local card = Instance.new("Frame")
	card.Size               = UDim2.new(0, 480, 0, 400)
	card.AnchorPoint        = Vector2.new(0.5, 0.5)
	card.Position           = UDim2.new(0.5, 0, 0.5, 0)
	card.BackgroundColor3   = theme.cardColor
	card.BackgroundTransparency = 0.12
	card.BorderSizePixel    = 0
	card.ZIndex             = 21
	card.Parent             = screen
	makeRound(card, 28)
	makeShadow(card)

	-- Emoji
	local emoji = Instance.new("TextLabel")
	emoji.Size               = UDim2.fromOffset(90, 90)
	emoji.AnchorPoint        = Vector2.new(0.5, 0)
	emoji.Position           = UDim2.new(0.5, 0, 0, 28)
	emoji.BackgroundTransparency = 1
	emoji.Text               = theme.emoji
	emoji.TextSize           = 64
	emoji.Font               = Enum.Font.GothamBold
	emoji.ZIndex             = 22
	emoji.Parent             = card

	-- Mood label
	local moodLbl = Instance.new("TextLabel")
	moodLbl.Size               = UDim2.new(1, -40, 0, 50)
	moodLbl.AnchorPoint        = Vector2.new(0.5, 0)
	moodLbl.Position           = UDim2.new(0.5, 0, 0, 124)
	moodLbl.BackgroundTransparency = 1
	moodLbl.Text               = "You seem " .. theme.label
	moodLbl.TextColor3         = theme.textColor
	moodLbl.TextSize           = 30
	moodLbl.Font               = Enum.Font.GothamBold
	moodLbl.TextXAlignment     = Enum.TextXAlignment.Center
	moodLbl.ZIndex             = 22
	moodLbl.Parent             = card

	-- Tagline
	local tag = Instance.new("TextLabel")
	tag.Size               = UDim2.new(1, -60, 0, 60)
	tag.AnchorPoint        = Vector2.new(0.5, 0)
	tag.Position           = UDim2.new(0.5, 0, 0, 180)
	tag.BackgroundTransparency = 1
	tag.Text               = theme.tagline
	tag.TextColor3         = theme.textColor
	tag.TextSize           = 18
	tag.Font               = Enum.Font.GothamSemibold
	tag.TextWrapped        = true
	tag.TextXAlignment     = Enum.TextXAlignment.Center
	tag.ZIndex             = 22
	tag.Parent             = card

	-- Game suggestion chip
	local gameInfo = MoodConfig.GameInfo[theme.game]
	local chip = Instance.new("Frame")
	chip.Size               = UDim2.new(0.8, 0, 0, 48)
	chip.AnchorPoint        = Vector2.new(0.5, 0)
	chip.Position           = UDim2.new(0.5, 0, 0, 252)
	chip.BackgroundColor3   = theme.accentColor
	chip.BackgroundTransparency = 0.25
	chip.BorderSizePixel    = 0
	chip.ZIndex             = 22
	chip.Parent             = card
	makeRound(chip, 24)

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
	playBtn.Size               = UDim2.new(0.7, 0, 0, 52)
	playBtn.AnchorPoint        = Vector2.new(0.5, 0)
	playBtn.Position           = UDim2.new(0.5, 0, 0, 318)
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
		tweenProps(playBtn, { BackgroundTransparency = 0.2, Size = UDim2.new(0.72, 0, 0, 54) }, 0.12)
	end)
	playBtn.MouseLeave:Connect(function()
		tweenProps(playBtn, { BackgroundTransparency = 0, Size = UDim2.new(0.7, 0, 0, 52) }, 0.12)
	end)
	playBtn.MouseButton1Click:Connect(function()
		tweenProps(card, { BackgroundTransparency = 1 }, 0.35)
		tweenProps(card, { Position = UDim2.new(0.5, 0, 0.35, 0) }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.45, function()
			screen:Destroy()
			onPlay()
		end)
	end)

	-- Animate in
	card.Size               = UDim2.new(0, 200, 0, 200)
	card.BackgroundTransparency = 1
	tweenProps(card, {
		Size = UDim2.new(0, 480, 0, 400),
		BackgroundTransparency = 0.12,
	}, 0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	-- Emoji bounce
	task.delay(0.5, function()
		if emoji.Parent then
			tweenProps(emoji, { Position = UDim2.new(0.5, 0, 0, 16) }, 0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
			task.delay(0.35, function()
				if emoji.Parent then
					tweenProps(emoji, { Position = UDim2.new(0.5, 0, 0, 28) }, 0.3)
				end
			end)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SCREEN 4: Game Screen
-- ═══════════════════════════════════════════════════════════════════════════

local function buildGameScreen(mood)
	local theme = MoodConfig.Themes[mood]

	local screen = Instance.new("Frame")
	screen.Name              = "GameScreen"
	screen.Size              = UDim2.new(1, 0, 1, 0)
	screen.BackgroundTransparency = 1
	screen.ZIndex            = 10
	screen.Parent            = masterGui

	-- Top bar
	local topBar = Instance.new("Frame")
	topBar.Size               = UDim2.new(1, 0, 0, 58)
	topBar.BackgroundColor3   = theme.cardColor
	topBar.BackgroundTransparency = 0.18
	topBar.BorderSizePixel    = 0
	topBar.ZIndex             = 12
	topBar.Parent             = screen

	local topGrad = Instance.new("UIGradient")
	topGrad.Color   = ColorSequence.new({
		ColorSequenceKeypoint.new(0, theme.accentColor),
		ColorSequenceKeypoint.new(1, theme.cardColor),
	})
	topGrad.Rotation = 90
	topGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.0),
		NumberSequenceKeypoint.new(1, 0.3),
	})
	topGrad.Parent = topBar

	local gameInfo = MoodConfig.GameInfo[theme.game]

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size               = UDim2.new(1, -120, 1, 0)
	titleLbl.Position           = UDim2.new(0, 16, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text               = gameInfo.icon .. "  " .. gameInfo.name
	titleLbl.TextColor3         = theme.textColor
	titleLbl.TextSize           = 22
	titleLbl.Font               = Enum.Font.GothamBold
	titleLbl.ZIndex             = 13
	titleLbl.Parent             = topBar

	-- Back / restart button
	local backBtn = Instance.new("TextButton")
	backBtn.Size               = UDim2.fromOffset(90, 36)
	backBtn.AnchorPoint        = Vector2.new(1, 0.5)
	backBtn.Position           = UDim2.new(1, -12, 0.5, 0)
	backBtn.BackgroundColor3   = theme.accentColor
	backBtn.BackgroundTransparency = 0.3
	backBtn.BorderSizePixel    = 0
	backBtn.Text               = "↩  Back"
	backBtn.TextColor3         = theme.textColor
	backBtn.TextSize           = 16
	backBtn.Font               = Enum.Font.GothamSemibold
	backBtn.AutoButtonColor    = false
	backBtn.ZIndex             = 13
	backBtn.Parent             = topBar
	makeRound(backBtn, 18)

	backBtn.MouseButton1Click:Connect(function()
		if currentGame then currentGame:Stop() end
		screen:Destroy()
		-- Return to start screen
		buildStartScreen_entry()
	end)

	-- Description strip
	local descLbl = Instance.new("TextLabel")
	descLbl.Size               = UDim2.new(1, 0, 0, 34)
	descLbl.Position           = UDim2.new(0, 0, 0, 58)
	descLbl.BackgroundColor3   = theme.accentColor
	descLbl.BackgroundTransparency = 0.5
	descLbl.BorderSizePixel    = 0
	descLbl.Text               = gameInfo.description
	descLbl.TextColor3         = theme.textColor
	descLbl.TextSize           = 15
	descLbl.Font               = Enum.Font.Gotham
	descLbl.TextXAlignment     = Enum.TextXAlignment.Center
	descLbl.ZIndex             = 12
	descLbl.Parent             = screen

	-- Game container
	local gameContainer = Instance.new("Frame")
	gameContainer.Name              = "GameContainer"
	gameContainer.Size              = UDim2.new(1, 0, 1, -92)
	gameContainer.Position          = UDim2.new(0, 0, 0, 92)
	gameContainer.BackgroundTransparency = 1
	gameContainer.ZIndex            = 11
	gameContainer.Parent            = screen

	-- Load game module
	local gameModuleInstance = Games:FindFirstChild(theme.game)
	if gameModuleInstance then
		local GameModule = require(gameModuleInstance)
		local game_ = GameModule.new()
		game_:Start(gameContainer, theme)
		currentGame = game_
	else
		local fallback = Instance.new("TextLabel")
		fallback.Size               = UDim2.new(1, 0, 1, 0)
		fallback.BackgroundTransparency = 1
		fallback.Text               = "🎮 Game coming soon!"
		fallback.TextColor3         = theme.textColor
		fallback.TextSize           = 28
		fallback.Font               = Enum.Font.GothamBold
		fallback.ZIndex             = 11
		fallback.Parent             = gameContainer
	end

	-- Slide in from bottom
	screen.Position = UDim2.new(0, 0, 1, 0)
	tweenProps(screen, { Position = UDim2.new(0, 0, 0, 0) }, 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- MAIN FLOW
-- ═══════════════════════════════════════════════════════════════════════════

-- forward declaration for back-button use
function buildStartScreen_entry()
	-- Remove ambient particles from previous state
	clearParticles()

	local screen, inputField, btn = buildStartScreen()

	local function submit()
		local text = inputField.Text:match("^%s*(.-)%s*$")
		if text == "" then
			-- Shake input
			local origPos = inputField.Parent.Position
			for i = 1, 4 do
				task.delay(i * 0.06, function()
					if inputField.Parent.Parent then
						inputField.Parent.Position = origPos + UDim2.fromOffset((i%2==0 and 6 or -6), 0)
					end
				end)
			end
			task.delay(0.3, function()
				if inputField.Parent.Parent then
					inputField.Parent.Position = origPos
				end
			end)
			return
		end

		-- Fade out start screen
		tweenProps(screen, { BackgroundTransparency = 0 }, 0.3)
		screen.BackgroundColor3 = Color3.fromRGB(10, 10, 30)
		task.delay(0.3, function()
			tweenProps(screen, { BackgroundTransparency = 1 }, 0.4)
		end)
		task.delay(0.6, function()
			screen:Destroy()

			-- Show loading
			local loadScreen, dotConn = buildLoadingScreen()
			loadScreen.Visible = true

			-- Call server (async)
			task.spawn(function()
				local mood = "neutral"
				local ok, result = pcall(function()
					return AnalyzeMood:InvokeServer(text)
				end)
				if ok and result then
					mood = result
				end

				-- Hide loader
				dotConn:Disconnect()
				tweenProps(loadScreen, { BackgroundTransparency = 1 }, 0.4)
				task.delay(0.45, function()
					loadScreen:Destroy()

					-- Apply theme
					transitionBackground(MoodConfig.Themes[mood])
					applyLighting(MoodConfig.Themes[mood])
					playMusic(MoodConfig.Themes[mood])
					spawnAmbientParticles(masterGui, MoodConfig.Themes[mood])

					currentMood = mood

					-- Mood reveal
					buildMoodReveal(mood, function()
						buildGameScreen(mood)
					end)
				end)
			end)
		end)
	end

	btn.MouseButton1Click:Connect(submit)
	inputField.FocusLost:Connect(function(enter)
		if enter then submit() end
	end)
end

-- Boot
buildStartScreen_entry()
