# Wellness World — Roblox Game

A mood-aware Roblox experience that reads how a player is feeling, uses **Gemini AI** to classify their mood, then sets a matching atmosphere (sky, lighting, music) and launches an interactive mini-game designed to support that emotional state.

---

## Mood → Theme → Game map

| Mood | Visual Theme | Music | Mini-Game |
|------|-------------|-------|-----------|
| **Happy** | Golden sunrise gradient | Upbeat lo-fi | 🎨 Color Burst |
| **Calm** | Soft blue sky | Nature ambience | ☁️ Cloud Float |
| **Excited** | Electric pink-purple | High-energy beat | ⭐ Star Smash |
| **Anxious** | Gentle forest green | Soothing nature | 🫧 Bubble Breathing |
| **Sad** | Soft lavender dusk | Gentle piano | 🌸 Memory Garden |
| **Angry** | Volcanic red-orange | Rhythmic release | ⭐ Star Smash |
| **Stressed** | Healing sage green | Lo-fi calm | 🫙 Gratitude Jar |
| **Neutral** | Starry night blue | Chill ambient | 🎨 Color Burst |

---

## Project structure

```
WellnessWorld/
├── default.project.json          ← Rojo project file
└── src/
    ├── ServerScriptService/
    │   └── MoodServer.server.lua  ← Gemini API call + mood classification
    ├── StarterPlayerScripts/
    │   └── MoodClient.client.lua  ← All UI screens, lighting, music, game flow
    └── ReplicatedStorage/
        ├── Modules/
        │   └── MoodConfig.lua     ← All theme colours, lighting, audio IDs
        └── Games/
            ├── ColorBurst.lua     ← Click-to-burst colour particles
            ├── BubbleBreathing.lua← Guided 4-4-6-2 breathing exercise
            ├── MemoryGarden.lua   ← Type memories → plant flowers
            ├── StarSmash.lua      ← Smash falling stars to release tension
            ├── GratitudeJar.lua   ← Write gratitudes → glowing jar
            └── CloudFloat.lua     ← Collect peace items from drifting clouds
```

---

## Setup in Roblox Studio

### 1. Install Rojo

Download Rojo from [rojo.space](https://rojo.space/) and install the **Rojo Studio plugin** from the Roblox plugin marketplace.

### 2. Sync with Studio

```bash
# Install Rojo CLI (requires Aftman or cargo)
aftman install

# In the project root:
rojo serve
```

Then in Studio, open the **Rojo** panel and click **Connect**.

> **Without Rojo:** You can also copy each `.lua` file into Studio manually:
> - `MoodServer.server.lua` → `ServerScriptService`
> - `MoodClient.client.lua` → `StarterPlayer > StarterPlayerScripts`
> - `MoodConfig.lua` → `ReplicatedStorage > Modules` (ModuleScript)
> - Each game file → `ReplicatedStorage > Games` (ModuleScript)

### 3. Add your Gemini API key

1. In Studio, open **ServerStorage**.
2. Create a new `StringValue` named exactly **`GEMINI_API_KEY`**.
3. Paste your [Google AI Studio](https://aistudio.google.com/) key as its `Value`.
4. The server script reads this at runtime — the key is never exposed to clients.

> **No key?** The game still works! A keyword-based heuristic fallback classifies mood without any API call.

### 4. Enable HTTP requests

In Studio: **Home → Game Settings → Security → Allow HTTP Requests** → Enable.

### 5. Add background music (optional)

The config uses free Roblox audio asset IDs. Replace the `music` values in `MoodConfig.lua` with your own uploaded audio asset IDs for custom tracks.

---

## Mini-game descriptions

### 🎨 Color Burst *(happy, neutral)*
Tap anywhere on screen to fire colourful particle explosions. Collect 10 bursts to win a round. Pure joy and colour therapy.

### 🫧 Bubble Breathing *(anxious)*
A guided 4-4-6-2 breathing exercise. Watch the bubble grow as you inhale and shrink as you exhale. Completes 5 full cycles.

### 🌸 Memory Garden *(sad)*
Type a happy memory or something you're grateful for. Each entry plants a blooming flower with an animated tag. Watch your personal garden grow.

### ⭐ Star Smash *(angry, excited)*
Click falling stars before they reach the ground. The pace increases over time. Physically satisfying way to channel and release pent-up energy.

### 🫙 Gratitude Jar *(stressed)*
Write things you're grateful for. Each entry makes the jar glow brighter and shows a positive affirmation. The jar fills with light as you fill it with gratitude.

### ☁️ Cloud Float *(calm)*
Gently drifting clouds carry peace items across the screen. Click them to collect tranquility. A slow, mindful clicking experience.

---

## Architecture notes

- **Gemini integration** lives entirely in `MoodServer.server.lua` — the LocalScript never has API key access.
- All visual theming is data-driven via `MoodConfig.lua` — adding a new mood only requires adding one entry to the `Themes` table and a corresponding game module.
- The UI uses pure Roblox `ScreenGui` / `Frame` / `TextLabel` — no external assets required beyond the soft shadow image (asset ID `5028857084`).
- Lighting transitions use `TweenService` for smooth sky colour interpolation; `Atmosphere` properties not tweeneable are swapped at the midpoint.
- Each game module follows the same interface: `GameModule.new()`, `:Start(container, theme)`, `:Stop()`.

---

## Extending the game

To add a new mood or game:

1. Add a new entry in `MoodConfig.Themes` with the desired colours, lighting, music, and game name.
2. Create a new `GameModule.lua` in `src/ReplicatedStorage/Games/` following the `.new()` / `:Start()` / `:Stop()` pattern.
3. Add a description entry in `MoodConfig.GameInfo`.
4. Update `MoodServer.server.lua`'s `VALID_MOODS` table and `KEYWORD_RULES` if you want the heuristic fallback to handle it.

---

## Credits

Built with ❤️ for LA Hacks. Powered by Google Gemini.
