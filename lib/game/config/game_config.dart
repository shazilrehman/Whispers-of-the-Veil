/// Game-wide configuration constants for Whispers of the Veil.
library;

import 'dart:ui';

abstract final class GameConfig {
  // ── Canvas ──────────────────────────────────────────────────────────────
  static const double designWidth = 800;
  static const double designHeight = 600;

  // ── Background Colors ──────────────────────────────────────────────────
  /// Deep void background gradient stops.
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
}
