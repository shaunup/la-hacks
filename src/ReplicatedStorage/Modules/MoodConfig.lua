-- MoodConfig v3: themes, ambient styles, music, games, session timers
-- sessionDuration: how long (seconds) the timer runs for each mood/game combo

local MoodConfig = {}

-- ─── Music asset IDs ─────────────────────────────────────────────────────────
-- All IDs below are from the Roblox free audio library.
-- Each mood gets a genuinely different track character.
--
-- HOW TO SWAP: upload your own audio in Studio → open Properties →
-- copy the asset ID → replace the string here.
local MUSIC = {
	-- ☀️ Bright, cheerful acoustic/lo-fi — happy
	upbeat  = "rbxassetid://1843620355",

	-- 🌊 Gentle ambient piano — calm
	calm    = "rbxassetid://5982562",

	-- ⚡ Upbeat electronic / synth pop — excited
	intense = "rbxassetid://142376088",

	-- 🌿 Soft nature + piano — anxious (soothing)
	nature  = "rbxassetid://145391007",

	-- 🌸 Melancholy piano — sad
	sad     = "rbxassetid://258670963",

	-- 🌌 Sparse orchestral / starry — lonely
	night   = "rbxassetid://1507272891",

	-- 🌋 Powerful rhythmic — angry (release tension)
	intense_2 = "rbxassetid://249835920",

	-- 🍃 Soft ambient rain + nature — stressed
	rain    = "rbxassetid://172301154",

	-- 🌙 Lo-fi twilight — neutral
	dreamy  = "rbxassetid://1843620355",
}

MoodConfig.Themes = {

	happy = {
		label         = "Happy",
		emoji         = "☀️",
		tagline       = "You're radiating sunshine! Let's keep that energy going!",
		topColor      = Color3.fromRGB(255, 215,  90),
		bottomColor   = Color3.fromRGB(255, 130,  30),
		accentColor   = Color3.fromRGB(255, 195,  20),
		textColor     = Color3.fromRGB( 80,  45,   0),
		cardColor     = Color3.fromRGB(255, 238, 170),
		lighting = {
			Ambient           = Color3.fromRGB(180, 150,  70),
			Brightness        = 3.2,
			ColorShift_Bottom = Color3.fromRGB(255, 175,  55),
			ColorShift_Top    = Color3.fromRGB(255, 228, 120),
			OutdoorAmbient    = Color3.fromRGB(200, 175,  95),
			FogEnd            = 1200,
			FogColor          = Color3.fromRGB(255, 215, 130),
		},
		atmosphere = {
			Density = 0.25, Offset = 0.12,
			Color   = Color3.fromRGB(255, 195,  90),
			Decay   = Color3.fromRGB(255, 150,  50),
			Glare   = 1.1, Haze = 0.15,
		},
		ambient = {
			style  = "sunray",
			count  = 16,
			shapes = {"✦","✧","⭐","🌟","✨","☀️"},
			color  = Color3.fromRGB(255, 230, 80),
		},
		music            = MUSIC.upbeat,
		sceneStyle       = "happy",
		game             = "MindfulTap",
		alternateGame    = "StarSmash",
		sessionDuration  = 90,   -- 90s of tapping joy
	},

	calm = {
		label         = "Calm",
		emoji         = "🌊",
		tagline       = "A peaceful mind is a powerful mind. Breathe in, breathe out.",
		topColor      = Color3.fromRGB( 75, 155, 215),
		bottomColor   = Color3.fromRGB(155, 205, 238),
		accentColor   = Color3.fromRGB(115, 195, 255),
		textColor     = Color3.fromRGB(  8,  48,  88),
		cardColor     = Color3.fromRGB(205, 232, 255),
		lighting = {
			Ambient           = Color3.fromRGB( 75, 115, 155),
			Brightness        = 1.8,
			ColorShift_Bottom = Color3.fromRGB( 75, 145, 195),
			ColorShift_Top    = Color3.fromRGB(115, 185, 238),
			OutdoorAmbient    = Color3.fromRGB( 75, 135, 175),
			FogEnd            = 1700,
			FogColor          = Color3.fromRGB(155, 208, 238),
		},
		atmosphere = {
			Density = 0.42, Offset = 0.06,
			Color   = Color3.fromRGB(115, 175, 218),
			Decay   = Color3.fromRGB( 75, 138, 188),
			Glare   = 0.15, Haze = 0.55,
		},
		ambient = {
			style  = "ripple",
			count  = 10,
			shapes = {"○","◌","◦","·","☁️","∘"},
			color  = Color3.fromRGB(155, 215, 255),
		},
		music            = MUSIC.calm,
		sceneStyle       = "calm",
		game             = "CloudFloat",
		alternateGame    = "GratitudeJar",
		sessionDuration  = 120,  -- 2 min gentle float
	},

	excited = {
		label         = "Excited",
		emoji         = "⚡",
		tagline       = "You've got that electric energy! Let's channel it!",
		topColor      = Color3.fromRGB(255,  95, 195),
		bottomColor   = Color3.fromRGB(115,  55, 218),
		accentColor   = Color3.fromRGB(255, 218,  45),
		textColor     = Color3.fromRGB(255, 255, 255),
		cardColor     = Color3.fromRGB(195,  75, 175),
		lighting = {
			Ambient           = Color3.fromRGB(118,  38, 138),
			Brightness        = 4,
			ColorShift_Bottom = Color3.fromRGB(198,  58, 158),
			ColorShift_Top    = Color3.fromRGB(255, 138, 218),
			OutdoorAmbient    = Color3.fromRGB(158,  78, 198),
			FogEnd            = 1400,
			FogColor          = Color3.fromRGB(198, 118, 218),
		},
		atmosphere = {
			Density = 0.18, Offset = 0.12,
			Color   = Color3.fromRGB(218,  95, 198),
			Decay   = Color3.fromRGB(158,  58, 178),
			Glare   = 1.6, Haze = 0.08,
		},
		ambient = {
			style  = "spark",
			count  = 24,
			shapes = {"⚡","✦","✨","★","◈","⭐"},
			color  = Color3.fromRGB(255, 218, 60),
		},
		music            = MUSIC.intense,
		sceneStyle       = "excited",
		game             = "StarSmash",
		alternateGame    = "MindfulTap",
		sessionDuration  = 60,   -- fast-paced 60s sprint
	},

	anxious = {
		label         = "Anxious",
		emoji         = "🌿",
		tagline       = "It's okay. Take it one breath at a time. You're safe here.",
		topColor      = Color3.fromRGB( 65, 145, 115),
		bottomColor   = Color3.fromRGB(135, 195, 165),
		accentColor   = Color3.fromRGB( 85, 195, 155),
		textColor     = Color3.fromRGB(  8,  58,  38),
		cardColor     = Color3.fromRGB(185, 228, 208),
		lighting = {
			Ambient           = Color3.fromRGB( 48, 108,  78),
			Brightness        = 1.5,
			ColorShift_Bottom = Color3.fromRGB( 58, 128,  98),
			ColorShift_Top    = Color3.fromRGB( 98, 178, 138),
			OutdoorAmbient    = Color3.fromRGB( 58, 118,  88),
			FogEnd            = 2100,
			FogColor          = Color3.fromRGB(158, 208, 188),
		},
		atmosphere = {
			Density = 0.62, Offset = 0.0,
			Color   = Color3.fromRGB( 98, 168, 138),
			Decay   = Color3.fromRGB( 58, 118,  98),
			Glare   = 0.0, Haze = 0.82,
		},
		ambient = {
			style  = "float",
			count  = 12,
			shapes = {"🍃","·","∘","○","🌿","⋆"},
			color  = Color3.fromRGB( 95, 198, 148),
		},
		music            = MUSIC.nature,
		sceneStyle       = "anxious",
		game             = "LanternRelease",
		alternateGame    = "GratitudeJar",
		sessionDuration  = 150,  -- 5 lanterns at your own pace, ~2.5 min
	},

	sad = {
		label         = "Sad",
		emoji         = "🌸",
		tagline       = "Feelings are visitors. Let's gently tend to your garden.",
		topColor      = Color3.fromRGB(138, 118, 178),
		bottomColor   = Color3.fromRGB(198, 178, 218),
		accentColor   = Color3.fromRGB(198, 158, 218),
		textColor     = Color3.fromRGB( 58,  38,  88),
		cardColor     = Color3.fromRGB(218, 208, 238),
		lighting = {
			Ambient           = Color3.fromRGB( 78,  68, 118),
			Brightness        = 1.2,
			ColorShift_Bottom = Color3.fromRGB( 98,  88, 148),
			ColorShift_Top    = Color3.fromRGB(158, 148, 198),
			OutdoorAmbient    = Color3.fromRGB( 88,  78, 128),
			FogEnd            = 1900,
			FogColor          = Color3.fromRGB(188, 178, 218),
		},
		atmosphere = {
			Density = 0.72, Offset = 0.0,
			Color   = Color3.fromRGB(158, 148, 198),
			Decay   = Color3.fromRGB( 98,  98, 158),
			Glare   = 0.0, Haze = 1.0,
		},
		ambient = {
			style  = "petal",
			count  = 18,
			shapes = {"🌸","🌺","🌷","✿","❀","🌼"},
			color  = Color3.fromRGB(218, 178, 238),
		},
		music            = MUSIC.sad,
		sceneStyle       = "sad",
		game             = "MemoryGarden",
		alternateGame    = "GratitudeJar",
		sessionDuration  = 180,  -- gentle 3 min garden session
	},

	lonely = {
		label         = "Lonely",
		emoji         = "🌌",
		tagline       = "You don't have to be alone in this. Let's build something together.",
		topColor      = Color3.fromRGB( 18,  28,  78),
		bottomColor   = Color3.fromRGB( 58,  48, 118),
		accentColor   = Color3.fromRGB(138, 158, 255),
		textColor     = Color3.fromRGB(218, 228, 255),
		cardColor     = Color3.fromRGB( 48,  58, 128),
		lighting = {
			Ambient           = Color3.fromRGB( 18,  28,  78),
			Brightness        = 1.0,
			ColorShift_Bottom = Color3.fromRGB( 28,  38,  98),
			ColorShift_Top    = Color3.fromRGB( 58,  78, 158),
			OutdoorAmbient    = Color3.fromRGB( 28,  38,  88),
			FogEnd            = 2300,
			FogColor          = Color3.fromRGB( 58,  68, 128),
		},
		atmosphere = {
			Density = 0.82, Offset = 0.0,
			Color   = Color3.fromRGB( 78,  88, 158),
			Decay   = Color3.fromRGB( 38,  48, 118),
			Glare   = 0.0, Haze = 1.25,
		},
		ambient = {
			style  = "snowflake",
			count  = 22,
			shapes = {"✦","✧","·","⋆","★","⊹"},
			color  = Color3.fromRGB(158, 178, 255),
		},
		music            = MUSIC.night,
		sceneStyle       = "lonely",
		game             = "StarBridge",
		alternateGame    = "MemoryGarden",
		sessionDuration  = 240,  -- 4 min to find a partner + build a constellation
	},

	angry = {
		label         = "Angry",
		emoji         = "🌋",
		tagline       = "That fire has power. Let's redirect it into something great.",
		topColor      = Color3.fromRGB(218,  58,  58),
		bottomColor   = Color3.fromRGB(255, 138,  58),
		accentColor   = Color3.fromRGB(255, 198,  78),
		textColor     = Color3.fromRGB(255, 238, 218),
		cardColor     = Color3.fromRGB(198,  58,  58),
		lighting = {
			Ambient           = Color3.fromRGB(138,  38,  28),
			Brightness        = 2.6,
			ColorShift_Bottom = Color3.fromRGB(198,  78,  38),
			ColorShift_Top    = Color3.fromRGB(238, 128,  58),
			OutdoorAmbient    = Color3.fromRGB(158,  58,  38),
			FogEnd            = 1000,
			FogColor          = Color3.fromRGB(218, 118,  78),
		},
		atmosphere = {
			Density = 0.52, Offset = 0.22,
			Color   = Color3.fromRGB(218,  78,  58),
			Decay   = Color3.fromRGB(178,  48,  38),
			Glare   = 0.85, Haze = 0.38,
		},
		ambient = {
			style  = "ember",
			count  = 22,
			shapes = {"🔥","✦","◈","◆","▲","🌋"},
			color  = Color3.fromRGB(255, 118, 38),
		},
		music            = MUSIC.intense_2,
		sceneStyle       = "angry",
		game             = "StarSmash",
		alternateGame    = "LanternRelease",
		sessionDuration  = 60,   -- short intense burst to release tension
	},

	stressed = {
		label         = "Stressed",
		emoji         = "🍃",
		tagline       = "Let's slow down together. You deserve this moment of peace.",
		topColor      = Color3.fromRGB( 58, 128,  88),
		bottomColor   = Color3.fromRGB(128, 188, 148),
		accentColor   = Color3.fromRGB( 98, 218, 158),
		textColor     = Color3.fromRGB(  8,  48,  28),
		cardColor     = Color3.fromRGB(178, 218, 198),
		lighting = {
			Ambient           = Color3.fromRGB( 38,  88,  58),
			Brightness        = 1.4,
			ColorShift_Bottom = Color3.fromRGB( 48, 108,  78),
			ColorShift_Top    = Color3.fromRGB( 88, 158, 118),
			OutdoorAmbient    = Color3.fromRGB( 48,  98,  68),
			FogEnd            = 2100,
			FogColor          = Color3.fromRGB(148, 198, 168),
		},
		atmosphere = {
			Density = 0.62, Offset = 0.0,
			Color   = Color3.fromRGB( 98, 168, 128),
			Decay   = Color3.fromRGB( 58, 118,  98),
			Glare   = 0.0, Haze = 0.92,
		},
		ambient = {
			style  = "float",
			count  = 10,
			shapes = {"🍃","🌿","·","∘","○","⋆"},
			color  = Color3.fromRGB( 98, 198, 138),
		},
		music            = MUSIC.rain,
		sceneStyle       = "stressed",
		game             = "GratitudeJar",
		alternateGame    = "LanternRelease",
		sessionDuration  = 150,  -- 5 gratitudes, ~2.5 min slow pace
	},

	neutral = {
		label         = "Neutral",
		emoji         = "🌙",
		tagline       = "Just vibing? Let's make it fun!",
		topColor      = Color3.fromRGB( 58,  78, 138),
		bottomColor   = Color3.fromRGB(138, 158, 198),
		accentColor   = Color3.fromRGB(158, 198, 255),
		textColor     = Color3.fromRGB(218, 228, 255),
		cardColor     = Color3.fromRGB( 98, 118, 178),
		lighting = {
			Ambient           = Color3.fromRGB( 38,  58,  98),
			Brightness        = 2.0,
			ColorShift_Bottom = Color3.fromRGB( 58,  78, 138),
			ColorShift_Top    = Color3.fromRGB( 98, 128, 188),
			OutdoorAmbient    = Color3.fromRGB( 58,  78, 118),
			FogEnd            = 1400,
			FogColor          = Color3.fromRGB(118, 148, 198),
		},
		atmosphere = {
			Density = 0.45, Offset = 0.05,
			Color   = Color3.fromRGB(118, 148, 198),
			Decay   = Color3.fromRGB( 78, 108, 168),
			Glare   = 0.3, Haze = 0.4,
		},
		ambient = {
			style  = "float",
			count  = 14,
			shapes = {"✦","✧","⋆","·","★","○"},
			color  = Color3.fromRGB(158, 198, 255),
		},
		music            = MUSIC.dreamy,
		sceneStyle       = "neutral",
		game             = "MindfulTap",
		alternateGame    = "CloudFloat",
		sessionDuration  = 90,
	},
}

-- ─── Game info ─────────────────────────────────────────────────────────────

MoodConfig.GameInfo = {
	MindfulTap = {
		name        = "Mindful Tap",
		icon        = "🌟",
		description = "Tap each glowing orb mindfully — stay present, build your combo!",
	},
	LanternRelease = {
		name        = "Lantern Release",
		icon        = "🏮",
		description = "Write a worry, light a lantern, and watch it float away.",
	},
	MemoryGarden = {
		name        = "Memory Garden",
		icon        = "🌸",
		description = "Plant flowers for every happy memory. Watch your garden bloom.",
	},
	StarSmash = {
		name        = "Star Smash",
		icon        = "⭐",
		description = "Smash falling stars and unleash your inner energy!",
	},
	GratitudeJar = {
		name        = "Gratitude Jar",
		icon        = "🫙",
		description = "Drop good thoughts into the jar and watch it glow brighter.",
	},
	CloudFloat = {
		name        = "Cloud Float",
		icon        = "☁️",
		description = "Drift on gentle clouds and collect peace as you float by.",
	},
	StarBridge = {
		name        = "Star Bridge",
		icon        = "🌌",
		description = "Connect with another player — draw constellations together.",
		twoPlayer   = true,
	},
}

MoodConfig.TransitionTime = 0.7   -- fast enough to feel instant

-- ─── Immersive Intro: shown for ~18s between MoodReveal and the mini-game ────
--
-- landscapeDescription : brief text description of the video/image to upload
-- landscapeImage       : rbxassetid://  ← REPLACE with your Decal/Image asset ID
--                        Upload a landscape photo in Studio → Toolbox → My Decals
--                        then paste the asset ID here.
-- introAudio           : rbxassetid://  ← REPLACE with a SoundAsset ID
--                        Descriptions below tell you what type of audio to upload.
-- introDuration        : seconds the intro plays before transitioning (17)
-- quotes               : 2-3 short quotes shown one at a time, fading in/out
--
MoodConfig.Intros = {

	happy = {
		landscapeDescription = [[
			A sun-drenched golden meadow in summer. Wildflowers in every direction,
			rolling hills bathed in warm afternoon light. Butterflies drift past.
			Upload a photo: bright sunlit field / golden meadow / sunflower landscape.
		]],
		landscapeImage  = "rbxassetid://REPLACE_HAPPY_IMAGE",
		-- Audio: cheerful acoustic guitar or gentle upbeat piano, no lyrics
		introAudio      = "rbxassetid://REPLACE_HAPPY_AUDIO",
		introDuration   = 17,
		quotes = {
			"Happiness is not something ready-made.\nIt comes from your own actions.",
			"The present moment is filled with joy and happiness.\nIf you are attentive, you will see it.",
			"Joy is the simplest form of gratitude.",
		},
	},

	calm = {
		landscapeDescription = [[
			A still alpine lake at dawn. Mirror-flat water reflecting snow-capped mountains.
			Mist rising gently from the surface. Absolute silence except for birdsong.
			Upload: calm mountain lake / misty mountain reflection / serene alpine scenery.
		]],
		landscapeImage  = "rbxassetid://REPLACE_CALM_IMAGE",
		-- Audio: soft ambient nature — gentle stream water sounds or soft piano
		introAudio      = "rbxassetid://REPLACE_CALM_AUDIO",
		introDuration   = 17,
		quotes = {
			"Calm mind brings inner strength and self-confidence.",
			"Within you there is a stillness and a sanctuary\nto which you can retreat at any time.",
			"Peace is not the absence of conflict,\nbut the ability to cope with it.",
		},
	},

	excited = {
		landscapeDescription = [[
			A dramatic mountain peak at sunrise. Rays of light bursting over the ridge,
			lighting up clouds in orange and pink. A sense of limitless possibility.
			Upload: mountain sunrise / epic sunrise peak / golden hour mountain vista.
		]],
		landscapeImage  = "rbxassetid://REPLACE_EXCITED_IMAGE",
		-- Audio: uplifting orchestral swell or energetic electronic ambient
		introAudio      = "rbxassetid://REPLACE_EXCITED_AUDIO",
		introDuration   = 15,
		quotes = {
			"Energy and persistence conquer all things.",
			"Life is either a daring adventure or nothing at all.",
			"Your excitement is your compass — let it lead.",
		},
	},

	anxious = {
		landscapeDescription = [[
			A quiet forest path in the early morning. Soft green light filtering through
			tall trees. Dewdrops on leaves. A peaceful trail leading forward.
			Upload: morning forest path / misty woodland trail / green forest sunlight.
		]],
		landscapeImage  = "rbxassetid://REPLACE_ANXIOUS_IMAGE",
		-- Audio: gentle forest ambience — birds, soft breeze, no music
		introAudio      = "rbxassetid://REPLACE_ANXIOUS_AUDIO",
		introDuration   = 18,
		quotes = {
			"You don't have to control your thoughts.\nYou just have to stop letting them control you.",
			"Breathe. You are exactly where you need to be.",
			"Anxiety is love's greatest killer.\nBut one breath at a time, you return to yourself.",
		},
	},

	sad = {
		landscapeDescription = [[
			A cherry blossom path in soft spring rain. Pink petals falling slowly
			onto a quiet stone path. Puddles reflecting the blossoms above.
			Upload: cherry blossom rain / sakura path / pink blossom falling petals.
		]],
		landscapeImage  = "rbxassetid://REPLACE_SAD_IMAGE",
		-- Audio: soft melancholy piano solo, gentle and soothing
		introAudio      = "rbxassetid://REPLACE_SAD_AUDIO",
		introDuration   = 18,
		quotes = {
			"It's okay to feel sad. Even the sky cries sometimes\n— and then it clears.",
			"The wound is the place where the light enters you.",
			"Grief is just love with nowhere to go.\nGive it somewhere beautiful.",
		},
	},

	lonely = {
		landscapeDescription = [[
			A vast starfield over a desert mesa at night. The Milky Way stretching
			across the entire sky. A single lantern glowing in the foreground.
			Upload: milky way desert / starry night landscape / night sky stars mesa.
		]],
		landscapeImage  = "rbxassetid://REPLACE_LONELY_IMAGE",
		-- Audio: sparse orchestral or ambient with soft pads, starry feeling
		introAudio      = "rbxassetid://REPLACE_LONELY_AUDIO",
		introDuration   = 18,
		quotes = {
			"Even stars burn alone — yet they light\nthe whole sky for everyone else.",
			"Loneliness is the poverty of self;\nsolitude is the richness of self.",
			"You are never truly alone.\nEvery person who ever looked at the same stars felt this too.",
		},
	},

	angry = {
		landscapeDescription = [[
			A powerful waterfall crashing into a canyon. Raw energy and force.
			Mist rising. Water thundering, releasing everything into the open air.
			Upload: powerful waterfall / waterfall canyon / rushing falls nature.
		]],
		landscapeImage  = "rbxassetid://REPLACE_ANGRY_IMAGE",
		-- Audio: powerful flowing water ambience, dramatic but not harsh
		introAudio      = "rbxassetid://REPLACE_ANGRY_AUDIO",
		introDuration   = 16,
		quotes = {
			"Speak when you are angry and you will make\nthe best speech you will ever regret.",
			"The greatest remedy for anger is delay.\nLet it move through you like a river.",
			"Your fire is valid. Now — where will you direct it?",
		},
	},

	stressed = {
		landscapeDescription = [[
			A gentle coastal cliff at dusk. Waves rolling in slowly below.
			Warm orange light fading to purple on the horizon. Soft sea breeze.
			Upload: coastal cliff sunset / cliffside ocean view / calm ocean dusk.
		]],
		landscapeImage  = "rbxassetid://REPLACE_STRESSED_IMAGE",
		-- Audio: slow ocean wave sounds, very calming, no music needed
		introAudio      = "rbxassetid://REPLACE_STRESSED_AUDIO",
		introDuration   = 18,
		quotes = {
			"You can't stop the waves, but you can learn to surf.",
			"Almost everything will work again if you unplug it for a few minutes.\nIncluding you.",
			"Rest is not quitting. Rest is recharging\nso you can go further.",
		},
	},

	neutral = {
		landscapeDescription = [[
			A lavender field at twilight, stretching to the horizon.
			Soft purple hues, first stars appearing, a warm breeze.
			Upload: lavender field twilight / purple flower field evening / lavender landscape.
		]],
		landscapeImage  = "rbxassetid://REPLACE_NEUTRAL_IMAGE",
		-- Audio: soft ambient electronic or gentle acoustic, relaxed
		introAudio      = "rbxassetid://REPLACE_NEUTRAL_AUDIO",
		introDuration   = 16,
		quotes = {
			"Not every day needs a direction.\nSometimes just being here is enough.",
			"Let whatever you do today be enough.",
			"The secret of getting ahead is getting started.",
		},
	},
}

return MoodConfig
