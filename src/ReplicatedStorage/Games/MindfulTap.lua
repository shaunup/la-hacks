-- MindfulTap: mindful awareness orb-tapping game
-- Glowing orbs appear at calm intervals; tap each one for a satisfying
-- mindful moment + a small affirmation word. Combo multiplier rewards focus.
-- Works for happy, neutral, excited as a lighter, joyful activity.
-- Interface: .new() → :Start(container, theme, onComplete) → :Stop()
-- onComplete is called by the external timer (timer overlay calls onTimeUp)

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local MindfulTap = {}
MindfulTap.__index = MindfulTap

local ORB_WORDS = {
	"Present","Breathe","Aware","Notice","Here","Now",
	"Gentle","Focus","Calm","Kind","Open","Free",
	"Joy","Bright","Light","Warm","Peace","Alive",
}

local ORB_COLORS = {
	Color3.fromRGB(255, 200,  80),
	Color3.fromRGB(100, 220, 200),
	Color3.fromRGB(200, 140, 255),
	Color3.fromRGB(120, 200, 255),
	Color3.fromRGB(255, 160, 120),
	Color3.fromRGB(160, 255, 160),
}

local COMBO_LABELS = { "✦ Good", "✦✦ Nice!", "✦✦✦ Great!", "✦✦✦✦ Amazing!", "✦✦✦✦✦ PERFECT!" }

-- Spawn interval decreases slightly as score increases (flow state curve)
local function spawnInterval(score)
	return math.max(0.9, 2.2 - score * 0.04)
end

function MindfulTap.new()
	return setmetatable({
		_connections = {},
		_active      = false,
		_score       = 0,
		_combo       = 0,
	}, MindfulTap)
end

function MindfulTap:Start(container, theme, onComplete)
	self._active     = true
	self._score      = 0
	self._combo      = 0
	self._container  = container
	self._theme      = theme
	self._onComplete = onComplete
	self:_buildUI()
	self:_spawnLoop()
end

function MindfulTap:_buildUI()
	local theme = self._theme

	local header = Instance.new("TextLabel")
	header.Size               = UDim2.new(1, 0, 0, 42)
	header.BackgroundTransparency = 1
	header.Text               = "🌟  Mindful Tap — be present with each orb"
	header.TextColor3         = theme.textColor
	header.TextSize           = 20
	header.Font               = Enum.Font.GothamBold
	header.TextXAlignment     = Enum.TextXAlignment.Center
	header.ZIndex             = 10
	header.Parent             = self._container

	local scoreLbl = Instance.new("TextLabel")
	scoreLbl.Name               = "MTScore"
	scoreLbl.Size               = UDim2.new(0, 160, 0, 34)
	scoreLbl.AnchorPoint        = Vector2.new(0.5, 0)
	scoreLbl.Position           = UDim2.new(0.5, 0, 0, 46)
	scoreLbl.BackgroundTransparency = 1
	scoreLbl.Text               = "Orbs: 0"
	scoreLbl.TextColor3         = theme.accentColor
	scoreLbl.TextSize           = 22
	scoreLbl.Font               = Enum.Font.GothamBold
	scoreLbl.ZIndex             = 10
	scoreLbl.Parent             = self._container
	self._scoreLbl = scoreLbl

	local comboLbl = Instance.new("TextLabel")
	comboLbl.Name               = "MTCombo"
	comboLbl.Size               = UDim2.new(0, 200, 0, 28)
	comboLbl.AnchorPoint        = Vector2.new(0.5, 0)
	comboLbl.Position           = UDim2.new(0.5, 0, 0, 82)
	comboLbl.BackgroundTransparency = 1
	comboLbl.Text               = ""
	comboLbl.TextColor3         = theme.accentColor
	comboLbl.TextSize           = 17
	comboLbl.Font               = Enum.Font.GothamSemibold
	comboLbl.ZIndex             = 10
	comboLbl.Parent             = self._container
	self._comboLbl = comboLbl

	-- Canvas for orbs
	local canvas = Instance.new("Frame")
	canvas.Name              = "MTCanvas"
	canvas.Size              = UDim2.new(1, 0, 1, -118)
	canvas.Position          = UDim2.new(0, 0, 0, 118)
	canvas.BackgroundTransparency = 1
	canvas.ZIndex            = 9
	canvas.Parent            = self._container
	self._canvas = canvas
end

function MindfulTap:_spawnLoop()
	local function next()
		if not self._active then return end
		self:_spawnOrb()
		task.delay(spawnInterval(self._score), next)
	end
	task.delay(0.6, next)
end

function MindfulTap:_spawnOrb()
	local canvas = self._canvas
	local w = canvas.AbsoluteSize.X
	local h = canvas.AbsoluteSize.Y
	local sz = math.random(60, 96)

	local col  = ORB_COLORS[math.random(1, #ORB_COLORS)]
	local word = ORB_WORDS[math.random(1, #ORB_WORDS)]

	local px = math.random(sz, math.max(sz+1, w - sz))
	local py = math.random(sz, math.max(sz+1, h - sz))

	-- Outer glow ring (behind orb)
	local glow = Instance.new("Frame")
	glow.Size               = UDim2.fromOffset(sz + 20, sz + 20)
	glow.AnchorPoint        = Vector2.new(0.5, 0.5)
	glow.Position           = UDim2.new(0, px, 0, py)
	glow.BackgroundColor3   = col
	glow.BackgroundTransparency = 0.7
	glow.BorderSizePixel    = 0
	glow.ZIndex             = 11
	glow.Parent             = canvas

	local glowC = Instance.new("UICorner")
	glowC.CornerRadius = UDim.new(1, 0)
	glowC.Parent = glow

	-- Orb body
	local orb = Instance.new("TextButton")
	orb.Size               = UDim2.fromOffset(0, 0)
	orb.AnchorPoint        = Vector2.new(0.5, 0.5)
	orb.Position           = UDim2.new(0, px, 0, py)
	orb.BackgroundColor3   = col
	orb.BackgroundTransparency = 0.15
	orb.BorderSizePixel    = 0
	orb.AutoButtonColor    = false
	orb.ZIndex             = 12
	orb.Parent             = canvas

	local orbC = Instance.new("UICorner")
	orbC.CornerRadius = UDim.new(1, 0)
	orbC.Parent = orb

	-- Word label inside
	local lbl = Instance.new("TextLabel")
	lbl.Size               = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text               = word
	lbl.TextColor3         = Color3.new(1, 1, 1)
	lbl.TextSize           = math.floor(sz * 0.28)
	lbl.Font               = Enum.Font.GothamBold
	lbl.ZIndex             = 13
	lbl.Parent             = orb

	-- Appear animation
	TweenService:Create(orb, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(sz, sz)
	}):Play()

	-- Gentle pulse loop
	local phase = 0
	local pulseConn
	pulseConn = RunService.Heartbeat:Connect(function(dt)
		if not orb.Parent then pulseConn:Disconnect() return end
		phase += dt * 1.6
		local s = sz + math.sin(phase) * 4
		glow.Size               = UDim2.fromOffset(s + 20, s + 20)
		glow.BackgroundTransparency = 0.6 + math.sin(phase * 0.8) * 0.15
	end)
	table.insert(self._connections, pulseConn)

	-- Auto-disappear after 3.5s (miss)
	local lifetime = 3.5
	local elapsed  = 0
	local lifeConn
	lifeConn = RunService.Heartbeat:Connect(function(dt)
		if not orb.Parent then lifeConn:Disconnect() return end
		elapsed += dt
		-- Fade warning in last 0.8s
		if elapsed > lifetime - 0.8 then
			local f = (elapsed - (lifetime - 0.8)) / 0.8
			orb.BackgroundTransparency = 0.15 + f * 0.85
			lbl.TextTransparency       = f
		end
		if elapsed >= lifetime then
			lifeConn:Disconnect()
			pulseConn:Disconnect()
			-- Miss: reset combo
			self._combo = 0
			if self._comboLbl and self._comboLbl.Parent then
				TweenService:Create(self._comboLbl, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
			end
			if orb.Parent then orb:Destroy() end
			if glow.Parent then glow:Destroy() end
		end
	end)
	table.insert(self._connections, lifeConn)

	-- Tap
	local tapConn
	tapConn = orb.MouseButton1Click:Connect(function()
		if not self._active then return end
		tapConn:Disconnect()
		pulseConn:Disconnect()
		lifeConn:Disconnect()

		self._score += 1
		self._combo += 1

		-- Score label
		if self._scoreLbl and self._scoreLbl.Parent then
			self._scoreLbl.Text = "Orbs: " .. self._score
			TweenService:Create(self._scoreLbl,
				TweenInfo.new(0.08), { TextSize = 28 }):Play()
			task.delay(0.12, function()
				if self._scoreLbl.Parent then
					TweenService:Create(self._scoreLbl, TweenInfo.new(0.1), { TextSize = 22 }):Play()
				end
			end)
		end

		-- Combo label
		if self._comboLbl and self._comboLbl.Parent then
			local comboIdx = math.min(self._combo, #COMBO_LABELS)
			self._comboLbl.Text        = COMBO_LABELS[comboIdx]
			self._comboLbl.TextTransparency = 0
			TweenService:Create(self._comboLbl,
				TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ TextTransparency = 1 }):Play()
		end

		-- Burst expand + fade
		TweenService:Create(orb, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size                  = UDim2.fromOffset(sz * 1.6, sz * 1.6),
			BackgroundTransparency = 1,
		}):Play()
		TweenService:Create(lbl, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
		TweenService:Create(glow, TweenInfo.new(0.35), {
			Size                  = UDim2.fromOffset(sz * 2, sz * 2),
			BackgroundTransparency = 1,
		}):Play()

		-- Word popup floating upward
		local pop = Instance.new("TextLabel")
		pop.Size               = UDim2.fromOffset(120, 36)
		pop.AnchorPoint        = Vector2.new(0.5, 1)
		pop.Position           = UDim2.new(0, px, 0, py - sz/2 - 4)
		pop.BackgroundTransparency = 1
		pop.Text               = word
		pop.TextColor3         = col
		pop.TextSize           = 19
		pop.Font               = Enum.Font.GothamBold
		pop.ZIndex             = 20
		pop.Parent             = canvas

		TweenService:Create(pop, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position      = UDim2.new(0, px, 0, py - sz/2 - 60),
			TextTransparency = 1,
		}):Play()

		game:GetService("Debris"):AddItem(orb,  0.35)
		game:GetService("Debris"):AddItem(glow, 0.4)
		game:GetService("Debris"):AddItem(pop,  1.05)
	end)
end

-- Called by the timer overlay when time is up
function MindfulTap:OnTimeUp()
	self._active = false
	if self._onComplete then self._onComplete() end
end

function MindfulTap:Stop()
	self._active = false
	for _, c in ipairs(self._connections) do c:Disconnect() end
	self._connections = {}
end

return MindfulTap
