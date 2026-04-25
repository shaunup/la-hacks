-- MemoryGarden: for sadness – type a happy memory/thought, plant a flower
-- Each thought spawns a blooming flower animation in the garden

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local MemoryGarden = {}
MemoryGarden.__index = MemoryGarden

local FLOWER_EMOJIS = { "🌸","🌺","🌼","🌻","🌹","💐","🏵️","🌷" }
local PETAL_COLORS  = {
	Color3.fromRGB(255, 160, 200),
	Color3.fromRGB(255, 210, 120),
	Color3.fromRGB(200, 140, 255),
	Color3.fromRGB(140, 220, 160),
	Color3.fromRGB(255, 180, 100),
}

local PROMPTS = {
	"Type a happy memory and press Enter…",
	"What's something you're grateful for?",
	"Name someone who makes you smile…",
	"What's a little joy from today?",
	"Think of a place that feels safe…",
}

function MemoryGarden.new()
	return setmetatable({ _connections = {}, _active = false, _flowerCount = 0 }, MemoryGarden)
end

local GARDEN_GOAL = 5  -- flowers needed to unlock finish

function MemoryGarden:Start(container, theme, onComplete)
	self._active     = true
	self._container  = container
	self._theme      = theme
	self._onComplete = onComplete
	self:_buildUI()
end

function MemoryGarden:_buildUI()
	local theme = self._theme

	-- Garden canvas (lower half)
	local garden = Instance.new("Frame")
	garden.Name               = "MGGarden"
	garden.Size               = UDim2.new(1, 0, 0.55, 0)
	garden.Position           = UDim2.new(0, 0, 0.45, 0)
	garden.BackgroundTransparency = 1
	garden.ZIndex             = 5
	garden.Parent             = self._container
	self._garden = garden

	-- Prompt label
	local prompt = Instance.new("TextLabel")
	prompt.Name               = "MGPrompt"
	prompt.Size               = UDim2.new(0.9, 0, 0, 40)
	prompt.AnchorPoint        = Vector2.new(0.5, 0)
	prompt.Position           = UDim2.new(0.5, 0, 0.05, 0)
	prompt.BackgroundTransparency = 1
	prompt.Text               = PROMPTS[1]
	prompt.TextColor3         = theme.textColor
	prompt.TextSize           = 20
	prompt.Font               = Enum.Font.GothamSemibold
	prompt.TextXAlignment     = Enum.TextXAlignment.Center
	prompt.TextWrapped        = true
	prompt.ZIndex             = 10
	prompt.Parent             = self._container
	self._prompt = prompt

	-- Input box
	local inputBG = Instance.new("Frame")
	inputBG.Name               = "MGInputBG"
	inputBG.Size               = UDim2.new(0.75, 0, 0, 48)
	inputBG.AnchorPoint        = Vector2.new(0.5, 0)
	inputBG.Position           = UDim2.new(0.5, 0, 0.15, 0)
	inputBG.BackgroundColor3   = theme.cardColor
	inputBG.BackgroundTransparency = 0.2
	inputBG.BorderSizePixel    = 0
	inputBG.ZIndex             = 10
	inputBG.Parent             = self._container

	local ibCorner = Instance.new("UICorner")
	ibCorner.CornerRadius = UDim.new(0, 24)
	ibCorner.Parent = inputBG

	local input = Instance.new("TextBox")
	input.Name               = "MGInput"
	input.Size               = UDim2.new(1, -24, 1, 0)
	input.Position           = UDim2.new(0, 12, 0, 0)
	input.BackgroundTransparency = 1
	input.Text               = ""
	input.PlaceholderText    = "Write here and press Enter…"
	input.PlaceholderColor3  = theme.textColor
	input.TextColor3         = theme.textColor
	input.TextSize           = 18
	input.Font               = Enum.Font.Gotham
	input.ZIndex             = 11
	input.ClearTextOnFocus   = false
	input.Parent             = inputBG
	self._input = input

	-- Flower count label
	local countLbl = Instance.new("TextLabel")
	countLbl.Name               = "MGCount"
	countLbl.Size               = UDim2.new(1, 0, 0, 30)
	countLbl.AnchorPoint        = Vector2.new(0.5, 0)
	countLbl.Position           = UDim2.new(0.5, 0, 0.35, 0)
	countLbl.BackgroundTransparency = 1
	countLbl.Text               = "Your garden has 0 flowers 🌱"
	countLbl.TextColor3         = theme.accentColor
	countLbl.TextSize           = 17
	countLbl.Font               = Enum.Font.Gotham
	countLbl.TextXAlignment     = Enum.TextXAlignment.Center
	countLbl.ZIndex             = 10
	countLbl.Parent             = self._container
	self._countLbl = countLbl

	-- Connect input
	local conn = input.FocusLost:Connect(function(enterPressed)
		if enterPressed and self._active then
			local text = input.Text:match("^%s*(.-)%s*$")
			if text ~= "" then
				self:_plantFlower(text)
				input.Text = ""
				-- Cycle prompt
				local idx = math.random(1, #PROMPTS)
				prompt.Text = PROMPTS[idx]
			end
		end
	end)
	table.insert(self._connections, conn)
end

function MemoryGarden:_plantFlower(text)
	self._flowerCount += 1
	self._countLbl.Text = "Your garden has " .. self._flowerCount .. " flowers 🌸"

	-- Random position in the garden frame
	local gw = self._garden.AbsoluteSize.X
	local gh = self._garden.AbsoluteSize.Y
	local px = math.random(30, math.max(31, gw - 80))
	local py = math.random(20, math.max(21, gh - 100))

	-- Stem
	local stem = Instance.new("Frame")
	stem.Size               = UDim2.fromOffset(4, 0)
	stem.Position           = UDim2.new(0, px + 28, 0, py + 60)
	stem.BackgroundColor3   = Color3.fromRGB(80, 160, 80)
	stem.BorderSizePixel    = 0
	stem.ZIndex             = 8
	stem.Parent             = self._garden

	TweenService:Create(stem, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(4, 50) }
	):Play()

	-- Flower head (emoji label)
	local flower = Instance.new("TextLabel")
	flower.Size               = UDim2.fromOffset(60, 60)
	flower.Position           = UDim2.new(0, px, 0, py)
	flower.BackgroundTransparency = 1
	flower.Text               = FLOWER_EMOJIS[math.random(1, #FLOWER_EMOJIS)]
	flower.TextSize           = 36
	flower.Font               = Enum.Font.GothamBold
	flower.ZIndex             = 9
	flower.Size               = UDim2.fromOffset(0, 0)
	flower.Parent             = self._garden

	TweenService:Create(flower, TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(60, 60) }
	):Play()

	-- Memory tag bubble
	local tag = Instance.new("TextLabel")
	tag.Size               = UDim2.fromOffset(0, 0)
	tag.Position           = UDim2.new(0, px - 20, 0, py - 36)
	tag.BackgroundColor3   = PETAL_COLORS[math.random(1, #PETAL_COLORS)]
	tag.BackgroundTransparency = 0.15
	tag.BorderSizePixel    = 0
	tag.Text               = text:sub(1, 28)
	tag.TextSize           = 12
	tag.Font               = Enum.Font.Gotham
	tag.TextColor3         = Color3.fromRGB(60, 30, 60)
	tag.TextWrapped        = true
	tag.ZIndex             = 12
	tag.Parent             = self._garden

	local tagC = Instance.new("UICorner")
	tagC.CornerRadius = UDim.new(0, 8)
	tagC.Parent = tag

	local tagP = Instance.new("UIPadding")
	tagP.PaddingLeft   = UDim.new(0, 6)
	tagP.PaddingRight  = UDim.new(0, 6)
	tagP.PaddingTop    = UDim.new(0, 3)
	tagP.PaddingBottom = UDim.new(0, 3)
	tagP.Parent = tag

	TweenService:Create(tag, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(math.min(#text * 8 + 16, 140), 30) }
	):Play()

	-- Celebrate at goal and show finish button
	if self._flowerCount == GARDEN_GOAL then
		self._countLbl.Text = "🌟 Beautiful garden! Keep going or finish!"
		TweenService:Create(self._countLbl,
			TweenInfo.new(0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
			{ TextSize = 20 }
		):Play()
		-- Show finish button
		if not self._finishBtn then
			local fb = Instance.new("TextButton")
			fb.Size               = UDim2.new(0.5, 0, 0, 44)
			fb.AnchorPoint        = Vector2.new(0.5, 0)
			fb.Position           = UDim2.new(0.5, 0, 0, self._countLbl.Position.Y.Offset + 36)
			fb.BackgroundColor3   = self._theme.accentColor
			fb.BorderSizePixel    = 0
			fb.Text               = "🌸  I'm done — take me back"
			fb.TextColor3         = self._theme.textColor
			fb.TextSize           = 15
			fb.Font               = Enum.Font.GothamSemibold
			fb.AutoButtonColor    = false
			fb.ZIndex             = 15
			fb.Parent             = self._container
			local fbc = Instance.new("UICorner")
			fbc.CornerRadius = UDim.new(0, 22)
			fbc.Parent = fb
			self._finishBtn = fb
			fb.MouseButton1Click:Connect(function()
				if self._onComplete then self._onComplete() end
			end)
		end
	end
end

function MemoryGarden:Stop()
	self._active = false
	for _, c in ipairs(self._connections) do
		c:Disconnect()
	end
	self._connections = {}
end

return MemoryGarden
