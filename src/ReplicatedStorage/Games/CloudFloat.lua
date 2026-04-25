-- CloudFloat: gentle cloud drifting – click clouds to collect peace stars
-- Great for: calm, neutral

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local CloudFloat = {}
CloudFloat.__index = CloudFloat

local CLOUD_SHAPES = { "☁️", "🌤️", "⛅", "🌥️" }
local PEACE_ITEMS  = { "⭐","✨","💫","🌟","🍃","🌸","❄️" }
local SCORE_GOAL   = 15

function CloudFloat.new()
	return setmetatable({ _connections = {}, _active = false, _score = 0 }, CloudFloat)
end

function CloudFloat:Start(container, theme, onComplete)
	self._active     = true
	self._score      = 0
	self._container  = container
	self._theme      = theme
	self._onComplete = onComplete
	self:_buildUI()
	self:_spawnLoop()
end

function CloudFloat:_buildUI()
	local theme = self._theme

	local header = Instance.new("TextLabel")
	header.Size               = UDim2.new(1, 0, 0, 44)
	header.BackgroundTransparency = 1
	header.Text               = "☁️  Collect peaceful moments"
	header.TextColor3         = theme.textColor
	header.TextSize           = 22
	header.Font               = Enum.Font.GothamBold
	header.TextXAlignment     = Enum.TextXAlignment.Center
	header.ZIndex             = 10
	header.Parent             = self._container

	local scoreLbl = Instance.new("TextLabel")
	scoreLbl.Name               = "CFScore"
	scoreLbl.Size               = UDim2.new(0, 200, 0, 34)
	scoreLbl.AnchorPoint        = Vector2.new(0.5, 0)
	scoreLbl.Position           = UDim2.new(0.5, 0, 0, 50)
	scoreLbl.BackgroundTransparency = 1
	scoreLbl.Text               = "Peace: 0 / " .. SCORE_GOAL
	scoreLbl.TextColor3         = theme.accentColor
	scoreLbl.TextSize           = 20
	scoreLbl.Font               = Enum.Font.GothamSemibold
	scoreLbl.ZIndex             = 10
	scoreLbl.Parent             = self._container
	self._scoreLbl = scoreLbl
end

function CloudFloat:_spawnLoop()
	local function next()
		if not self._active then return end
		self:_spawnCloud()
		task.delay(math.random(12, 22) / 10, next)
	end
	task.delay(0.8, next)
end

function CloudFloat:_spawnCloud()
	local w = self._container.AbsoluteSize.X
	local h = self._container.AbsoluteSize.Y
	local cloudW = math.random(120, 200)
	local startY = math.random(80, math.max(81, h - 120))

	-- Start from either left or right edge
	local fromLeft = math.random() > 0.5
	local startX   = fromLeft and -cloudW or w + 10
	local endX     = fromLeft and (w + 10) or -cloudW
	local duration = math.random(55, 90) / 10  -- 5.5–9 s

	-- Cloud label
	local cloud = Instance.new("TextButton")
	cloud.Size               = UDim2.fromOffset(cloudW, 60)
	cloud.Position           = UDim2.new(0, startX, 0, startY)
	cloud.BackgroundTransparency = 1
	cloud.Text               = CLOUD_SHAPES[math.random(1, #CLOUD_SHAPES)]
	cloud.TextSize           = 54
	cloud.Font               = Enum.Font.GothamBold
	cloud.ZIndex             = 12
	cloud.AutoButtonColor    = false
	cloud.Parent             = self._container

	-- Floating item on top of cloud
	local item = Instance.new("TextLabel")
	item.Size               = UDim2.fromOffset(40, 40)
	item.AnchorPoint        = Vector2.new(0.5, 1)
	item.Position           = UDim2.new(0.5, 0, 0, -2)
	item.BackgroundTransparency = 1
	item.Text               = PEACE_ITEMS[math.random(1, #PEACE_ITEMS)]
	item.TextSize           = 28
	item.Font               = Enum.Font.GothamBold
	item.ZIndex             = 13
	item.Parent             = cloud

	-- Gentle bob
	local bobAngle = math.random() * math.pi * 2
	local bobConn
	bobConn = RunService.Heartbeat:Connect(function(dt)
		if not cloud.Parent then bobConn:Disconnect() return end
		bobAngle += dt * 1.8
		item.Position = UDim2.new(0.5, 0, 0, -2 + math.sin(bobAngle) * 5)
	end)
	table.insert(self._connections, bobConn)

	-- Drift tween
	local drift = TweenService:Create(cloud,
		TweenInfo.new(duration, Enum.EasingStyle.Linear),
		{ Position = UDim2.new(0, endX, 0, startY) }
	)
	drift:Play()
	drift.Completed:Connect(function()
		bobConn:Disconnect()
		if cloud.Parent then cloud:Destroy() end
	end)

	-- Click to collect
	local clickConn
	clickConn = cloud.MouseButton1Click:Connect(function()
		if not self._active then return end
		clickConn:Disconnect()
		bobConn:Disconnect()
		drift:Cancel()

		-- Sparkle burst
		local absPos = cloud.AbsolutePosition + Vector2.new(cloudW/2, 30)
		for i = 1, 8 do
			local sp = Instance.new("TextLabel")
			sp.Size               = UDim2.fromOffset(24, 24)
			sp.Position           = UDim2.new(0, absPos.X - 12, 0, absPos.Y - 12)
			sp.BackgroundTransparency = 1
			sp.Text               = PEACE_ITEMS[math.random(1, #PEACE_ITEMS)]
			sp.TextSize           = 20
			sp.Font               = Enum.Font.GothamBold
			sp.ZIndex             = 20
			sp.Parent             = self._container

			local a = (i / 8) * math.pi * 2
			local spd = math.random(60, 130)
			TweenService:Create(sp, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(0, absPos.X - 12 + math.cos(a)*spd, 0, absPos.Y - 12 + math.sin(a)*spd),
				TextTransparency = 1,
			}):Play()
			game:GetService("Debris"):AddItem(sp, 0.55)
		end

		cloud:Destroy()

		self._score += 1
		if self._scoreLbl.Parent then
			self._scoreLbl.Text = "Peace: " .. self._score .. " / " .. SCORE_GOAL
		end

		if self._score >= SCORE_GOAL then
			self:_showWin()
		end
	end)
end

function CloudFloat:_showWin()
	self._active = false

	local win = Instance.new("TextLabel")
	win.Size               = UDim2.new(0.72, 0, 0, 90)
	win.AnchorPoint        = Vector2.new(0.5, 0.5)
	win.Position           = UDim2.new(0.5, 0, 0.5, 0)
	win.BackgroundColor3   = self._theme.cardColor
	win.BackgroundTransparency = 0.1
	win.BorderSizePixel    = 0
	win.Text               = "✨  You collected " .. SCORE_GOAL .. " peaceful moments!\nYour mind is a calm sky. ☁️"
	win.TextColor3         = self._theme.textColor
	win.TextSize           = 19
	win.Font               = Enum.Font.GothamBold
	win.TextWrapped        = true
	win.ZIndex             = 30
	win.Parent             = self._container

	local wc = Instance.new("UICorner")
	wc.CornerRadius = UDim.new(0, 16)
	wc.Parent = win

	task.delay(3.5, function()
		if win.Parent then win:Destroy() end
		if self._onComplete then
			self._onComplete()
		else
			self._score  = 0
			self._active = true
			if self._scoreLbl.Parent then self._scoreLbl.Text = "Peace: 0 / " .. SCORE_GOAL end
		end
	end)
end

function CloudFloat:OnTimeUp()
	self._active = false
	local msgLbl = Instance.new("TextLabel")
	msgLbl.Size               = UDim2.new(0.65, 0, 0, 70)
	msgLbl.AnchorPoint        = Vector2.new(0.5, 0.5)
	msgLbl.Position           = UDim2.new(0.5, 0, 0.5, 0)
	msgLbl.BackgroundColor3   = self._theme.cardColor
	msgLbl.BackgroundTransparency = 0.1
	msgLbl.BorderSizePixel    = 0
	msgLbl.Text               = "☁️  Time's up!\nPeace collected: " .. self._score
	msgLbl.TextColor3         = self._theme.textColor
	msgLbl.TextSize           = 20
	msgLbl.Font               = Enum.Font.GothamBold
	msgLbl.TextWrapped        = true
	msgLbl.ZIndex             = 30
	msgLbl.Parent             = self._container
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,16); c.Parent = msgLbl
	task.delay(2, function()
		if msgLbl.Parent then msgLbl:Destroy() end
		if self._onComplete then self._onComplete() end
	end)
end

function CloudFloat:Stop()
	self._active = false
	for _, c in ipairs(self._connections) do c:Disconnect() end
	self._connections = {}
end

return CloudFloat
