-- MoodClient v4 – show UI immediately, lazy remote init, full scene+music+ambient
-- Flow: NameEntry → StartScreen → Loading → MoodReveal → GameScreen+Timer → PostGame → loop

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local Lighting          = game:GetService("Lighting")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ─── Modules (require synchronously – they are ModuleScripts, always present) ─
local Modules      = ReplicatedStorage:WaitForChild("Modules")
local MoodConfig   = require(Modules:WaitForChild("MoodConfig"))
local AmbientLayer = require(Modules:WaitForChild("AmbientLayer"))
local SceneLayer   = require(Modules:WaitForChild("SceneLayer"))
local Games        = ReplicatedStorage:WaitForChild("Games")

-- ─── Remotes – initialised in background so UI shows immediately ──────────────
local remotes = {}
task.spawn(function()
	-- WaitForChild in background so buildNameEntry() runs right away
	remotes.AnalyzeMood            = ReplicatedStorage:WaitForChild("AnalyzeMood",            60)
	remotes.GetPersonalizedContent = ReplicatedStorage:WaitForChild("GetPersonalizedContent", 60)
	remotes.GetPostGameMessage     = ReplicatedStorage:WaitForChild("GetPostGameMessage",     60)
	remotes.GetDailyChallenge      = ReplicatedStorage:WaitForChild("GetDailyChallenge",      60)
	print("[MoodClient] All remotes ready")
end)

-- ─── State ────────────────────────────────────────────────────────────────────
local playerName   = player.Name
local currentMood  = nil
local currentGame  = nil
local bgMusic      = nil
local ambientObj   = nil
local sceneObj     = nil
local musicVolume  = 0.6
local gradTop      = Color3.fromRGB(14, 14, 40)
local gradBottom   = Color3.fromRGB(40, 20, 68)

-- ─── Helpers ──────────────────────────────────────────────────────────────────

local function tw(obj, props, dur, sty, dir)
	if not (obj and obj.Parent) then return end
	local ok, err = pcall(function()
		TweenService:Create(obj,
			TweenInfo.new(dur or 0.4, sty or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
			props):Play()
	end)
	if not ok then warn("[tw]", err) end
end

local function round(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 12)
	c.Parent = p
	return c
end

local function shadow(p)
	local s = Instance.new("ImageLabel")
	s.Size               = UDim2.new(1, 24, 1, 24)
	s.Position           = UDim2.new(0, -10, 0, 8)
	s.BackgroundTransparency = 1
	s.Image              = "rbxassetid://5028857084"
	s.ImageColor3        = Color3.fromRGB(0, 0, 0)
	s.ImageTransparency  = 0.72
	s.ZIndex             = math.max(0, (p.ZIndex or 5) - 1)
	s.ScaleType          = Enum.ScaleType.Slice
	s.SliceCenter        = Rect.new(24, 24, 276, 276)
	s.Parent             = p
	return s
end

local function stroke(p, col, th)
	local s = Instance.new("UIStroke")
	s.Color     = col or Color3.new(1,1,1)
	s.Thickness = th  or 1.5
	s.Transparency = 0.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
	return s
end

local function styledBtn(parent, text, bgCol, fgCol, yPos, wScale, h)
	local b = Instance.new("TextButton")
	b.Size               = UDim2.new(wScale or 0.74, 0, 0, h or 50)
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
	b.MouseEnter:Connect(function() tw(b, { BackgroundTransparency = 0.18 }, 0.12) end)
	b.MouseLeave:Connect(function() tw(b, { BackgroundTransparency = 0    }, 0.12) end)
	b.MouseButton1Down:Connect(function() tw(b, { BackgroundTransparency = 0.35 }, 0.06) end)
	return b
end

-- ─── Master ScreenGui ─────────────────────────────────────────────────────────

local gui = Instance.new("ScreenGui")
gui.Name           = "WellnessGui"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent         = playerGui

-- Full-screen background (gradient lives here; scene children go here)
local bgFrame = Instance.new("Frame")
bgFrame.Name             = "BG"
bgFrame.Size             = UDim2.new(1, 0, 1, 0)
bgFrame.BackgroundColor3 = gradTop
bgFrame.BorderSizePixel  = 0
bgFrame.ZIndex           = 1        -- ZIndex 1 so scene children (2-6) show clearly
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
	local lt  = theme.lighting
	local dur = MoodConfig.TransitionTime

	local ok, err = pcall(function()
		TweenService:Create(Lighting, TweenInfo.new(dur), {
			Ambient           = lt.Ambient,
			Brightness        = lt.Brightness,
			ColorShift_Bottom = lt.ColorShift_Bottom,
			ColorShift_Top    = lt.ColorShift_Top,
			OutdoorAmbient    = lt.OutdoorAmbient,
			FogEnd            = lt.FogEnd,
			FogColor          = lt.FogColor,
		}):Play()
	end)
	if not ok then warn("[Lighting tween]", err) end

	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atm then
		atm = Instance.new("Atmosphere")
		atm.Parent = Lighting
	end
	local at = theme.atmosphere
	pcall(function()
		TweenService:Create(atm, TweenInfo.new(dur), {
			Density = math.min(at.Density, 1),
			Offset  = at.Offset,
			Glare   = at.Glare,
			Haze    = math.min(at.Haze, 1),
		}):Play()
	end)
	task.delay(dur * 0.5, function()
		if atm.Parent then
			atm.Color = at.Color
			atm.Decay = at.Decay
		end
	end)
end

-- ─── Gradient transition ──────────────────────────────────────────────────────

local function transitionBG(theme)
	local s1, s2  = gradTop, gradBottom
	local dur, el = MoodConfig.TransitionTime, 0
	local conn; conn = RunService.Heartbeat:Connect(function(dt)
		el = math.min(el + dt, dur)
		local a = el / dur
		local function lerp(c1, c2, t)
			return Color3.new(c1.R+(c2.R-c1.R)*t, c1.G+(c2.G-c1.G)*t, c1.B+(c2.B-c1.B)*t)
		end
		bgGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, lerp(s1, theme.topColor,    a)),
			ColorSequenceKeypoint.new(1, lerp(s2, theme.bottomColor, a)),
		})
		if el >= dur then
			gradTop = theme.topColor; gradBottom = theme.bottomColor
			conn:Disconnect()
		end
	end)
end

-- ─── Music ────────────────────────────────────────────────────────────────────

local function playMusic(theme)
	local old = bgMusic
	if old then
		pcall(function() TweenService:Create(old, TweenInfo.new(1.2), { Volume = 0 }):Play() end)
		task.delay(1.3, function() if old and old.Parent then old:Destroy() end end)
	end
	local snd = Instance.new("Sound")
	snd.SoundId  = theme.music
	snd.Volume   = 0
	snd.Looped   = true
	snd.RollOffMaxDistance = 1e9
	snd.Parent   = SoundService
	snd:Play()
	pcall(function() TweenService:Create(snd, TweenInfo.new(2.5), { Volume = musicVolume }):Play() end)
	bgMusic = snd
end

-- ─── Scene ────────────────────────────────────────────────────────────────────

local function startScene(theme)
	if sceneObj then pcall(function() sceneObj:Stop() end) end
	local ok, result = pcall(function()
		return SceneLayer.new(bgFrame, theme.sceneStyle or "neutral")
	end)
	if ok then sceneObj = result
	else warn("[SceneLayer]", result) end
end

local function clearScene()
	if sceneObj then pcall(function() sceneObj:Stop() end); sceneObj = nil end
end

-- ─── Ambient particles ────────────────────────────────────────────────────────

local function startAmbient(theme)
	if ambientObj then pcall(function() ambientObj:Stop() end) end
	local ok, result = pcall(function()
		return AmbientLayer.new(bgFrame, theme)
	end)
	if ok then ambientObj = result
	else warn("[AmbientLayer]", result) end
end

-- ─── Full theme apply ─────────────────────────────────────────────────────────

local function applyTheme(theme)
	transitionBG(theme)
	applyLighting(theme)
	playMusic(theme)
	startScene(theme)
	startAmbient(theme)
end

-- ─── Volume button ────────────────────────────────────────────────────────────

local volBtn = Instance.new("TextButton")
volBtn.Name               = "VolumeBtn"
volBtn.Size               = UDim2.fromOffset(125, 36)
volBtn.AnchorPoint        = Vector2.new(1, 1)
volBtn.Position           = UDim2.new(1, -12, 1, -12)
volBtn.BackgroundColor3   = Color3.fromRGB(30, 30, 70)
volBtn.BackgroundTransparency = 0.25
volBtn.BorderSizePixel    = 0
volBtn.Text               = "🔊  Vol: 60%"
volBtn.TextColor3         = Color3.fromRGB(210, 215, 255)
volBtn.TextSize           = 14
volBtn.Font               = Enum.Font.GothamSemibold
volBtn.AutoButtonColor    = false
volBtn.ZIndex             = 60
volBtn.Visible            = false
volBtn.Parent             = gui
round(volBtn, 18)

local VOL_STEPS = {0, 0.2, 0.4, 0.6, 0.8, 1.0}
local volIdx    = 4  -- starts at 0.6

local function setVolume(v)
	musicVolume = v
	if bgMusic and bgMusic.Parent then bgMusic.Volume = v end
	local icon = v == 0 and "🔇" or (v < 0.4 and "🔉" or "🔊")
	volBtn.Text = icon .. "  Vol: " .. math.floor(v*100) .. "%"
end

volBtn.MouseButton1Click:Connect(function()
	volIdx = (volIdx % #VOL_STEPS) + 1
	setVolume(VOL_STEPS[volIdx])
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER: safe remote invoke (returns nil on failure)
-- ═══════════════════════════════════════════════════════════════════════════════

local function waitRemotes(timeoutSecs)
	local t = 0
	while (not remotes.AnalyzeMood) and t < timeoutSecs do
		task.wait(0.1)
		t += 0.1
	end
	return remotes.AnalyzeMood ~= nil
end

local function safeInvoke(remote, ...)
	if not remote then return nil end
	local ok, res = pcall(function(...) return remote:InvokeServer(...) end, ...)
	if ok then return res end
	warn("[Remote]", res)
	return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCREEN 0: Name Entry
-- ═══════════════════════════════════════════════════════════════════════════════

local buildStartScreen_entry  -- forward declaration

local function buildNameEntry()
	clearScene()
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
	screen.ZIndex            = 10
	screen.Parent            = gui

	local card = Instance.new("Frame")
	card.Size               = UDim2.new(0, 460, 0, 310)
	card.AnchorPoint        = Vector2.new(0.5, 0.5)
	card.Position           = UDim2.new(0.5, 0, 0.65, 0)
	card.BackgroundColor3   = Color3.fromRGB(255, 255, 255)
	card.BackgroundTransparency = 0.06
	card.BorderSizePixel    = 0
	card.ZIndex             = 12
	card.Parent             = screen
	round(card, 28)
	shadow(card)

	local cg = Instance.new("UIGradient")
	cg.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 238, 255)),
		ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
	}); cg.Rotation = 130; cg.Parent = card

	local logo = Instance.new("TextLabel")
	logo.Size               = UDim2.fromOffset(64, 64)
	logo.AnchorPoint        = Vector2.new(0.5, 0)
	logo.Position           = UDim2.new(0.5, 0, 0, 18)
	logo.BackgroundTransparency = 1
	logo.Text               = "✨"
	logo.TextSize           = 46
	logo.Font               = Enum.Font.GothamBold
	logo.ZIndex             = 13
	logo.Parent             = card

	local title = Instance.new("TextLabel")
	title.Size               = UDim2.new(1, -40, 0, 44)
	title.Position           = UDim2.new(0, 20, 0, 80)
	title.BackgroundTransparency = 1
	title.Text               = "Welcome to Wellness World"
	title.TextColor3         = Color3.fromRGB(36, 26, 76)
	title.TextSize           = 26
	title.Font               = Enum.Font.GothamBold
	title.TextXAlignment     = Enum.TextXAlignment.Center
	title.ZIndex             = 13; title.Parent = card

	local sub = Instance.new("TextLabel")
	sub.Size               = UDim2.new(1, -50, 0, 26)
	sub.Position           = UDim2.new(0, 25, 0, 128)
	sub.BackgroundTransparency = 1
	sub.Text               = "What would you like to be called?"
	sub.TextColor3         = Color3.fromRGB(76, 56, 126)
	sub.TextSize           = 18
	sub.Font               = Enum.Font.GothamSemibold
	sub.TextXAlignment     = Enum.TextXAlignment.Center
	sub.ZIndex             = 13; sub.Parent = card

	local ibg = Instance.new("Frame")
	ibg.Size               = UDim2.new(1, -60, 0, 50)
	ibg.Position           = UDim2.new(0, 30, 0, 164)
	ibg.BackgroundColor3   = Color3.fromRGB(242, 240, 255)
	ibg.BackgroundTransparency = 0.04
	ibg.BorderSizePixel    = 0
	ibg.ZIndex             = 13; ibg.Parent = card
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
	nameBox.PlaceholderColor3  = Color3.fromRGB(160, 148, 200)
	nameBox.TextColor3         = Color3.fromRGB(38, 28, 68)
	nameBox.TextSize           = 18
	nameBox.Font               = Enum.Font.Gotham
	nameBox.ClearTextOnFocus   = false
	nameBox.ZIndex             = 14; nameBox.Parent = ibg

	nameBox.Focused:Connect(function()  tw(ring, { Thickness = 3   }, 0.18) end)
	nameBox.FocusLost:Connect(function() tw(ring, { Thickness = 0   }, 0.18) end)

	local goBtn = styledBtn(card, "Let's Begin  →", Color3.fromRGB(100, 80, 220), Color3.new(1,1,1), 228)

	-- Animate card in
	card.BackgroundTransparency = 1
	tw(card, { Position = UDim2.new(0.5,0,0.5,0), BackgroundTransparency = 0.06 }, 0.72,
		Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	-- Logo sway
	local swayAngle = 0
	local swayConn = RunService.Heartbeat:Connect(function(dt)
		if not logo.Parent then return end
		swayAngle += dt
		logo.Rotation = math.sin(swayAngle * 1.3) * 10
	end)

	local function proceed()
		swayConn:Disconnect()
		local name = nameBox.Text:match("^%s*(.-)%s*$")
		if name == "" then name = player.Name end
		playerName = name:sub(1, 30)
		tw(card, { Position = UDim2.new(0.5,0,0.34,0), BackgroundTransparency = 1 }, 0.38,
			Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.42, function()
			screen:Destroy()
			buildStartScreen_entry()
		end)
	end

	goBtn.MouseButton1Click:Connect(proceed)
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
	screen.ZIndex            = 10
	screen.Parent            = gui

	local card = Instance.new("Frame")
	card.Size               = UDim2.new(0, 500, 0, 340)
	card.AnchorPoint        = Vector2.new(0.5, 0.5)
	card.Position           = UDim2.new(0.5, 0, 0.62, 0)
	card.BackgroundColor3   = Color3.fromRGB(255, 255, 255)
	card.BackgroundTransparency = 0.06
	card.BorderSizePixel    = 0
	card.ZIndex             = 12
	card.Parent             = screen
	round(card, 30); shadow(card)

	local cg = Instance.new("UIGradient")
	cg.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(234, 238, 255)),
		ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
	}); cg.Rotation = 128; cg.Parent = card

	local title = Instance.new("TextLabel")
	title.Size               = UDim2.new(1, -40, 0, 48)
	title.Position           = UDim2.new(0, 20, 0, 16)
	title.BackgroundTransparency = 1
	title.Text               = "✨  Hey " .. playerName .. "!"
	title.TextColor3         = Color3.fromRGB(36, 26, 76)
	title.TextSize           = 30
	title.Font               = Enum.Font.GothamBold
	title.TextXAlignment     = Enum.TextXAlignment.Center
	title.ZIndex             = 13; title.Parent = card

	local sub = Instance.new("TextLabel")
	sub.Size               = UDim2.new(1, -60, 0, 30)
	sub.Position           = UDim2.new(0, 30, 0, 68)
	sub.BackgroundTransparency = 1
	sub.Text               = "How are you feeling today?"
	sub.TextColor3         = Color3.fromRGB(76, 56, 128)
	sub.TextSize           = 21
	sub.Font               = Enum.Font.GothamSemibold
	sub.TextXAlignment     = Enum.TextXAlignment.Center
	sub.ZIndex             = 13; sub.Parent = card

	local ibg = Instance.new("Frame")
	ibg.Size               = UDim2.new(1, -60, 0, 52)
	ibg.Position           = UDim2.new(0, 30, 0, 110)
	ibg.BackgroundColor3   = Color3.fromRGB(242, 240, 255)
	ibg.BackgroundTransparency = 0.04
	ibg.BorderSizePixel    = 0
	ibg.ZIndex             = 13; ibg.Parent = card
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
	inputField.PlaceholderColor3  = Color3.fromRGB(158, 148, 200)
	inputField.TextColor3         = Color3.fromRGB(38, 28, 68)
	inputField.TextSize           = 17
	inputField.Font               = Enum.Font.Gotham
	inputField.ClearTextOnFocus   = false
	inputField.MultiLine          = false
	inputField.ZIndex             = 14; inputField.Parent = ibg

	inputField.Focused:Connect(function()  tw(ring, { Thickness = 3 }, 0.18) end)
	inputField.FocusLost:Connect(function() tw(ring, { Thickness = 0 }, 0.18) end)

	local btn = styledBtn(card, "✦  Explore My World", Color3.fromRGB(100, 80, 220), Color3.new(1,1,1), 178)

	local hint = Instance.new("TextLabel")
	hint.Size               = UDim2.new(1, -40, 0, 28)
	hint.Position           = UDim2.new(0, 20, 0, 244)
	hint.BackgroundTransparency = 1
	hint.Text               = "Powered by Gemini AI  ·  Your feelings are heard 💛"
	hint.TextColor3         = Color3.fromRGB(136, 126, 182)
	hint.TextSize           = 13
	hint.Font               = Enum.Font.Gotham
	hint.TextXAlignment     = Enum.TextXAlignment.Center
	hint.ZIndex             = 13; hint.Parent = card

	local chgName = Instance.new("TextButton")
	chgName.Size               = UDim2.fromOffset(130, 24)
	chgName.AnchorPoint        = Vector2.new(1, 1)
	chgName.Position           = UDim2.new(1, -10, 1, -6)
	chgName.BackgroundTransparency = 1
	chgName.Text               = "✎ Change name"
	chgName.TextColor3         = Color3.fromRGB(118, 108, 178)
	chgName.TextSize           = 13
	chgName.Font               = Enum.Font.Gotham
	chgName.ZIndex             = 13; chgName.Parent = card
	chgName.MouseButton1Click:Connect(function()
		tw(card, { BackgroundTransparency = 1, Position = UDim2.new(0.5,0,0.34,0) }, 0.32)
		task.delay(0.36, function()
			screen:Destroy()
			buildNameEntry()
		end)
	end)

	card.BackgroundTransparency = 1
	tw(card, { Position = UDim2.new(0.5,0,0.5,0), BackgroundTransparency = 0.06 }, 0.72,
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
	screen.BackgroundColor3  = Color3.fromRGB(8, 6, 24)
	screen.BackgroundTransparency = 0.3
	screen.BorderSizePixel   = 0
	screen.ZIndex            = 30
	screen.Parent            = gui

	local lbl = Instance.new("TextLabel")
	lbl.Size               = UDim2.new(0, 380, 0, 54)
	lbl.AnchorPoint        = Vector2.new(0.5, 0.5)
	lbl.Position           = UDim2.new(0.5, 0, 0.5, -22)
	lbl.BackgroundTransparency = 1
	lbl.Text               = labelText or "Reading your mood…"
	lbl.TextColor3         = Color3.fromRGB(220, 218, 255)
	lbl.TextSize           = 24
	lbl.Font               = Enum.Font.GothamBold
	lbl.ZIndex             = 31; lbl.Parent = screen

	local dotsF = Instance.new("Frame")
	dotsF.Size               = UDim2.fromOffset(90, 24)
	dotsF.AnchorPoint        = Vector2.new(0.5, 0)
	dotsF.Position           = UDim2.new(0.5, 0, 0.5, 28)
	dotsF.BackgroundTransparency = 1
	dotsF.ZIndex             = 31; dotsF.Parent = screen

	local dots = {}
	for i = 1, 3 do
		local d = Instance.new("Frame")
		d.Size               = UDim2.fromOffset(14, 14)
		d.Position           = UDim2.new(0, (i-1)*38, 0.5, -7)
		d.BackgroundColor3   = Color3.fromRGB(180, 158, 255)
		d.BorderSizePixel    = 0
		d.ZIndex             = 32; d.Parent = dotsF
		round(d, 50); dots[i] = d
	end

	local t = 0
	local conn = RunService.Heartbeat:Connect(function(dt)
		t += dt
		for i, d in ipairs(dots) do
			if d.Parent then
				d.Position = UDim2.new(0, (i-1)*38, 0.5, -7 + math.sin(t*4+(i-1)*1.2)*7)
			end
		end
	end)

	return screen, conn, lbl
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCREEN 3: Mood Reveal
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
	card.BackgroundTransparency = 0.08
	card.BorderSizePixel    = 0
	card.ZIndex             = 22; card.Parent = screen
	round(card, 30); shadow(card); stroke(card, theme.accentColor, 2)

	local y = 18

	local emojiLbl = Instance.new("TextLabel")
	emojiLbl.Size               = UDim2.fromOffset(80, 80)
	emojiLbl.AnchorPoint        = Vector2.new(0.5, 0)
	emojiLbl.Position           = UDim2.new(0.5, 0, 0, y)
	emojiLbl.BackgroundTransparency = 1
	emojiLbl.Text               = theme.emoji
	emojiLbl.TextSize           = 56
	emojiLbl.Font               = Enum.Font.GothamBold
	emojiLbl.ZIndex             = 23; emojiLbl.Parent = card
	y += 86

	local greeting = Instance.new("TextLabel")
	greeting.Size               = UDim2.new(1, -40, 0, 40)
	greeting.AnchorPoint        = Vector2.new(0.5, 0)
	greeting.Position           = UDim2.new(0.5, 0, 0, y)
	greeting.BackgroundTransparency = 1
	greeting.Text               = "Hey " .. playerName .. ", you seem " .. theme.label .. " " .. theme.emoji
	greeting.TextColor3         = theme.textColor
	greeting.TextSize           = 25
	greeting.Font               = Enum.Font.GothamBold
	greeting.TextXAlignment     = Enum.TextXAlignment.Center
	greeting.ZIndex             = 23; greeting.Parent = card
	y += 48

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
	tagLbl.ZIndex             = 23; tagLbl.Parent = card
	y += 56

	local tipText = personalised and personalised.tip or ""
	if tipText ~= "" then
		local tipBG = Instance.new("Frame")
		tipBG.Size               = UDim2.new(0.88, 0, 0, 42)
		tipBG.AnchorPoint        = Vector2.new(0.5, 0)
		tipBG.Position           = UDim2.new(0.5, 0, 0, y)
		tipBG.BackgroundColor3   = theme.accentColor
		tipBG.BackgroundTransparency = 0.3
		tipBG.BorderSizePixel    = 0
		tipBG.ZIndex             = 23; tipBG.Parent = card
		round(tipBG, 21)
		local tl = Instance.new("TextLabel")
		tl.Size               = UDim2.new(1, -14, 1, 0)
		tl.Position           = UDim2.new(0, 7, 0, 0)
		tl.BackgroundTransparency = 1
		tl.Text               = "💡  " .. tipText
		tl.TextColor3         = theme.textColor
		tl.TextSize           = 14
		tl.Font               = Enum.Font.Gotham
		tl.TextWrapped        = true
		tl.ZIndex             = 24; tl.Parent = tipBG
		y += 50
	end

	local gameInfo = MoodConfig.GameInfo[theme.game]
	local chip = Instance.new("Frame")
	chip.Size               = UDim2.new(0.82, 0, 0, 42)
	chip.AnchorPoint        = Vector2.new(0.5, 0)
	chip.Position           = UDim2.new(0.5, 0, 0, y)
	chip.BackgroundColor3   = theme.accentColor
	chip.BackgroundTransparency = 0.2
	chip.BorderSizePixel    = 0
	chip.ZIndex             = 23; chip.Parent = card
	round(chip, 21)
	local cl = Instance.new("TextLabel")
	cl.Size               = UDim2.new(1, -14, 1, 0)
	cl.Position           = UDim2.new(0, 7, 0, 0)
	cl.BackgroundTransparency = 1
	cl.Text               = gameInfo.icon .. "  Today's activity: " .. gameInfo.name
	cl.TextColor3         = theme.textColor
	cl.TextSize           = 16
	cl.Font               = Enum.Font.GothamSemibold
	cl.ZIndex             = 24; cl.Parent = chip
	y += 50

	local timerBadge = Instance.new("TextLabel")
	timerBadge.Size               = UDim2.new(0, 130, 0, 24)
	timerBadge.AnchorPoint        = Vector2.new(0.5, 0)
	timerBadge.Position           = UDim2.new(0.5, 0, 0, y)
	timerBadge.BackgroundTransparency = 1
	timerBadge.Text               = "⏱  " .. (theme.sessionDuration or 90) .. "s session"
	timerBadge.TextColor3         = theme.textColor
	timerBadge.TextTransparency   = 0.25
	timerBadge.TextSize           = 14
	timerBadge.Font               = Enum.Font.Gotham
	timerBadge.ZIndex             = 23; timerBadge.Parent = card
	y += 32

	local playBtn = styledBtn(card, "Let's Go! →", theme.accentColor, theme.textColor, y, 0.65, 50)
	y += 60

	tw(card, { Size = UDim2.new(0, 500, 0, y) }, 0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	playBtn.MouseButton1Click:Connect(function()
		tw(card, { BackgroundTransparency = 1, Position = UDim2.new(0.5,0,0.34,0) }, 0.38,
			Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.42, function()
			screen:Destroy()
			onPlay()
		end)
	end)

	task.delay(0.55, function()
		if emojiLbl.Parent then
			tw(emojiLbl, { Position = UDim2.new(0.5,0,0,10) }, 0.26, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
			task.delay(0.3, function()
				if emojiLbl.Parent then tw(emojiLbl, { Position = UDim2.new(0.5,0,0,18) }, 0.26) end
			end)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- TIMER OVERLAY
-- ═══════════════════════════════════════════════════════════════════════════════

local function buildTimerOverlay(parent, theme, durationSecs, onTimeUp)
	local pill_ = Instance.new("Frame")
	pill_.Size               = UDim2.fromOffset(120, 34)
	pill_.AnchorPoint        = Vector2.new(1, 0)
	pill_.Position           = UDim2.new(1, -10, 0, 60)
	pill_.BackgroundColor3   = theme.cardColor
	pill_.BackgroundTransparency = 0.18
	pill_.BorderSizePixel    = 0
	pill_.ZIndex             = 18; pill_.Parent = parent
	round(pill_, 17); stroke(pill_, theme.accentColor, 1)

	local timeLbl = Instance.new("TextLabel")
	timeLbl.Size               = UDim2.new(1, -8, 1, 0)
	timeLbl.Position           = UDim2.new(0, 4, 0, 0)
	timeLbl.BackgroundTransparency = 1
	timeLbl.Text               = "⏱  " .. durationSecs .. "s"
	timeLbl.TextColor3         = theme.textColor
	timeLbl.TextSize           = 15
	timeLbl.Font               = Enum.Font.GothamBold
	timeLbl.ZIndex             = 19; timeLbl.Parent = pill_

	local barBG = Instance.new("Frame")
	barBG.Size               = UDim2.new(1, 0, 0, 4)
	barBG.Position           = UDim2.new(0, 0, 0, 56)
	barBG.BackgroundColor3   = theme.cardColor
	barBG.BackgroundTransparency = 0.5
	barBG.BorderSizePixel    = 0
	barBG.ZIndex             = 18; barBG.Parent = parent

	local barFill = Instance.new("Frame")
	barFill.Size               = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3   = theme.accentColor
	barFill.BorderSizePixel    = 0
	barFill.ZIndex             = 19; barFill.Parent = barBG

	local elapsed = 0; local fired = false
	local conn; conn = RunService.Heartbeat:Connect(function(dt)
		if not pill_.Parent then conn:Disconnect() return end
		elapsed = math.min(elapsed + dt, durationSecs)
		local remaining = durationSecs - elapsed
		local frac      = 1 - elapsed / durationSecs
		timeLbl.Text = "⏱  " .. math.ceil(remaining) .. "s"
		if barFill.Parent then barFill.Size = UDim2.new(frac, 0, 1, 0) end
		if frac < 0.2 then
			pill_.BackgroundColor3 = Color3.fromRGB(220, 55, 55)
			timeLbl.TextColor3     = Color3.new(1,1,1)
		elseif frac < 0.4 then
			pill_.BackgroundColor3 = Color3.fromRGB(218, 138, 38)
		end
		if remaining <= 10 then
			pill_.BackgroundTransparency = math.abs(math.sin(elapsed * math.pi * 2)) * 0.4
		end
		if elapsed >= durationSecs and not fired then
			fired = true; conn:Disconnect(); onTimeUp()
		end
	end)

	return function()
		conn:Disconnect()
		if pill_.Parent  then pill_:Destroy()  end
		if barBG.Parent  then barBG:Destroy()  end
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
	card.BackgroundTransparency = 0.08
	card.BorderSizePixel    = 0
	card.ZIndex             = 32; card.Parent = screen
	round(card, 28); shadow(card); stroke(card, theme.accentColor, 2)

	local y = 20

	local confetti = Instance.new("TextLabel")
	confetti.Size               = UDim2.fromOffset(60, 60)
	confetti.AnchorPoint        = Vector2.new(0.5, 0)
	confetti.Position           = UDim2.new(0.5, 0, 0, y)
	confetti.BackgroundTransparency = 1
	confetti.Text               = "🎉"
	confetti.TextSize           = 46
	confetti.Font               = Enum.Font.GothamBold
	confetti.ZIndex             = 33; confetti.Parent = card
	y += 66

	local msgLbl = Instance.new("TextLabel")
	msgLbl.Size               = UDim2.new(1, -50, 0, 0)
	msgLbl.AnchorPoint        = Vector2.new(0.5, 0)
	msgLbl.Position           = UDim2.new(0.5, 0, 0, y)
	msgLbl.BackgroundTransparency = 1
	msgLbl.Text               = postMsg or ("Great session, " .. playerName .. "! You did amazing.")
	msgLbl.TextColor3         = theme.textColor
	msgLbl.TextSize           = 19
	msgLbl.Font               = Enum.Font.GothamBold
	msgLbl.TextWrapped        = true
	msgLbl.TextXAlignment     = Enum.TextXAlignment.Center
	msgLbl.AutomaticSize      = Enum.AutomaticSize.Y
	msgLbl.ZIndex             = 33; msgLbl.Parent = card
	y += 68

	if challenge then
		local chalBG = Instance.new("Frame")
		chalBG.Size               = UDim2.new(0.9, 0, 0, 0)
		chalBG.AnchorPoint        = Vector2.new(0.5, 0)
		chalBG.Position           = UDim2.new(0.5, 0, 0, y)
		chalBG.BackgroundColor3   = theme.accentColor
		chalBG.BackgroundTransparency = 0.28
		chalBG.BorderSizePixel    = 0
		chalBG.AutomaticSize      = Enum.AutomaticSize.Y
		chalBG.ZIndex             = 33; chalBG.Parent = card
		round(chalBG, 13)
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0,12); pad.PaddingRight = UDim.new(0,12)
		pad.PaddingTop  = UDim.new(0,8);  pad.PaddingBottom = UDim.new(0,8)
		pad.Parent = chalBG

		local ct = Instance.new("TextLabel")
		ct.Size               = UDim2.new(1,0,0,20)
		ct.BackgroundTransparency = 1
		ct.Text               = "✦  " .. playerName .. "'s Wellness Challenge"
		ct.TextColor3         = theme.textColor
		ct.TextSize           = 13
		ct.Font               = Enum.Font.GothamBold
		ct.ZIndex             = 34; ct.Parent = chalBG

		local cl2 = Instance.new("TextLabel")
		cl2.Size               = UDim2.new(1,0,0,0)
		cl2.Position           = UDim2.new(0,0,0,22)
		cl2.BackgroundTransparency = 1
		cl2.Text               = challenge
		cl2.TextColor3         = theme.textColor
		cl2.TextSize           = 15
		cl2.Font               = Enum.Font.Gotham
		cl2.TextWrapped        = true
		cl2.AutomaticSize      = Enum.AutomaticSize.Y
		cl2.ZIndex             = 34; cl2.Parent = chalBG
		y += 90
	end

	y += 8

	local function go(action)
		tw(card, { BackgroundTransparency = 1, Position = UDim2.new(0.5,0,0.34,0) }, 0.32)
		task.delay(0.36, function() screen:Destroy(); action() end)
	end

	local altInfo = MoodConfig.GameInfo[MoodConfig.Themes[mood].alternateGame]
	styledBtn(card, "↺  Play Again", theme.accentColor, theme.textColor, y)
		.MouseButton1Click:Connect(function() go(onReplay) end)
	y += 56
	styledBtn(card, altInfo.icon .. "  Try " .. altInfo.name, theme.cardColor, theme.textColor, y)
		.MouseButton1Click:Connect(function() go(onAlt) end)
	y += 56
	styledBtn(card, "🏠  Return Home", Color3.fromRGB(68, 68, 108), Color3.fromRGB(210, 214, 255), y)
		.MouseButton1Click:Connect(function() go(onHome) end)
	y += 62

	tw(card, { Size = UDim2.new(0, 480, 0, y) }, 0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	task.delay(0.4, function()
		if confetti.Parent then
			tw(confetti, { Position = UDim2.new(0.5,0,0,8) }, 0.22, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
			task.delay(0.26, function()
				if confetti.Parent then tw(confetti, { Position = UDim2.new(0.5,0,0,20) }, 0.2) end
			end)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCREEN 4: Game Screen + Timer
-- ═══════════════════════════════════════════════════════════════════════════════

local function launchGame(mood, gameName)
	local theme    = MoodConfig.Themes[mood]
	local gameInfo = MoodConfig.GameInfo[gameName]
	local duration = theme.sessionDuration or 90

	local screen = Instance.new("Frame")
	screen.Name              = "GameScreen"
	screen.Size              = UDim2.new(1, 0, 1, 0)
	screen.BackgroundTransparency = 1
	screen.ZIndex            = 15
	screen.Parent            = gui

	-- Top bar
	local topBar = Instance.new("Frame")
	topBar.Size               = UDim2.new(1, 0, 0, 56)
	topBar.BackgroundColor3   = theme.cardColor
	topBar.BackgroundTransparency = 0.15
	topBar.BorderSizePixel    = 0
	topBar.ZIndex             = 17; topBar.Parent = screen

	local tg = Instance.new("UIGradient")
	tg.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, theme.accentColor),
		ColorSequenceKeypoint.new(1, theme.cardColor),
	}); tg.Rotation = 90
	tg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0,0.0), NumberSequenceKeypoint.new(1,0.3)
	}); tg.Parent = topBar

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size               = UDim2.new(1, -110, 1, 0)
	titleLbl.Position           = UDim2.new(0, 14, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text               = gameInfo.icon .. "  " .. gameInfo.name
	titleLbl.TextColor3         = theme.textColor
	titleLbl.TextSize           = 20
	titleLbl.Font               = Enum.Font.GothamBold
	titleLbl.ZIndex             = 18; titleLbl.Parent = topBar

	local menuBtn = Instance.new("TextButton")
	menuBtn.Size               = UDim2.fromOffset(82, 32)
	menuBtn.AnchorPoint        = Vector2.new(1, 0.5)
	menuBtn.Position           = UDim2.new(1, -10, 0.5, 0)
	menuBtn.BackgroundColor3   = theme.accentColor
	menuBtn.BackgroundTransparency = 0.35
	menuBtn.BorderSizePixel    = 0
	menuBtn.Text               = "↩  Menu"
	menuBtn.TextColor3         = theme.textColor
	menuBtn.TextSize           = 14
	menuBtn.Font               = Enum.Font.GothamSemibold
	menuBtn.AutoButtonColor    = false
	menuBtn.ZIndex             = 18; menuBtn.Parent = topBar
	round(menuBtn, 16)

	local descLbl = Instance.new("TextLabel")
	descLbl.Size               = UDim2.new(1, 0, 0, 28)
	descLbl.Position           = UDim2.new(0, 0, 0, 56)
	descLbl.BackgroundColor3   = theme.accentColor
	descLbl.BackgroundTransparency = 0.55
	descLbl.BorderSizePixel    = 0
	descLbl.Text               = gameInfo.description
	descLbl.TextColor3         = theme.textColor
	descLbl.TextSize           = 13
	descLbl.Font               = Enum.Font.Gotham
	descLbl.TextXAlignment     = Enum.TextXAlignment.Center
	descLbl.ZIndex             = 17; descLbl.Parent = screen

	local container = Instance.new("Frame")
	container.Name              = "GameContainer"
	container.Size              = UDim2.new(1, 0, 1, -84)
	container.Position          = UDim2.new(0, 0, 0, 84)
	container.BackgroundTransparency = 1
	container.ZIndex            = 16; container.Parent = screen

	screen.Position = UDim2.new(0, 0, 1, 0)
	tw(screen, { Position = UDim2.new(0, 0, 0, 0) }, 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	local cleanupTimer = nil
	local timerFired   = false

	local function onComplete()
		if timerFired then return end
		timerFired = true
		if cleanupTimer then cleanupTimer() end
		if currentGame then pcall(function() currentGame:Stop() end) end

		local loadScr, lConn = buildLoadingScreen("Getting your results…")
		task.spawn(function()
			local postMsg   = safeInvoke(remotes.GetPostGameMessage,  mood, gameName, playerName)
			local challenge = safeInvoke(remotes.GetDailyChallenge,   mood, playerName)

			lConn:Disconnect()
			tw(loadScr, { BackgroundTransparency = 1 }, 0.3)
			task.delay(0.35, function()
				if loadScr.Parent then loadScr:Destroy() end
				screen:Destroy()
				buildPostGameScreen(mood, gameName, postMsg, challenge,
					function() launchGame(mood, gameName) end,
					function() launchGame(mood, MoodConfig.Themes[mood].alternateGame) end,
					function() buildStartScreen_entry() end
				)
			end)
		end)
	end

	menuBtn.MouseButton1Click:Connect(onComplete)

	local modInst = Games:FindFirstChild(gameName)
	if modInst then
		local ok, GameModule = pcall(require, modInst)
		if ok then
			local g = GameModule.new()
			g:Start(container, theme, onComplete)
			currentGame = g
			cleanupTimer = buildTimerOverlay(screen, theme, duration, function()
				if g.OnTimeUp then g:OnTimeUp() else onComplete() end
			end)
		else
			warn("[MoodClient] require failed:", gameName, tostring(GameModule))
			cleanupTimer = buildTimerOverlay(screen, theme, duration, onComplete)
		end
	else
		local fb = Instance.new("TextLabel")
		fb.Size               = UDim2.new(1, 0, 1, 0)
		fb.BackgroundTransparency = 1
		fb.Text               = "🎮  " .. gameName .. " — coming soon!"
		fb.TextColor3         = theme.textColor
		fb.TextSize           = 26; fb.Font = Enum.Font.GothamBold
		fb.ZIndex             = 16; fb.Parent = container
		cleanupTimer = buildTimerOverlay(screen, theme, duration, onComplete)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- MAIN FLOW
-- ═══════════════════════════════════════════════════════════════════════════════

function buildStartScreen_entry()
	currentGame = nil
	clearScene()

	-- Restore calm starfield ambient during mood input
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
			local orig = inputField.Parent.Position
			for i = 1, 4 do
				task.delay(i * 0.06, function()
					if inputField.Parent and inputField.Parent.Parent then
						inputField.Parent.Position = orig + UDim2.fromOffset(i%2==0 and 8 or -8, 0)
					end
				end)
			end
			task.delay(0.28, function()
				if inputField.Parent and inputField.Parent.Parent then
					inputField.Parent.Position = orig
				end
			end)
			return
		end

		submitted = true
		local userText = text

		tw(screen, { BackgroundTransparency = 0 }, 0.22)
		screen.BackgroundColor3 = Color3.fromRGB(6, 4, 20)
		task.delay(0.22, function() tw(screen, { BackgroundTransparency = 1 }, 0.28) end)
		task.delay(0.46, function()
			if screen.Parent then screen:Destroy() end

			local loadScr, dotConn, loadLbl = buildLoadingScreen("Reading your mood, " .. playerName .. "…")

			task.spawn(function()
				-- Wait for server remotes (non-blocking during name entry)
				if not remotes.AnalyzeMood then
					loadLbl.Text = "Connecting to server…"
					waitRemotes(25)
				end

				-- Mood classification
				local mood = "neutral"
				loadLbl.Text = "Reading your mood, " .. playerName .. "…"
				local r1 = safeInvoke(remotes.AnalyzeMood, userText)
				if r1 and type(r1) == "string" then mood = r1 end

				-- Personalised content
				loadLbl.Text = "Crafting your world…"
				local personalised = safeInvoke(remotes.GetPersonalizedContent, userText, mood, playerName)

				-- Apply full mood theme
				applyTheme(MoodConfig.Themes[mood])
				currentMood = mood
				volBtn.Visible = true

				dotConn:Disconnect()
				tw(loadScr, { BackgroundTransparency = 1 }, 0.38)
				task.delay(0.42, function()
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

-- Boot – show name entry IMMEDIATELY, remotes initialise in background
buildNameEntry()
