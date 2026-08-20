# Whispers of the Veil — Google Play Store Listing

## App Details

| Field | Value |
|-------|-------|
| **App Name** | Whispers of the Veil |
| **Package** | `com.whispersoftheveil.game` |
| **Category** | Games → Casual |
| **Content Rating** | Everyone |
| **Price** | $4.99 (paid upfront) |
| **Version** | 1.0.0 (build 1) |

---

## Short Description (80 characters max)

> A meditative ethereal game — awaken forgotten lights across two mystical veils.

---

## Full Description (4000 characters max)

**Whispers of the Veil** is a contemplative, hand-crafted exploration game set in a dark ethereal world of forgotten light.

You are a spirit — a soft luminous presence drifting through two veils of dormant memory. Your purpose is gentle: find the sleeping bloom nodes scattered across the landscape, awaken them with your presence, and restore the veils to their radiant glory.

**✦ Two Handcrafted Veils**
Explore two distinct biomes, each with their own visual identity and atmosphere:
• **The First Veil** — Warm violet-purple hues, soft ground glow, and delicate crystal formations.
• **The Second Veil** — Cool indigo-teal tones, drifting mist clouds, and tall crystalline structures.

**✦ 25 Interactive Bloom Nodes**
Discover 13 nodes in the First Veil and 12 in the Second — including hidden nodes that require careful exploration or special abilities to find.

**✦ Two Awakened Abilities**
Collect Lumina Shards to unlock:
• **Bloom Pulse** — Send a radial wave of light to awaken hidden nodes nearby.
• **Veil Shift** — Dash instantly toward the nearest dormant bloom.

**✦ The Eternal Sanctuary**
A living record of your progress. Watch the central orb grow brighter with every shard collected. When both veils are restored, the Sanctuary enters its final radiant state — golden motes orbit a luminous core.

**✦ Calm, Rewarding Progression**
No timers. No enemies. No pressure. Just you, the light, and the quiet satisfaction of restoring a forgotten world.

**✦ Premium. No Ads. No In-App Purchases.**
Pay once. Play at your own pace. Your progress is saved locally — no account required.

---

## What's New (Release Notes for 1.0.0)

Initial release:
• Two fully explorable veils with 25 bloom nodes
• Two abilities: Bloom Pulse and Veil Shift
• Sanctuary progression system
• World state persistence
• Ambient audio and particle effects
• Settings with volume controls

---

## Content Rating & Privacy

| Item | Status |
|------|--------|
| Ads | **None** |
| In-App Purchases | **None** |
| Account Required | **No** |
| Data Collection | **None** — all saves are local (SharedPreferences) |
| User-Generated Content | **None** |
| Violence | **None** |
| Suggestive Content | **None** |
| Language | **None** |
| COPPA Compliant | **Yes** |

**Privacy Policy**: This app does not collect, store, or transmit any personal data. All game progress is stored locally on the device using SharedPreferences. No analytics, no telemetry, no network requests.

---

## Store Graphics Checklist

### Required Assets

| Asset | Spec | Status |
|-------|------|--------|
| **App Icon** | 512×512 PNG, 32-bit | ✅ Generated (adaptive icon in repo) |
| **Feature Graphic** | 1024×500 PNG | 📋 See guidance below |
| **Phone Screenshots** | 2–8 screenshots, 16:9 or 9:16 | 📋 See guidance below |

### Feature Graphic Guidance (1024×500)

Create a dark banner image with:
- Deep navy background (#050510 → #0B0B2A gradient)
- Central luminous spirit orb (matching app icon style)
- Game title "Whispers of the Veil" in light ethereal text
- Subtle floating motes and glow particles
- No heavy text — let the atmosphere speak

### Screenshot Guidance (Phone, 9:16 portrait)

Capture these 5 key moments on a real device or emulator:

1. **Title Screen** — "Whispers of the Veil" with glowing orb and floating motes
2. **First Veil Exploration** — Spirit player near several bloom nodes, warm purple palette
3. **Bloom Pulse Activation** — Radial light wave expanding from the player
4. **Sanctuary Overlay** — Orb with orbiting motes, shard count, ability status
5. **Second Veil** — Cool indigo-teal palette, crystal mist, taller formations

Optional:
6. **Shard Collection** — Close to a blooming node with particles
7. **Veil Portal** — Player near the swirling portal between veils
8. **Completion Overlay** — "The First Veil Has Been Restored" moment

---

## Signing & Release Checklist

- [ ] Generate release keystore: `keytool -genkey -v -keystore whispers-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias whispers-release`
- [ ] Create `android/key.properties` from `android/key.properties.example`
- [ ] Build release bundle: `flutter build appbundle`
- [ ] Test release APK on device: `flutter build apk --release && flutter install`
- [ ] Upload AAB to Google Play Console
- [ ] Fill in store listing (copy from this document)
- [ ] Upload feature graphic + screenshots
- [ ] Complete content rating questionnaire
- [ ] Set pricing to $4.99
- [ ] Submit for review
