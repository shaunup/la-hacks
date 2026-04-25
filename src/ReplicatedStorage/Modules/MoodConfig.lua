-- MoodConfig: all visual themes, lighting, sounds, and game assignments per mood
-- Every colour is a Color3 (RGB 0-1).  Music IDs are free Roblox audio assets.

local MoodConfig = {}

-- ────────────────────────────────────────────────────────────────────────────
-- AMBIENT PARTICLE STYLES  (used by AmbientLayer)
-- ────────────────────────────────────────────────────────────────────────────
-- style can be: "float", "sunray", "ember", "petal", "snowflake", "spark", "ripple"
-- count   : how many particles
-- shapes  : emoji array shown as TextLabel
-- ────────────────────────────────────────────────────────────────────────────

MoodConfig.Themes = {

	happy = {
		label      = "Happy",
		emoji      = "☀️",
		tagline    = "You're radiating sunshine! Let's keep that energy going!",
		topColor    = Color3.fromRGB(255, 220, 100),
		bottomColor = Color3.fromRGB(255, 140,  40),
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
			Density = 0.3, Offset = 0.1,
			Color   = Color3.fromRGB(255, 200, 100),
			Decay   = Color3.fromRGB(255, 160,  60),
			Glare   = 1.0, Haze = 0.2,
		},
		ambient = {
			style  = "sunray",
			count  = 14,
			shapes = {"✦","✧","⭐","🌟","✨"},
			color  = Color3.fromRGB(255, 230, 80),
		},
		music        = "rbxassetid://1843620355",
		game         = "ColorBurst",
		alternateGame = "StarSmash",
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
			Density = 0.4, Offset = 0.05,
			Color   = Color3.fromRGB(120, 180, 220),
			Decay   = Color3.fromRGB( 80, 140, 190),
			Glare   = 0.2, Haze = 0.5,
		},
		ambient = {
			style  = "ripple",
			count  = 10,
			shapes = {"○","◌","◦","·","☁️"},
			color  = Color3.fromRGB(160, 220, 255),
		},
		music        = "rbxassetid://5982562",
		game         = "CloudFloat",
		alternateGame = "GratitudeJar",
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
			Density = 0.2, Offset = 0.1,
			Color   = Color3.fromRGB(220, 100, 200),
			Decay   = Color3.fromRGB(160,  60, 180),
			Glare   = 1.5, Haze = 0.1,
		},
		ambient = {
			style  = "spark",
			count  = 22,
			shapes = {"⚡","✦","✨","★","◈"},
			color  = Color3.fromRGB(255, 220, 60),
		},
		music        = "rbxassetid://1843620355",
		game         = "StarSmash",
		alternateGame = "ColorBurst",
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
			Density = 0.6, Offset = 0.0,
			Color   = Color3.fromRGB(100, 170, 140),
			Decay   = Color3.fromRGB( 60, 120, 100),
			Glare   = 0.0, Haze = 0.8,
		},
		ambient = {
			style  = "float",
			count  = 12,
			shapes = {"🍃","·","∘","○","🌿"},
			color  = Color3.fromRGB(100, 200, 150),
		},
		music        = "rbxassetid://5982562",
		game         = "LanternRelease",
		alternateGame = "GratitudeJar",
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
			Density = 0.7, Offset = 0.0,
			Color   = Color3.fromRGB(160, 150, 200),
			Decay   = Color3.fromRGB(100, 100, 160),
			Glare   = 0.0, Haze = 1.0,
		},
		ambient = {
			style  = "petal",
			count  = 18,
			shapes = {"🌸","🌺","🌷","✿","❀"},
			color  = Color3.fromRGB(220, 180, 240),
		},
		music        = "rbxassetid://5982562",
		game         = "MemoryGarden",
		alternateGame = "GratitudeJar",
	},

	lonely = {
		label      = "Lonely",
		emoji      = "🌌",
		tagline    = "You don't have to be alone in this. Let's build something together.",
		topColor    = Color3.fromRGB( 20,  30,  80),
		bottomColor = Color3.fromRGB( 60,  50, 120),
		accentColor = Color3.fromRGB(140, 160, 255),
		textColor   = Color3.fromRGB(220, 230, 255),
		cardColor   = Color3.fromRGB( 50,  60, 130),
		lighting = {
			Ambient           = Color3.fromRGB( 20,  30,  80),
			Brightness        = 1.0,
			ColorShift_Bottom = Color3.fromRGB( 30,  40, 100),
			ColorShift_Top    = Color3.fromRGB( 60,  80, 160),
			OutdoorAmbient    = Color3.fromRGB( 30,  40,  90),
			FogEnd            = 2200,
			FogColor          = Color3.fromRGB( 60,  70, 130),
		},
		atmosphere = {
			Density = 0.8, Offset = 0.0,
			Color   = Color3.fromRGB( 80,  90, 160),
			Decay   = Color3.fromRGB( 40,  50, 120),
			Glare   = 0.0, Haze = 1.2,
		},
		ambient = {
			style  = "snowflake",
			count  = 20,
			shapes = {"✦","✧","·","⋆","★"},
			color  = Color3.fromRGB(160, 180, 255),
		},
		music        = "rbxassetid://5982562",
		-- Primary: two-player constellation co-op
		game         = "StarBridge",
		alternateGame = "MemoryGarden",
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
			Density = 0.5, Offset = 0.2,
			Color   = Color3.fromRGB(220,  80,  60),
			Decay   = Color3.fromRGB(180,  50,  40),
			Glare   = 0.8, Haze = 0.4,
		},
		ambient = {
			style  = "ember",
			count  = 20,
			shapes = {"🔥","✦","◈","◆","▲"},
			color  = Color3.fromRGB(255, 120, 40),
		},
		music        = "rbxassetid://1843620355",
		game         = "StarSmash",
		alternateGame = "LanternRelease",
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
			Density = 0.6, Offset = 0.0,
			Color   = Color3.fromRGB(100, 170, 130),
			Decay   = Color3.fromRGB( 60, 120, 100),
			Glare   = 0.0, Haze = 0.9,
		},
		ambient = {
			style  = "float",
			count  = 10,
			shapes = {"🍃","🌿","·","∘","○"},
			color  = Color3.fromRGB(100, 200, 140),
		},
		music        = "rbxassetid://5982562",
		game         = "GratitudeJar",
		alternateGame = "LanternRelease",
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
			Density = 0.45, Offset = 0.05,
			Color   = Color3.fromRGB(120, 150, 200),
			Decay   = Color3.fromRGB( 80, 110, 170),
			Glare   = 0.3, Haze = 0.4,
		},
		ambient = {
			style  = "float",
			count  = 14,
			shapes = {"✦","✧","⋆","·","★"},
			color  = Color3.fromRGB(160, 200, 255),
		},
		music        = "rbxassetid://1843620355",
		game         = "ColorBurst",
		alternateGame = "CloudFloat",
	},
}

-- ─── Game info ─────────────────────────────────────────────────────────────
MoodConfig.GameInfo = {
	ColorBurst = {
		name        = "Color Burst",
		icon        = "🎨",
		description = "Paint the world with joyful explosions of colour!",
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

MoodConfig.TransitionTime = 2.5

return MoodConfig
