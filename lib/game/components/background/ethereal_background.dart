/// Dark ethereal background that fills the entire viewport with a
/// multi-stop radial gradient, subtle animated vignette, and faint
/// drifting nebula wisps.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart' hide Gradient;

import 'package:flame/components.dart';

import '../../config/game_config.dart';

class EtherealBackground extends PositionComponent with HasGameReference {
  // ── Nebula wisps state ─────────────────────────────────────────────────
  static const int _wispCount = 5;
  final List<_Wisp> _wisps = [];
  final Random _rng = Random();

  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = game.size;
    _initWisps();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  // ── Initialise drifting nebula wisps ────────────────────────────────────
  void _initWisps() {
    _wisps.clear();
    for (int i = 0; i < _wispCount; i++) {
      _wisps.add(
        _Wisp(
          center: Vector2(
            _rng.nextDouble() * size.x,
            _rng.nextDouble() * size.y,
          ),
          radius: 80 + _rng.nextDouble() * 160,
          drift: Vector2(
            (_rng.nextDouble() - 0.5) * 6,
            (_rng.nextDouble() - 0.5) * 4,
          ),
          alpha: 0.03 + _rng.nextDouble() * 0.04,
          hue: 250 + _rng.nextDouble() * 40, // purple–indigo range
        ),
      );
    }
  }

  // ── Tick ────────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    for (final w in _wisps) {
      w.center.add(w.drift * dt);
      // Wrap around screen edges
      if (w.center.x < -w.radius) w.center.x = size.x + w.radius;
      if (w.center.x > size.x + w.radius) w.center.x = -w.radius;
      if (w.center.y < -w.radius) w.center.y = size.y + w.radius;
      if (w.center.y > size.y + w.radius) w.center.y = -w.radius;
    }
  }

  // ── Render ──────────────────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // 1) Base vertical gradient
    final bgPaint = Paint()
      ..shader = Gradient.linear(
        Offset.zero,
        Offset(0, size.y),
        [GameConfig.bgTop, GameConfig.bgMid, GameConfig.bgBot],
        [0.0, 0.45, 1.0],
      );
    canvas.drawRect(rect, bgPaint);

    // 2) Nebula wisps (soft radial blobs)
    for (final w in _wisps) {
      final wispColor = HSLColor.fromAHSL(1, w.hue, 0.6, 0.35).toColor();
      final wispPaint = Paint()
        ..shader = Gradient.radial(
          Offset(w.center.x, w.center.y),
          w.radius,
          [
            wispColor.withValues(alpha: w.alpha),
            wispColor.withValues(alpha: 0),
          ],
        )
        ..blendMode = BlendMode.screen;
      canvas.drawCircle(Offset(w.center.x, w.center.y), w.radius, wispPaint);
    }

    // 3) Vignette overlay
    final vigPaint = Paint()
      ..shader = Gradient.radial(
        Offset(size.x / 2, size.y / 2),
        size.x * 0.7,
        [
          const Color(0x00000000),
          const Color(0xDD030308),
        ],
        [0.55, 1.0],
      );
    canvas.drawRect(rect, vigPaint);
  }
}

// ── Internal helper ──────────────────────────────────────────────────────────

class _Wisp {
  _Wisp({
    required this.center,
    required this.radius,
    required this.drift,
    required this.alpha,
    required this.hue,
  });

  final Vector2 center;
  final double radius;
  final Vector2 drift;
  final double alpha;
  final double hue;
}
