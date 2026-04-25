-- MoodServer: Gemini-powered mood analysis + personalised content generation
-- Four RemoteFunctions:
--   AnalyzeMood(text)           → moodString
--   GetPersonalizedContent(text, mood) → { tagline, tip, affirmation }
--   GetPostGameMessage(mood, gameName) → messageString
--   GetDailyChallenge(mood)     → challengeString

local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")

-- ─── RemoteFunctions ────────────────────────────────────────────────────────

local function makeRemote(name)
	local r = Instance.new("RemoteFunction")
	r.Name   = name
	r.Parent = ReplicatedStorage
	return r
end

local AnalyzeMood           = makeRemote("AnalyzeMood")
local GetPersonalizedContent = makeRemote("GetPersonalizedContent")
local GetPostGameMessage    = makeRemote("GetPostGameMessage")
local GetDailyChallenge     = makeRemote("GetDailyChallenge")

-- ─── Gemini helpers ──────────────────────────────────────────────────────────

local GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key="

local function getApiKey()
	local keyObj = ServerStorage:FindFirstChild("GEMINI_API_KEY")
	if keyObj and keyObj.Value ~= "" then return keyObj.Value end
	return "YOUR_GEMINI_API_KEY_HERE"
end

local function callGemini(systemPrompt, userText, maxTokens)
	local apiKey = getApiKey()
	if apiKey == "YOUR_GEMINI_API_KEY_HERE" then return nil end

	local payload = HttpService:JSONEncode({
		system_instruction = { parts = { { text = systemPrompt } } },
		contents           = { { role = "user", parts = { { text = userText } } } },
		generationConfig   = {
			temperature    = 0.7,
			maxOutputTokens = maxTokens or 120,
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

	if not ok then warn("[MoodServer] HTTP error:", result) return nil end
	if result.StatusCode ~= 200 then
		warn("[MoodServer] Gemini status", result.StatusCode)
		return nil
	end

	local decoded = HttpService:JSONDecode(result.Body)
	local text = decoded
		and decoded.candidates
		and decoded.candidates[1]
		and decoded.candidates[1].content
		and decoded.candidates[1].content.parts
		and decoded.candidates[1].content.parts[1]
		and decoded.candidates[1].content.parts[1].text

	return text and text:match("^%s*(.-)%s*$") or nil
end

-- ─── Mood Classification ─────────────────────────────────────────────────────

local MOOD_PROMPT = [[
You are a wellness assistant for a Roblox game.
Given a player's one-line message, classify their mood into EXACTLY ONE category (lowercase):
  happy, calm, excited, anxious, sad, lonely, angry, stressed, neutral

Rules (reply with ONLY the single mood word, nothing else):
- joy / contentment / gratitude → happy
- peace / relaxation / serenity → calm
- energy / enthusiasm / hype    → excited
- worry / nervousness / fear    → anxious
- sadness / grief / crying      → sad
- loneliness / isolation / missing people / no one to talk to → lonely
- frustration / anger / rage    → angry
- pressure / overwhelm / burnout → stressed
- Otherwise → neutral
]]

local KEYWORD_RULES = {
	happy    = {"happy","joy","great","wonderful","amazing","fantastic","love","glad","yay","cheerful","delighted"},
	calm     = {"calm","peace","relax","serene","chill","tranquil","quiet","still","okay","fine","content"},
	excited  = {"excited","hype","pumped","energetic","thrilled","stoked","woohoo","let's go","amped"},
	anxious  = {"anxious","nervous","worried","scared","afraid","fear","panic","overwhelm","dread","uneasy"},
	lonely   = {"lonely","alone","isolated","no one","miss everyone","nobody","by myself","no friends","empty"},
	sad      = {"sad","unhappy","depressed","crying","hurt","down","blue","grief","lost","heartbroken"},
	angry    = {"angry","mad","furious","annoyed","frustrated","rage","hate","upset","irritated","fuming"},
	stressed = {"stressed","tired","exhausted","burnt out","pressure","too much","overwhelmed","busy","cant cope"},
}

local VALID_MOODS = {
	happy=true, calm=true, excited=true, anxious=true,
	lonely=true, sad=true, angry=true, stressed=true, neutral=true
}

local function heuristicMood(text)
	local lower = text:lower()
	for mood, keywords in pairs(KEYWORD_RULES) do
		for _, kw in ipairs(keywords) do
			if lower:find(kw, 1, true) then return mood end
		end
	end
	return "neutral"
end

AnalyzeMood.OnServerInvoke = function(player, userText)
	if type(userText) ~= "string" then return "neutral" end
	userText = userText:sub(1, 500)

	local mood = callGemini(MOOD_PROMPT, userText, 8)
	if mood then mood = mood:lower():match("^%s*(.-)%s*$") end
	if not mood or not VALID_MOODS[mood] then mood = heuristicMood(userText) end

	print(string.format("[MoodServer] %s → %s", player.Name, mood))
	return mood
end

-- ─── Personalised Content ─────────────────────────────────────────────────────
-- Returns { tagline, tip, affirmation } table with Gemini-crafted text

local CONTENT_PROMPT = [[
You are a warm, empathetic wellness coach writing personalised messages for a Roblox wellness game.

Given the player's message and their detected mood, write THREE short strings separated by the pipe | character.
Format EXACTLY:  <tagline> | <game_tip> | <affirmation>

tagline (max 12 words):  A warm, personal acknowledgement of how they feel.
game_tip (max 16 words): A helpful hint or encouragement relevant to the activity they're about to do.
affirmation (max 10 words): A short uplifting affirmation for them right now.

Do NOT use quotes. Do NOT number them. Just the three strings separated by |.
Tone: gentle, supportive, age-appropriate (Roblox players).
]]

local FALLBACK_CONTENT = {
	happy    = { "You're glowing today — keep shining!",        "Click fast and fill the sky with colour!",              "You are joy made real." },
	calm     = { "Your stillness is your superpower.",          "Float gently — no rush, just peace.",                   "You are exactly where you need to be." },
	excited  = { "All that energy is ready to be unleashed!",   "Smash each star — let that excitement out!",            "Your enthusiasm lights up the room." },
	anxious  = { "You're braver than you feel right now.",      "Each lantern you release carries a worry away.",        "You are safe. You are okay." },
	sad      = { "Every feeling is valid. You're not alone.",   "Plant a flower for each good memory — watch it grow.",  "You are loved more than you know." },
	lonely   = { "Someone is out there waiting to connect.",    "Draw stars together — bridges start with one line.",    "You matter to more people than you think." },
	angry    = { "Your fire is energy — let's channel it!",    "Smash every star — release that tension safely.",       "You have the strength to transform this." },
	stressed = { "You don't have to carry everything at once.", "Each gratitude you add makes the jar glow brighter.",   "You are doing better than you think." },
	neutral  = { "No expectations — just good vibes ahead!",   "Tap anywhere and watch the magic happen.",              "Every moment is a fresh start." },
}

GetPersonalizedContent.OnServerInvoke = function(player, userText, mood)
	if type(userText) ~= "string" then userText = "" end
	if type(mood) ~= "string" or not VALID_MOODS[mood] then mood = "neutral" end

	local prompt = string.format(
		"Player's message: \"%s\"\nDetected mood: %s\n\nWrite the three strings:",
		userText:sub(1, 300), mood
	)

	local raw = callGemini(CONTENT_PROMPT, prompt, 80)

	if raw then
		local parts = {}
		for p in raw:gmatch("([^|]+)") do
			table.insert(parts, p:match("^%s*(.-)%s*$"))
		end
		if #parts >= 3 then
			return { tagline = parts[1], tip = parts[2], affirmation = parts[3] }
		end
	end

	-- Fallback
	local fb = FALLBACK_CONTENT[mood] or FALLBACK_CONTENT["neutral"]
	return { tagline = fb[1], tip = fb[2], affirmation = fb[3] }
end

-- ─── Post-Game Message ────────────────────────────────────────────────────────

local POSTGAME_PROMPT = [[
You are a warm wellness coach for a Roblox game.
The player just completed a mini-game activity.
Write ONE short celebratory sentence (max 18 words) acknowledging:
1. The mood they were feeling
2. The game they played
3. A positive observation about completing it

Be warm, personal, age-appropriate. No quotes. Just the sentence.
]]

local POSTGAME_FALLBACK = {
	ColorBurst     = "🎨 You painted the world brighter just by being here!",
	LanternRelease = "🏮 Those worries are floating away — you let them go beautifully.",
	MemoryGarden   = "🌸 Your garden is blooming — just like you are.",
	StarSmash      = "⭐ You smashed through every star — that energy is yours to keep!",
	GratitudeJar   = "🫙 Your jar is glowing — and so are you.",
	CloudFloat     = "☁️ You floated through and found your peace. Well done.",
	StarBridge     = "🌌 You built something beautiful together — connection is powerful.",
}

GetPostGameMessage.OnServerInvoke = function(player, mood, gameName)
	if type(mood) ~= "string" then mood = "neutral" end
	if type(gameName) ~= "string" then gameName = "activity" end

	local prompt = string.format(
		"Player's mood: %s\nActivity completed: %s\nWrite the celebratory sentence:",
		mood, gameName
	)

	local msg = callGemini(POSTGAME_PROMPT, prompt, 40)
	if msg and #msg > 5 then return msg end

	return POSTGAME_FALLBACK[gameName] or "🌟 Amazing work — you should be proud!"
end

-- ─── Daily Challenge ──────────────────────────────────────────────────────────

local CHALLENGE_PROMPT = [[
You are a wellness coach for a Roblox game.
Based on the player's mood, write ONE short daily wellness micro-challenge (max 20 words).
It should be gentle, achievable today, related to their emotion.
Examples: "Tell one person something you appreciate about them."
No quotes, no numbering. Just the challenge sentence.
]]

local CHALLENGE_FALLBACK = {
	happy    = "Share something that made you smile today with someone.",
	calm     = "Spend 2 minutes watching the sky — notice 3 things.",
	excited  = "Channel this energy into one creative thing you've been putting off.",
	anxious  = "Take 3 slow breaths and name 5 things you can see.",
	sad      = "Write down one small thing that went okay today.",
	lonely   = "Send a message to someone you haven't spoken to in a while.",
	angry    = "Take a walk outside for 5 minutes before responding to anything.",
	stressed = "Write down 3 things you've already accomplished — big or small.",
	neutral  = "Try something small and new today — even one bite of something different.",
}

GetDailyChallenge.OnServerInvoke = function(player, mood)
	if type(mood) ~= "string" or not VALID_MOODS[mood] then mood = "neutral" end

	local prompt = "Player's current mood: " .. mood .. "\nWrite the daily challenge:"
	local challenge = callGemini(CHALLENGE_PROMPT, prompt, 40)
	if challenge and #challenge > 8 then return challenge end

	return CHALLENGE_FALLBACK[mood] or CHALLENGE_FALLBACK["neutral"]
end

print("[MoodServer] Ready – 4 RemoteFunctions registered.")
