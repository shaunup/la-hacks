-- LanternRelease: write a worry, watch it sealed into a glowing lantern
-- that slowly floats up and disappears — a ritual of letting go.
-- Suitable for: anxious, angry, stressed
-- Interface: .new() → :Start(container, theme, onComplete) → :Stop()

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local LanternRelease = {}
LanternRelease.__index = LanternRelease

local PROMPTS = {
	"What's one worry you'd like to let go of?",
	"What's been weighing on your mind today?",
	"What would you release if you could?",
	"What fear would you love to float away?",
	"What thought keeps coming back uninvited?",
}

local LANTERN_COLORS = {
	Color3.fromRGB(255, 180,  60),
	Color3.fromRGB(255, 140,  80),
	Color3.fromRGB(240, 100, 120),
	Color3.fromRGB(200, 120, 255),
	Color3.fromRGB(120, 200, 255),
}

local RELEASE_MESSAGES = {
	"Gone. 🏮",
	"Released. ✨",
	"Let it go. 🌬️",
	"Floating away… 🌙",
	"Lighter now. 🕊️",
}

local MAX_LANTERNS = 5

function LanternRelease.new()
	return setmetatable({
		_connections = {},
		_active      = false,
		_count       = 0,
	}, LanternRelease)
end

function LanternRelease:Start(container, theme, onComplete)
	self._active     = true
	self._container  = container
	self._theme      = theme
	self._onComplete = onComplete
	self._count      = 0
	self:_buildUI()
end

function LanternRelease:_buildUI()
	local theme = self._theme

	-- Header
	local hdr = Instance.new("TextLabel")
	hdr.Size               = UDim2.new(0.9, 0, 0, 44)
	hdr.AnchorPoint        = Vector2.new(0.5, 0)
	hdr.Position           = UDim2.new(0.5, 0, 0, 6)
	hdr.BackgroundTransparency = 1
	hdr.Text               = "🏮  Lantern Release"
	hdr.TextColor3         = theme.textColor
	hdr.TextSize           = 26
	hdr.Font               = Enum.Font.GothamBold
	hdr.TextXAlignment     = Enum.TextXAlignment.Center
	hdr.ZIndex             = 10
	hdr.Parent             = self._container

	-- Prompt
	local prompt = Instance.new("TextLabel")
	prompt.Name               = "LRPrompt"
	prompt.Size               = UDim2.new(0.85, 0, 0, 40)
	prompt.AnchorPoint        = Vector2.new(0.5, 0)
	prompt.Position           = UDim2.new(0.5, 0, 0, 58)
	prompt.BackgroundTransparency = 1
	prompt.Text               = PROMPTS[1]
	prompt.TextColor3         = theme.textColor
	prompt.TextSize           = 18
	prompt.Font               = Enum.Font.GothamSemibold
	prompt.TextWrapped        = true
	prompt.TextXAlignment     = Enum.TextXAlignment.Center
	prompt.ZIndex             = 10
	prompt.Parent             = self._container
	self._prompt = prompt

	-- Input area
	local inputBG = Instance.new("Frame")
	inputBG.Size               = UDim2.new(0.78, 0, 0, 50)
	inputBG.AnchorPoint        = Vector2.new(0.5, 0)
	inputBG.Position           = UDim2.new(0.5, 0, 0, 106)
	inputBG.BackgroundColor3   = theme.cardColor
	inputBG.BackgroundTransparency = 0.2
	inputBG.BorderSizePixel    = 0
	inputBG.ZIndex             = 10
	inputBG.Parent             = self._container

	local ibC = Instance.new("UICorner")
	ibC.CornerRadius = UDim.new(0, 25)
	ibC.Parent = inputBG

	local input = Instance.new("TextBox")
	input.Size               = UDim2.new(1, -20, 1, 0)
	input.Position           = UDim2.new(0, 10, 0, 0)
	input.BackgroundTransparency = 1
	input.Text               = ""
	input.PlaceholderText    = "Write it here…"
	input.PlaceholderColor3  = theme.textColor
	input.TextColor3         = theme.textColor
	input.TextSize           = 17
	input.Font               = Enum.Font.Gotham
	input.ZIndex             = 11
	input.ClearTextOnFocus   = false
	input.Parent             = inputBG
	self._input = input

	-- Release button
	local relBtn = Instance.new("TextButton")
	relBtn.Size               = UDim2.new(0.5, 0, 0, 48)
	relBtn.AnchorPoint        = Vector2.new(0.5, 0)
	relBtn.Position           = UDim2.new(0.5, 0, 0, 164)
	relBtn.BackgroundColor3   = Color3.fromRGB(255, 180, 60)
	relBtn.BorderSizePixel    = 0
	relBtn.Text               = "🏮  Light & Release"
	relBtn.TextColor3         = Color3.fromRGB(80, 40, 0)
	relBtn.TextSize           = 17
	relBtn.Font               = Enum.Font.GothamBold
	relBtn.AutoButtonColor    = false
	relBtn.ZIndex             = 10
	relBtn.Parent             = self._container

	local rbC = Instance.new("UICorner")
	rbC.CornerRadius = UDim.new(0, 24)
	rbC.Parent = relBtn

	-- Progress label
	local prog = Instance.new("TextLabel")
	prog.Name               = "LRProg"
	prog.Size               = UDim2.new(1, 0, 0, 28)
	prog.AnchorPoint        = Vector2.new(0.5, 0)
	prog.Position           = UDim2.new(0.5, 0, 0, 220)
	prog.BackgroundTransparency = 1
	prog.Text               = "Release " .. MAX_LANTERNS .. " worries to complete"
	prog.TextColor3         = theme.accentColor
	prog.TextSize           = 15
	prog.Font               = Enum.Font.Gotham
	prog.TextXAlignment     = Enum.TextXAlignment.Center
	prog.ZIndex             = 10
	prog.Parent             = self._container
	self._prog = prog

	-- Sky canvas for lanterns
	local sky = Instance.new("Frame")
	sky.Name               = "LRSky"
	sky.Size               = UDim2.new(1, 0, 1, -260)
	sky.Position           = UDim2.new(0, 0, 0, 260)
	sky.BackgroundTransparency = 1
	sky.ZIndex             = 8
	sky.Parent             = self._container
	self._sky = sky

	-- Hover glow
	relBtn.MouseEnter:Connect(function()
		TweenService:Create(relBtn,
			TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(255, 210, 100) }
		):Play()
	end)
	relBtn.MouseLeave:Connect(function()
		TweenService:Create(relBtn,
			TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(255, 180, 60) }
		):Play()
	end)

	local conn = relBtn.MouseButton1Click:Connect(function()
		if not self._active then return end
		local text = input.Text:match("^%s*(.-)%s*$")
		if text == "" then
			-- Wiggle button
			for i = 1, 4 do
				task.delay(i * 0.06, function()
					if relBtn.Parent then
						relBtn.Position = UDim2.new(0.5, (i%2==0 and 8 or -8), 0, 164)
					end
				end)
			end
			task.delay(0.28, function()
				if relBtn.Parent then relBtn.Position = UDim2.new(0.5, 0, 0, 164) end
			end)
			return
		end
		input.Text = ""
		self._prompt.Text = PROMPTS[math.random(1, #PROMPTS)]
		self:_launchLantern(text)
	end)
	table.insert(self._connections, conn)
end

function LanternRelease:_launchLantern(worryText)
	self._count += 1
	local idx  = self._count
	local col  = LANTERN_COLORS[((idx - 1) % #LANTERN_COLORS) + 1]

	-- Lantern body
	local lantern = Instance.new("Frame")
	lantern.Size               = UDim2.fromOffset(60, 80)
	lantern.AnchorPoint        = Vector2.new(0.5, 1)
	local startX = math.random(20, 80) / 100
	lantern.Position           = UDim2.new(startX, 0, 1, 0)
	lantern.BackgroundColor3   = col
	lantern.BackgroundTransparency = 0.2
	lantern.BorderSizePixel    = 0
	lantern.ZIndex             = 12
	lantern.Parent             = self._sky

	local lC = Instance.new("UICorner")
	lC.CornerRadius = UDim.new(0, 12)
	lC.Parent = lantern

	-- Glow frame
	local glow = Instance.new("Frame")
	glow.Size               = UDim2.fromOffset(80, 100)
	glow.AnchorPoint        = Vector2.new(0.5, 0.5)
	glow.Position           = UDim2.new(0.5, 0, 0.5, 0)
	glow.BackgroundColor3   = col
	glow.BackgroundTransparency = 0.7
	glow.BorderSizePixel    = 0
	glow.ZIndex             = 11
	glow.Parent             = lantern

	local glowC = Instance.new("UICorner")
	glowC.CornerRadius = UDim.new(0, 18)
	glowC.Parent = glow

	-- Worry text sealed inside
	local txt = Instance.new("TextLabel")
	txt.Size               = UDim2.new(1, -6, 1, -8)
	txt.Position           = UDim2.new(0, 3, 0, 4)
	txt.BackgroundTransparency = 1
	txt.Text               = worryText:sub(1, 30)
	txt.TextColor3         = Color3.new(1,1,1)
	txt.TextSize           = 11
	txt.Font               = Enum.Font.Gotham
	txt.TextWrapped        = true
	txt.TextXAlignment     = Enum.TextXAlignment.Center
	txt.ZIndex             = 13
	txt.Parent             = lantern

	-- Flame emoji on top
	local flame = Instance.new("TextLabel")
	flame.Size               = UDim2.fromOffset(40, 40)
	flame.AnchorPoint        = Vector2.new(0.5, 1)
	flame.Position           = UDim2.new(0.5, 0, 0, 2)
	flame.BackgroundTransparency = 1
	flame.Text               = "🔥"
	flame.TextSize           = 24
	flame.Font               = Enum.Font.GothamBold
	flame.ZIndex             = 14
	flame.Parent             = lantern

	-- Float upward
	local skyH = self._sky.AbsoluteSize.Y
	local floatTime = math.random(40, 70) / 10  -- 4–7 s
	local driftX  = (math.random() - 0.5) * 0.15

	-- Glow pulse
	local phase = 0
	local pulseConn
	pulseConn = RunService.Heartbeat:Connect(function(dt)
		if not lantern.Parent then pulseConn:Disconnect() return end
		phase += dt * 1.8
		glow.BackgroundTransparency = 0.6 + math.sin(phase) * 0.2
		flame.Rotation = math.sin(phase * 2) * 8
	end)
	table.insert(self._connections, pulseConn)

	-- Float tween
	local targetX = math.clamp(startX + driftX, 0.05, 0.95)
	TweenService:Create(lantern, TweenInfo.new(floatTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position               = UDim2.new(targetX, 0, -0.2, 0),
		BackgroundTransparency = 1,
	}):Play()
	TweenService:Create(txt, TweenInfo.new(floatTime * 0.7), { TextTransparency = 1 }):Play()
	TweenService:Create(glow, TweenInfo.new(floatTime * 0.9), { BackgroundTransparency = 1 }):Play()

	game:GetService("Debris"):AddItem(lantern, floatTime + 0.2)

	-- Release message popup
	local msgPop = Instance.new("TextLabel")
	msgPop.Size               = UDim2.fromOffset(200, 40)
	msgPop.AnchorPoint        = Vector2.new(0.5, 1)
	msgPop.Position           = UDim2.new(startX, 0, 0.98, 0)
	msgPop.BackgroundTransparency = 1
	msgPop.Text               = RELEASE_MESSAGES[((idx - 1) % #RELEASE_MESSAGES) + 1]
	msgPop.TextColor3         = col
	msgPop.TextSize           = 18
	msgPop.Font               = Enum.Font.GothamBold
	msgPop.ZIndex             = 20
	msgPop.Parent             = self._sky

	TweenService:Create(msgPop, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position      = UDim2.new(startX, 0, 0.6, 0),
		TextTransparency = 1,
	}):Play()
	game:GetService("Debris"):AddItem(msgPop, 1.6)

	-- Update progress
	if self._prog and self._prog.Parent then
		local remaining = MAX_LANTERNS - self._count
		if remaining > 0 then
			self._prog.Text = remaining .. " more to release…"
		else
			self._prog.Text = "✨  All worries released!"
		end
	end

	-- Complete
	if self._count >= MAX_LANTERNS then
		task.delay(floatTime * 0.4, function()
			if self._active then
				self._active = false
				if self._onComplete then
					self._onComplete()
				end
			end
		end)
	end
end

function LanternRelease:Stop()
	self._active = false
	for _, c in ipairs(self._connections) do c:Disconnect() end
	self._connections = {}
end

return LanternRelease
