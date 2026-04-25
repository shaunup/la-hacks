-- MoodServer: receives player mood text, calls Gemini API, returns mood analysis
local HttpService    = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteFunction created here; client will wait for it
local AnalyzeMood = Instance.new("RemoteFunction")
AnalyzeMood.Name  = "AnalyzeMood"
AnalyzeMood.Parent = ReplicatedStorage

-- ─── Gemini configuration ──────────────────────────────────────────────────
-- Store your Gemini API key in a StringValue inside ServerStorage named
-- "GEMINI_API_KEY", or hardcode it here during local testing.
local function getApiKey()
	local keyObj = game:GetService("ServerStorage"):FindFirstChild("GEMINI_API_KEY")
	if keyObj and keyObj.Value ~= "" then
		return keyObj.Value
	end
	-- Fallback: replace with your key for local Studio testing
	return "YOUR_GEMINI_API_KEY_HERE"
end

local GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key="

-- ─── Mood categories returned by the server ────────────────────────────────
-- happy | calm | excited | anxious | sad | angry | stressed | neutral

local SYSTEM_PROMPT = [[
You are a wellness assistant for a Roblox game. 
Given a player's one-line message about how they feel, classify their mood 
into EXACTLY ONE of these categories (lowercase, no punctuation):
  happy, calm, excited, anxious, sad, angry, stressed, neutral

Rules:
- Reply with ONLY the single mood word. Nothing else.
- If the text expresses joy, contentment, or gratitude → happy
- If the text expresses peace, relaxation → calm
- If the text expresses energy, enthusiasm → excited
- If the text expresses worry, nervousness, fear → anxious
- If the text expresses sadness, loneliness, grief → sad
- If the text expresses frustration, anger, irritation → angry
- If the text expresses pressure, overwhelm, exhaustion → stressed
- Otherwise → neutral
]]

local function callGemini(userText)
	local apiKey = getApiKey()
	if apiKey == "YOUR_GEMINI_API_KEY_HERE" then
		warn("[MoodServer] No Gemini API key set – using heuristic fallback.")
		return nil
	end

	local payload = HttpService:JSONEncode({
		system_instruction = {
			parts = { { text = SYSTEM_PROMPT } }
		},
		contents = {
			{
				role = "user",
				parts = { { text = userText } }
			}
		},
		generationConfig = {
			temperature = 0.1,
			maxOutputTokens = 10
		}
	})

	local ok, result = pcall(function()
		return HttpService:RequestAsync({
			Url     = GEMINI_URL .. apiKey,
			Method  = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body    = payload
		})
	end)

	if not ok then
		warn("[MoodServer] HTTP request failed:", result)
		return nil
	end

	if result.StatusCode ~= 200 then
		warn("[MoodServer] Gemini returned status", result.StatusCode, result.Body)
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

	if text then
		-- Sanitise: lowercase + strip whitespace
		return text:lower():match("^%s*(.-)%s*$")
	end
	return nil
end

-- ─── Heuristic fallback (no API key) ───────────────────────────────────────
local KEYWORD_RULES = {
	happy    = {"happy","joy","great","wonderful","excited","amazing","fantastic","love","good","glad","yay"},
	calm     = {"calm","peace","relax","serene","chill","tranquil","quiet","still","okay","fine"},
	excited  = {"excited","hype","pumped","energetic","thrilled","stoked","woohoo","let's go"},
	anxious  = {"anxious","nervous","worried","scared","afraid","fear","panic","stress","overwhelm","dread"},
	sad      = {"sad","unhappy","depressed","crying","lonely","hurt","down","blue","miss","grief","lost"},
	angry    = {"angry","mad","furious","annoyed","frustrated","rage","hate","upset","irritated"},
	stressed = {"stressed","tired","exhausted","burnt","pressure","too much","overwhelmed","busy","cant cope"},
}

local function heuristicMood(text)
	local lower = text:lower()
	for mood, keywords in pairs(KEYWORD_RULES) do
		for _, kw in ipairs(keywords) do
			if lower:find(kw, 1, true) then
				return mood
			end
		end
	end
	return "neutral"
end

local VALID_MOODS = {
	happy=true, calm=true, excited=true, anxious=true,
	sad=true, angry=true, stressed=true, neutral=true
}

-- ─── RemoteFunction handler ─────────────────────────────────────────────────
AnalyzeMood.OnServerInvoke = function(player, userText)
	if type(userText) ~= "string" then return "neutral" end
	userText = userText:sub(1, 500) -- safety clamp

	local mood = callGemini(userText)

	-- Validate returned mood
	if not mood or not VALID_MOODS[mood] then
		mood = heuristicMood(userText)
	end

	print(string.format("[MoodServer] %s → mood: %s", player.Name, mood))
	return mood
end

print("[MoodServer] Ready.")
