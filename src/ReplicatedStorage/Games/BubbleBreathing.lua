-- BubbleBreathing: guided breathing exercise for anxiety
-- Inhale → bubble grows. Hold → shimmer. Exhale → bubble floats away.
-- Cycle: 4s inhale, 4s hold, 6s exhale, 2s rest (4-4-6-2 box variant)

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local BubbleBreathing = {}
BubbleBreathing.__index = BubbleBreathing

local PHASES = {
	{ name = "Breathe In",  duration = 4,  instruction = "🫁  Breathe IN slowly…"  },
	{ name = "Hold",        duration = 4,  instruction = "✋  Hold your breath…"    },
	{ name = "Breathe Out", duration = 6,  instruction = "🌬️  Breathe OUT gently…" },
	{ name = "Rest",        duration = 2,  instruction = "🌿  Rest…"               },
}

local BUBBLE_COLORS_START = Color3.fromRGB(120, 210, 240)
local BUBBLE_COLORS_END   = Color3.fromRGB(160, 240, 200)

function BubbleBreathing.new()
	return setmetatable({ _connections = {}, _active = false }, BubbleBreathing)
end

function BubbleBreathing:Start(container, theme)
	self._active = true
	self:_buildUI(container, theme)
	self:_runCycle()
end

function BubbleBreathing:_buildUI(container, theme)
	-- Backdrop
	local bg = Instance.new("Frame")
	bg.Name               = "BBBackground"
	bg.Size               = UDim2.new(1, 0, 1, 0)
	bg.BackgroundTransparency = 1
	bg.ZIndex             = 5
	bg.Parent             = container
	self._bg = bg

	-- Central bubble
	local bubble = Instance.new("Frame")
	bubble.Name              = "BBBubble"
	bubble.Size              = UDim2.fromOffset(80, 80)
	bubble.AnchorPoint       = Vector2.new(0.5, 0.5)
	bubble.Position          = UDim2.new(0.5, 0, 0.5, -20)
	bubble.BackgroundColor3  = BUBBLE_COLORS_START
	bubble.BackgroundTransparency = 0.3
	bubble.BorderSizePixel   = 0
	bubble.ZIndex            = 10
	bubble.Parent            = bg

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(1, 0)
	bCorner.Parent = bubble

	-- Shimmer gradient
	local grad = Instance.new("UIGradient")
	grad.Color    = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
		ColorSequenceKeypoint.new(1, BUBBLE_COLORS_END),
	})
	grad.Rotation  = 45
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.0),
		NumberSequenceKeypoint.new(1, 0.5),
	})
	grad.Parent = bubble
	self._bubbleGrad = grad

	-- Instruction text
	local inst = Instance.new("TextLabel")
	inst.Name               = "BBInstruction"
	inst.Size               = UDim2.new(0.8, 0, 0, 50)
	inst.AnchorPoint        = Vector2.new(0.5, 0)
	inst.Position           = UDim2.new(0.5, 0, 0.5, 120)
	inst.BackgroundTransparency = 1
	inst.Text               = "Get ready…"
	inst.TextColor3         = theme.textColor
	inst.TextSize           = 24
	inst.Font               = Enum.Font.GothamSemibold
	inst.TextXAlignment     = Enum.TextXAlignment.Center
	inst.ZIndex             = 10
	inst.Parent             = bg

	-- Phase timer arc label
	local timerLbl = Instance.new("TextLabel")
	timerLbl.Name               = "BBTimer"
	timerLbl.Size               = UDim2.fromOffset(60, 60)
	timerLbl.AnchorPoint        = Vector2.new(0.5, 0.5)
	timerLbl.Position           = UDim2.new(0.5, 0, 0.5, -20)
	timerLbl.BackgroundTransparency = 1
	timerLbl.Text               = ""
	timerLbl.TextColor3         = Color3.new(1,1,1)
	timerLbl.TextSize            = 22
	timerLbl.Font                = Enum.Font.GothamBold
	timerLbl.ZIndex              = 15
	timerLbl.Parent              = bg

	-- Cycle counter
	local cycles = Instance.new("TextLabel")
	cycles.Name               = "BBCycles"
	cycles.Size               = UDim2.new(1, 0, 0, 30)
	cycles.AnchorPoint        = Vector2.new(0.5, 0)
	cycles.Position           = UDim2.new(0.5, 0, 0, 10)
	cycles.BackgroundTransparency = 1
	cycles.Text               = "Cycle 1 of 5"
	cycles.TextColor3         = theme.accentColor
	cycles.TextSize           = 18
	cycles.Font               = Enum.Font.Gotham
	cycles.TextXAlignment     = Enum.TextXAlignment.Center
	cycles.ZIndex             = 10
	cycles.Parent             = bg

	self._bubble    = bubble
	self._inst      = inst
	self._timerLbl  = timerLbl
	self._cyclesLbl = cycles
	self._cycle     = 1
	self._maxCycles = 5
end

function BubbleBreathing:_runCycle()
	if not self._active then return end
	if self._cycle > self._maxCycles then
		self:_showComplete()
		return
	end
	self._cyclesLbl.Text = "Cycle " .. self._cycle .. " of " .. self._maxCycles
	self:_runPhase(1)
end

function BubbleBreathing:_runPhase(phaseIdx)
	if not self._active then return end
	local phase = PHASES[phaseIdx]
	self._inst.Text = phase.instruction

	local startSize, endSize
	if phase.name == "Breathe In" then
		startSize = UDim2.fromOffset(80, 80)
		endSize   = UDim2.fromOffset(200, 200)
	elseif phase.name == "Hold" then
		startSize = UDim2.fromOffset(200, 200)
		endSize   = UDim2.fromOffset(200, 200)
	elseif phase.name == "Breathe Out" then
		startSize = UDim2.fromOffset(200, 200)
		endSize   = UDim2.fromOffset(80, 80)
	else -- Rest
		startSize = UDim2.fromOffset(80, 80)
		endSize   = UDim2.fromOffset(80, 80)
	end

	self._bubble.Size = startSize

	-- Size tween
	TweenService:Create(self._bubble,
		TweenInfo.new(phase.duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{ Size = endSize }
	):Play()

	-- Countdown
	local elapsed = 0
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not self._active then conn:Disconnect() return end
		elapsed += dt
		local remaining = math.ceil(phase.duration - elapsed)
		self._timerLbl.Text = tostring(math.max(remaining, 0))
		if elapsed >= phase.duration then
			conn:Disconnect()
			-- Next phase or next cycle
			if phaseIdx < #PHASES then
				self:_runPhase(phaseIdx + 1)
			else
				self._cycle += 1
				self:_runCycle()
			end
		end
	end)
	table.insert(self._connections, conn)
end

function BubbleBreathing:_showComplete()
	self._inst.Text     = "🌟  Amazing! You completed 5 breathing cycles!"
	self._timerLbl.Text = ""
	self._cyclesLbl.Text = "✅  Session complete"

	-- Pulse the bubble once
	TweenService:Create(self._bubble,
		TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(220, 220), BackgroundColor3 = BUBBLE_COLORS_END }
	):Play()
end

function BubbleBreathing:Stop()
	self._active = false
	for _, c in ipairs(self._connections) do
		c:Disconnect()
	end
	self._connections = {}
	if self._bg then self._bg:Destroy() end
end

return BubbleBreathing
