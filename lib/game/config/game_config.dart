/// Game-wide configuration constants for Whispers of the Veil.
library;

import 'dart:ui';

abstract final class GameConfig {
  // ── Canvas ──────────────────────────────────────────────────────────────
  static const double designWidth = 800;
  static const double designHeight = 600;

  // ── Biome ───────────────────────────────────────────────────────────────
  static const double biomeWidth = 2000.0;
  static const double biomeHeight = 1500.0;
  static const double biomeBoundaryFog = 100.0;
  static const double biomePlayerPadding = 50.0;

  // ── Background Colors ──────────────────────────────────────────────────
  static const Color bgTop = Color(0xFF050510);
  static const Color bgMid = Color(0xFF0B0B2A);
  static const Color bgBot = Color(0xFF10061C);

  // ── Particle glow palette ──────────────────────────────────────────────
  static const Color glowCore = Color(0xFFE0D0FF);
  static const Color glowInner = Color(0xCC9B6DFF);
  static const Color glowOuter = Color(0x664B2D99);

  // ── Particle system defaults ───────────────────────────────────────────
  static const int maxParticles = 60;
  static const double particleMinRadius = 1.5;
  static const double particleMaxRadius = 5.0;
  static const double particleSpawnRadius = 120.0;
  static const double particleDriftSpeed = 18.0;
  static const double particleMinLife = 1.5;
  static const double particleMaxLife = 4.0;

  // ── Player spirit ──────────────────────────────────────────────────────
  static const double playerRadius = 14.0;
  static const double playerSmoothFactor = 4.5;
  static const double playerMaxSpeed = 320.0;
  static const double playerPulseSpeed = 2.5;
  static const double playerIdleBobAmplitude = 3.0;
  static const double playerIdleBobSpeed = 1.8;

  static const Color playerCore = Color(0xFFFFFFFF);
  static const Color playerInner = Color(0xFFD4BFFF);
  static const Color playerMid = Color(0xAA9B6DFF);
  static const Color playerOuter = Color(0x554B2D99);
  static const Color playerHalo = Color(0x22281A50);

  // ── Player aura ────────────────────────────────────────────────────────
  static const int auraParticles = 45;
  static const double auraSpawnRadius = 50.0;
  static const double auraDriftSpeed = 14.0;
  static const double auraMinRadius = 1.0;
  static const double auraMaxRadius = 4.0;
  static const double auraMinLife = 1.2;
  static const double auraMaxLife = 3.5;

  // ── Camera ─────────────────────────────────────────────────────────────
  static const double cameraFollowSpeed = 120.0;

  // ── Tap ripple ─────────────────────────────────────────────────────────
  static const double rippleDuration = 0.7;
  static const double rippleMaxRadius = 35.0;
  static const Color rippleColor = Color(0xCC9B6DFF);

  // ── Light bloom nodes ──────────────────────────────────────────────────
  static const double bloomActivationRadius = 110.0;
  static const double bloomRiseSpeed = 1.0;
  static const double bloomFadeSpeed = 0.45;
  static const double bloomDormantAlpha = 0.20;
  static const double bloomRememberedIntensity = 0.25;
  static const double bloomBaseRadius = 8.0;
  static const int bloomMaxParticles = 14;
  static const double bloomParticleSpeed = 22.0;
  static const double bloomParticleLife = 1.8;
  static const double bloomParticleRadius = 2.5;

  // ── Parallax ───────────────────────────────────────────────────────────
  static const double parallaxFarFactor = 0.12;
  static const double parallaxNearFactor = 0.30;

  // ── Environmental decoration ───────────────────────────────────────────
  static const int ambientWispCount = 40;
  static const double ambientWispMinRadius = 0.6;
  static const double ambientWispMaxRadius = 2.2;
  static const double ambientWispDriftSpeed = 3.5;
  static const double ambientWispAlpha = 0.14;

  static const int groundGlowCount = 10;
  static const double groundGlowMinRadius = 35.0;
  static const double groundGlowMaxRadius = 90.0;
  static const double groundGlowAlpha = 0.035;

  static const int crystalCount = 9;
  static const double crystalMaxHeight = 22.0;
  static const double crystalMinHeight = 10.0;
  static const double crystalAlpha = 0.09;

  // ── Lumina Shards ──────────────────────────────────────────────────────
  static const double shardRadius = 5.0;
  static const double shardPickupRadius = 34.0;
  static const double shardBobSpeed = 2.2;
  static const double shardBobAmplitude = 3.5;
  static const double shardDriftRadius = 40.0;
  static const Color shardCore = Color(0xFFFFE8B0);
  static const Color shardGlow = Color(0xCCFFBF40);
  static const double shardCollectDuration = 0.35;
  static const int shardDropMin = 1;
  static const int shardDropMax = 3;

  // ── Shard Counter HUD ─────────────────────────────────────────────────
  static const double shardHudPadding = 28.0;
  static const double shardIconRadius = 8.0;
  static const double shardHudFontSize = 17.0;
  static const Color shardHudColor = Color(0xFFFFE0A0);
  static const double shardHudPulseDuration = 0.5;

  // ── Sanctuary ──────────────────────────────────────────────────────────
  static const double sanctuaryBtnSize = 28.0;
  static const double sanctuaryOrbMinRadius = 22.0;
  static const double sanctuaryOrbMaxRadius = 60.0;
  static const int sanctuaryMaxShards = 18;
  static const Color sanctuaryColor = Color(0xFFB09FFF);
  static const Color sanctuaryCoreColor = Color(0xFFEADDFF);

  // ── Bloom Pulse ability ────────────────────────────────────────────────
  static const int bloomPulseThreshold = 8;
  static const double bloomPulseRadius = 200.0;
  static const double bloomPulseDuration = 0.7;
  static const double bloomPulseCooldown = 5.0;
  static const double abilityBtnRadius = 22.0;
  static const Color bloomPulseColor = Color(0xFFD4BFFF);

  // ── Ability notification ───────────────────────────────────────────────
  static const double notifyFadeIn = 0.5;
  static const double notifyHold = 2.5;
  static const double notifyFadeOut = 0.5;

  // ── Audio asset paths ──────────────────────────────────────────────────
  static const String sfxShardCollect = 'shard_collect.wav';
  static const String sfxBloomAwaken = 'bloom_awaken.wav';
  static const String sfxBloomPulse = 'bloom_pulse.wav';
  static const String sfxUiClick = 'ui_click.wav';
  static const String sfxAbilityUnlock = 'ability_unlock.wav';
  static const String bgmAmbient = 'ambient_veil.wav';
}
