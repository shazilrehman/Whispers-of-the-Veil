# Changelog

All notable changes to Whispers of the Veil will be documented in this file.

## [1.0.0] — 2026-08-21

### Initial Release

**Core Gameplay**
- Spirit player with smooth touch movement and camera follow
- Two fully explorable veils with distinct visual identities
- 25 interactive bloom nodes (13 + 12) including hidden nodes
- Lumina Shard collection with per-node randomized drops
- Bloom Pulse ability (radial awakening wave, 8 shard threshold)
- Veil Shift ability (dash to nearest dormant node, 16 shard threshold)

**Biomes**
- **First Veil**: Warm violet-purple palette, ambient wisps, ground glow, crystal formations
- **Second Veil**: Cool indigo-teal palette, crystal mist clouds, taller formations
- Seamless portal transitions between veils
- Return portal always available in the Second Veil

**Progression**
- Veil completion detection with celebratory overlay
- "Both Veils Restored" final completion moment
- Eternal Sanctuary with growing orb, orbiting motes, and golden glory state
- Full world state persistence (shards, abilities, bloomed nodes, current veil, volumes)

**UI & Polish**
- Premium title screen with floating particles and central glow
- Shard counter HUD with pulse animation
- Ability HUD with radial cooldown indicators
- Settings screen with Master / Music / SFX volume sliders
- Tap ripple feedback
- Glow particle aura around the player

**Audio**
- Ambient background music
- SFX: shard collect, bloom awaken, bloom pulse, veil shift, ability unlock, UI click

**Technical**
- Adaptive app icon for Android
- Dark splash screen matching game aesthetic
- Portrait orientation lock
- Edge-to-edge immersive system UI
- R8 minification and resource shrinking for release builds
- Release keystore configuration support via key.properties
