-- ColorBurst: tap/click anywhere to launch colourful particle explosions
-- Suitable for: happy, neutral, excited
-- Returns a table with :Start(container, theme) and :Stop() methods

local TweenService  = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService    = game:GetService("RunService")

local ColorBurst = {}
ColorBurst.__index = ColorBurst

local BURST_COLORS = {
	Color3.fromRGB(255, 80,  80),
	Color3.fromRGB(255, 180, 50),
	Color3.fromRGB(100, 220, 80),
	Color3.fromRGB(60,  180, 255),
	Color3.fromRGB(200, 80,  255),
	Color3.fromRGB(255, 120, 200),
	Color3.fromRGB(80,  255, 210),
}

local SCORE_GOAL = 10   -- bursts to "win" a round
local PARTICLE_COUNT = 14

function ColorBurst.new()
	return setmetatable({
		_connections = {},
		_active      = false,
		_score       = 0,
	}, ColorBurst)
end

-- ─── helpers ──────────────────────────────────────────────────────────────

local function randomFrom(t)
	return t[math.random(1, #t)]
end

local function spawnParticle(parent, origin, color)
	local dot = Instance.new("Frame")
	dot.Size            = UDim2.fromOffset(18, 18)
	dot.Position        = UDim2.new(0, origin.X - 9, 0, origin.Y - 9)
	dot.BackgroundColor3 = color
	dot.BorderSizePixel  = 0
	dot.ZIndex           = 20
	dot.Parent           = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = dot

	local angle  = math.random() * math.pi * 2
	local speed  = math.random(80, 220)
	local dx     = math.cos(angle) * speed
	local dy     = math.sin(angle) * speed

	local info = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(dot, info, {
		Position = UDim2.new(0, origin.X - 9 + dx, 0, origin.Y - 9 + dy),
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(6, 6),
	}):Play()

	game:GetService("Debris"):AddItem(dot, 0.6)
end

-- ─── UI ───────────────────────────────────────────────────────────────────

function ColorBurst:_buildUI(container, theme)
	-- Instruction banner
	local banner = Instance.new("TextLabel")
	banner.Name               = "CBBanner"
	banner.Size               = UDim2.new(1, 0, 0, 48)
	banner.Position           = UDim2.new(0, 0, 0, 0)
	banner.BackgroundTransparency = 1
	banner.Text               = "🎨  Tap anywhere to burst colours!"
	banner.TextColor3         = theme.textColor
	banner.TextSize           = 22
	banner.Font               = Enum.Font.GothamBold
	banner.TextXAlignment     = Enum.TextXAlignment.Center
	banner.ZIndex             = 10
	banner.Parent             = container

	-- Score
	local scoreLabel = Instance.new("TextLabel")
	scoreLabel.Name               = "CBScore"
	scoreLabel.Size               = UDim2.new(0, 200, 0, 40)
	scoreLabel.AnchorPoint        = Vector2.new(0.5, 0)
	scoreLabel.Position           = UDim2.new(0.5, 0, 0, 56)
	scoreLabel.BackgroundTransparency = 1
	scoreLabel.Text               = "Bursts: 0 / " .. SCORE_GOAL
	scoreLabel.TextColor3         = theme.accentColor
	scoreLabel.TextSize           = 20
	scoreLabel.Font               = Enum.Font.GothamSemibold
	scoreLabel.ZIndex             = 10
	scoreLabel.Parent             = container

	-- Invisible click catcher
	local catcher = Instance.new("TextButton")
	catcher.Name               = "CBCatcher"
	catcher.Size               = UDim2.new(1, 0, 1, 0)
	catcher.BackgroundTransparency = 1
	catcher.Text               = ""
	catcher.ZIndex             = 5
	catcher.Parent             = container

	self._scoreLabel = scoreLabel
	self._catcher    = catcher
	self._container  = container
end

function ColorBurst:Start(container, theme)
	self._active = true
	self._score  = 0
	self:_buildUI(container, theme)

	local conn = self._catcher.MouseButton1Click:Connect(function()
		if not self._active then return end

		local pos = UserInputService:GetMouseLocation()

		-- Burst particles
		for _ = 1, PARTICLE_COUNT do
			spawnParticle(container, pos, randomFrom(BURST_COLORS))
		end

		-- Ring flash
		local ring = Instance.new("Frame")
		ring.Size               = UDim2.fromOffset(10, 10)
		ring.Position           = UDim2.new(0, pos.X - 5, 0, pos.Y - 5)
		ring.AnchorPoint        = Vector2.new(0.5, 0.5)
		ring.BackgroundTransparency = 0.3
		ring.BackgroundColor3   = randomFrom(BURST_COLORS)
		ring.BorderSizePixel    = 0
		ring.ZIndex             = 15
		ring.Parent             = container

		local rc = Instance.new("UICorner")
		rc.CornerRadius = UDim.new(1, 0)
		rc.Parent = ring

		TweenService:Create(ring, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size               = UDim2.fromOffset(120, 120),
			Position           = UDim2.new(0, pos.X - 60, 0, pos.Y - 60),
			BackgroundTransparency = 1,
		}):Play()
		game:GetService("Debris"):AddItem(ring, 0.45)

		self._score += 1
		self._scoreLabel.Text = "Bursts: " .. self._score .. " / " .. SCORE_GOAL

		if self._score >= SCORE_GOAL then
			self:_showWin(container, theme)
		end
	end)
	table.insert(self._connections, conn)
end

function ColorBurst:_showWin(container, theme)
	self._active = false

	local win = Instance.new("TextLabel")
	win.Size               = UDim2.new(0.7, 0, 0, 80)
	win.AnchorPoint        = Vector2.new(0.5, 0.5)
	win.Position           = UDim2.new(0.5, 0, 0.5, 0)
	win.BackgroundColor3   = theme.cardColor
	win.BackgroundTransparency = 0.1
	win.BorderSizePixel    = 0
	win.Text               = "🌈  Beautiful!  You filled the world with colour!"
	win.TextColor3         = theme.textColor
	win.TextSize           = 20
	win.Font               = Enum.Font.GothamBold
	win.TextWrapped        = true
	win.ZIndex             = 30
	win.Parent             = container

	local wc = Instance.new("UICorner")
	wc.CornerRadius = UDim.new(0, 16)
	wc.Parent = win

	-- Burst confetti every 0.12s for 2s
	local t = 0
	local confettiConn
	confettiConn = RunService.Heartbeat:Connect(function(dt)
		t += dt
		if t < 2 then
			local px = math.random(50, container.AbsoluteSize.X - 50)
			local py = math.random(50, container.AbsoluteSize.Y - 50)
			for _ = 1, 6 do
				spawnParticle(container, Vector2.new(px, py), randomFrom(BURST_COLORS))
			end
		else
			confettiConn:Disconnect()
		end
	end)

	task.delay(3, function()
		win:Destroy()
		-- Reset for another round
		self._score  = 0
		self._active = true
		if self._scoreLabel and self._scoreLabel.Parent then
			self._scoreLabel.Text = "Bursts: 0 / " .. SCORE_GOAL
		end
	end)
end

function ColorBurst:Stop()
	self._active = false
	for _, c in ipairs(self._connections) do
		c:Disconnect()
	end
	self._connections = {}
end

return ColorBurst
