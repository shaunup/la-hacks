-- SceneLayer: draws a full-screen illustrated scene behind the gradient,
-- using only Roblox GUI primitives (Frame / TextLabel).
-- Each mood gets a unique scene: sun + clouds, night sky + stars, volcano, etc.
-- Usage:
--   local SceneLayer = require(...)
--   local scene = SceneLayer.new(bgFrame, mood)
--   scene:Stop()   -- removes all objects

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local SceneLayer = {}
SceneLayer.__index = SceneLayer

-- ─── tiny helpers ─────────────────────────────────────────────────────────────

local function rnd(a, b) return a + math.random() * (b - a) end
local function rndI(a, b) return math.random(a, b) end

local function frame(parent, x, y, w, h, col, alpha, z)
	local f = Instance.new("Frame")
	f.Position           = UDim2.new(x, 0, y, 0)
	f.Size               = UDim2.new(w, 0, h, 0)
	f.BackgroundColor3   = col
	f.BackgroundTransparency = alpha or 0
	f.BorderSizePixel    = 0
	f.ZIndex             = z or 1
	f.Parent             = parent
	return f
end

local function pill(parent, x, y, w, h, col, alpha, z, rx)
	local f = frame(parent, x, y, w, h, col, alpha, z)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, rx or 999)
	c.Parent = f
	return f
end

local function emoji(parent, x, y, sz, text, z, anchorX, anchorY)
	local l = Instance.new("TextLabel")
	l.Size               = UDim2.fromOffset(sz, sz)
	l.AnchorPoint        = Vector2.new(anchorX or 0, anchorY or 0)
	l.Position           = UDim2.new(x, 0, y, 0)
	l.BackgroundTransparency = 1
	l.Text               = text
	l.TextSize           = sz * 0.85
	l.Font               = Enum.Font.GothamBold
	l.ZIndex             = z or 1
	l.Parent             = parent
	return l
end

-- ─── constructor ──────────────────────────────────────────────────────────────

function SceneLayer.new(parent, mood)
	local self = setmetatable({
		_parent = parent,
		_objects = {},
		_conns   = {},
		_active  = true,
	}, SceneLayer)

	local builder = SceneLayer["_scene_" .. (mood or "neutral")]
	if builder then builder(self) end

	return self
end

-- ─── cleanup ──────────────────────────────────────────────────────────────────

function SceneLayer:_add(obj)
	table.insert(self._objects, obj)
	return obj
end

function SceneLayer:_conn(c)
	table.insert(self._conns, c)
	return c
end

function SceneLayer:Stop()
	self._active = false
	for _, c in ipairs(self._conns) do c:Disconnect() end
	for _, o in ipairs(self._objects) do
		if o and o.Parent then o:Destroy() end
	end
	self._conns, self._objects = {}, {}
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- HAPPY — sunrise sky: large glowing sun, light clouds drifting right
-- ═══════════════════════════════════════════════════════════════════════════════

function SceneLayer:_scene_happy()
	local p = self._parent

	-- Ground strip
	self:_add(pill(p, 0, 0.78, 1, 0.22, Color3.fromRGB(255, 200, 80), 0.55, 1, 0))

	-- Sun glow aura
	local sunGlow = self:_add(pill(p, 0, 0, 0, 0, Color3.fromRGB(255, 240, 120), 0.55, 1))
	sunGlow.Size     = UDim2.fromOffset(260, 260)
	sunGlow.AnchorPoint = Vector2.new(0.5, 0.5)
	sunGlow.Position    = UDim2.new(0.5, 0, 0.35, 0)

	-- Sun core
	local sun = self:_add(pill(p, 0, 0, 0, 0, Color3.fromRGB(255, 230, 50), 0.05, 2))
	sun.Size        = UDim2.fromOffset(120, 120)
	sun.AnchorPoint = Vector2.new(0.5, 0.5)
	sun.Position    = UDim2.new(0.5, 0, 0.35, 0)

	-- Sun rays (8 thin rectangles rotated)
	for i = 1, 8 do
		local ray = self:_add(pill(p, 0, 0, 0, 0, Color3.fromRGB(255, 240, 100), 0.55, 1))
		ray.Size        = UDim2.fromOffset(6, 140)
		ray.AnchorPoint = Vector2.new(0.5, 0.5)
		ray.Position    = UDim2.new(0.5, 0, 0.35, 0)
		ray.Rotation    = (i - 1) * 45
	end

	-- Clouds
	local cloudData = {
		{ x=0.08, y=0.15, w=160, wgt=0.6 },
		{ x=0.55, y=0.10, w=220, wgt=0.45 },
		{ x=0.25, y=0.24, w=130, wgt=0.7 },
		{ x=0.72, y=0.28, w=180, wgt=0.5 },
	}
	for _, cd in ipairs(cloudData) do
		local cloud = self:_add(pill(p, cd.x, cd.y, 0, 0, Color3.fromRGB(255, 255, 255), cd.wgt, 2))
		cloud.Size = UDim2.fromOffset(cd.w, cd.w * 0.45)
		local speed = rnd(0.003, 0.007)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not cloud.Parent then return end
			local cx = cloud.Position.X.Scale + speed * dt
			if cx > 1.1 then cx = -0.25 end
			cloud.Position = UDim2.new(cx, 0, cloud.Position.Y.Scale, 0)
		end))
	end

	-- Sun slow rotation
	local angle = 0
	self:_conn(RunService.Heartbeat:Connect(function(dt)
		if not sun.Parent then return end
		angle = angle + dt * 3
		sunGlow.Rotation = angle
	end))
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CALM — ocean horizon: gradient sea, distant mountains, slow waves
-- ═══════════════════════════════════════════════════════════════════════════════

function SceneLayer:_scene_calm()
	local p = self._parent

	-- Sea
	self:_add(frame(p, 0, 0.60, 1, 0.40, Color3.fromRGB(60, 140, 200), 0.15, 1))
	-- Sea shimmer
	self:_add(frame(p, 0, 0.60, 1, 0.04, Color3.fromRGB(160, 220, 255), 0.5, 2))

	-- Distant mountains (layered)
	local mtns = {
		{ col = Color3.fromRGB(100, 160, 200), y = 0.48, peaks = 4, wgt = 0.35 },
		{ col = Color3.fromRGB(70,  130, 180), y = 0.54, peaks = 3, wgt = 0.45 },
	}
	for _, m in ipairs(mtns) do
		-- Simple triangle approximation using a tall pill
		for i = 1, m.peaks do
			local mf = self:_add(pill(p, (i-1)/m.peaks + rnd(-0.03,0.03), m.y, 0, 0, m.col, m.wgt, 1, 6))
			mf.Size = UDim2.fromOffset(rndI(120,200), rndI(80,130))
		end
	end

	-- Waves (slow horizontal lines)
	for i = 1, 5 do
		local wy = 0.62 + i * 0.055
		local wv = self:_add(pill(p, 0, wy, rnd(0.3, 0.6), 0, Color3.fromRGB(180, 230, 255), 0.6, 2))
		wv.Size = UDim2.new(rnd(0.3, 0.6), 0, 0, 3)
		local speed = rnd(-0.004, 0.004)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not wv.Parent then return end
			local wx = wv.Position.X.Scale + speed * dt
			if wx > 1.1 then wx = -0.7 elseif wx < -0.7 then wx = 1.1 end
			wv.Position = UDim2.new(wx, 0, wy, 0)
		end))
	end

	-- Fluffy clouds (calm, barely moving)
	for i = 1, 3 do
		local cx = rnd(0.05, 0.85)
		local cy = rnd(0.08, 0.30)
		local cw = rndI(120, 200)
		local cl = self:_add(pill(p, cx, cy, 0, 0, Color3.fromRGB(240, 250, 255), 0.25, 2))
		cl.Size = UDim2.fromOffset(cw, cw * 0.4)
		local spd = rnd(0.001, 0.003)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not cl.Parent then return end
			local nx = cl.Position.X.Scale + spd * dt
			if nx > 1.1 then nx = -0.3 end
			cl.Position = UDim2.new(nx, 0, cy, 0)
		end))
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- EXCITED — neon city at dusk: skyline silhouette, streaking lights
-- ═══════════════════════════════════════════════════════════════════════════════

function SceneLayer:_scene_excited()
	local p = self._parent

	-- Horizon glow
	self:_add(pill(p, 0, 0.65, 1, 0.08, Color3.fromRGB(255, 80, 200), 0.25, 1, 0))

	-- Skyline buildings (dark silhouette)
	local buildings = {
		{x=0.0,  h=0.28, w=0.07}, {x=0.06, h=0.36, w=0.05},
		{x=0.11, h=0.22, w=0.09}, {x=0.20, h=0.42, w=0.06},
		{x=0.26, h=0.30, w=0.08}, {x=0.34, h=0.48, w=0.05},
		{x=0.60, h=0.32, w=0.06}, {x=0.66, h=0.26, w=0.08},
		{x=0.74, h=0.44, w=0.05}, {x=0.79, h=0.20, w=0.10},
		{x=0.89, h=0.36, w=0.06}, {x=0.95, h=0.28, w=0.07},
	}
	for _, b in ipairs(buildings) do
		self:_add(frame(p, b.x, 1 - b.h, b.w, b.h, Color3.fromRGB(20, 10, 40), 0.0, 2))
		-- Window lights
		for row = 1, rndI(2, 5) do
			for col_ = 1, rndI(2, 4) do
				if math.random() > 0.45 then
					local wx = b.x + col_ * (b.w / 5) - 0.005
					local wy = 1 - b.h + row * 0.06
					self:_add(frame(p, wx, wy, 0.008, 0.012, Color3.fromRGB(255, 230, 120), 0.1, 3))
				end
			end
		end
	end

	-- Neon streaks flying across
	for _ = 1, 5 do
		local sy   = rnd(0.2, 0.65)
		local col  = ({
			Color3.fromRGB(255,80,200),
			Color3.fromRGB(80,200,255),
			Color3.fromRGB(255,220,50),
			Color3.fromRGB(200,100,255),
		})[rndI(1,4)]

		local streak = self:_add(pill(p, rnd(-0.5, 0), sy, 0, 0, col, 0.25, 3))
		streak.Size = UDim2.new(rnd(0.1, 0.25), 0, 0, 3)
		local speed = rnd(0.2, 0.45)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not streak.Parent then return end
			local nx = streak.Position.X.Scale + speed * dt
			if nx > 1.3 then
				nx = rnd(-0.5, -0.1)
				streak.Size = UDim2.new(rnd(0.08, 0.22), 0, 0, 3)
			end
			streak.Position = UDim2.new(nx, 0, sy, 0)
		end))
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ANXIOUS — misty forest: layered trees in fog, fireflies
-- ═══════════════════════════════════════════════════════════════════════════════

function SceneLayer:_scene_anxious()
	local p = self._parent

	-- Ground mist
	self:_add(pill(p, 0, 0.75, 1, 0.25, Color3.fromRGB(160, 210, 190), 0.4, 1, 0))

	-- Tree layers (back to front, lightening)
	local layers = {
		{ col = Color3.fromRGB( 30,  80,  55), alpha = 0.15, y = 0.35, count = 8 },
		{ col = Color3.fromRGB( 50, 110,  75), alpha = 0.25, y = 0.45, count = 7 },
		{ col = Color3.fromRGB( 70, 140,  95), alpha = 0.35, y = 0.55, count = 6 },
	}
	for _, l in ipairs(layers) do
		for i = 1, l.count do
			local tw_ = rnd(0.06, 0.12)
			local th  = rnd(0.25, 0.42)
			local tx  = (i - 1) / l.count + rnd(-0.02, 0.02)
			-- Trunk
			self:_add(frame(p, tx + tw_*0.4, l.y + th*0.5, tw_*0.2, th*0.55, l.col, l.alpha, 2))
			-- Canopy (pill)
			local can = self:_add(pill(p, tx, l.y, tw_, th, l.col, l.alpha, 2))
			can.Size = UDim2.new(tw_, 0, th, 0)
		end
	end

	-- Fireflies (glowing dots floating gently)
	for i = 1, 12 do
		local fx = rnd(0.05, 0.95)
		local fy = rnd(0.50, 0.80)
		local ff = self:_add(pill(p, fx, fy, 0, 0, Color3.fromRGB(200, 255, 180), 0.2, 4))
		ff.Size = UDim2.fromOffset(10, 10)
		local phase = rnd(0, math.pi*2)
		local sx = rnd(-0.004, 0.004)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not ff.Parent then return end
			phase += dt * rnd(0.8, 1.8)
			local nx = ff.Position.X.Scale + sx * dt
			if nx < 0.02 then nx = 0.02; sx = math.abs(sx)
			elseif nx > 0.98 then nx = 0.98; sx = -math.abs(sx) end
			local ny = fy + math.sin(phase) * 0.04
			ff.Position              = UDim2.new(nx, 0, ny, 0)
			ff.BackgroundTransparency = 0.1 + math.abs(math.sin(phase)) * 0.65
		end))
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SAD — gentle rain on a garden: falling rain streaks, soft flower silhouettes
-- ═══════════════════════════════════════════════════════════════════════════════

function SceneLayer:_scene_sad()
	local p = self._parent

	-- Ground
	self:_add(frame(p, 0, 0.78, 1, 0.22, Color3.fromRGB(160, 130, 190), 0.5, 1))

	-- Flower silhouettes
	local flowerEmojis = {"🌸","🌷","🌺","🌼"}
	for i = 1, 8 do
		local fe = self:_add(emoji(p, (i-1)*0.13 + rnd(-0.02,0.02), rnd(0.68,0.76),
			rndI(28,48), flowerEmojis[rndI(1,#flowerEmojis)], 3))
		-- Gentle sway
		local phase = rnd(0, math.pi*2)
		local startY = fe.Position.Y.Scale
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not fe.Parent then return end
			phase += dt * 0.7
			fe.Rotation = math.sin(phase) * 6
			fe.Position = UDim2.new(fe.Position.X.Scale, 0, startY + math.sin(phase*0.5)*0.005, 0)
		end))
	end

	-- Rain (short vertical pill streaks)
	for i = 1, 30 do
		local rx = rnd(0, 1)
		local ry = rnd(-0.2, 1.0)
		local rain = self:_add(pill(p, rx, ry, 0, 0, Color3.fromRGB(180, 200, 230), 0.55, 3))
		rain.Size = UDim2.fromOffset(2, rndI(12, 22))
		local speed = rnd(0.25, 0.55)
		local drift = rnd(-0.012, 0.012)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not rain.Parent then return end
			local ny = rain.Position.Y.Scale + speed * dt
			local nx = rain.Position.X.Scale + drift * dt
			if ny > 1.05 then
				ny = rnd(-0.2, -0.02)
				nx = rnd(0, 1)
			end
			rain.Position = UDim2.new(nx, 0, ny, 0)
		end))
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- LONELY — deep night sky: stars twinkling, lone crescent moon
-- ═══════════════════════════════════════════════════════════════════════════════

function SceneLayer:_scene_lonely()
	local p = self._parent

	-- Ground (dark plain)
	self:_add(frame(p, 0, 0.80, 1, 0.20, Color3.fromRGB(15, 20, 55), 0.2, 1))

	-- Crescent moon
	-- Outer circle
	local moonOut = self:_add(pill(p, 0, 0, 0, 0, Color3.fromRGB(220, 230, 255), 0.05, 2))
	moonOut.Size     = UDim2.fromOffset(90, 90)
	moonOut.AnchorPoint = Vector2.new(0, 0)
	moonOut.Position    = UDim2.new(0.72, 0, 0.08, 0)
	-- Inner "bite" circle (same as background colour)
	local moonIn = self:_add(pill(p, 0, 0, 0, 0, Color3.fromRGB(18, 24, 72), 0.0, 3))
	moonIn.Size     = UDim2.fromOffset(72, 72)
	moonIn.Position = UDim2.new(0.74, 0, 0.06, 0)

	-- Stars (static twinkling)
	for i = 1, 50 do
		local sx = rnd(0.01, 0.99)
		local sy = rnd(0.01, 0.72)
		local sz = rndI(3, 8)
		local st = self:_add(pill(p, sx, sy, 0, 0, Color3.fromRGB(200, 215, 255), 0.1, 2))
		st.Size = UDim2.fromOffset(sz, sz)
		local phase = rnd(0, math.pi*2)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not st.Parent then return end
			phase += dt * rnd(0.4, 1.2)
			st.BackgroundTransparency = 0.05 + math.abs(math.sin(phase)) * 0.75
		end))
	end

	-- Shooting star occasionally
	local ssPhase = rnd(0, 10)
	local ss = self:_add(pill(p, -0.1, rnd(0.1, 0.4), 0, 0, Color3.fromRGB(255, 255, 255), 0.0, 3))
	ss.Size = UDim2.fromOffset(80, 2)
	ss.Rotation = 25
	self:_conn(RunService.Heartbeat:Connect(function(dt)
		if not ss.Parent then return end
		ssPhase += dt
		local cycle = ssPhase % 8
		if cycle < 1.5 then
			ss.BackgroundTransparency = 0.1 + math.abs(math.sin(cycle * math.pi)) * 0.5
			local nx = -0.1 + cycle / 1.5 * 1.3
			local ny = ss.Position.Y.Scale + dt * 0.08
			ss.Position = UDim2.new(nx, 0, ny, 0)
		else
			ss.BackgroundTransparency = 1
			if cycle > 7.5 then
				ss.Position = UDim2.new(rnd(-0.2, 0), rnd(0.05, 0.4), 0, 0)
			end
		end
	end))
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ANGRY — volcanic eruption: lava glow, rising ash particles
-- ═══════════════════════════════════════════════════════════════════════════════

function SceneLayer:_scene_angry()
	local p = self._parent

	-- Lava ground glow
	self:_add(frame(p, 0, 0.75, 1, 0.25, Color3.fromRGB(200, 40, 10), 0.15, 1))
	self:_add(pill(p, 0, 0.73, 1, 0.05, Color3.fromRGB(255, 140, 20), 0.35, 2, 0))

	-- Volcano silhouette (two overlapping pills)
	local vol = self:_add(pill(p, 0.30, 0.35, 0.40, 0.50, Color3.fromRGB(30, 15, 10), 0.05, 2, 8))
	vol.Size = UDim2.new(0.40, 0, 0.50, 0)
	-- Crater opening (lighter)
	self:_add(pill(p, 0.38, 0.33, 0.24, 0.06, Color3.fromRGB(255, 80, 20), 0.4, 3, 999))

	-- Lava streams
	for i = 1, 3 do
		local lx = 0.42 + i * 0.04
		local lava = self:_add(pill(p, lx, 0.38, 0, 0, Color3.fromRGB(255, 120, 0), 0.3, 3, 4))
		lava.Size = UDim2.fromOffset(6, rndI(50, 100))
	end

	-- Ash/embers rising
	for i = 1, 20 do
		local ex = rnd(0.35, 0.65)
		local ey = rnd(0.30, 0.75)
		local em = self:_add(pill(p, ex, ey, 0, 0, Color3.fromRGB(255, rndI(60,160), 0), 0.3, 4))
		em.Size = UDim2.fromOffset(rndI(4, 12), rndI(4, 12))
		local speed = rnd(0.04, 0.14)
		local drift = rnd(-0.02, 0.02)
		local phase = rnd(0, math.pi*2)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not em.Parent then return end
			phase += dt * rnd(1.5, 3)
			local ny = em.Position.Y.Scale - speed * dt
			local nx = em.Position.X.Scale + drift * dt
			if ny < -0.05 then
				ny = rnd(0.30, 0.75)
				nx = rnd(0.35, 0.65)
			end
			em.Position              = UDim2.new(nx, 0, ny, 0)
			em.BackgroundTransparency = 0.2 + math.abs(math.sin(phase)) * 0.6
		end))
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- STRESSED — rainy dusk: city skyline with rain, muted grey
-- ═══════════════════════════════════════════════════════════════════════════════

function SceneLayer:_scene_stressed()
	local p = self._parent

	-- Ground
	self:_add(frame(p, 0, 0.80, 1, 0.20, Color3.fromRGB(50, 90, 65), 0.35, 1))

	-- Rolling hills
	for i = 1, 4 do
		local hill = self:_add(pill(p, (i-1)*0.26 - 0.05, rnd(0.62, 0.72), rnd(0.3,0.5), rnd(0.18,0.28),
			Color3.fromRGB(55, 120, 80), 0.4, 2, 8))
	end

	-- Light drizzle (finer than sad scene)
	for i = 1, 22 do
		local rx = rnd(0, 1)
		local ry = rnd(-0.1, 1.0)
		local rain = self:_add(pill(p, rx, ry, 0, 0, Color3.fromRGB(170, 210, 185), 0.6, 3))
		rain.Size = UDim2.fromOffset(1, rndI(8, 16))
		local speed = rnd(0.18, 0.38)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not rain.Parent then return end
			local ny = rain.Position.Y.Scale + speed * dt
			if ny > 1.05 then ny = rnd(-0.1, -0.01) end
			rain.Position = UDim2.new(rain.Position.X.Scale, 0, ny, 0)
		end))
	end

	-- Floating leaf particles
	for i = 1, 6 do
		local leaf = self:_add(emoji(p, rnd(0.05,0.95), rnd(0.1,0.7), rndI(18,28), "🍃", 3))
		local sx = rnd(-0.02, -0.005)
		local sy = rnd(0.01, 0.04)
		local phase = rnd(0, math.pi*2)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not leaf.Parent then return end
			phase += dt * 0.9
			local nx = leaf.Position.X.Scale + sx * dt
			local ny = leaf.Position.Y.Scale + sy * dt
			if nx < -0.05 then nx = 1.05 end
			if ny > 0.95 then ny = rnd(0.1, 0.3); nx = rnd(0.2, 0.9) end
			leaf.Position = UDim2.new(nx, 0, ny, 0)
			leaf.Rotation = math.sin(phase) * 20
		end))
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- NEUTRAL — twilight: simple horizon glow, a few drifting clouds
-- ═══════════════════════════════════════════════════════════════════════════════

function SceneLayer:_scene_neutral()
	local p = self._parent

	-- Horizon glow strip
	self:_add(pill(p, 0, 0.56, 1, 0.08, Color3.fromRGB(120, 160, 220), 0.35, 1, 0))
	-- Ground silhouette
	self:_add(frame(p, 0, 0.72, 1, 0.28, Color3.fromRGB(35, 50, 90), 0.3, 1))

	-- Moon
	local moon = self:_add(pill(p, 0, 0, 0, 0, Color3.fromRGB(240, 245, 255), 0.08, 2))
	moon.Size     = UDim2.fromOffset(60, 60)
	moon.Position = UDim2.new(0.78, 0, 0.12, 0)

	-- Stars
	for i = 1, 30 do
		local st = self:_add(pill(p, rnd(0,1), rnd(0,0.55), 0, 0, Color3.fromRGB(200, 215, 255), 0.2, 2))
		st.Size = UDim2.fromOffset(rndI(2,6), rndI(2,6))
		local phase = rnd(0, math.pi*2)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not st.Parent then return end
			phase += dt * rnd(0.5, 1.3)
			st.BackgroundTransparency = 0.1 + math.abs(math.sin(phase)) * 0.7
		end))
	end

	-- Slow drifting clouds
	for i = 1, 3 do
		local cy = rnd(0.20, 0.42)
		local cl = self:_add(pill(p, rnd(-0.2, 0.8), cy, 0, 0, Color3.fromRGB(80, 110, 180), 0.55, 2))
		cl.Size = UDim2.fromOffset(rndI(100, 180), rndI(35, 60))
		local spd = rnd(0.003, 0.007)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not cl.Parent then return end
			local nx = cl.Position.X.Scale + spd * dt
			if nx > 1.15 then nx = -0.3 end
			cl.Position = UDim2.new(nx, 0, cy, 0)
		end))
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- excited uses neutral scene (stars/neon) – already defined above
-- ═══════════════════════════════════════════════════════════════════════════════

return SceneLayer
