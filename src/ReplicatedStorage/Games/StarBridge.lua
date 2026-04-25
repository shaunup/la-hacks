-- StarBridge: 2-player co-op constellation drawing game (for lonely mood)
-- Each player clicks to place stars; lines are drawn between consecutive stars
-- by either player. Goal: build a shared constellation of 10 stars together.
-- Interface: .new() → :Start(container, theme, onComplete) → :Stop()

local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local StarBridge = {}
StarBridge.__index = StarBridge

-- Colors per player (two tones that blend into a constellation)
local PLAYER_COLORS = {
	Color3.fromRGB(140, 160, 255),  -- player 1 (blue-violet)
	Color3.fromRGB(255, 200, 120),  -- player 2 (warm gold)
}
local LINE_COLOR   = Color3.fromRGB(200, 220, 255)
local TOTAL_STARS  = 10

-- ─── Remotes (created by StarBridgeServer) ─────────────────────────────────
local function waitRemote(name, cls)
	return ReplicatedStorage:WaitForChild(name, 15)
end

function StarBridge.new()
	return setmetatable({
		_connections = {},
		_active      = false,
		_stars       = {},      -- {x, y, colorIdx} placed so far (local copy)
		_sessionId   = nil,
		_playerColorIdx = 1,    -- will be 1 or 2 depending on join order
		_isWaiting   = false,
	}, StarBridge)
end

function StarBridge:Start(container, theme, onComplete)
	self._active     = true
	self._container  = container
	self._theme      = theme
	self._onComplete = onComplete
	self._stars      = {}
	self:_buildWaitingUI()
	self:_joinSession()
end

-- ─── Waiting screen ────────────────────────────────────────────────────────

function StarBridge:_buildWaitingUI()
	local theme = self._theme

	local waitFrame = Instance.new("Frame")
	waitFrame.Name              = "SBWaiting"
	waitFrame.Size              = UDim2.new(1, 0, 1, 0)
	waitFrame.BackgroundTransparency = 1
	waitFrame.ZIndex            = 10
	waitFrame.Parent            = self._container
	self._waitFrame = waitFrame

	local pulse = Instance.new("TextLabel")
	pulse.Name               = "SBPulse"
	pulse.Size               = UDim2.new(0, 280, 0, 60)
	pulse.AnchorPoint        = Vector2.new(0.5, 0.5)
	pulse.Position           = UDim2.new(0.5, 0, 0.5, -30)
	pulse.BackgroundTransparency = 1
	pulse.Text               = "🌌  Looking for a partner…"
	pulse.TextColor3         = theme.accentColor
	pulse.TextSize           = 22
	pulse.Font               = Enum.Font.GothamBold
	pulse.ZIndex             = 11
	pulse.Parent             = waitFrame

	local sub = Instance.new("TextLabel")
	sub.Size               = UDim2.new(0, 360, 0, 40)
	sub.AnchorPoint        = Vector2.new(0.5, 0)
	sub.Position           = UDim2.new(0.5, 0, 0.5, 40)
	sub.BackgroundTransparency = 1
	sub.Text               = "Another player will join soon.\nYou won't be alone for long."
	sub.TextColor3         = theme.textColor
	sub.TextSize           = 17
	sub.Font               = Enum.Font.Gotham
	sub.TextWrapped        = true
	sub.TextXAlignment     = Enum.TextXAlignment.Center
	sub.ZIndex             = 11
	sub.Parent             = waitFrame

	-- Stars orbiting animation
	local t = 0
	local animConn = RunService.Heartbeat:Connect(function(dt)
		if not pulse.Parent then return end
		t += dt
		pulse.TextTransparency = 0.2 + math.abs(math.sin(t * 1.5)) * 0.5
	end)
	table.insert(self._connections, animConn)
	self._waitPulseConn = animConn
end

-- ─── Join matchmaking ───────────────────────────────────────────────────────

function StarBridge:_joinSession()
	local JoinFunc = waitRemote("StarBridge_Join", "RemoteFunction")
	if not JoinFunc then
		self:_showSoloFallback()
		return
	end

	task.spawn(function()
		local ok, result = pcall(function()
			return JoinFunc:InvokeServer()
		end)

		if not ok or not result then
			self:_showSoloFallback()
			return
		end

		if result == "waiting" then
			self._isWaiting = true
			-- Listen for partner join event
			local joinEvt = waitRemote("StarBridge_PartnerJoined", "RemoteEvent")
			if joinEvt then
				local c = joinEvt.OnClientEvent:Connect(function(partnerName, sessionId)
					self._sessionId       = sessionId
					self._playerColorIdx  = 2  -- late joiner is P2
					self._isWaiting       = false
					if self._waitFrame and self._waitFrame.Parent then
						self._waitFrame:Destroy()
					end
					self:_buildGameUI(partnerName)
				end)
				table.insert(self._connections, c)
			end
		else
			-- Immediately matched
			self._sessionId      = result
			self._playerColorIdx = 1
			self._isWaiting      = false
			if self._waitFrame and self._waitFrame.Parent then
				self._waitFrame:Destroy()
			end
			-- Wait briefly for partner event to populate partner name
			local joinEvt = waitRemote("StarBridge_PartnerJoined", "RemoteEvent")
			if joinEvt then
				local c = joinEvt.OnClientEvent:Connect(function(partnerName, _)
					self:_buildGameUI(partnerName)
				end)
				table.insert(self._connections, c)
			end
		end
	end)
end

function StarBridge:_showSoloFallback()
	if self._waitFrame and self._waitFrame.Parent then
		self._waitFrame:Destroy()
	end
	local theme = self._theme

	local notif = Instance.new("TextLabel")
	notif.Size               = UDim2.new(0.75, 0, 0, 80)
	notif.AnchorPoint        = Vector2.new(0.5, 0.5)
	notif.Position           = UDim2.new(0.5, 0, 0.35, 0)
	notif.BackgroundColor3   = theme.cardColor
	notif.BackgroundTransparency = 0.15
	notif.BorderSizePixel    = 0
	notif.Text               = "🌌  Playing solo tonight.\nEvery star you place is yours."
	notif.TextColor3         = theme.textColor
	notif.TextSize           = 19
	notif.Font               = Enum.Font.GothamSemibold
	notif.TextWrapped        = true
	notif.TextXAlignment     = Enum.TextXAlignment.Center
	notif.ZIndex             = 12
	notif.Parent             = self._container

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 16)
	c.Parent = notif

	task.delay(2, function()
		if notif.Parent then
			TweenService:Create(notif, TweenInfo.new(0.5), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
			task.delay(0.5, function() if notif.Parent then notif:Destroy() end end)
		end
		self:_buildGameUI("The Stars")
	end)
end

-- ─── Main game UI ──────────────────────────────────────────────────────────

function StarBridge:_buildGameUI(partnerName)
	local theme = self._theme

	-- Canvas
	local canvas = Instance.new("Frame")
	canvas.Name              = "SBCanvas"
	canvas.Size              = UDim2.new(1, 0, 1, -52)
	canvas.Position          = UDim2.new(0, 0, 0, 52)
	canvas.BackgroundTransparency = 1
	canvas.ZIndex            = 10
	canvas.Parent            = self._container
	self._canvas = canvas

	-- Header
	local hdr = Instance.new("TextLabel")
	hdr.Size               = UDim2.new(1, 0, 0, 44)
	hdr.BackgroundTransparency = 1
	hdr.Text               = "🌌  Building a constellation with " .. partnerName
	hdr.TextColor3         = theme.accentColor
	hdr.TextSize           = 18
	hdr.Font               = Enum.Font.GothamBold
	hdr.TextXAlignment     = Enum.TextXAlignment.Center
	hdr.ZIndex             = 11
	hdr.Parent             = self._container

	-- Counter
	local counter = Instance.new("TextLabel")
	counter.Name               = "SBCounter"
	counter.Size               = UDim2.new(1, 0, 0, 28)
	counter.Position           = UDim2.new(0, 0, 0, 22)
	counter.BackgroundTransparency = 1
	counter.Text               = "0 / " .. TOTAL_STARS .. " stars"
	counter.TextColor3         = theme.textColor
	counter.TextSize           = 16
	counter.Font               = Enum.Font.Gotham
	counter.TextXAlignment     = Enum.TextXAlignment.Center
	counter.ZIndex             = 11
	counter.Parent             = self._container
	self._counter = counter

	-- Instruction
	local inst = Instance.new("TextLabel")
	inst.Size               = UDim2.new(1, -20, 0, 26)
	inst.Position           = UDim2.new(0, 10, 0, 0)
	inst.BackgroundTransparency = 1
	inst.Text               = "✦ Click anywhere to place your star"
	inst.TextColor3         = PLAYER_COLORS[self._playerColorIdx]
	inst.TextSize           = 15
	inst.Font               = Enum.Font.GothamSemibold
	inst.TextXAlignment     = Enum.TextXAlignment.Center
	inst.ZIndex             = 11
	inst.Parent             = canvas

	-- Click catcher
	local catcher = Instance.new("TextButton")
	catcher.Name               = "SBCatcher"
	catcher.Size               = UDim2.new(1, 0, 1, 0)
	catcher.Position           = UDim2.new(0, 0, 0, 28)
	catcher.BackgroundTransparency = 1
	catcher.Text               = ""
	catcher.ZIndex             = 10
	catcher.AutoButtonColor    = false
	catcher.Parent             = canvas
	self._catcher = catcher

	-- Subscribe to remote events
	local starEvt = ReplicatedStorage:FindFirstChild("StarBridge_StarPlaced")
	if starEvt then
		local c = starEvt.OnClientEvent:Connect(function(placerName, x, y, colorIdx)
			self:_addStar(x, y, colorIdx)
		end)
		table.insert(self._connections, c)
	end

	local doneEvt = ReplicatedStorage:FindFirstChild("StarBridge_ConstellationDone")
	if doneEvt then
		local c = doneEvt.OnClientEvent:Connect(function()
			self:_showComplete()
		end)
		table.insert(self._connections, c)
	end

	local leftEvt = ReplicatedStorage:FindFirstChild("StarBridge_PartnerLeft")
	if leftEvt then
		local c = leftEvt.OnClientEvent:Connect(function()
			if inst.Parent then
				inst.Text      = "⚠️  Your partner left. You can keep going solo!"
				inst.TextColor3 = Color3.fromRGB(255, 200, 80)
			end
		end)
		table.insert(self._connections, c)
	end

	-- Click to place star
	local clickConn = catcher.MouseButton1Click:Connect(function()
		if not self._active then return end
		if #self._stars >= TOTAL_STARS then return end

		local mouse = game:GetService("UserInputService"):GetMouseLocation()
		local canvasAbsPos = canvas.AbsolutePosition
		local canvasAbsSize = canvas.AbsoluteSize
		-- Normalise to [0,1] within canvas
		local nx = math.clamp((mouse.X - canvasAbsPos.X) / canvasAbsSize.X, 0.02, 0.98)
		local ny = math.clamp((mouse.Y - canvasAbsPos.Y) / canvasAbsSize.Y, 0.05, 0.95)

		-- Add locally immediately
		self:_addStar(nx, ny, self._playerColorIdx)

		-- Sync to server
		if self._sessionId then
			local placeFunc = ReplicatedStorage:FindFirstChild("StarBridge_PlaceStar")
			if placeFunc then
				task.spawn(function()
					pcall(function()
						placeFunc:InvokeServer(self._sessionId, nx, ny, self._playerColorIdx)
					end)
				end)
			end
		end
	end)
	table.insert(self._connections, clickConn)
end

-- ─── Place a star and draw line to previous ─────────────────────────────────

function StarBridge:_addStar(nx, ny, colorIdx)
	-- Deduplicate: ignore if we already have this exact star from network echo
	-- (server fires to both players including originator)
	-- We'll just let duplicates render; the small gap doesn't matter visually.

	local prev = self._stars[#self._stars]
	table.insert(self._stars, { x = nx, y = ny, colorIdx = colorIdx })

	local col = PLAYER_COLORS[colorIdx] or PLAYER_COLORS[1]

	-- Star dot
	local star = Instance.new("TextLabel")
	star.Size               = UDim2.fromOffset(0, 0)
	star.AnchorPoint        = Vector2.new(0.5, 0.5)
	star.Position           = UDim2.new(nx, 0, ny, 0)
	star.BackgroundTransparency = 1
	star.Text               = "✦"
	star.TextColor3         = col
	star.TextSize           = 26
	star.Font               = Enum.Font.GothamBold
	star.ZIndex             = 16
	star.Parent             = self._canvas

	TweenService:Create(star, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(36, 36)
	}):Play()

	-- Glow ring
	local ring = Instance.new("Frame")
	ring.Size               = UDim2.fromOffset(0, 0)
	ring.AnchorPoint        = Vector2.new(0.5, 0.5)
	ring.Position           = UDim2.new(nx, 0, ny, 0)
	ring.BackgroundColor3   = col
	ring.BackgroundTransparency = 0.4
	ring.BorderSizePixel    = 0
	ring.ZIndex             = 15
	ring.Parent             = self._canvas

	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(1, 0)
	rc.Parent = ring

	TweenService:Create(ring, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size                  = UDim2.fromOffset(60, 60),
		BackgroundTransparency = 1,
	}):Play()
	game:GetService("Debris"):AddItem(ring, 0.6)

	-- Draw connection line to previous star
	if prev then
		self:_drawLine(prev.x, prev.y, nx, ny)
	end

	-- Update counter
	local count = #self._stars
	if self._counter and self._counter.Parent then
		self._counter.Text = count .. " / " .. TOTAL_STARS .. " stars"
	end
end

function StarBridge:_drawLine(x1, y1, x2, y2)
	local dx = x2 - x1
	local dy = y2 - y1
	local len = math.sqrt(dx*dx + dy*dy)
	if len < 0.001 then return end

	local cx = (x1 + x2) / 2
	local cy = (y1 + y2) / 2
	local angle = math.deg(math.atan2(dy, dx))

	-- Convert normalised length to pixel length roughly
	local canvasAbsW = self._canvas and self._canvas.AbsoluteSize.X or 800
	local canvasAbsH = self._canvas and self._canvas.AbsoluteSize.Y or 600
	local pxLen = math.sqrt((dx * canvasAbsW)^2 + (dy * canvasAbsH)^2)

	local line = Instance.new("Frame")
	line.AnchorPoint        = Vector2.new(0.5, 0.5)
	line.Position           = UDim2.new(cx, 0, cy, 0)
	line.Size               = UDim2.fromOffset(0, 2)
	line.Rotation           = angle
	line.BackgroundColor3   = LINE_COLOR
	line.BackgroundTransparency = 0.4
	line.BorderSizePixel    = 0
	line.ZIndex             = 14
	line.Parent             = self._canvas

	TweenService:Create(line, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(pxLen, 2)
	}):Play()
end

-- ─── Completion ─────────────────────────────────────────────────────────────

function StarBridge:_showComplete()
	self._active = false

	local theme = self._theme

	-- Sparkle all stars
	for _, s in ipairs(self._stars) do
		task.spawn(function()
			task.wait(math.random() * 0.5)
			-- pulse each star position
			local sp = Instance.new("TextLabel")
			sp.Size               = UDim2.fromOffset(50, 50)
			sp.AnchorPoint        = Vector2.new(0.5, 0.5)
			sp.Position           = UDim2.new(s.x, 0, s.y, 0)
			sp.BackgroundTransparency = 1
			sp.Text               = "✨"
			sp.TextSize           = 30
			sp.Font               = Enum.Font.GothamBold
			sp.ZIndex             = 25
			sp.Parent             = self._canvas

			TweenService:Create(sp, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(80, 80),
				TextTransparency = 1,
			}):Play()
			game:GetService("Debris"):AddItem(sp, 0.9)
		end)
	end

	-- Win card
	local win = Instance.new("Frame")
	win.Size               = UDim2.new(0, 360, 0, 130)
	win.AnchorPoint        = Vector2.new(0.5, 0.5)
	win.Position           = UDim2.new(0.5, 0, 0.5, 0)
	win.BackgroundColor3   = theme.cardColor
	win.BackgroundTransparency = 0.1
	win.BorderSizePixel    = 0
	win.ZIndex             = 30
	win.Parent             = self._canvas

	local wc = Instance.new("UICorner")
	wc.CornerRadius = UDim.new(0, 20)
	wc.Parent = win

	local wLbl = Instance.new("TextLabel")
	wLbl.Size               = UDim2.new(1, -20, 1, -10)
	wLbl.Position           = UDim2.new(0, 10, 0, 5)
	wLbl.BackgroundTransparency = 1
	wLbl.Text               = "🌌  Constellation complete!\nYou built something beautiful together.\nYou are not alone. ✨"
	wLbl.TextColor3         = theme.textColor
	wLbl.TextSize           = 18
	wLbl.Font               = Enum.Font.GothamBold
	wLbl.TextWrapped        = true
	wLbl.TextXAlignment     = Enum.TextXAlignment.Center
	wLbl.ZIndex             = 31
	wLbl.Parent             = win

	win.Size = UDim2.new(0, 100, 0, 60)
	TweenService:Create(win, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 360, 0, 130),
	}):Play()

	task.delay(4, function()
		if self._onComplete then self._onComplete() end
	end)
end

function StarBridge:Stop()
	self._active = false
	if self._sessionId then
		local leaveFunc = ReplicatedStorage:FindFirstChild("StarBridge_Leave")
		if leaveFunc then
			pcall(function() leaveFunc:InvokeServer(self._sessionId) end)
		end
	end
	for _, c in ipairs(self._connections) do c:Disconnect() end
	self._connections = {}
end

return StarBridge
