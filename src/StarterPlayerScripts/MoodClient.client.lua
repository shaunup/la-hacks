-- MoodClient v3
-- Flow: NameEntry → StartScreen → Loading → MoodReveal → GameScreen+Timer → PostGame → loop

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local Lighting          = game:GetService("Lighting")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ─── Remotes ─────────────────────────────────────────────────────────────────
local AnalyzeMood            = ReplicatedStorage:WaitForChild("AnalyzeMood", 30)
local GetPersonalizedContent = ReplicatedStorage:WaitForChild("GetPersonalizedContent", 30)
local GetPostGameMessage     = ReplicatedStorage:WaitForChild("GetPostGameMessage", 30)
local GetDailyChallenge      = ReplicatedStorage:WaitForChild("GetDailyChallenge", 30)

-- ─── Modules ─────────────────────────────────────────────────────────────────
local Modules      = ReplicatedStorage:WaitForChild("Modules")
local MoodConfig   = require(Modules:WaitForChild("MoodConfig"))
local AmbientLayer = require(Modules:WaitForChild("AmbientLayer"))
local SceneLayer   = require(Modules:WaitForChild("SceneLayer"))
local Games        = ReplicatedStorage:WaitForChild("Games")

-- ─── State ───────────────────────────────────────────────────────────────────
local playerName    = player.Name   -- overwritten by NameEntry
local currentMood   = nil
local currentGame   = nil
local bgMusic       = nil
local ambient       = nil
local sceneObj      = nil           -- SceneLayer instance
local musicVolume   = 0.55          -- adjustable via volume button
local gradTop       = Color3.fromRGB(16, 16, 48)
local gradBottom    = Color3.fromRGB(48, 24, 72)

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function tw(obj, props, dur, sty, dir)
	if not (obj and obj.Parent) then return end
	TweenService:Create(obj,
		TweenInfo.new(dur or 0.4, sty or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props):Play()
end

local function round(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 12)
	c.Parent = p
	return c
end

local function shadow(p)
	local s = Instance.new("ImageLabel")
	s.Size               = UDim2.new(1, 26, 1, 26)
	s.Position           = UDim2.new(0, -11, 0, 9)
	s.BackgroundTransparency = 1
	s.Image              = "rbxassetid://5028857084"
	s.ImageColor3        = Color3.new(0, 0, 0)
	s.ImageTransparency  = 0.73
	s.ZIndex             = (p.ZIndex or 5) - 1
	s.ScaleType          = Enum.ScaleType.Slice
	s.SliceCenter        = Rect.new(24, 24, 276, 276)
	s.Parent             = p
	return s
end

local function stroke(p, col, th)
	local s = Instance.new("UIStroke")
	s.Color     = col or Color3.new(1,1,1)
	s.Thickness = th  or 1.5
	s.Transparency = 0.6
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
	return s
end

local function makeStyledBtn(parent, text, bgCol, fgCol, yPos, w, h)
	local b = Instance.new("TextButton")
	b.Size               = UDim2.new(w or 0.72, 0, 0, h or 50)
	b.AnchorPoint        = Vector2.new(0.5, 0)
	b.Position           = UDim2.new(0.5, 0, 0, yPos)
	b.BackgroundColor3   = bgCol
	b.BorderSizePixel    = 0
	b.Text               = text
	b.TextColor3         = fgCol
	b.TextSize           = 18
	b.Font               = Enum.Font.GothamBold
	b.AutoButtonColor    = false
	b.ZIndex             = parent.ZIndex + 1
	b.Parent             = parent
	round(b, 25)
	b.MouseEnter:Connect(function()
		tw(b, { BackgroundTransparency = 0.18 }, 0.12)
	end)
	b.MouseLeave:Connect(function()
		tw(b, { BackgroundTransparency = 0 }, 0.12)
	end)
	return b
end

-- ─── Master GUI ───────────────────────────────────────────────────────────────

local gui = Instance.new("ScreenGui")
gui.Name           = "WellnessGui"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent         = playerGui

local bgFrame = Instance.new("Frame")
bgFrame.Name             = "BG"
bgFrame.Size             = UDim2.new(1, 0, 1, 0)
bgFrame.BackgroundColor3 = gradTop
bgFrame.BorderSizePixel  = 0
bgFrame.ZIndex           = 0
bgFrame.Parent           = gui

local bgGrad = Instance.new("UIGradient")
bgGrad.Color    = ColorSequence.new({
	ColorSequenceKeypoint.new(0, gradTop),
	ColorSequenceKeypoint.new(1, gradBottom),
})
bgGrad.Rotation = 135
bgGrad.Parent   = bgFrame

-- ─── Lighting ─────────────────────────────────────────────────────────────────

local function applyLighting(theme)
	local lt = theme.lighting
	tw(Lighting, {
		Ambient           = lt.Ambient,
		Brightness        = lt.Brightness,
		ColorShift_Bottom = lt.ColorShift_Bottom,
		ColorShift_Top    = lt.ColorShift_Top,
		OutdoorAmbient    = lt.OutdoorAmbient,
		FogEnd            = lt.FogEnd,
		FogColor          = lt.FogColor,
	}, MoodConfig.TransitionTime)

	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atm then atm = Instance.new("Atmosphere"); atm.Parent = Lighting end
	local at = theme.atmosphere
	tw(atm, { Density = at.Density, Offset = at.Offset, Glare = at.Glare, Haze = at.Haze },
		MoodConfig.TransitionTime)
	task.delay(MoodConfig.TransitionTime * 0.45, function()
		if atm.Parent then atm.Color = at.Color; atm.Decay = at.Decay end
	end)
end

-- ─── Background gradient transition ──────────────────────────────────────────

local function transitionBG(theme)
	local s1, s2 = gradTop, gradBottom
	local dur, elapsed = MoodConfig.TransitionTime, 0
	local c; c = RunService.Heartbeat:Connect(function(dt)
		elapsed = math.min(elapsed + dt, dur)
		local a = elapsed / dur
		local function lerp(a_, b_, t) return Color3.new(a_.R+(b_.R-a_.R)*t, a_.G+(b_.G-a_.G)*t, a_.B+(b_.B-a_.B)*t) end
		bgGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, lerp(s1, theme.topColor,    a)),
			ColorSequenceKeypoint.new(1, lerp(s2, theme.bottomColor, a)),
		})
		if elapsed >= dur then
			gradTop = theme.topColor; gradBottom = theme.bottomColor
			c:Disconnect()
		end
	end)
end

-- ─── Music ───────────────────────────────────────────────────────────────────

local function playMusic(theme)
	local old = bgMusic
	if old then
		tw(old, { Volume = 0 }, 1.4)
		task.delay(1.5, function() if old and old.Parent then old:Destroy() end end)
	end
	local snd = Instance.new("Sound")
	snd.SoundId  = theme.music
	snd.Volume   = 0
	snd.Looped   = true
	snd.RollOffMaxDistance = 1e9
	snd.Parent   = SoundService
	snd:Play()
	tw(snd, { Volume = musicVolume }, 2.5)
	bgMusic = snd
end

-- ─── Scene layer ─────────────────────────────────────────────────────────────

local function startScene(theme)
	if sceneObj then sceneObj:Stop() end
	sceneObj = SceneLayer.new(bgFrame, theme.sceneStyle or "neutral")
end

-- ─── Ambient particles ────────────────────────────────────────────────────────

local function startAmbient(theme)
	if ambient then ambient:Stop() end
	ambient = AmbientLayer.new(bgFrame, theme)
end

-- ─── Full theme apply ─────────────────────────────────────────────────────────

local function applyTheme(theme)
	transitionBG(theme)
	applyLighting(theme)
	playMusic(theme)
	startScene(theme)
	startAmbient(theme)  -- ambient particles on top of scene
end

-- ─── Volume control overlay ───────────────────────────────────────────────────
-- Persistent pill in the bottom-right corner; always visible after first theme

local volBtn = Instance.new("TextButton")
volBtn.Name               = "VolumeBtn"
volBtn.Size               = UDim2.fromOffset(120, 36)
volBtn.AnchorPoint        = Vector2.new(1, 1)
volBtn.Position           = UDim2.new(1, -12, 1, -12)
volBtn.BackgroundColor3   = Color3.fromRGB(40, 40, 80)
volBtn.BackgroundTransparency = 0.35
volBtn.BorderSizePixel    = 0
volBtn.Text               = "🔊  Vol: 55%"
volBtn.TextColor3         = Color3.fromRGB(220, 220, 255)
volBtn.TextSize           = 14
volBtn.Font               = Enum.Font.GothamSemibold
volBtn.AutoButtonColor    = false
volBtn.ZIndex             = 50
volBtn.Visible            = false   -- shown after first mood
volBtn.Parent             = gui
round(volBtn, 18)

local VOL_STEPS = { 0, 0.2, 0.4, 0.6, 0.8, 1.0 }
local volIdx    = 4  -- starts at 0.6 (index 4 = 0.6 → shown as 55 initially)

local function setVolume(v)
	musicVolume = v
	if bgMusic and bgMusic.Parent then bgMusic.Volume = v end
	local pct = math.floor(v * 100)
	local icon = v == 0 and "🔇" or (v < 0.4 and "🔉" or "🔊")
	volBtn.Text = icon .. "  Vol: " .. pct .. "%"
end

volBtn.MouseButton1Click:Connect(function()
	volIdx = (volIdx % #VOL_STEPS) + 1
	setVolume(VOL_STEPS[volIdx])
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCREEN 0: Name Entry  (first-time personalisation)
-- ═══════════════════════════════════════════════════════════════════════════════

local buildStartScreen_entry  -- forward

local function buildNameEntry()
	if sceneObj then sceneObj:Stop(); sceneObj = nil end
	startAmbient({
		ambient = {
			style  = "snowflake", count  = 18,
			shapes = {"✦","·","⋆","○","✧","⊹"},
			color  = Color3.fromRGB(180, 195, 255),
		}
	})

	local screen = Instance.new("Frame")
	screen.Name              = "NameEntry"
	screen.Size              = UDim2.new(1, 0, 1, 0)
	screen.BackgroundTransparency = 1
	screen.ZIndex            = 5
	screen.Parent            = gui

	local card = Instance.new("Frame")
	card.Size               = UDim2.new(0, 440, 0, 300)
	card.AnchorPoint        = Vector2.new(0.5, 0.5)
	card.Position           = UDim2.new(0.5, 0, 0.65, 0)
	card.BackgroundColor3   = Color3.fromRGB(255, 255, 255)
	card.BackgroundTransparency = 0.1
	card.BorderSizePixel    = 0
	card.ZIndex             = 8
	card.Parent             = screen
	round(card, 28)
	shadow(card)

	-- Gradient overlay
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 240, 255)),
		ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
	})
	g.Rotation = 130; g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.06),
		NumberSequenceKeypoint.new(1, 0.0),
	}); g.Parent = card

	-- Sparkle logo
	local logo = Instance.new("TextLabel")
	logo.Size               = UDim2.fromOffset(60, 60)
	logo.AnchorPoint        = Vector2.new(0.5, 0)
	logo.Position           = UDim2.new(0.5, 0, 0, 16)
	logo.BackgroundTransparency = 1
	logo.Text               = "✨"
	logo.TextSize           = 44
	logo.Font               = Enum.Font.GothamBold
	logo.ZIndex             = 9
	logo.Parent             = card

	local title = Instance.new("TextLabel")
	title.Size               = UDim2.new(1, -40, 0, 44)
	title.Position           = UDim2.new(0, 20, 0, 76)
	title.BackgroundTransparency = 1
	title.Text               = "Welcome to Wellness World"
	title.TextColor3         = Color3.fromRGB(38, 28, 78)
	title.TextSize           = 26
	title.Font               = Enum.Font.GothamBold
	title.TextXAlignment     = Enum.TextXAlignment.Center
	title.ZIndex             = 9
	title.Parent             = card

	local sub = Instance.new("TextLabel")
	sub.Size               = UDim2.new(1, -50, 0, 28)
	sub.Position           = UDim2.new(0, 25, 0, 124)
	sub.BackgroundTransparency = 1
	sub.Text               = "What would you like to be called?"
	sub.TextColor3         = Color3.fromRGB(78, 58, 128)
	sub.TextSize           = 18
	sub.Font               = Enum.Font.GothamSemibold
	sub.TextXAlignment     = Enum.TextXAlignment.Center
	sub.ZIndex             = 9
	sub.Parent             = card

	-- Name input
	local ibg = Instance.new("Frame")
	ibg.Size               = UDim2.new(1, -60, 0, 50)
	ibg.Position           = UDim2.new(0, 30, 0, 162)
	ibg.BackgroundColor3   = Color3.fromRGB(245, 245, 255)
	ibg.BackgroundTransparency = 0.05
	ibg.BorderSizePixel    = 0
	ibg.ZIndex             = 9
	ibg.Parent             = card
	round(ibg, 25)

	local ring = Instance.new("UIStroke")
	ring.Thickness = 0; ring.Color = Color3.fromRGB(120, 100, 255)
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ring.Parent = ibg

	local nameBox = Instance.new("TextBox")
	nameBox.Size               = UDim2.new(1, -22, 1, 0)
	nameBox.Position           = UDim2.new(0, 11, 0, 0)
	nameBox.BackgroundTransparency = 1
	nameBox.Text               = ""
	nameBox.PlaceholderText    = "Your name (e.g. Alex)"
	nameBox.PlaceholderColor3  = Color3.fromRGB(160, 150, 200)
	nameBox.TextColor3         = Color3.fromRGB(40, 30, 70)
	nameBox.TextSize           = 18
	nameBox.Font               = Enum.Font.Gotham
	nameBox.ClearTextOnFocus   = false
	nameBox.ZIndex             = 10
	nameBox.Parent             = ibg
	nameBox.Focused:Connect(function() tw(ring, { Thickness = 3 }, 0.2) end)
	nameBox.FocusLost:Connect(function() tw(ring, { Thickness = 0 }, 0.2) end)

	local continueBtn = makeStyledBtn(card, "Let's Begin  →", Color3.fromRGB(100, 80, 220), Color3.new(1,1,1), 226)

	-- Animate in
	card.BackgroundTransparency = 1
	tw(card, { Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 0.1 }, 0.75,
		Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	-- Logo pulse
	task.spawn(function()
		while logo.Parent do
			tw(logo, { Rotation = 8 }, 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			task.wait(0.65)
			if logo.Parent then
				tw(logo, { Rotation = -8 }, 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				task.wait(0.65)
			end
		end
	end)

	local function proceed()
		local name = nameBox.Text:match("^%s*(.-)%s*$")
		if name == "" then name = player.Name end
		playerName = name:sub(1, 30)

		tw(card, { Position = UDim2.new(0.5, 0, 0.35, 0), BackgroundTransparency = 1 }, 0.4,
			Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.45, function()
			screen:Destroy()
			buildStartScreen_entry()
		end)
	end

	continueBtn.MouseButton1Click:Connect(proceed)
	nameBox.FocusLost:Connect(function(enter) if enter then proceed() end end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCREEN 1: Mood Input
-- ═══════════════════════════════════════════════════════════════════════════════

local function buildStartScreen()
	local screen = Instance.new("Frame")
	screen.Name              = "StartScreen"
	screen.Size              = UDim2.new(1, 0, 1, 0)
	screen.BackgroundTransparency = 1
	screen.ZIndex            = 5
	screen.Parent            = gui

	local card = Instance.new("Frame")
	card.Size               = UDim2.new(0, 500, 0, 340)
	card.AnchorPoint        = Vector2.new(0.5, 0.5)
	card.Position           = UDim2.new(0.5, 0, 0.6, 0)
	card.BackgroundColor3   = Color3.fromRGB(255, 255, 255)
	card.BackgroundTransparency = 0.1
	card.BorderSizePixel    = 0
	card.ZIndex             = 8
	card.Parent             = screen
	round(card, 30); shadow(card)

	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(235, 240, 255)),
		ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
	}); g.Rotation = 128; g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.06), NumberSequenceKeypoint.new(1, 0.0),
	}); g.Parent = card

	local title = Instance.new("TextLabel")
	title.Size               = UDim2.new(1, -40, 0, 48)
	title.Position           = UDim2.new(0, 20, 0, 18)
	title.BackgroundTransparency = 1
	title.Text               = "✨  Hey " .. playerName .. "!"
	title.TextColor3         = Color3.fromRGB(38, 28, 78)
	title.TextSize           = 30
	title.Font               = Enum.Font.GothamBold
	title.TextXAlignment     = Enum.TextXAlignment.Center
	title.ZIndex             = 9; title.Parent = card

	local sub = Instance.new("TextLabel")
	sub.Size               = UDim2.new(1, -60, 0, 32)
	sub.Position           = UDim2.new(0, 30, 0, 72)
	sub.BackgroundTransparency = 1
	sub.Text               = "How are you feeling today?"
	sub.TextColor3         = Color3.fromRGB(78, 58, 130)
	sub.TextSize           = 21
	sub.Font               = Enum.Font.GothamSemibold
	sub.TextXAlignment     = Enum.TextXAlignment.Center
	sub.ZIndex             = 9; sub.Parent = card

	-- Input
	local ibg = Instance.new("Frame")
	ibg.Size               = UDim2.new(1, -60, 0, 52)
	ibg.Position           = UDim2.new(0, 30, 0, 116)
	ibg.BackgroundColor3   = Color3.fromRGB(245, 245, 255)
	ibg.BackgroundTransparency = 0.05
	ibg.BorderSizePixel    = 0
	ibg.ZIndex             = 9; ibg.Parent = card
	round(ibg, 26)

	local ring = Instance.new("UIStroke")
	ring.Thickness = 0; ring.Color = Color3.fromRGB(120, 100, 255)
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ring.Parent = ibg

	local inputField = Instance.new("TextBox")
	inputField.Size               = UDim2.new(1, -22, 1, 0)
	inputField.Position           = UDim2.new(0, 11, 0, 0)
	inputField.BackgroundTransparency = 1
	inputField.Text               = ""
	inputField.PlaceholderText    = "e.g.  I'm feeling a bit anxious today…"
	inputField.PlaceholderColor3  = Color3.fromRGB(160, 150, 200)
	inputField.TextColor3         = Color3.fromRGB(40, 30, 70)
	inputField.TextSize           = 17
	inputField.Font               = Enum.Font.Gotham
	inputField.ClearTextOnFocus   = false
	inputField.MultiLine          = false
	inputField.ZIndex             = 10; inputField.Parent = ibg

	inputField.Focused:Connect(function() tw(ring, { Thickness = 3 }, 0.2) end)
	inputField.FocusLost:Connect(function() tw(ring, { Thickness = 0 }, 0.2) end)

	local btn = makeStyledBtn(card, "✦  Explore My World", Color3.fromRGB(100, 80, 220), Color3.new(1,1,1), 186)

	local hint = Instance.new("TextLabel")
	hint.Size               = UDim2.new(1, -40, 0, 30)
	hint.Position           = UDim2.new(0, 20, 0, 250)
	hint.BackgroundTransparency = 1
	hint.Text               = "Powered by Gemini AI  ·  Your feelings are heard 💛"
	hint.TextColor3         = Color3.fromRGB(140, 130, 185)
	hint.TextSize           = 13
	hint.Font               = Enum.Font.Gotham
	hint.TextXAlignment     = Enum.TextXAlignment.Center
	hint.ZIndex             = 9; hint.Parent = card

	-- Change-name link
	local chgName = Instance.new("TextButton")
	chgName.Size               = UDim2.fromOffset(130, 26)
	chgName.AnchorPoint        = Vector2.new(1, 1)
	chgName.Position           = UDim2.new(1, -12, 1, -8)
	chgName.BackgroundTransparency = 1
	chgName.Text               = "✎ Change name"
	chgName.TextColor3         = Color3.fromRGB(120, 110, 180)
	chgName.TextSize           = 13
	chgName.Font               = Enum.Font.Gotham
	chgName.ZIndex             = 9; chgName.Parent = card
	chgName.MouseButton1Click:Connect(function()
		tw(card, { BackgroundTransparency = 1, Position = UDim2.new(0.5,0,0.35,0) }, 0.35)
		task.delay(0.4, function()
			screen:Destroy()
			buildNameEntry()
		end)
	end)

	card.BackgroundTransparency = 1
	tw(card, { Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 0.1 }, 0.75,
		Enum.EasingStyle.Back, Enum.EasingDirection.Out)

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
	screen.Parent            = gui

	local lbl = Instance.new("TextLabel")
	lbl.Size               = UDim2.new(0, 360, 0, 56)
	lbl.AnchorPoint        = Vector2.new(0.5, 0.5)
	lbl.Position           = UDim2.new(0.5, 0, 0.5, -22)
	lbl.BackgroundTransparency = 1
	lbl.Text               = labelText or "Reading your mood…"
	lbl.TextColor3         = Color3.fromRGB(220, 220, 255)
	lbl.TextSize           = 25
	lbl.Font               = Enum.Font.GothamBold
	lbl.ZIndex             = 26; lbl.Parent = screen

	local dotsF = Instance.new("Frame")
	dotsF.Size               = UDim2.fromOffset(88, 24)
	dotsF.AnchorPoint        = Vector2.new(0.5, 0)
	dotsF.Position           = UDim2.new(0.5, 0, 0.5, 28)
	dotsF.BackgroundTransparency = 1
	dotsF.ZIndex             = 26; dotsF.Parent = screen

	local dots = {}
	for i = 1, 3 do
		local d = Instance.new("Frame")
		d.Size               = UDim2.fromOffset(14, 14)
		d.Position           = UDim2.new(0, (i-1)*37, 0.5, -7)
		d.BackgroundColor3   = Color3.fromRGB(180, 160, 255)
		d.BorderSizePixel    = 0
		d.ZIndex             = 27; d.Parent = dotsF
		round(d, 50); dots[i] = d
	end

	local t = 0
	local c = RunService.Heartbeat:Connect(function(dt)
		t += dt
		for i, d in ipairs(dots) do
			if d.Parent then
				d.Position = UDim2.new(0, (i-1)*37, 0.5, -7 + math.sin(t*4+(i-1)*1.2)*7)
			end
		end
	end)

	return screen, c, lbl
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCREEN 3: Mood Reveal  (dramatic animated reveal with name)
-- ═══════════════════════════════════════════════════════════════════════════════

local function buildMoodReveal(mood, personalised, onPlay)
	local theme = MoodConfig.Themes[mood]

	local screen = Instance.new("Frame")
	screen.Name              = "MoodReveal"
	screen.Size              = UDim2.new(1, 0, 1, 0)
	screen.BackgroundTransparency = 1
	screen.ZIndex            = 20
	screen.Parent            = gui

	local card = Instance.new("Frame")
	card.Size               = UDim2.new(0, 500, 0, 0)
	card.AnchorPoint        = Vector2.new(0.5, 0.5)
	card.Position           = UDim2.new(0.5, 0, 0.5, 0)
	card.BackgroundColor3   = theme.cardColor
	card.BackgroundTransparency = 0.12
	card.BorderSizePixel    = 0
	card.ZIndex             = 21; card.Parent = screen
	round(card, 30); shadow(card); stroke(card, theme.accentColor, 1.5)

	local y = 20

	-- Big mood emoji
	local emojiLbl = Instance.new("TextLabel")
	emojiLbl.Size               = UDim2.fromOffset(80, 80)
	emojiLbl.AnchorPoint        = Vector2.new(0.5, 0)
	emojiLbl.Position           = UDim2.new(0.5, 0, 0, y)
	emojiLbl.BackgroundTransparency = 1
	emojiLbl.Text               = theme.emoji
	emojiLbl.TextSize           = 58
	emojiLbl.Font               = Enum.Font.GothamBold
	emojiLbl.ZIndex             = 22; emojiLbl.Parent = card
	y = y + 88

	-- "Hey [Name], you seem..."
	local greeting = Instance.new("TextLabel")
	greeting.Size               = UDim2.new(1, -40, 0, 42)
	greeting.AnchorPoint        = Vector2.new(0.5, 0)
	greeting.Position           = UDim2.new(0.5, 0, 0, y)
	greeting.BackgroundTransparency = 1
	greeting.Text               = "Hey " .. playerName .. ", you seem  " .. theme.label .. "  " .. theme.emoji
	greeting.TextColor3         = theme.textColor
	greeting.TextSize           = 26
	greeting.Font               = Enum.Font.GothamBold
	greeting.TextXAlignment     = Enum.TextXAlignment.Center
	greeting.ZIndex             = 22; greeting.Parent = card
	y = y + 50

	-- Gemini tagline
	local tagText = (personalised and personalised.tagline ~= "") and personalised.tagline or theme.tagline
	local tagLbl = Instance.new("TextLabel")
	tagLbl.Size               = UDim2.new(1, -60, 0, 52)
	tagLbl.AnchorPoint        = Vector2.new(0.5, 0)
	tagLbl.Position           = UDim2.new(0.5, 0, 0, y)
	tagLbl.BackgroundTransparency = 1
	tagLbl.Text               = tagText
	tagLbl.TextColor3         = theme.textColor
	tagLbl.TextSize           = 17
	tagLbl.Font               = Enum.Font.GothamSemibold
	tagLbl.TextWrapped        = true
	tagLbl.TextXAlignment     = Enum.TextXAlignment.Center
	tagLbl.ZIndex             = 22; tagLbl.Parent = card
	y = y + 58

	-- Gemini tip
	local tipText = personalised and personalised.tip or ""
	if tipText ~= "" then
		local tipBG = Instance.new("Frame")
		tipBG.Size               = UDim2.new(0.88, 0, 0, 44)
		tipBG.AnchorPoint        = Vector2.new(0.5, 0)
		tipBG.Position           = UDim2.new(0.5, 0, 0, y)
		tipBG.BackgroundColor3   = theme.accentColor
		tipBG.BackgroundTransparency = 0.35
		tipBG.BorderSizePixel    = 0
		tipBG.ZIndex             = 22; tipBG.Parent = card
		round(tipBG, 22)

		local tipLbl = Instance.new("TextLabel")
		tipLbl.Size               = UDim2.new(1, -16, 1, 0)
		tipLbl.Position           = UDim2.new(0, 8, 0, 0)
		tipLbl.BackgroundTransparency = 1
		tipLbl.Text               = "💡  " .. tipText
		tipLbl.TextColor3         = theme.textColor
		tipLbl.TextSize           = 14
		tipLbl.Font               = Enum.Font.Gotham
		tipLbl.TextWrapped        = true
		tipLbl.ZIndex             = 23; tipLbl.Parent = tipBG
		y = y + 52
	end

	-- Game chip
	local gameInfo = MoodConfig.GameInfo[theme.game]
	local chip = Instance.new("Frame")
	chip.Size               = UDim2.new(0.82, 0, 0, 42)
	chip.AnchorPoint        = Vector2.new(0.5, 0)
	chip.Position           = UDim2.new(0.5, 0, 0, y)
	chip.BackgroundColor3   = theme.accentColor
	chip.BackgroundTransparency = 0.22
	chip.BorderSizePixel    = 0
	chip.ZIndex             = 22; chip.Parent = card
	round(chip, 21)

	local chipLbl = Instance.new("TextLabel")
	chipLbl.Size               = UDim2.new(1, -14, 1, 0)
	chipLbl.Position           = UDim2.new(0, 7, 0, 0)
	chipLbl.BackgroundTransparency = 1
	chipLbl.Text               = gameInfo.icon .. "  Today's activity: " .. gameInfo.name
	chipLbl.TextColor3         = theme.textColor
	chipLbl.TextSize           = 16
	chipLbl.Font               = Enum.Font.GothamSemibold
	chipLbl.ZIndex             = 23; chipLbl.Parent = chip
	y = y + 52

	-- Timer preview badge
	local dur = theme.sessionDuration
	local timerBadge = Instance.new("TextLabel")
	timerBadge.Size               = UDim2.new(0, 120, 0, 26)
	timerBadge.AnchorPoint        = Vector2.new(0.5, 0)
	timerBadge.Position           = UDim2.new(0.5, 0, 0, y)
	timerBadge.BackgroundTransparency = 1
	timerBadge.Text               = "⏱  " .. dur .. "s session"
	timerBadge.TextColor3         = theme.textColor
	timerBadge.TextTransparency   = 0.3
	timerBadge.TextSize           = 14
	timerBadge.Font               = Enum.Font.Gotham
	timerBadge.ZIndex             = 22; timerBadge.Parent = card
	y = y + 34

	-- Play button
	local playBtn = makeStyledBtn(card, "Let's Go! →", theme.accentColor, theme.textColor, y, 0.65, 50)
	y = y + 62

	-- Expand card
	tw(card, { Size = UDim2.new(0, 500, 0, y) }, 0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	playBtn.MouseButton1Click:Connect(function()
		tw(card, { BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.34, 0) }, 0.4,
			Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.45, function()
			screen:Destroy()
			onPlay()
		end)
	end)

	-- Emoji bounce
	task.delay(0.55, function()
		if emojiLbl.Parent then
			tw(emojiLbl, { Position = UDim2.new(0.5, 0, 0, 10) }, 0.28, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
			task.delay(0.3, function()
				if emojiLbl.Parent then tw(emojiLbl, { Position = UDim2.new(0.5, 0, 0, 20) }, 0.28) end
			end)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- TIMER OVERLAY  (dynamic per mood session duration)
-- Returns a cleanup function.  onTimeUp fires when timer reaches 0.
-- ═══════════════════════════════════════════════════════════════════════════════

local function buildTimerOverlay(parent, theme, durationSecs, onTimeUp)
	-- Top-right pill with countdown + thin progress bar underneath top bar
	local pill = Instance.new("Frame")
	pill.Name               = "TimerPill"
	pill.Size               = UDim2.fromOffset(120, 36)
	pill.AnchorPoint        = Vector2.new(1, 0)
	pill.Position           = UDim2.new(1, -10, 0, 62)
	pill.BackgroundColor3   = theme.cardColor
	pill.BackgroundTransparency = 0.18
	pill.BorderSizePixel    = 0
	pill.ZIndex             = 18
	pill.Parent             = parent
	round(pill, 18)
	stroke(pill, theme.accentColor, 1)

	local timeLabel = Instance.new("TextLabel")
	timeLabel.Size               = UDim2.new(1, -8, 1, 0)
	timeLabel.Position           = UDim2.new(0, 4, 0, 0)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Text               = "⏱  " .. durationSecs .. "s"
	timeLabel.TextColor3         = theme.textColor
	timeLabel.TextSize           = 16
	timeLabel.Font               = Enum.Font.GothamBold
	timeLabel.ZIndex             = 19
	timeLabel.Parent             = pill

	-- Progress bar (full width strip at very top of screen)
	local barBG = Instance.new("Frame")
	barBG.Size               = UDim2.new(1, 0, 0, 4)
	barBG.Position           = UDim2.new(0, 0, 0, 56)
	barBG.BackgroundColor3   = theme.cardColor
	barBG.BackgroundTransparency = 0.5
	barBG.BorderSizePixel    = 0
	barBG.ZIndex             = 18
	barBG.Parent             = parent

	local barFill = Instance.new("Frame")
	barFill.Size               = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3   = theme.accentColor
	barFill.BorderSizePixel    = 0
	barFill.ZIndex             = 19
	barFill.Parent             = barBG

	-- Countdown
	local elapsed    = 0
	local fired      = false
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not pill.Parent then conn:Disconnect() return end
		elapsed = math.min(elapsed + dt, durationSecs)
		local remaining = durationSecs - elapsed
		local frac      = 1 - elapsed / durationSecs

		timeLabel.Text = "⏱  " .. math.ceil(remaining) .. "s"
		if barFill.Parent then
			barFill.Size = UDim2.new(frac, 0, 1, 0)
		end

		-- Warning colour change at 20%
		if frac < 0.2 then
			pill.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
			timeLabel.TextColor3  = Color3.new(1, 1, 1)
		elseif frac < 0.4 then
			pill.BackgroundColor3 = Color3.fromRGB(220, 140, 40)
		end

		-- Pulse last 10s
		if remaining <= 10 then
			local pulse = math.abs(math.sin(elapsed * math.pi * 2)) * 0.4
			pill.BackgroundTransparency = pulse
		end

		if elapsed >= durationSecs and not fired then
			fired = true
			conn:Disconnect()
			onTimeUp()
		end
	end)

	return function()
		conn:Disconnect()
		if pill.Parent    then pill:Destroy()  end
		if barBG.Parent   then barBG:Destroy() end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCREEN 5: Post-Game
-- ═══════════════════════════════════════════════════════════════════════════════

local function buildPostGameScreen(mood, gameName, postMsg, challenge, onReplay, onAlt, onHome)
	local theme = MoodConfig.Themes[mood]

	local screen = Instance.new("Frame")
	screen.Name              = "PostGame"
	screen.Size              = UDim2.new(1, 0, 1, 0)
	screen.BackgroundTransparency = 1
	screen.ZIndex            = 30
	screen.Parent            = gui

	local card = Instance.new("Frame")
	card.Size               = UDim2.new(0, 480, 0, 0)
	card.AnchorPoint        = Vector2.new(0.5, 0.5)
	card.Position           = UDim2.new(0.5, 0, 0.5, 0)
	card.BackgroundColor3   = theme.cardColor
	card.BackgroundTransparency = 0.1
	card.BorderSizePixel    = 0
	card.ZIndex             = 31; card.Parent = screen
	round(card, 28); shadow(card); stroke(card, theme.accentColor, 1.5)

	local y = 22

	local confetti = Instance.new("TextLabel")
	confetti.Size               = UDim2.fromOffset(60, 60)
	confetti.AnchorPoint        = Vector2.new(0.5, 0)
	confetti.Position           = UDim2.new(0.5, 0, 0, y)
	confetti.BackgroundTransparency = 1
	confetti.Text               = "🎉"
	confetti.TextSize           = 46
	confetti.Font               = Enum.Font.GothamBold
	confetti.ZIndex             = 32; confetti.Parent = card
	y = y + 68

	-- Post-game message
	local msgLbl = Instance.new("TextLabel")
	msgLbl.Size               = UDim2.new(1, -50, 0, 0)
	msgLbl.AnchorPoint        = Vector2.new(0.5, 0)
	msgLbl.Position           = UDim2.new(0.5, 0, 0, y)
	msgLbl.BackgroundTransparency = 1
	msgLbl.Text               = postMsg or "Amazing session, " .. playerName .. "! You did great."
	msgLbl.TextColor3         = theme.textColor
	msgLbl.TextSize           = 19
	msgLbl.Font               = Enum.Font.GothamBold
	msgLbl.TextWrapped        = true
	msgLbl.TextXAlignment     = Enum.TextXAlignment.Center
	msgLbl.AutomaticSize      = Enum.AutomaticSize.Y
	msgLbl.ZIndex             = 32; msgLbl.Parent = card
	y = y + 70

	-- Affirmation strip
	local aff = (currentGame and currentGame._affirmation) and currentGame._affirmation
		or (personalised and personalised.affirmation) or nil

	-- Daily challenge chip
	if challenge then
		local chalBG = Instance.new("Frame")
		chalBG.Size               = UDim2.new(0.9, 0, 0, 0)
		chalBG.AnchorPoint        = Vector2.new(0.5, 0)
		chalBG.Position           = UDim2.new(0.5, 0, 0, y)
		chalBG.BackgroundColor3   = theme.accentColor
		chalBG.BackgroundTransparency = 0.32
		chalBG.BorderSizePixel    = 0
		chalBG.AutomaticSize      = Enum.AutomaticSize.Y
		chalBG.ZIndex             = 32; chalBG.Parent = card
		round(chalBG, 14)

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0,12); pad.PaddingRight = UDim.new(0,12)
		pad.PaddingTop  = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8)
		pad.Parent = chalBG

		local chalTitle = Instance.new("TextLabel")
		chalTitle.Size               = UDim2.new(1, 0, 0, 20)
		chalTitle.BackgroundTransparency = 1
		chalTitle.Text               = "✦  " .. playerName .. "'s Wellness Challenge"
		chalTitle.TextColor3         = theme.textColor
		chalTitle.TextSize           = 13
		chalTitle.Font               = Enum.Font.GothamBold
		chalTitle.ZIndex             = 33; chalTitle.Parent = chalBG

		local chalLbl = Instance.new("TextLabel")
		chalLbl.Size               = UDim2.new(1, 0, 0, 0)
		chalLbl.Position           = UDim2.new(0, 0, 0, 22)
		chalLbl.BackgroundTransparency = 1
		chalLbl.Text               = challenge
		chalLbl.TextColor3         = theme.textColor
		chalLbl.TextSize           = 15
		chalLbl.Font               = Enum.Font.Gotham
		chalLbl.TextWrapped        = true
		chalLbl.AutomaticSize      = Enum.AutomaticSize.Y
		chalLbl.ZIndex             = 33; chalLbl.Parent = chalBG
		y = y + 92
	end

	y = y + 10

	local function dismissAndRun(action)
		tw(card, { BackgroundTransparency = 1, Position = UDim2.new(0.5,0,0.35,0) }, 0.35)
		task.delay(0.4, function()
			screen:Destroy()
			action()
		end)
	end

	local altInfo = MoodConfig.GameInfo[MoodConfig.Themes[mood].alternateGame]
	makeStyledBtn(card, "↺  Play Again",                  theme.accentColor, theme.textColor, y):MouseButton1Click:Connect(function() dismissAndRun(onReplay) end)
	y = y + 58
	makeStyledBtn(card, altInfo.icon.."  Try "..altInfo.name, theme.cardColor, theme.textColor, y):MouseButton1Click:Connect(function() dismissAndRun(onAlt) end)
	y = y + 58
	makeStyledBtn(card, "🏠  Return Home", Color3.fromRGB(70,70,110), Color3.fromRGB(210,215,255), y):MouseButton1Click:Connect(function() dismissAndRun(onHome) end)
	y = y + 62

	tw(card, { Size = UDim2.new(0, 480, 0, y) }, 0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	-- Confetti bounce
	task.delay(0.42, function()
		if confetti.Parent then
			tw(confetti, { Position = UDim2.new(0.5,0,0,10) }, 0.24, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
			task.delay(0.28, function()
				if confetti.Parent then tw(confetti, { Position = UDim2.new(0.5,0,0,22) }, 0.2) end
			end)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCREEN 4: Game Screen + timer
-- ═══════════════════════════════════════════════════════════════════════════════

local function launchGame(mood, gameName)
	local theme    = MoodConfig.Themes[mood]
	local gameInfo = MoodConfig.GameInfo[gameName]
	local duration = theme.sessionDuration or 90

	local screen = Instance.new("Frame")
	screen.Name              = "GameScreen"
	screen.Size              = UDim2.new(1, 0, 1, 0)
	screen.BackgroundTransparency = 1
	screen.ZIndex            = 10
	screen.Parent            = gui

	-- Top bar
	local topBar = Instance.new("Frame")
	topBar.Size               = UDim2.new(1, 0, 0, 56)
	topBar.BackgroundColor3   = theme.cardColor
	topBar.BackgroundTransparency = 0.18
	topBar.BorderSizePixel    = 0
	topBar.ZIndex             = 12; topBar.Parent = screen

	local tg = Instance.new("UIGradient")
	tg.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, theme.accentColor),
		ColorSequenceKeypoint.new(1, theme.cardColor),
	}); tg.Rotation = 90
	tg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.0), NumberSequenceKeypoint.new(1, 0.3),
	}); tg.Parent = topBar

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size               = UDim2.new(1, -110, 1, 0)
	titleLbl.Position           = UDim2.new(0, 14, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text               = gameInfo.icon .. "  " .. gameInfo.name
	titleLbl.TextColor3         = theme.textColor
	titleLbl.TextSize           = 20
	titleLbl.Font               = Enum.Font.GothamBold
	titleLbl.ZIndex             = 13; titleLbl.Parent = topBar

	local menuBtn = Instance.new("TextButton")
	menuBtn.Size               = UDim2.fromOffset(82, 32)
	menuBtn.AnchorPoint        = Vector2.new(1, 0.5)
	menuBtn.Position           = UDim2.new(1, -10, 0.5, 0)
	menuBtn.BackgroundColor3   = theme.accentColor
	menuBtn.BackgroundTransparency = 0.38
	menuBtn.BorderSizePixel    = 0
	menuBtn.Text               = "↩  Menu"
	menuBtn.TextColor3         = theme.textColor
	menuBtn.TextSize           = 14
	menuBtn.Font               = Enum.Font.GothamSemibold
	menuBtn.AutoButtonColor    = false
	menuBtn.ZIndex             = 13; menuBtn.Parent = topBar
	round(menuBtn, 16)

	-- Description strip
	local descLbl = Instance.new("TextLabel")
	descLbl.Size               = UDim2.new(1, 0, 0, 28)
	descLbl.Position           = UDim2.new(0, 0, 0, 56)
	descLbl.BackgroundColor3   = theme.accentColor
	descLbl.BackgroundTransparency = 0.58
	descLbl.BorderSizePixel    = 0
	descLbl.Text               = gameInfo.description
	descLbl.TextColor3         = theme.textColor
	descLbl.TextSize           = 13
	descLbl.Font               = Enum.Font.Gotham
	descLbl.TextXAlignment     = Enum.TextXAlignment.Center
	descLbl.ZIndex             = 12; descLbl.Parent = screen

	-- Game container
	local container = Instance.new("Frame")
	container.Name              = "GameContainer"
	container.Size              = UDim2.new(1, 0, 1, -84)
	container.Position          = UDim2.new(0, 0, 0, 84)
	container.BackgroundTransparency = 1
	container.ZIndex            = 11; container.Parent = screen

	-- Slide in
	screen.Position = UDim2.new(0, 0, 1, 0)
	tw(screen, { Position = UDim2.new(0, 0, 0, 0) }, 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	-- onComplete: called by game callback OR timer
	local cleanupTimer = nil
	local timerFired   = false
	local function onComplete()
		if timerFired then return end
		timerFired = true
		if cleanupTimer then cleanupTimer() end
		if currentGame then currentGame:Stop() end

		-- Fetch Gemini post-game content
		local loadScr, lConn = buildLoadingScreen("Getting your results…")
		task.spawn(function()
			local postMsg, challenge = nil, nil
			local ok1, r1 = pcall(function()
				return GetPostGameMessage:InvokeServer(mood, gameName, playerName)
			end)
			if ok1 then postMsg = r1 end

			local ok2, r2 = pcall(function()
				return GetDailyChallenge:InvokeServer(mood, playerName)
			end)
			if ok2 then challenge = r2 end

			lConn:Disconnect()
			tw(loadScr, { BackgroundTransparency = 1 }, 0.3)
			task.delay(0.35, function()
				if loadScr.Parent then loadScr:Destroy() end
				screen:Destroy()
				buildPostGameScreen(
					mood, gameName, postMsg, challenge,
					function() launchGame(mood, gameName) end,
					function() launchGame(mood, MoodConfig.Themes[mood].alternateGame) end,
					function() buildStartScreen_entry() end
				)
			end)
		end)
	end

	menuBtn.MouseButton1Click:Connect(onComplete)

	-- Load game module
	local modInst = Games:FindFirstChild(gameName)
	if modInst then
		local ok, GameModule = pcall(require, modInst)
		if ok then
			local g = GameModule.new()
			g:Start(container, theme, onComplete)
			currentGame = g

			-- StarSmash / MindfulTap: hook OnTimeUp if they support it
			cleanupTimer = buildTimerOverlay(screen, theme, duration, function()
				if g.OnTimeUp then
					g:OnTimeUp()
				else
					onComplete()
				end
			end)
		else
			warn("[MoodClient] require failed:", gameName, GameModule)
		end
	else
		local fb = Instance.new("TextLabel")
		fb.Size               = UDim2.new(1, 0, 1, 0)
		fb.BackgroundTransparency = 1
		fb.Text               = "🎮  " .. gameName .. " – coming soon!"
		fb.TextColor3         = theme.textColor
		fb.TextSize           = 26; fb.Font = Enum.Font.GothamBold
		fb.ZIndex             = 11; fb.Parent = container
		cleanupTimer = buildTimerOverlay(screen, theme, duration, onComplete)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- MAIN FLOW
-- ═══════════════════════════════════════════════════════════════════════════════

function buildStartScreen_entry()
	currentGame = nil
	-- Clear any mood scene so start screen looks clean
	if sceneObj then sceneObj:Stop(); sceneObj = nil end
	-- Restore neutral ambient during mood input
	startAmbient({
		ambient = {
			style  = "snowflake", count = 16,
			shapes = {"✦","·","⋆","○","✧","⊹"},
			color  = Color3.fromRGB(180, 195, 255),
		}
	})

	local screen, inputField, btn = buildStartScreen()

	local submitted = false
	local function submit()
		if submitted then return end
		local text = inputField.Text:match("^%s*(.-)%s*$")
		if text == "" then
			-- Shake the input box
			local orig = inputField.Parent.Position
			for i = 1, 4 do
				task.delay(i * 0.06, function()
					if inputField.Parent and inputField.Parent.Parent then
						inputField.Parent.Position = orig + UDim2.fromOffset((i%2==0 and 8 or -8), 0)
					end
				end)
			end
			task.delay(0.3, function()
				if inputField.Parent and inputField.Parent.Parent then
					inputField.Parent.Position = orig
				end
			end)
			return
		end

		submitted = true
		local userText = text

		tw(screen, { BackgroundTransparency = 0 }, 0.25)
		screen.BackgroundColor3 = Color3.fromRGB(8, 8, 24)
		task.delay(0.25, function() tw(screen, { BackgroundTransparency = 1 }, 0.3) end)
		task.delay(0.5, function()
			if screen.Parent then screen:Destroy() end

			local loadScr, dotConn, loadLbl = buildLoadingScreen("Reading your mood, " .. playerName .. "…")

			task.spawn(function()
				-- Step 1: Classify mood
				local mood = "neutral"
				local ok1, r1 = pcall(function()
					return AnalyzeMood:InvokeServer(userText)
				end)
				if ok1 and r1 then mood = r1 end

				-- Step 2: Personalised content (uses name)
				loadLbl.Text = "Crafting your experience…"
				local personalised = nil
				local ok2, r2 = pcall(function()
					return GetPersonalizedContent:InvokeServer(userText, mood, playerName)
				end)
				if ok2 then personalised = r2 end

				-- Apply full theme (background + lighting + music + scene + ambient)
				applyTheme(MoodConfig.Themes[mood])
				currentMood = mood
				volBtn.Visible = true

				dotConn:Disconnect()
				tw(loadScr, { BackgroundTransparency = 1 }, 0.4)
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

-- Boot: start with name entry
buildNameEntry()
