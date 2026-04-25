-- StarSmash: click falling stars to smash them – releases energy & tension
-- Great for: angry, excited

local TweenService    = game:GetService("TweenService")
local RunService      = game:GetService("RunService")

local StarSmash = {}
StarSmash.__index = StarSmash

local STAR_COLORS = {
	Color3.fromRGB(255, 220,  60),
	Color3.fromRGB(255, 120,  60),
	Color3.fromRGB(255,  80, 160),
	Color3.fromRGB(120,  80, 255),
	Color3.fromRGB( 60, 200, 255),
}

local SCORE_GOAL     = 20
local SPAWN_INTERVAL = 0.9   -- seconds between spawns (speeds up over time)
local MIN_INTERVAL   = 0.35

function StarSmash.new()
	return setmetatable({
		_connections = {},
		_active      = false,
		_score       = 0,
		_missed      = 0,
	}, StarSmash)
end

function StarSmash:Start(container, theme)
	self._active    = true
	self._score     = 0
	self._missed    = 0
	self._container = container
	self._theme     = theme
	self:_buildUI()
	self:_spawnLoop()
end

function StarSmash:_buildUI()
	local theme = self._theme

	local header = Instance.new("TextLabel")
	header.Name               = "SSHeader"
	header.Size               = UDim2.new(1, 0, 0, 44)
	header.Position           = UDim2.new(0, 0, 0, 0)
	header.BackgroundTransparency = 1
	header.Text               = "⭐  Smash the falling stars!"
	header.TextColor3         = theme.textColor
	header.TextSize           = 22
	header.Font               = Enum.Font.GothamBold
	header.TextXAlignment     = Enum.TextXAlignment.Center
	header.ZIndex             = 10
	header.Parent             = self._container

	local scoreLbl = Instance.new("TextLabel")
	scoreLbl.Name               = "SSScore"
	scoreLbl.Size               = UDim2.new(0, 180, 0, 36)
	scoreLbl.AnchorPoint        = Vector2.new(0.5, 0)
	scoreLbl.Position           = UDim2.new(0.5, 0, 0, 50)
	scoreLbl.BackgroundTransparency = 1
	scoreLbl.Text               = "Score: 0"
	scoreLbl.TextColor3         = theme.accentColor
	scoreLbl.TextSize           = 22
	scoreLbl.Font               = Enum.Font.GothamBold
	scoreLbl.ZIndex             = 10
	scoreLbl.Parent             = self._container

	self._scoreLbl = scoreLbl
end

function StarSmash:_spawnLoop()
	local interval = SPAWN_INTERVAL
	local function spawnNext()
		if not self._active then return end
		self:_spawnStar()
		interval = math.max(MIN_INTERVAL, interval - 0.015)
		task.delay(interval, spawnNext)
	end
	task.delay(0.5, spawnNext)
end

function StarSmash:_spawnStar()
	local w = self._container.AbsoluteSize.X
	local size = math.random(44, 70)
	local startX = math.random(size, math.max(size + 1, w - size))

	local star = Instance.new("TextButton")
	star.Size               = UDim2.fromOffset(size, size)
	star.Position           = UDim2.new(0, startX, 0, -size)
	star.BackgroundColor3   = STAR_COLORS[math.random(1, #STAR_COLORS)]
	star.BackgroundTransparency = 0.1
	star.BorderSizePixel    = 0
	star.Text               = "⭐"
	star.TextSize           = size * 0.6
	star.Font               = Enum.Font.GothamBold
	star.ZIndex             = 15
	star.AutoButtonColor    = false
	star.Parent             = self._container

	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(1, 0)
	sc.Parent = star

	-- Fall animation
	local fallTime = math.random(20, 36) / 10  -- 2–3.6 s
	local h        = self._container.AbsoluteSize.Y + size + 10
	local fallTween = TweenService:Create(star,
		TweenInfo.new(fallTime, Enum.EasingStyle.Linear),
		{ Position = UDim2.new(0, startX, 0, h) }
	)
	fallTween:Play()

	-- Rotation spin
	local angle = 0
	local spinConn
	spinConn = RunService.Heartbeat:Connect(function(dt)
		if not star.Parent then spinConn:Disconnect() return end
		angle += dt * 120
		star.Rotation = angle % 360
	end)
	table.insert(self._connections, spinConn)

	-- Miss detection
	fallTween.Completed:Connect(function()
		if star.Parent then
			self._missed += 1
			star:Destroy()
			spinConn:Disconnect()
		end
	end)

	-- Click to smash
	local clickConn
	clickConn = star.MouseButton1Click:Connect(function()
		if not self._active then return end
		clickConn:Disconnect()
		spinConn:Disconnect()
		fallTween:Cancel()

		-- Burst effect
		self:_burst(star.AbsolutePosition + Vector2.new(size/2, size/2), star.BackgroundColor3)
		star:Destroy()

		self._score += 1
		self._scoreLbl.Text = "Score: " .. self._score

		-- Pop scale feedback
		if self._scoreLbl.Parent then
			TweenService:Create(self._scoreLbl,
				TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ TextSize = 28 }
			):Play()
			task.delay(0.1, function()
				if self._scoreLbl.Parent then
					TweenService:Create(self._scoreLbl,
						TweenInfo.new(0.1), { TextSize = 22 }
					):Play()
				end
			end)
		end

		if self._score >= SCORE_GOAL then
			self:_showWin()
		end
	end)
end

function StarSmash:_burst(pos, color)
	for i = 1, 10 do
		local shard = Instance.new("Frame")
		shard.Size               = UDim2.fromOffset(12, 12)
		shard.Position           = UDim2.new(0, pos.X - 6, 0, pos.Y - 6)
		shard.BackgroundColor3   = color
		shard.BorderSizePixel    = 0
		shard.ZIndex             = 20
		shard.Parent             = self._container

		local sc2 = Instance.new("UICorner")
		sc2.CornerRadius = UDim.new(1, 0)
		sc2.Parent = shard

		local a = (i / 10) * math.pi * 2
		local spd = math.random(60, 160)
		TweenService:Create(shard, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, pos.X - 6 + math.cos(a)*spd, 0, pos.Y - 6 + math.sin(a)*spd),
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(4, 4),
		}):Play()

		game:GetService("Debris"):AddItem(shard, 0.45)
	end
end

function StarSmash:_showWin()
	self._active = false

	local win = Instance.new("TextLabel")
	win.Size               = UDim2.new(0.7, 0, 0, 90)
	win.AnchorPoint        = Vector2.new(0.5, 0.5)
	win.Position           = UDim2.new(0.5, 0, 0.5, 0)
	win.BackgroundColor3   = self._theme.cardColor
	win.BackgroundTransparency = 0.1
	win.BorderSizePixel    = 0
	win.Text               = "💥  You smashed " .. SCORE_GOAL .. " stars!\nThat energy is RELEASED! 🔥"
	win.TextColor3         = self._theme.textColor
	win.TextSize           = 20
	win.Font               = Enum.Font.GothamBold
	win.TextWrapped        = true
	win.ZIndex             = 30
	win.Parent             = self._container

	local wc = Instance.new("UICorner")
	wc.CornerRadius = UDim.new(0, 16)
	wc.Parent = win

	task.delay(3, function()
		if win.Parent then win:Destroy() end
		self._score  = 0
		self._active = true
		if self._scoreLbl.Parent then
			self._scoreLbl.Text = "Score: 0"
		end
	end)
end

function StarSmash:Stop()
	self._active = false
	for _, c in ipairs(self._connections) do
		c:Disconnect()
	end
	self._connections = {}
end

return StarSmash
