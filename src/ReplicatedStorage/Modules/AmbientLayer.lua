-- AmbientLayer: mood-specific 2-D background particle animations
-- Each style drives the particles differently for a distinctive look.
-- Usage:
--   local AmbientLayer = require(...)
--   local layer = AmbientLayer.new(screenGui, theme)
--   layer:Stop()  -- cleans up everything

local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local AmbientLayer = {}
AmbientLayer.__index = AmbientLayer

-- ─── helpers ──────────────────────────────────────────────────────────────

local function rnd(a, b)  return a + math.random() * (b - a) end
local function rndInt(a, b) return math.random(a, b) end

local function newDot(parent, zIndex)
	local f = Instance.new("Frame")
	f.BorderSizePixel    = 0
	f.BackgroundTransparency = 1
	f.ZIndex             = zIndex or 2
	f.Parent             = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = f
	return f
end

local function newText(parent, zIndex)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.TextTransparency       = 1
	t.ZIndex                 = zIndex or 2
	t.Font                   = Enum.Font.GothamBold
	t.Parent                 = parent
	return t
end

-- ─── constructor ──────────────────────────────────────────────────────────

function AmbientLayer.new(parent, theme)
	local self = setmetatable({
		_parent  = parent,
		_conns   = {},
		_objects = {},
		_active  = true,
	}, AmbientLayer)

	local cfg = theme.ambient
	if not cfg then return self end

	self["_build_" .. (cfg.style or "float")](self, cfg, theme)
	return self
end

-- ─── style: float  (gentle upward drifting dots) ─────────────────────────

function AmbientLayer:_build_float(cfg, theme)
	local count = cfg.count or 16
	for i = 1, count do
		local sz   = rndInt(6, 20)
		local dot  = newDot(self._parent, 2)
		dot.Size               = UDim2.fromOffset(sz, sz)
		dot.Position           = UDim2.new(rnd(0,1), 0, rnd(0.1, 1.1), 0)
		dot.BackgroundColor3   = cfg.color or theme.accentColor

		local speedY  = rnd(0.04, 0.12)
		local driftX  = rnd(-0.015, 0.015)
		local phase   = rnd(0, math.pi * 2)
		local baseAlp = rnd(0.45, 0.7)

		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if not dot.Parent then conn:Disconnect() return end
			phase += dt * rnd(0.8, 1.5)
			local p = dot.Position
			local ny = p.Y.Scale - speedY * dt
			if ny < -0.06 then ny = 1.06 end
			dot.Position              = UDim2.new(p.X.Scale + driftX * dt, 0, ny, 0)
			dot.BackgroundTransparency = baseAlp + math.sin(phase) * 0.2
		end)
		table.insert(self._conns, conn)
		table.insert(self._objects, dot)
	end
end

-- ─── style: sunray  (radial glowing streaks from top, happy) ─────────────

function AmbientLayer:_build_sunray(cfg, theme)
	-- Soft golden circles that fade in/out in screen corners
	local count = cfg.count or 12
	for i = 1, count do
		local sz   = rndInt(30, 80)
		local lbl  = newText(self._parent, 2)
		lbl.Text      = (cfg.shapes or {"✦"})[rndInt(1, #(cfg.shapes or {"✦"}))]
		lbl.TextSize  = rndInt(18, 44)
		lbl.TextColor3 = cfg.color or theme.accentColor
		lbl.Size       = UDim2.fromOffset(sz, sz)
		lbl.Position   = UDim2.new(rnd(0, 1), 0, rnd(0.05, 0.95), 0)

		local speedX  = rnd(0.02, 0.08) * (math.random() > 0.5 and 1 or -1)
		local speedY  = rnd(-0.02, 0.02)
		local phase   = rnd(0, math.pi * 2)
		local rot     = rnd(0, 360)

		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if not lbl.Parent then conn:Disconnect() return end
			phase += dt * 1.2
			rot   += dt * rnd(20, 60)
			local p = lbl.Position
			local nx = p.X.Scale + speedX * dt
			if nx > 1.05 then nx = -0.05 elseif nx < -0.05 then nx = 1.05 end
			local ny = p.Y.Scale + speedY * dt
			if ny > 1.05 then ny = -0.05 elseif ny < -0.05 then ny = 1.05 end
			lbl.Position      = UDim2.new(nx, 0, ny, 0)
			lbl.Rotation      = rot % 360
			lbl.TextTransparency = 0.3 + math.abs(math.sin(phase)) * 0.55
		end)
		table.insert(self._conns, conn)
		table.insert(self._objects, lbl)
	end
end

-- ─── style: ember  (rising hot particles for angry) ──────────────────────

function AmbientLayer:_build_ember(cfg, theme)
	local shapes = cfg.shapes or {"◆"}
	for i = 1, (cfg.count or 20) do
		local lbl = newText(self._parent, 2)
		lbl.Text       = shapes[rndInt(1, #shapes)]
		lbl.TextSize   = rndInt(10, 28)
		lbl.TextColor3 = cfg.color or theme.accentColor
		local sz       = rndInt(20, 36)
		lbl.Size       = UDim2.fromOffset(sz, sz)
		lbl.Position   = UDim2.new(rnd(0.1, 0.9), 0, rnd(0.7, 1.1), 0)

		local speedY  = rnd(0.06, 0.18)
		local wobble  = rnd(0.008, 0.025) * (math.random() > 0.5 and 1 or -1)
		local phase   = rnd(0, math.pi * 2)

		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if not lbl.Parent then conn:Disconnect() return end
			phase += dt * rnd(2, 4)
			local p = lbl.Position
			local ny = p.Y.Scale - speedY * dt
			if ny < -0.08 then ny = rnd(0.7, 1.1) end
			lbl.Position         = UDim2.new(p.X.Scale + math.sin(phase) * wobble, 0, ny, 0)
			lbl.TextTransparency = 0.2 + math.abs(math.cos(phase * 0.5)) * 0.6
		end)
		table.insert(self._conns, conn)
		table.insert(self._objects, lbl)
	end
end

-- ─── style: petal  (gentle sideways drifting petals, sad) ────────────────

function AmbientLayer:_build_petal(cfg, theme)
	local shapes = cfg.shapes or {"🌸"}
	for i = 1, (cfg.count or 18) do
		local lbl = newText(self._parent, 2)
		lbl.Text       = shapes[rndInt(1, #shapes)]
		lbl.TextSize   = rndInt(14, 32)
		lbl.TextColor3 = cfg.color or theme.accentColor
		local sz       = rndInt(28, 48)
		lbl.Size       = UDim2.fromOffset(sz, sz)
		-- Start spread across top
		lbl.Position   = UDim2.new(rnd(0, 1), 0, rnd(-0.1, 0.3), 0)

		local speedY  = rnd(0.025, 0.07)
		local speedX  = rnd(0.008, 0.03) * (math.random() > 0.5 and 1 or -1)
		local sway    = rnd(0.006, 0.016)
		local phase   = rnd(0, math.pi * 2)
		local rot     = rnd(0, 360)

		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if not lbl.Parent then conn:Disconnect() return end
			phase += dt * rnd(0.5, 1.2)
			rot   += dt * rnd(15, 40) * (speedX > 0 and 1 or -1)
			local p = lbl.Position
			local ny = p.Y.Scale + speedY * dt
			if ny > 1.1 then ny = rnd(-0.1, 0.0) end
			lbl.Position         = UDim2.new(p.X.Scale + speedX * dt + math.sin(phase) * sway * dt, 0, ny, 0)
			lbl.Rotation         = rot % 360
			lbl.TextTransparency = 0.15 + math.abs(math.sin(phase * 0.4)) * 0.5
		end)
		table.insert(self._conns, conn)
		table.insert(self._objects, lbl)
	end
end

-- ─── style: snowflake  (slow drifting starfield, lonely) ─────────────────

function AmbientLayer:_build_snowflake(cfg, theme)
	local shapes = cfg.shapes or {"✦","·","⋆"}
	for i = 1, (cfg.count or 20) do
		local lbl = newText(self._parent, 2)
		lbl.Text       = shapes[rndInt(1, #shapes)]
		lbl.TextSize   = rndInt(8, 24)
		lbl.TextColor3 = cfg.color or theme.accentColor
		local sz       = rndInt(16, 36)
		lbl.Size       = UDim2.fromOffset(sz, sz)
		lbl.Position   = UDim2.new(rnd(0, 1), 0, rnd(0, 1), 0)

		local speedY  = rnd(0.012, 0.04)
		local speedX  = rnd(-0.006, 0.006)
		local phase   = rnd(0, math.pi * 2)
		local baseAlp = rnd(0.2, 0.55)

		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if not lbl.Parent then conn:Disconnect() return end
			phase += dt * rnd(0.4, 0.9)
			local p = lbl.Position
			local ny = p.Y.Scale + speedY * dt
			if ny > 1.08 then ny = -0.04 end
			lbl.Position         = UDim2.new(p.X.Scale + speedX * dt, 0, ny, 0)
			lbl.TextTransparency = baseAlp + math.sin(phase) * 0.25
		end)
		table.insert(self._conns, conn)
		table.insert(self._objects, lbl)
	end
end

-- ─── style: spark  (fast twinkling bursts, excited) ──────────────────────

function AmbientLayer:_build_spark(cfg, theme)
	local shapes = cfg.shapes or {"✦","★","◈"}
	for i = 1, (cfg.count or 22) do
		local lbl = newText(self._parent, 2)
		lbl.Text       = shapes[rndInt(1, #shapes)]
		lbl.TextSize   = rndInt(10, 30)
		lbl.TextColor3 = cfg.color or theme.accentColor
		local sz = rndInt(18, 40)
		lbl.Size       = UDim2.fromOffset(sz, sz)
		lbl.Position   = UDim2.new(rnd(0, 1), 0, rnd(0, 1), 0)

		local phase   = rnd(0, math.pi * 2)
		local moveX   = rnd(-0.04, 0.04)
		local moveY   = rnd(-0.04, 0.04)

		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if not lbl.Parent then conn:Disconnect() return end
			phase += dt * rnd(3, 7)
			local p = lbl.Position
			local nx = p.X.Scale + moveX * dt
			local ny = p.Y.Scale + moveY * dt
			if nx > 1.05 then nx = -0.05 elseif nx < -0.05 then nx = 1.05 end
			if ny > 1.05 then ny = -0.05 elseif ny < -0.05 then ny = 1.05 end
			lbl.Position         = UDim2.new(nx, 0, ny, 0)
			lbl.Rotation         = math.sin(phase * 1.3) * 45
			lbl.TextTransparency = 0.1 + math.abs(math.sin(phase)) * 0.75
		end)
		table.insert(self._conns, conn)
		table.insert(self._objects, lbl)
	end
end

-- ─── style: ripple  (concentric expanding circles, calm) ─────────────────

function AmbientLayer:_build_ripple(cfg, theme)
	-- Floating soft circle shapes
	local count = cfg.count or 10
	for i = 1, count do
		local sz = rndInt(20, 60)
		local dot = newDot(self._parent, 2)
		dot.Size             = UDim2.fromOffset(sz, sz)
		dot.Position         = UDim2.new(rnd(0.05, 0.95), 0, rnd(0.05, 0.95), 0)
		dot.BackgroundColor3 = cfg.color or theme.accentColor

		local phase  = rnd(0, math.pi * 2)
		local growSz = rndInt(10, 30)
		local speed  = rnd(0.3, 0.8)

		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if not dot.Parent then conn:Disconnect() return end
			phase += dt * speed
			local scale = 1 + math.sin(phase) * 0.25
			local cur   = sz * scale
			dot.Size                 = UDim2.fromOffset(cur, cur)
			dot.BackgroundTransparency = 0.55 + math.abs(math.sin(phase)) * 0.3
		end)
		table.insert(self._conns, conn)
		table.insert(self._objects, dot)
	end
end

-- ─── cleanup ──────────────────────────────────────────────────────────────

function AmbientLayer:Stop()
	self._active = false
	for _, c in ipairs(self._conns) do
		c:Disconnect()
	end
	self._conns = {}
	for _, o in ipairs(self._objects) do
		if o and o.Parent then o:Destroy() end
	end
	self._objects = {}
end

return AmbientLayer
