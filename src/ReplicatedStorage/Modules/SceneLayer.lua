-- SceneLayer v2: vivid mood-matched illustrated backgrounds
-- Uses scale-based sizing/positioning so scenes fill any resolution.
-- ZIndex range: 2-6. Gradient (bgFrame UIGradient) is at ZIndex 1.
-- Ambient particles live at ZIndex 7+, all UI cards at ZIndex 10+.
-- All BackgroundTransparency values kept LOW (0-0.3) so shapes are clearly visible.

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local SceneLayer = {}
SceneLayer.__index = SceneLayer

-- ─── helpers ──────────────────────────────────────────────────────────────────

local function rnd(a, b)  return a + math.random() * (b - a)    end
local function rndI(a, b) return math.random(a, b)              end

-- Scale-based Frame
local function sf(parent, x, y, w, h, col, alpha, z)
	local f = Instance.new("Frame")
	f.Position           = UDim2.new(x, 0, y, 0)
	f.Size               = UDim2.new(w, 0, h, 0)
	f.BackgroundColor3   = col
	f.BackgroundTransparency = alpha or 0
	f.BorderSizePixel    = 0
	f.ZIndex             = z or 2
	f.Parent             = parent
	return f
end

-- Pill (rounded) Frame
local function pill(parent, x, y, w, h, col, alpha, z)
	local f = sf(parent, x, y, w, h, col, alpha, z)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 999)
	c.Parent = f
	return f
end

-- Rounded Frame with explicit radius
local function rounded(parent, x, y, w, h, col, alpha, z, r)
	local f = sf(parent, x, y, w, h, col, alpha, z)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 12)
	c.Parent = f
	return f
end

-- Emoji TextLabel (scale-positioned)
local function emojiLabel(parent, x, y, sz, text, z)
	local l = Instance.new("TextLabel")
	l.AnchorPoint        = Vector2.new(0, 0)
	l.Size               = UDim2.new(0, sz, 0, sz)
	l.Position           = UDim2.new(x, 0, y, 0)
	l.BackgroundTransparency = 1
	l.Text               = text
	l.TextSize           = sz * 0.88
	l.Font               = Enum.Font.GothamBold
	l.ZIndex             = z or 2
	l.Parent             = parent
	return l
end

-- ─── constructor ──────────────────────────────────────────────────────────────

function SceneLayer.new(parent, mood)
	local self = setmetatable({ _parent=parent, _objects={}, _conns={}, _active=true }, SceneLayer)
	local ok, err = pcall(function()
		local builder = SceneLayer["_scene_" .. tostring(mood)]
		if builder then builder(self) end
	end)
	if not ok then warn("[SceneLayer] build error for", mood, ":", err) end
	return self
end

function SceneLayer:_add(o) table.insert(self._objects, o); return o end
function SceneLayer:_conn(c) table.insert(self._conns,   c); return c end

function SceneLayer:Stop()
	self._active = false
	for _, c in ipairs(self._conns)   do pcall(function() c:Disconnect() end) end
	for _, o in ipairs(self._objects) do if o and o.Parent then o:Destroy() end end
	self._conns, self._objects = {}, {}
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- HAPPY — brilliant sunrise: deep gold sky, sun, rays, white clouds
-- ═══════════════════════════════════════════════════════════════════════════════
function SceneLayer:_scene_happy()
	local p = self._parent

	-- Sky fill (warm amber-to-gold)
	self:_add(sf(p, 0, 0, 1, 1, Color3.fromRGB(255, 185, 40), 0.0, 2))
	-- Horizon glow band
	self:_add(sf(p, 0, 0.55, 1, 0.2, Color3.fromRGB(255, 130, 0), 0.15, 2))
	-- Ground strip
	self:_add(rounded(p, 0, 0.8, 1, 0.2, Color3.fromRGB(200, 120, 20), 0.0, 2, 0))

	-- Sun outer glow
	local sunGlow = self:_add(pill(p, 0, 0, 0, 0, Color3.fromRGB(255, 255, 180), 0.0, 3))
	sunGlow.Size     = UDim2.new(0.38, 0, 0, 0)
	sunGlow.Size     = UDim2.fromOffset(220, 220)
	sunGlow.AnchorPoint = Vector2.new(0.5, 0.5)
	sunGlow.Position    = UDim2.new(0.5, 0, 0.38, 0)
	sunGlow.BackgroundTransparency = 0.3

	-- Sun core
	local sun = self:_add(pill(p, 0, 0, 0, 0, Color3.fromRGB(255, 240, 60), 0.0, 4))
	sun.Size        = UDim2.fromOffset(110, 110)
	sun.AnchorPoint = Vector2.new(0.5, 0.5)
	sun.Position    = UDim2.new(0.5, 0, 0.38, 0)

	-- Sun rays (8 rectangles, rotate around centre)
	for i = 1, 8 do
		local ray = self:_add(sf(p, 0, 0, 0, 0, Color3.fromRGB(255, 235, 80), 0.2, 3))
		ray.Size        = UDim2.fromOffset(8, 150)
		ray.AnchorPoint = Vector2.new(0.5, 0.5)
		ray.Position    = UDim2.new(0.5, 0, 0.38, 0)
		ray.Rotation    = (i - 1) * 45
	end

	-- Rotating animation
	local angle = 0
	self:_conn(RunService.Heartbeat:Connect(function(dt)
		if not sun.Parent then return end
		angle += dt * 4
		sunGlow.Rotation = angle
	end))

	-- Clouds
	local clouds = {
		{ x=0.05, y=0.14, w=200, alpha=0.0 },
		{ x=0.60, y=0.09, w=260, alpha=0.0 },
		{ x=0.22, y=0.25, w=160, alpha=0.05 },
		{ x=0.72, y=0.30, w=210, alpha=0.05 },
	}
	for _, cd in ipairs(clouds) do
		local cl = self:_add(pill(p, cd.x, cd.y, 0, 0, Color3.fromRGB(255, 255, 255), cd.alpha, 5))
		cl.Size = UDim2.fromOffset(cd.w, cd.w * 0.40)
		local speed = rnd(0.003, 0.006)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not cl.Parent then return end
			local nx = cl.Position.X.Scale + speed * dt
			if nx > 1.1 then nx = -0.28 end
			cl.Position = UDim2.new(nx, 0, cl.Position.Y.Scale, 0)
		end))
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CALM — serene ocean at midday: blue sky, layered sea, waves
-- ═══════════════════════════════════════════════════════════════════════════════
function SceneLayer:_scene_calm()
	local p = self._parent

	-- Sky
	self:_add(sf(p, 0, 0, 1, 0.60, Color3.fromRGB(120, 195, 240), 0.0, 2))
	-- Deep ocean
	self:_add(sf(p, 0, 0.55, 1, 0.45, Color3.fromRGB(30, 110, 180), 0.0, 2))
	-- Lighter mid-ocean
	self:_add(sf(p, 0, 0.58, 1, 0.12, Color3.fromRGB(60, 155, 210), 0.1, 3))
	-- Horizon shimmer
	self:_add(pill(p, 0, 0.54, 1, 0.04, Color3.fromRGB(200, 235, 255), 0.2, 4))

	-- Distant mountains
	local mtns = {
		{col=Color3.fromRGB(90,155,200), y=0.38, w=0.32, h=0.22, x=0.02},
		{col=Color3.fromRGB(70,135,185), y=0.42, w=0.28, h=0.18, x=0.30},
		{col=Color3.fromRGB(55,120,175), y=0.40, w=0.36, h=0.20, x=0.55},
		{col=Color3.fromRGB(75,140,195), y=0.44, w=0.25, h=0.15, x=0.78},
	}
	for _, m in ipairs(mtns) do
		self:_add(rounded(p, m.x, m.y, m.w, m.h, m.col, 0.0, 3, 8))
	end

	-- Waves (horizontal pill strips)
	for i = 1, 6 do
		local wy = 0.60 + i * 0.052
		local ww = rnd(0.25, 0.55)
		local wx0 = rnd(0, 1 - ww)
		local wv  = self:_add(pill(p, wx0, wy, ww, 0, Color3.fromRGB(190, 230, 255), 0.3, 4))
		wv.Size = UDim2.new(ww, 0, 0, 4)
		local spd = rnd(-0.005, 0.005)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not wv.Parent then return end
			local nx = wv.Position.X.Scale + spd * dt
			if nx > 1.1 then nx = -0.6 elseif nx < -0.6 then nx = 1.1 end
			wv.Position = UDim2.new(nx, 0, wy, 0)
		end))
	end

	-- Sun (smaller, high up)
	local sun = self:_add(pill(p, 0, 0, 0, 0, Color3.fromRGB(255, 245, 180), 0.0, 5))
	sun.Size     = UDim2.fromOffset(70, 70)
	sun.Position = UDim2.new(0.82, 0, 0.07, 0)

	-- Slow clouds
	for i = 1, 3 do
		local cy = rnd(0.05, 0.28)
		local cl = self:_add(pill(p, rnd(0, 0.8), cy, 0, 0, Color3.fromRGB(255, 255, 255), 0.1, 5))
		cl.Size = UDim2.fromOffset(rndI(130, 210), rndI(42, 65))
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
-- EXCITED — neon-lit night city: purple sky, buildings, coloured streaks
-- ═══════════════════════════════════════════════════════════════════════════════
function SceneLayer:_scene_excited()
	local p = self._parent

	-- Night sky
	self:_add(sf(p, 0, 0, 1, 1, Color3.fromRGB(55, 15, 90), 0.0, 2))
	-- Horizon neon glow
	self:_add(pill(p, 0, 0.62, 1, 0.08, Color3.fromRGB(220, 50, 200), 0.1, 3))
	self:_add(pill(p, 0, 0.65, 1, 0.06, Color3.fromRGB(80, 180, 255), 0.15, 3))

	-- Ground
	self:_add(sf(p, 0, 0.78, 1, 0.22, Color3.fromRGB(15, 5, 35), 0.0, 2))

	-- Buildings silhouette
	local blds = {
		{x=0.00, h=0.30, w=0.08}, {x=0.07, h=0.40, w=0.06},
		{x=0.13, h=0.24, w=0.09}, {x=0.22, h=0.46, w=0.07},
		{x=0.29, h=0.33, w=0.08}, {x=0.37, h=0.52, w=0.06},
		{x=0.58, h=0.35, w=0.07}, {x=0.65, h=0.28, w=0.09},
		{x=0.74, h=0.48, w=0.06}, {x=0.80, h=0.22, w=0.10},
		{x=0.90, h=0.38, w=0.07}, {x=0.97, h=0.30, w=0.07},
	}
	for _, b in ipairs(blds) do
		self:_add(sf(p, b.x, 1 - b.h, b.w, b.h, Color3.fromRGB(10, 5, 22), 0.0, 3))
		-- Coloured window lights
		for row = 1, rndI(3, 6) do
			for col_ = 1, rndI(2, 4) do
				if math.random() > 0.4 then
					local winColors = {
						Color3.fromRGB(255, 230, 100),
						Color3.fromRGB(200, 100, 255),
						Color3.fromRGB(80, 200, 255),
					}
					local wx2 = b.x + col_ * (b.w / 5.5)
					local wy2 = 1 - b.h + row * 0.055
					self:_add(sf(p, wx2, wy2, 0.009, 0.014, winColors[rndI(1,3)], 0.0, 4))
				end
			end
		end
	end

	-- Neon streaks across screen
	local streakCols = {
		Color3.fromRGB(255, 60, 200),
		Color3.fromRGB(60, 200, 255),
		Color3.fromRGB(255, 220, 40),
		Color3.fromRGB(160, 80, 255),
	}
	for _ = 1, 6 do
		local sy  = rnd(0.18, 0.70)
		local scl = streakCols[rndI(1,4)]
		local stk = self:_add(pill(p, rnd(-0.6, 0), sy, 0, 0, scl, 0.0, 5))
		stk.Size = UDim2.new(rnd(0.10, 0.28), 0, 0, 3)
		local spd = rnd(0.18, 0.42)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not stk.Parent then return end
			local nx = stk.Position.X.Scale + spd * dt
			if nx > 1.35 then
				nx = rnd(-0.6, -0.08)
				stk.Size = UDim2.new(rnd(0.08, 0.26), 0, 0, 3)
			end
			stk.Position = UDim2.new(nx, 0, sy, 0)
		end))
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ANXIOUS — misty green forest: layered trees, soft ground mist, fireflies
-- ═══════════════════════════════════════════════════════════════════════════════
function SceneLayer:_scene_anxious()
	local p = self._parent

	-- Sky (soft sage-green)
	self:_add(sf(p, 0, 0, 1, 1, Color3.fromRGB(140, 195, 165), 0.0, 2))
	-- Mist layers
	self:_add(pill(p, 0, 0.65, 1, 0.18, Color3.fromRGB(200, 235, 215), 0.1, 5))
	self:_add(pill(p, 0, 0.72, 1, 0.15, Color3.fromRGB(220, 245, 230), 0.15, 5))

	-- Ground
	self:_add(sf(p, 0, 0.82, 1, 0.18, Color3.fromRGB(60, 120, 80), 0.0, 2))

	-- Tree layers — back to front
	local treeLayers = {
		{col=Color3.fromRGB(40, 100, 65),  y=0.30, count=9,  wScale=0.10, hScale=0.42, alpha=0.0},
		{col=Color3.fromRGB(55, 125, 80),  y=0.40, count=8,  wScale=0.12, hScale=0.38, alpha=0.0},
		{col=Color3.fromRGB(70, 150, 95),  y=0.50, count=7,  wScale=0.14, hScale=0.34, alpha=0.0},
	}
	for _, l in ipairs(treeLayers) do
		for i = 1, l.count do
			local tx  = (i - 1) / l.count + rnd(-0.015, 0.015)
			local tw_ = l.wScale + rnd(-0.02, 0.02)
			local th  = l.hScale + rnd(-0.04, 0.04)
			-- Trunk
			self:_add(sf(p, tx + tw_*0.42, l.y + th*0.45, tw_*0.16, th*0.55, l.col, l.alpha, 3))
			-- Canopy (pill)
			self:_add(pill(p, tx, l.y, tw_, th, l.col, l.alpha, 3))
		end
	end

	-- Fireflies
	for _ = 1, 14 do
		local fx0 = rnd(0.04, 0.96)
		local fy0 = rnd(0.48, 0.80)
		local ff  = self:_add(pill(p, fx0, fy0, 0, 0, Color3.fromRGB(200, 255, 160), 0.0, 6))
		ff.Size = UDim2.fromOffset(10, 10)
		local phase = rnd(0, math.pi * 2)
		local sx    = rnd(-0.003, 0.003)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not ff.Parent then return end
			phase += dt * rnd(1.0, 2.2)
			local nx = ff.Position.X.Scale + sx * dt
			if nx < 0.02 then nx = 0.02; sx = math.abs(sx)
			elseif nx > 0.98 then nx = 0.98; sx = -math.abs(sx) end
			local ny = fy0 + math.sin(phase) * 0.04
			ff.Position              = UDim2.new(nx, 0, ny, 0)
			ff.BackgroundTransparency = math.abs(math.sin(phase * 0.5)) * 0.7
		end))
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SAD — purple dusk with falling rain over a flower garden
-- ═══════════════════════════════════════════════════════════════════════════════
function SceneLayer:_scene_sad()
	local p = self._parent

	-- Lilac sky
	self:_add(sf(p, 0, 0, 1, 1, Color3.fromRGB(170, 140, 200), 0.0, 2))
	-- Dusk gradient (darker at top)
	self:_add(sf(p, 0, 0, 1, 0.45, Color3.fromRGB(100, 80, 150), 0.15, 3))
	-- Ground
	self:_add(sf(p, 0, 0.80, 1, 0.20, Color3.fromRGB(100, 70, 140), 0.0, 2))

	-- Flower garden silhouette
	local flowers = {"🌸","🌷","🌺","🌼","🌸","🌷","🌺","🌼"}
	for i, emoji in ipairs(flowers) do
		local fe = self:_add(emojiLabel(p, (i-1)*0.127 + rnd(-0.01,0.01), rnd(0.68,0.75), rndI(32,52), emoji, 4))
		local phase = rnd(0, math.pi*2)
		local startY = fe.Position.Y.Scale
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not fe.Parent then return end
			phase += dt * 0.75
			fe.Rotation = math.sin(phase) * 7
			fe.Position = UDim2.new(fe.Position.X.Scale, 0, startY + math.sin(phase*0.45)*0.006, 0)
		end))
	end

	-- Rain
	for _ = 1, 35 do
		local rx0 = rnd(0, 1)
		local ry0 = rnd(-0.25, 1.0)
		local rain = self:_add(pill(p, rx0, ry0, 0, 0, Color3.fromRGB(190, 165, 225), 0.2, 5))
		rain.Size = UDim2.fromOffset(2, rndI(14, 26))
		local spd   = rnd(0.28, 0.60)
		local drift = rnd(-0.010, 0.010)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not rain.Parent then return end
			local ny = rain.Position.Y.Scale + spd * dt
			local nx = rain.Position.X.Scale + drift * dt
			if ny > 1.06 then ny = rnd(-0.2, -0.02); nx = rnd(0, 1) end
			rain.Position = UDim2.new(nx, 0, ny, 0)
		end))
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- LONELY — deep space night: lots of twinkling stars, crescent moon, shooting star
-- ═══════════════════════════════════════════════════════════════════════════════
function SceneLayer:_scene_lonely()
	local p = self._parent

	-- Deep dark blue-navy sky fill
	self:_add(sf(p, 0, 0, 1, 1, Color3.fromRGB(8, 12, 50), 0.0, 2))
	-- Purple nebula hint
	self:_add(pill(p, 0.15, 0.10, 0.70, 0.45, Color3.fromRGB(60, 30, 100), 0.55, 3))
	-- Ground silhouette
	self:_add(sf(p, 0, 0.83, 1, 0.17, Color3.fromRGB(10, 14, 40), 0.0, 2))

	-- Crescent moon (outer circle)
	local moonOut = self:_add(pill(p, 0, 0, 0, 0, Color3.fromRGB(230, 238, 255), 0.0, 4))
	moonOut.Size     = UDim2.fromOffset(90, 90)
	moonOut.Position = UDim2.new(0.73, 0, 0.07, 0)
	-- "Bite" circle same colour as sky
	local moonIn  = self:_add(pill(p, 0, 0, 0, 0, Color3.fromRGB(8, 12, 50), 0.0, 5))
	moonIn.Size     = UDim2.fromOffset(72, 72)
	moonIn.Position = UDim2.new(0.755, 0, 0.052, 0)

	-- Stars
	for _ = 1, 55 do
		local sx = rnd(0.01, 0.99)
		local sy = rnd(0.01, 0.76)
		local sz = rndI(3, 9)
		local st = self:_add(pill(p, sx, sy, 0, 0, Color3.fromRGB(210, 220, 255), 0.0, 4))
		st.Size = UDim2.fromOffset(sz, sz)
		local phase = rnd(0, math.pi*2)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not st.Parent then return end
			phase += dt * rnd(0.5, 1.5)
			st.BackgroundTransparency = 0.05 + math.abs(math.sin(phase)) * 0.8
		end))
	end

	-- Shooting star
	local ssTimer = rnd(2, 6)
	local ss = self:_add(pill(p, -0.15, rnd(0.08, 0.40), 0, 0, Color3.fromRGB(255, 255, 220), 1.0, 5))
	ss.Size = UDim2.fromOffset(90, 2); ss.Rotation = 28
	local ssElapsed = 0
	self:_conn(RunService.Heartbeat:Connect(function(dt)
		if not ss.Parent then return end
		ssElapsed += dt
		if ssElapsed < ssTimer then return end
		local progress = ssElapsed - ssTimer
		if progress < 1.6 then
			ss.BackgroundTransparency = math.max(0, 0.1 - progress * 0.06)
			ss.Position = UDim2.new(-0.15 + progress / 1.6 * 1.5, 0, ss.Position.Y.Scale + dt * 0.1, 0)
		else
			ss.BackgroundTransparency = 1
			if progress > 2.2 then
				ssTimer   = ssElapsed + rnd(3, 8)
				ss.Position = UDim2.new(rnd(-0.2, 0), rnd(0.05, 0.40), 0, 0)
			end
		end
	end))
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ANGRY — volcanic eruption: red-orange sky, volcano silhouette, rising embers
-- ═══════════════════════════════════════════════════════════════════════════════
function SceneLayer:_scene_angry()
	local p = self._parent

	-- Dark red-orange sky
	self:_add(sf(p, 0, 0, 1, 1, Color3.fromRGB(160, 30, 10), 0.0, 2))
	-- Lava horizon glow
	self:_add(pill(p, 0, 0.55, 1, 0.18, Color3.fromRGB(255, 100, 0), 0.0, 3))
	self:_add(pill(p, 0, 0.65, 1, 0.10, Color3.fromRGB(255, 160, 0), 0.1, 3))

	-- Lava ground
	self:_add(sf(p, 0, 0.80, 1, 0.20, Color3.fromRGB(180, 40, 0), 0.0, 2))
	-- Lava flow lines
	for i = 1, 4 do
		self:_add(pill(p, rnd(0,1), rnd(0.78, 0.85), rnd(0.1, 0.3), 0,
			Color3.fromRGB(255, 120, 0), 0.0, 3))
	end

	-- Volcano shape (two overlapping rounded frames)
	self:_add(rounded(p, 0.28, 0.30, 0.44, 0.55, Color3.fromRGB(25, 10, 5), 0.0, 3, 12))
	self:_add(rounded(p, 0.34, 0.25, 0.32, 0.20, Color3.fromRGB(20, 8, 3), 0.0, 4, 12))
	-- Crater glow
	self:_add(pill(p, 0, 0, 0, 0, Color3.fromRGB(255, 80, 0), 0.1, 5)).Size = UDim2.fromOffset(80, 22)
	do
		local cr = self._objects[#self._objects]
		cr.Position = UDim2.new(0.37, 0, 0.25, 0)
	end

	-- Embers rising
	for _ = 1, 22 do
		local ex0 = rnd(0.33, 0.67)
		local ey0 = rnd(0.25, 0.70)
		local ec  = Color3.fromRGB(255, rndI(60, 160), 0)
		local em  = self:_add(pill(p, ex0, ey0, 0, 0, ec, 0.0, 5))
		em.Size = UDim2.fromOffset(rndI(5, 13), rndI(5, 13))
		local spd   = rnd(0.04, 0.15)
		local drift = rnd(-0.02, 0.02)
		local phase = rnd(0, math.pi*2)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not em.Parent then return end
			phase += dt * rnd(2, 4)
			local ny = em.Position.Y.Scale - spd * dt
			local nx = em.Position.X.Scale + drift * dt + math.sin(phase) * 0.004
			if ny < -0.05 then ny = rnd(0.25, 0.70); nx = rnd(0.33, 0.67) end
			em.Position              = UDim2.new(nx, 0, ny, 0)
			em.BackgroundTransparency = math.abs(math.sin(phase)) * 0.55
		end))
	end

	-- Smoke puffs
	for _ = 1, 5 do
		local sx0 = rnd(0.36, 0.60)
		local sy0 = rnd(0.18, 0.28)
		local sm  = self:_add(pill(p, sx0, sy0, 0, 0, Color3.fromRGB(80, 40, 20), 0.2, 4))
		sm.Size = UDim2.fromOffset(rndI(30, 65), rndI(30, 65))
		local spd = rnd(0.008, 0.018)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not sm.Parent then return end
			local ny = sm.Position.Y.Scale - spd * dt
			if ny < -0.08 then ny = rnd(0.18, 0.30) end
			sm.Position              = UDim2.new(sm.Position.X.Scale, 0, ny, 0)
			sm.BackgroundTransparency = 0.2 + (0.30 - ny) * 1.2
		end))
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- STRESSED — soft rainy hills: sage-green rolling hills, drizzle, falling leaves
-- ═══════════════════════════════════════════════════════════════════════════════
function SceneLayer:_scene_stressed()
	local p = self._parent

	-- Overcast grey-green sky
	self:_add(sf(p, 0, 0, 1, 1, Color3.fromRGB(100, 150, 115), 0.0, 2))
	-- Cloud layer
	self:_add(sf(p, 0, 0, 1, 0.45, Color3.fromRGB(140, 180, 155), 0.1, 3))
	-- Ground
	self:_add(sf(p, 0, 0.78, 1, 0.22, Color3.fromRGB(55, 110, 70), 0.0, 2))

	-- Rolling hills
	local hills = {
		{x=-0.05, y=0.55, w=0.40, h=0.28, col=Color3.fromRGB(70, 135, 90)},
		{x=0.28,  y=0.60, w=0.38, h=0.22, col=Color3.fromRGB(80, 145, 98)},
		{x=0.60,  y=0.52, w=0.45, h=0.30, col=Color3.fromRGB(65, 128, 85)},
		{x=0.85,  y=0.58, w=0.30, h=0.24, col=Color3.fromRGB(75, 140, 92)},
	}
	for _, h in ipairs(hills) do
		self:_add(rounded(p, h.x, h.y, h.w, h.h, h.col, 0.0, 3, 999))
	end

	-- Drizzle
	for _ = 1, 28 do
		local rx = rnd(0, 1); local ry = rnd(-0.15, 1.0)
		local rain = self:_add(pill(p, rx, ry, 0, 0, Color3.fromRGB(170, 210, 185), 0.15, 5))
		rain.Size = UDim2.fromOffset(1, rndI(9, 18))
		local spd = rnd(0.18, 0.40)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not rain.Parent then return end
			local ny = rain.Position.Y.Scale + spd * dt
			if ny > 1.05 then ny = rnd(-0.15, -0.01) end
			rain.Position = UDim2.new(rain.Position.X.Scale, 0, ny, 0)
		end))
	end

	-- Drifting leaves
	for _ = 1, 7 do
		local lx0 = rnd(0.05, 0.95); local ly0 = rnd(0.08, 0.65)
		local leaf = self:_add(emojiLabel(p, lx0, ly0, rndI(20, 32), "🍃", 4))
		local spx  = rnd(-0.015, -0.005); local spy = rnd(0.008, 0.030)
		local phase = rnd(0, math.pi*2)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not leaf.Parent then return end
			phase += dt * 0.9
			local nx = leaf.Position.X.Scale + spx * dt
			local ny = leaf.Position.Y.Scale + spy * dt
			if nx < -0.06 then nx = 1.06 end
			if ny > 0.95 then ny = rnd(0.05, 0.35); nx = rnd(0.1, 0.9) end
			leaf.Position = UDim2.new(nx, 0, ny, 0)
			leaf.Rotation = math.sin(phase) * 22
		end))
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- NEUTRAL — twilight: blue-purple gradient, moon, twinkling stars, slow clouds
-- ═══════════════════════════════════════════════════════════════════════════════
function SceneLayer:_scene_neutral()
	local p = self._parent

	-- Twilight sky
	self:_add(sf(p, 0, 0, 1, 1, Color3.fromRGB(55, 70, 140), 0.0, 2))
	-- Horizon glow
	self:_add(pill(p, 0, 0.58, 1, 0.10, Color3.fromRGB(120, 140, 210), 0.2, 3))
	-- Ground
	self:_add(sf(p, 0, 0.78, 1, 0.22, Color3.fromRGB(30, 40, 90), 0.0, 2))

	-- Moon
	local moon = self:_add(pill(p, 0, 0, 0, 0, Color3.fromRGB(240, 245, 255), 0.0, 4))
	moon.Size     = UDim2.fromOffset(65, 65)
	moon.Position = UDim2.new(0.80, 0, 0.10, 0)

	-- Stars
	for _ = 1, 38 do
		local sx = rnd(0.01, 0.99); local sy = rnd(0.01, 0.60)
		local sz = rndI(3, 8)
		local st = self:_add(pill(p, sx, sy, 0, 0, Color3.fromRGB(200, 215, 255), 0.1, 4))
		st.Size = UDim2.fromOffset(sz, sz)
		local phase = rnd(0, math.pi*2)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not st.Parent then return end
			phase += dt * rnd(0.5, 1.4)
			st.BackgroundTransparency = 0.05 + math.abs(math.sin(phase)) * 0.75
		end))
	end

	-- Slow drifting clouds
	for _ = 1, 4 do
		local cy = rnd(0.18, 0.44)
		local cl = self:_add(pill(p, rnd(-0.3, 0.85), cy, 0, 0, Color3.fromRGB(90, 115, 195), 0.3, 5))
		cl.Size = UDim2.fromOffset(rndI(110, 200), rndI(36, 62))
		local spd = rnd(0.002, 0.006)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not cl.Parent then return end
			local nx = cl.Position.X.Scale + spd * dt
			if nx > 1.12 then nx = -0.30 end
			cl.Position = UDim2.new(nx, 0, cy, 0)
		end))
	end
end

return SceneLayer
