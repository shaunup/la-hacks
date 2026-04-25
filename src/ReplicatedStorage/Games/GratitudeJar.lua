-- GratitudeJar: for stressed players – write something you're grateful for,
-- drop it in the jar. The jar glows brighter with each entry.

local TweenService = game:GetService("TweenService")

local GratitudeJar = {}
GratitudeJar.__index = GratitudeJar

local GLOW_COLORS = {
	Color3.fromRGB(220, 255, 200),
	Color3.fromRGB(200, 240, 255),
	Color3.fromRGB(255, 230, 200),
	Color3.fromRGB(240, 210, 255),
	Color3.fromRGB(255, 255, 180),
}

local AFFIRMATIONS = {
	"You are doing great. ✨",
	"Every small thing matters. 🌱",
	"You are enough. 💛",
	"Breathing is an act of strength. 🌬️",
	"Today is a step forward. 🚶",
	"You've got through hard days before. 🌅",
	"It's okay to take a break. 🍃",
	"You are not alone. 🤝",
}

local PROMPTS = {
	"What's one small thing you're grateful for?",
	"Who made you smile recently?",
	"Name something that went okay today.",
	"What's a comfort that exists in your life?",
	"Think of a tiny pleasure — a warm drink, a song…",
}

function GratitudeJar.new()
	return setmetatable({ _connections = {}, _active = false, _count = 0 }, GratitudeJar)
end

local JAR_GOAL = 5

function GratitudeJar:Start(container, theme, onComplete)
	self._active     = true
	self._container  = container
	self._theme      = theme
	self._onComplete = onComplete
	self._count      = 0
	self:_buildUI()
end

function GratitudeJar:_buildUI()
	local theme = self._theme

	-- Header
	local hdr = Instance.new("TextLabel")
	hdr.Size               = UDim2.new(0.9, 0, 0, 40)
	hdr.AnchorPoint        = Vector2.new(0.5, 0)
	hdr.Position           = UDim2.new(0.5, 0, 0, 8)
	hdr.BackgroundTransparency = 1
	hdr.Text               = "🫙  Your Gratitude Jar"
	hdr.TextColor3         = theme.textColor
	hdr.TextSize           = 24
	hdr.Font               = Enum.Font.GothamBold
	hdr.TextXAlignment     = Enum.TextXAlignment.Center
	hdr.ZIndex             = 10
	hdr.Parent             = self._container

	-- Prompt
	local prompt = Instance.new("TextLabel")
	prompt.Name               = "GJPrompt"
	prompt.Size               = UDim2.new(0.85, 0, 0, 36)
	prompt.AnchorPoint        = Vector2.new(0.5, 0)
	prompt.Position           = UDim2.new(0.5, 0, 0, 55)
	prompt.BackgroundTransparency = 1
	prompt.Text               = PROMPTS[1]
	prompt.TextColor3         = theme.textColor
	prompt.TextSize           = 17
	prompt.Font               = Enum.Font.Gotham
	prompt.TextWrapped        = true
	prompt.TextXAlignment     = Enum.TextXAlignment.Center
	prompt.ZIndex             = 10
	prompt.Parent             = self._container
	self._prompt = prompt

	-- Input
	local ibg = Instance.new("Frame")
	ibg.Size               = UDim2.new(0.75, 0, 0, 46)
	ibg.AnchorPoint        = Vector2.new(0.5, 0)
	ibg.Position           = UDim2.new(0.5, 0, 0, 98)
	ibg.BackgroundColor3   = theme.cardColor
	ibg.BackgroundTransparency = 0.2
	ibg.BorderSizePixel    = 0
	ibg.ZIndex             = 10
	ibg.Parent             = self._container

	local ibgC = Instance.new("UICorner")
	ibgC.CornerRadius = UDim.new(0, 24)
	ibgC.Parent = ibg

	local input = Instance.new("TextBox")
	input.Size               = UDim2.new(1, -20, 1, 0)
	input.Position           = UDim2.new(0, 10, 0, 0)
	input.BackgroundTransparency = 1
	input.Text               = ""
	input.PlaceholderText    = "Type here and press Enter…"
	input.PlaceholderColor3  = theme.textColor
	input.TextColor3         = theme.textColor
	input.TextSize           = 17
	input.Font               = Enum.Font.Gotham
	input.ZIndex             = 11
	input.ClearTextOnFocus   = false
	input.Parent             = ibg
	self._input = input

	-- Jar visual (big emoji with glow frame)
	local jarFrame = Instance.new("Frame")
	jarFrame.Name              = "GJJar"
	jarFrame.Size              = UDim2.fromOffset(120, 120)
	jarFrame.AnchorPoint       = Vector2.new(0.5, 0)
	jarFrame.Position          = UDim2.new(0.5, 0, 0, 160)
	jarFrame.BackgroundColor3  = Color3.fromRGB(240, 240, 200)
	jarFrame.BackgroundTransparency = 0.3
	jarFrame.BorderSizePixel   = 0
	jarFrame.ZIndex            = 10
	jarFrame.Parent            = self._container

	local jfc = Instance.new("UICorner")
	jfc.CornerRadius = UDim.new(0, 20)
	jfc.Parent = jarFrame

	local jarLabel = Instance.new("TextLabel")
	jarLabel.Size              = UDim2.new(1, 0, 1, 0)
	jarLabel.BackgroundTransparency = 1
	jarLabel.Text              = "🫙"
	jarLabel.TextSize          = 64
	jarLabel.Font              = Enum.Font.GothamBold
	jarLabel.ZIndex            = 11
	jarLabel.Parent            = jarFrame

	self._jarFrame = jarFrame

	-- Count label
	local countLbl = Instance.new("TextLabel")
	countLbl.Name              = "GJCount"
	countLbl.Size              = UDim2.new(1, 0, 0, 28)
	countLbl.AnchorPoint       = Vector2.new(0.5, 0)
	countLbl.Position          = UDim2.new(0.5, 0, 0, 288)
	countLbl.BackgroundTransparency = 1
	countLbl.Text              = "0 gratitudes  •  keep going!"
	countLbl.TextColor3        = theme.accentColor
	countLbl.TextSize          = 16
	countLbl.Font              = Enum.Font.Gotham
	countLbl.TextXAlignment    = Enum.TextXAlignment.Center
	countLbl.ZIndex            = 10
	countLbl.Parent            = self._container
	self._countLbl = countLbl

	-- Affirmation popup label (hidden by default)
	local aff = Instance.new("TextLabel")
	aff.Name               = "GJAffirmation"
	aff.Size               = UDim2.new(0.7, 0, 0, 50)
	aff.AnchorPoint        = Vector2.new(0.5, 0)
	aff.Position           = UDim2.new(0.5, 0, 0, 325)
	aff.BackgroundTransparency = 1
	aff.Text               = ""
	aff.TextColor3         = theme.textColor
	aff.TextSize           = 16
	aff.Font               = Enum.Font.GothamSemibold
	aff.TextWrapped        = true
	aff.TextXAlignment     = Enum.TextXAlignment.Center
	aff.ZIndex             = 10
	aff.Parent             = self._container
	self._affLbl = aff

	-- Connect
	local conn = input.FocusLost:Connect(function(entered)
		if entered and self._active then
			local text = input.Text:match("^%s*(.-)%s*$")
			if text ~= "" then
				self:_addGratitude(text)
				input.Text = ""
				self._prompt.Text = PROMPTS[math.random(1, #PROMPTS)]
			end
		end
	end)
	table.insert(self._connections, conn)
end

function GratitudeJar:_addGratitude(text)
	self._count += 1
	self._countLbl.Text = self._count .. " gratitude" ..
		(self._count == 1 and "" or "s") .. "  •  beautiful 🌟"

	-- Unlock finish after goal
	if self._count == JAR_GOAL and not self._finishBtn then
		local fb = Instance.new("TextButton")
		fb.Size               = UDim2.new(0.55, 0, 0, 42)
		fb.AnchorPoint        = Vector2.new(0.5, 0)
		fb.Position           = UDim2.new(0.5, 0, 0, 370)
		fb.BackgroundColor3   = self._theme.accentColor
		fb.BorderSizePixel    = 0
		fb.Text               = "🫙  Jar complete — see your reward"
		fb.TextColor3         = self._theme.textColor
		fb.TextSize           = 14
		fb.Font               = Enum.Font.GothamSemibold
		fb.AutoButtonColor    = false
		fb.ZIndex             = 15
		fb.Parent             = self._container
		local fbc = Instance.new("UICorner")
		fbc.CornerRadius = UDim.new(0, 21)
		fbc.Parent = fb
		self._finishBtn = fb
		fb.MouseButton1Click:Connect(function()
			if self._onComplete then self._onComplete() end
		end)
	end

	-- Pulse jar
	local glow = GLOW_COLORS[((self._count - 1) % #GLOW_COLORS) + 1]
	TweenService:Create(self._jarFrame,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundColor3 = glow, BackgroundTransparency = 0 }
	):Play()
	task.delay(0.4, function()
		if self._jarFrame.Parent then
			TweenService:Create(self._jarFrame,
				TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{ BackgroundTransparency = 0.3 }
			):Play()
		end
	end)

	-- Show affirmation
	local aff = AFFIRMATIONS[math.random(1, #AFFIRMATIONS)]
	self._affLbl.Text               = aff
	self._affLbl.BackgroundTransparency = 1
	TweenService:Create(self._affLbl,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TextTransparency = 0 }
	):Play()
	task.delay(2.5, function()
		if self._affLbl.Parent then
			TweenService:Create(self._affLbl,
				TweenInfo.new(0.5), { TextTransparency = 1 }
			):Play()
		end
	end)
end

function GratitudeJar:Stop()
	self._active = false
	for _, c in ipairs(self._connections) do c:Disconnect() end
	self._connections = {}
end

return GratitudeJar
