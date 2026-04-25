-- MoodConfig: all visual themes, lighting, sounds, and game assignments per mood
-- Every colour is a Color3 (RGB 0-1).  Music IDs are free Roblox audio assets.

local MoodConfig = {}

-- ────────────────────────────────────────────────────────────────────────────
-- THEME TABLE
-- ────────────────────────────────────────────────────────────────────────────
-- sky        : Atmosphere / sky hex
-- topColor   : gradient top
-- bottomColor: gradient bottom
-- accentColor: UI highlight, glow
-- textColor  : primary UI text
-- cardColor  : panel background (with transparency applied by client)
-- lighting   : Lighting service properties
-- music      : Roblox audio asset ID (SoundId)
-- game       : which mini-game module to load
-- label      : human-readable mood name
-- tagline    : message shown to the player after mood detection
-- emoji      : purely decorative label in UI
-- ────────────────────────────────────────────────────────────────────────────

MoodConfig.Themes = {

	happy = {
		label      = "Happy",
		emoji      = "☀️",
		tagline    = "You're radiating sunshine! Let's keep that energy going!",
		topColor    = Color3.fromRGB(255, 220, 100),
		bottomColor = Color3.fromRGB(255, 160,  50),
		accentColor = Color3.fromRGB(255, 200,  30),
		textColor   = Color3.fromRGB(80,  50,   0),
		cardColor   = Color3.fromRGB(255, 240, 180),
		lighting = {
			Ambient           = Color3.fromRGB(180, 155,  80),
			Brightness        = 3,
			ColorShift_Bottom = Color3.fromRGB(255, 180,  60),
			ColorShift_Top    = Color3.fromRGB(255, 230, 130),
			OutdoorAmbient    = Color3.fromRGB(200, 180, 100),
			FogEnd            = 1200,
			FogColor          = Color3.fromRGB(255, 220, 140),
		},
		atmosphere = {
			Density    = 0.3,
			Offset     = 0.1,
			Color      = Color3.fromRGB(255, 200, 100),
			Decay      = Color3.fromRGB(255, 160,  60),
			Glare      = 1.0,
			Haze       = 0.2,
		},
		-- Upbeat lofi / cheerful background – Roblox free audio
		music  = "rbxassetid://1843620355",
		game   = "ColorBurst",
	},

	calm = {
		label      = "Calm",
		emoji      = "🌊",
		tagline    = "A peaceful mind is a powerful mind. Breathe in, breathe out.",
		topColor    = Color3.fromRGB( 80, 160, 220),
		bottomColor = Color3.fromRGB(160, 210, 240),
		accentColor = Color3.fromRGB(120, 200, 255),
		textColor   = Color3.fromRGB( 10,  50,  90),
		cardColor   = Color3.fromRGB(210, 235, 255),
		lighting = {
			Ambient           = Color3.fromRGB( 80, 120, 160),
			Brightness        = 1.8,
			ColorShift_Bottom = Color3.fromRGB( 80, 150, 200),
			ColorShift_Top    = Color3.fromRGB(120, 190, 240),
			OutdoorAmbient    = Color3.fromRGB( 80, 140, 180),
			FogEnd            = 1600,
			FogColor          = Color3.fromRGB(160, 210, 240),
		},
		atmosphere = {
			Density    = 0.4,
			Offset     = 0.05,
			Color      = Color3.fromRGB(120, 180, 220),
			Decay      = Color3.fromRGB( 80, 140, 190),
			Glare      = 0.2,
			Haze       = 0.5,
		},
		-- Gentle lo-fi / nature ambience
		music  = "rbxassetid://5982562",
		game   = "CloudFloat",
	},

	excited = {
		label      = "Excited",
		emoji      = "⚡",
		tagline    = "You've got that electric energy! Let's channel it!",
		topColor    = Color3.fromRGB(255, 100, 200),
		bottomColor = Color3.fromRGB(120,  60, 220),
		accentColor = Color3.fromRGB(255, 220,  50),
		textColor   = Color3.fromRGB(255, 255, 255),
		cardColor   = Color3.fromRGB(200,  80, 180),
		lighting = {
			Ambient           = Color3.fromRGB(120,  40, 140),
			Brightness        = 4,
			ColorShift_Bottom = Color3.fromRGB(200,  60, 160),
			ColorShift_Top    = Color3.fromRGB(255, 140, 220),
			OutdoorAmbient    = Color3.fromRGB(160,  80, 200),
			FogEnd            = 1400,
			FogColor          = Color3.fromRGB(200, 120, 220),
		},
		atmosphere = {
			Density    = 0.2,
			Offset     = 0.1,
			Color      = Color3.fromRGB(220, 100, 200),
			Decay      = Color3.fromRGB(160,  60, 180),
			Glare      = 1.5,
			Haze       = 0.1,
		},
		-- High-energy arcade beat
		music  = "rbxassetid://1843620355",
		game   = "StarSmash",
	},

	anxious = {
		label      = "Anxious",
		emoji      = "🌿",
		tagline    = "It's okay. Take it one breath at a time. You're safe here.",
		topColor    = Color3.fromRGB( 70, 150, 120),
		bottomColor = Color3.fromRGB(140, 200, 170),
		accentColor = Color3.fromRGB( 90, 200, 160),
		textColor   = Color3.fromRGB( 10,  60,  40),
		cardColor   = Color3.fromRGB(190, 230, 210),
		lighting = {
			Ambient           = Color3.fromRGB( 50, 110,  80),
			Brightness        = 1.5,
			ColorShift_Bottom = Color3.fromRGB( 60, 130, 100),
			ColorShift_Top    = Color3.fromRGB(100, 180, 140),
			OutdoorAmbient    = Color3.fromRGB( 60, 120,  90),
			FogEnd            = 2000,
			FogColor          = Color3.fromRGB(160, 210, 190),
		},
		atmosphere = {
			Density    = 0.6,
			Offset     = 0.0,
			Color      = Color3.fromRGB(100, 170, 140),
			Decay      = Color3.fromRGB( 60, 120, 100),
			Glare      = 0.0,
			Haze       = 0.8,
		},
		-- Soothing nature / forest ambience
		music  = "rbxassetid://5982562",
		game   = "BubbleBreathing",
	},

	sad = {
		label      = "Sad",
		emoji      = "🌸",
		tagline    = "Feelings are visitors. Let's gently tend to your garden.",
		topColor    = Color3.fromRGB(140, 120, 180),
		bottomColor = Color3.fromRGB(200, 180, 220),
		accentColor = Color3.fromRGB(200, 160, 220),
		textColor   = Color3.fromRGB( 60,  40,  90),
		cardColor   = Color3.fromRGB(220, 210, 240),
		lighting = {
			Ambient           = Color3.fromRGB( 80,  70, 120),
			Brightness        = 1.2,
			ColorShift_Bottom = Color3.fromRGB(100,  90, 150),
			ColorShift_Top    = Color3.fromRGB(160, 150, 200),
			OutdoorAmbient    = Color3.fromRGB( 90,  80, 130),
			FogEnd            = 1800,
			FogColor          = Color3.fromRGB(190, 180, 220),
		},
		atmosphere = {
			Density    = 0.7,
			Offset     = 0.0,
			Color      = Color3.fromRGB(160, 150, 200),
			Decay      = Color3.fromRGB(100, 100, 160),
			Glare      = 0.0,
			Haze       = 1.0,
		},
		-- Gentle piano / soft melody
		music  = "rbxassetid://5982562",
		game   = "MemoryGarden",
	},

	angry = {
		label      = "Angry",
		emoji      = "🌋",
		tagline    = "That fire has power. Let's redirect it into something great.",
		topColor    = Color3.fromRGB(220,  60,  60),
		bottomColor = Color3.fromRGB(255, 140,  60),
		accentColor = Color3.fromRGB(255, 200,  80),
		textColor   = Color3.fromRGB(255, 240, 220),
		cardColor   = Color3.fromRGB(200,  60,  60),
		lighting = {
			Ambient           = Color3.fromRGB(140,  40,  30),
			Brightness        = 2.5,
			ColorShift_Bottom = Color3.fromRGB(200,  80,  40),
			ColorShift_Top    = Color3.fromRGB(240, 130,  60),
			OutdoorAmbient    = Color3.fromRGB(160,  60,  40),
			FogEnd            = 1000,
			FogColor          = Color3.fromRGB(220, 120,  80),
		},
		atmosphere = {
			Density    = 0.5,
			Offset     = 0.2,
			Color      = Color3.fromRGB(220,  80,  60),
			Decay      = Color3.fromRGB(180,  50,  40),
			Glare      = 0.8,
			Haze       = 0.4,
		},
		-- Powerful, rhythmic beat (release tension)
		music  = "rbxassetid://1843620355",
		game   = "StarSmash",
	},

	stressed = {
		label      = "Stressed",
		emoji      = "🍃",
		tagline    = "Let's slow down together. You deserve this moment of peace.",
		topColor    = Color3.fromRGB( 60, 130,  90),
		bottomColor = Color3.fromRGB(130, 190, 150),
		accentColor = Color3.fromRGB(100, 220, 160),
		textColor   = Color3.fromRGB( 10,  50,  30),
		cardColor   = Color3.fromRGB(180, 220, 200),
		lighting = {
			Ambient           = Color3.fromRGB( 40,  90,  60),
			Brightness        = 1.4,
			ColorShift_Bottom = Color3.fromRGB( 50, 110,  80),
			ColorShift_Top    = Color3.fromRGB( 90, 160, 120),
			OutdoorAmbient    = Color3.fromRGB( 50, 100,  70),
			FogEnd            = 2000,
			FogColor          = Color3.fromRGB(150, 200, 170),
		},
		atmosphere = {
			Density    = 0.6,
			Offset     = 0.0,
			Color      = Color3.fromRGB(100, 170, 130),
			Decay      = Color3.fromRGB( 60, 120, 100),
			Glare      = 0.0,
			Haze       = 0.9,
		},
		-- Lo-fi / calm study beats
		music  = "rbxassetid://5982562",
		game   = "GratitudeJar",
	},

	neutral = {
		label      = "Neutral",
		emoji      = "🌙",
		tagline    = "Just vibing? Let's make it fun!",
		topColor    = Color3.fromRGB( 60,  80, 140),
		bottomColor = Color3.fromRGB(140, 160, 200),
		accentColor = Color3.fromRGB(160, 200, 255),
		textColor   = Color3.fromRGB(220, 230, 255),
		cardColor   = Color3.fromRGB(100, 120, 180),
		lighting = {
			Ambient           = Color3.fromRGB( 40,  60, 100),
			Brightness        = 2.0,
			ColorShift_Bottom = Color3.fromRGB( 60,  80, 140),
			ColorShift_Top    = Color3.fromRGB(100, 130, 190),
			OutdoorAmbient    = Color3.fromRGB( 60,  80, 120),
			FogEnd            = 1400,
			FogColor          = Color3.fromRGB(120, 150, 200),
		},
		atmosphere = {
			Density    = 0.45,
			Offset     = 0.05,
			Color      = Color3.fromRGB(120, 150, 200),
			Decay      = Color3.fromRGB( 80, 110, 170),
			Glare      = 0.3,
			Haze       = 0.4,
		},
		-- Chill background music
		music  = "rbxassetid://1843620355",
		game   = "ColorBurst",
	},
}

-- ─── Game descriptions shown in the selection screen ───────────────────────
MoodConfig.GameInfo = {
	ColorBurst = {
		name        = "Color Burst",
		icon        = "🎨",
		description = "Paint the world with joyful explosions of colour!",
	},
	BubbleBreathing = {
		name        = "Bubble Breathing",
		icon        = "🫧",
		description = "Breathe in to grow the bubble, breathe out to float it away.",
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
}

-- Tween durations (seconds) for lighting/sky transitions
MoodConfig.TransitionTime = 2.5

return MoodConfig
