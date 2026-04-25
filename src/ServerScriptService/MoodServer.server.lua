-- MoodServer v3: robust Gemini integration + 4 personalised content calls
-- Fix: temperature=0 for classification, word-scan extraction, prompt embedded
-- in user turn (more compatible than system_instruction across Gemini versions)

local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")

-- ─── Remotes ────────────────────────────────────────────────────────────────

local function makeRemote(name)
	local r = Instance.new("RemoteFunction")
	r.Name   = name
	r.Parent = ReplicatedStorage
	return r
end

local AnalyzeMood            = makeRemote("AnalyzeMood")
local GetPersonalizedContent = makeRemote("GetPersonalizedContent")
local GetPostGameMessage     = makeRemote("GetPostGameMessage")
local GetDailyChallenge      = makeRemote("GetDailyChallenge")

-- ─── Gemini call helper ──────────────────────────────────────────────────────

local GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key="

local function getApiKey()
	local keyObj = ServerStorage:FindFirstChild("GEMINI_API_KEY")
	if keyObj and keyObj.Value ~= "" then return keyObj.Value end
	return "YOUR_GEMINI_API_KEY_HERE"
end

-- callGemini: embeds instruction inside the user turn for max compatibility
local function callGemini(instruction, userInput, temperature, maxTokens)
	local apiKey = getApiKey()
	if apiKey == "YOUR_GEMINI_API_KEY_HERE" then return nil end

	-- Combine instruction + user input into a single user message
	-- This is more reliable than system_instruction across Gemini versions
	local combinedMsg = instruction .. "\n\n" .. userInput

	local payload = HttpService:JSONEncode({
		contents = {
			{ role = "user", parts = { { text = combinedMsg } } }
		},
		generationConfig = {
			temperature     = temperature or 0,
			maxOutputTokens = maxTokens or 60,
		},
	})

	local ok, result = pcall(function()
		return HttpService:RequestAsync({
			Url     = GEMINI_URL .. apiKey,
			Method  = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body    = payload,
		})
	end)

	if not ok then
		warn("[MoodServer] HTTP error:", tostring(result))
		return nil
	end

	if result.StatusCode ~= 200 then
		warn("[MoodServer] Gemini HTTP", result.StatusCode, "–", tostring(result.Body):sub(1, 200))
		return nil
	end

	local ok2, decoded = pcall(HttpService.JSONDecode, HttpService, result.Body)
	if not ok2 then warn("[MoodServer] JSON parse error") return nil end

	local candidate = decoded
		and decoded.candidates
		and decoded.candidates[1]
	if not candidate then
		warn("[MoodServer] No candidates in response")
		return nil
	end

	-- Handle safety blocks
	if candidate.finishReason == "SAFETY" or candidate.finishReason == "RECITATION" then
		warn("[MoodServer] Response blocked:", candidate.finishReason)
		return nil
	end

	local text = candidate.content
		and candidate.content.parts
		and candidate.content.parts[1]
		and candidate.content.parts[1].text

	return text and text:match("^%s*(.-)%s*$") or nil
end

-- ─── Valid moods ─────────────────────────────────────────────────────────────

local VALID_MOODS = {
	happy=true, calm=true, excited=true, anxious=true,
	lonely=true, sad=true, angry=true, stressed=true, neutral=true
}

-- ─── Mood extraction: scan response for first valid mood word ─────────────────

local function extractMood(text)
	if not text then return nil end
	local lower = text:lower()
	-- Exact match after trim
	local trimmed = lower:match("^%s*(.-)%s*$")
	if VALID_MOODS[trimmed] then return trimmed end
	-- Word-by-word scan (handles "You seem: happy" etc.)
	for word in lower:gmatch("[a-z]+") do
		if VALID_MOODS[word] then return word end
	end
	return nil
end

-- ─── Mood classification ─────────────────────────────────────────────────────

local MOOD_INSTRUCTION = [[
TASK: Classify the player's emotional message into exactly one mood word.

VALID MOODS (choose ONLY one):
  happy, calm, excited, anxious, sad, lonely, angry, stressed, neutral

RULES:
- joy / gratitude / contentment    → happy
- peace / relaxation / serenity    → calm
- high energy / enthusiasm / hype  → excited
- worry / nervousness / fear       → anxious
- sadness / crying / grief         → sad
- loneliness / isolation / "alone" / "no one" → lonely
- frustration / anger / irritation → angry
- pressure / overwhelm / burnout   → stressed
- unclear / vague / "fine" / "okay" → neutral

OUTPUT: Respond with EXACTLY ONE word — the mood. No explanation, no punctuation, no other text.
EXAMPLES:
  "I'm feeling pretty happy today!" → happy
  "I'm so tired and can't cope"     → stressed
  "I feel all alone"                → lonely
  "ugh I'm so mad"                  → angry
  "whatever, just here"             → neutral
]]

-- Heuristic fallback (when Gemini unreachable / no key)
local KEYWORD_RULES = {
	happy    = {"happy","joy","great","wonderful","amazing","fantastic","love","glad","yay","cheerful","blessed","excited about","thrilled"},
	calm     = {"calm","peace","relax","serene","chill","tranquil","quiet","still","content","at ease","zen"},
	excited  = {"excited","hype","pumped","energetic","thrilled","stoked","woohoo","can't wait","amped","psyched"},
	anxious  = {"anxious","nervous","worried","scared","afraid","fear","panic","dread","uneasy","on edge","freaking"},
	lonely   = {"lonely","alone","isolated","no one","miss everyone","nobody","by myself","no friends","empty inside","left out"},
	sad      = {"sad","unhappy","depressed","crying","hurt","down","blue","grief","heartbroken","miserable","devastated"},
	angry    = {"angry","mad","furious","annoyed","frustrated","rage","hate","upset","irritated","fuming","livid"},
	stressed = {"stressed","tired","exhausted","burnt out","pressure","too much","overwhelmed","busy","can't cope","drowning in"},
}

local function heuristicMood(text)
	local lower = text:lower()
	-- Check each mood's keywords; longer keywords take priority
	local best, bestLen = "neutral", 0
	for mood, keywords in pairs(KEYWORD_RULES) do
		for _, kw in ipairs(keywords) do
			if lower:find(kw, 1, true) and #kw > bestLen then
				best    = mood
				bestLen = #kw
			end
		end
	end
	return best
end

AnalyzeMood.OnServerInvoke = function(player, userText)
	if type(userText) ~= "string" then return "neutral" end
	userText = userText:sub(1, 500)

	local raw  = callGemini(MOOD_INSTRUCTION, 'Player message: "' .. userText .. '"', 0, 20)
	local mood = extractMood(raw)

	if not mood then
		mood = heuristicMood(userText)
		if raw then
			print(string.format("[MoodServer] Gemini returned '%s' – used heuristic: %s", raw:sub(1,50), mood))
		else
			print(string.format("[MoodServer] Gemini unavailable – heuristic: %s", mood))
		end
	else
		print(string.format("[MoodServer] %s → %s (Gemini)", player.Name, mood))
	end

	return mood
end

-- ─── Personalised content ────────────────────────────────────────────────────

local CONTENT_INSTRUCTION = [[
You are a warm, empathetic wellness coach for a Roblox game.
Write THREE short personalised strings, separated by the pipe | character.

FORMAT (exactly): <tagline> | <game_tip> | <affirmation>

tagline      (max 12 words): Warm acknowledgement using the player's name if provided.
game_tip     (max 16 words): Encouraging hint for the activity they are about to do.
affirmation  (max 10 words): Short uplifting affirmation for this moment.

Rules:
- Do NOT use quotes, numbers, or labels.
- Just the three strings separated by |, on one line.
- Tone: gentle, supportive, age-appropriate.
- Use the player's name naturally if provided.
]]

local FALLBACK_CONTENT = {
	happy    = { "You're absolutely glowing right now, keep shining!",     "Tap the orbs and let that joy out!",           "You are a beam of pure light." },
	calm     = { "Your stillness is your greatest superpower.",            "Float gently — no rush, just pure peace.",      "You are exactly where you need to be." },
	excited  = { "That electric energy is yours to unleash!",             "Smash every star — let the excitement out!",    "Your enthusiasm lights up every room." },
	anxious  = { "You are braver than you feel right now.",               "Each lantern carries your worry far away.",     "You are safe. You are okay. Breathe." },
	sad      = { "Every feeling is valid — you are not alone.",           "Plant a flower for each good memory you hold.", "You are loved more than you know." },
	lonely   = { "Someone out there is waiting to connect with you.",     "Draw stars together — bridges start here.",    "You matter to more people than you think." },
	angry    = { "That fire inside you holds tremendous power.",          "Smash every star and release that tension!",   "You have the strength to transform this." },
	stressed = { "You don't have to carry everything all at once.",       "Each gratitude makes your jar glow brighter.",  "You are doing better than you think." },
	neutral  = { "No pressure — just good vibes and fun ahead!",         "Tap the orbs and see what happens!",           "Every moment is a fresh start." },
}

GetPersonalizedContent.OnServerInvoke = function(player, userText, mood, playerName)
	if type(userText) ~= "string" then userText = "" end
	if not VALID_MOODS[mood] then mood = "neutral" end
	playerName = type(playerName) == "string" and playerName:sub(1, 30) or player.Name

	local input = string.format(
		'Player name: %s\nPlayer message: "%s"\nDetected mood: %s\n\nWrite the three strings:',
		playerName, userText:sub(1, 300), mood
	)

	local raw = callGemini(CONTENT_INSTRUCTION, input, 0.7, 100)
	if raw then
		local parts = {}
		for p in (raw .. "|"):gmatch("([^|]+)|") do
			local trimmed = p:match("^%s*(.-)%s*$")
			if trimmed ~= "" then table.insert(parts, trimmed) end
		end
		if #parts >= 3 then
			return { tagline = parts[1], tip = parts[2], affirmation = parts[3] }
		end
	end

	local fb = FALLBACK_CONTENT[mood] or FALLBACK_CONTENT["neutral"]
	local t1 = fb[1]
	if playerName ~= "" and playerName ~= player.Name then
		t1 = "Hey " .. playerName .. " — " .. t1:gsub("^%u", string.lower)
	end
	return { tagline = t1, tip = fb[2], affirmation = fb[3] }
end

-- ─── Post-game message ───────────────────────────────────────────────────────

local POSTGAME_INSTRUCTION = [[
You are a warm wellness coach for a Roblox game.
The player just completed a mini-game. Write ONE celebratory sentence (max 20 words) that:
1. Acknowledges the mood they were feeling
2. Mentions the game they played (but in a natural, not robotic way)
3. Affirms something positive about them completing it

Use the player's name if provided. Warm, personal, age-appropriate.
Output ONLY the sentence. No quotes.
]]

local POSTGAME_FALLBACK = {
	MindfulTap     = "🌟 You tapped into pure mindfulness — your awareness is beautiful.",
	LanternRelease = "🏮 Those worries are floating away — you let them go beautifully.",
	MemoryGarden   = "🌸 Your garden is blooming — just like you are, every single day.",
	StarSmash       = "⭐ You smashed through every star — that energy is yours to keep!",
	GratitudeJar   = "🫙 Your jar is glowing — and so is your heart.",
	CloudFloat     = "☁️ You floated through and found your peace. That's a real skill.",
	StarBridge     = "🌌 You built something beautiful together — connection is everything.",
}

GetPostGameMessage.OnServerInvoke = function(player, mood, gameName, playerName)
	playerName = type(playerName) == "string" and playerName:sub(1, 30) or player.Name

	local input = string.format(
		"Player name: %s\nMood: %s\nGame completed: %s\nWrite the sentence:",
		playerName, tostring(mood), tostring(gameName)
	)

	local msg = callGemini(POSTGAME_INSTRUCTION, input, 0.8, 50)
	if msg and #msg > 8 then return msg end

	return POSTGAME_FALLBACK[gameName] or "🌟 Amazing — you should be so proud of yourself!"
end

-- ─── Daily challenge ──────────────────────────────────────────────────────────

local CHALLENGE_INSTRUCTION = [[
You are a wellness coach for a Roblox game.
Write ONE short daily wellness micro-challenge (max 20 words) tailored to the player's current mood.
It should be gentle, actionable today, and emotionally relevant.
Use the player's name if provided for a personal touch.
Output ONLY the challenge sentence. No quotes, no numbering.
]]

local CHALLENGE_FALLBACK = {
	happy    = "Share something that made you smile today with someone you care about.",
	calm     = "Spend 2 minutes watching the sky and notice 3 small beautiful things.",
	excited  = "Channel this energy into one creative thing you've been putting off.",
	anxious  = "Take 3 slow breaths and name 5 things you can see right now.",
	sad      = "Write down one small thing that went okay today — no matter how tiny.",
	lonely   = "Send a message to someone you haven't spoken to in a while.",
	angry    = "Step outside for 5 minutes and breathe before responding to anything.",
	stressed = "Write down 3 things you have already accomplished today, big or small.",
	neutral  = "Try one tiny new thing today — even a different route or snack.",
}

GetDailyChallenge.OnServerInvoke = function(player, mood, playerName)
	if not VALID_MOODS[mood] then mood = "neutral" end
	playerName = type(playerName) == "string" and playerName:sub(1, 30) or player.Name

	local input = string.format(
		"Player name: %s\nCurrent mood: %s\nWrite the daily challenge:",
		playerName, mood
	)

	local challenge = callGemini(CHALLENGE_INSTRUCTION, input, 0.8, 50)
	if challenge and #challenge > 8 then return challenge end

	return CHALLENGE_FALLBACK[mood] or CHALLENGE_FALLBACK["neutral"]
end

print("[MoodServer] v3 ready — 4 RemoteFunctions. Gemini key: " ..
	(getApiKey() ~= "YOUR_GEMINI_API_KEY_HERE" and "SET ✓" or "NOT SET (heuristic fallback)"))
