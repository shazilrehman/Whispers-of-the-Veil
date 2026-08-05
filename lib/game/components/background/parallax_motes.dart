/// Floating ethereal motes rendered at two parallax depths behind
/// the world content. Creates a sense of depth as the camera moves.
///
/// Added at game level (screen coordinates) with parallax offset
/// computed from camera position each frame.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' hide Gradient;

import '../../config/game_config.dart';

class ParallaxMotes extends Component with HasGameReference {
  final List<_Mote> _motes = [];
  final Random _rng = Random();

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _generate();
  }

  // ── Generate two layers of motes ───────────────────────────────────────
  void _generate() {
    // Far layer — large, very faint, slow
    for (int i = 0; i < 8; i++) {
      _motes.add(_Mote(
        base: Vector2(
          _rng.nextDouble() * 1400 - 100,
          _rng.nextDouble() * 1100 - 100,
        ),
        radius: 50 + _rng.nextDouble() * 90,
        alpha: 0.018 + _rng.nextDouble() * 0.025,
        parallax: GameConfig.parallaxFarFactor +
            _rng.nextDouble() * 0.04,
        drift: Vector2(
          (_rng.nextDouble() - 0.5) * 2.5,
          (_rng.nextDouble() - 0.5) * 1.5,
        ),
        hue: 240 + _rng.nextDouble() * 50, // blue–purple
      ));
    }

    // Near layer — smaller, slightly brighter, faster drift
    for (int i = 0; i < 10; i++) {
      _motes.add(_Mote(
        base: Vector2(
          _rng.nextDouble() * 1600 - 200,
          _rng.nextDouble() * 1200 - 100,
        ),
        radius: 18 + _rng.nextDouble() * 35,
        alpha: 0.025 + _rng.nextDouble() * 0.035,
        parallax: GameConfig.parallaxNearFactor +
            _rng.nextDouble() * 0.08,
        drift: Vector2(
          (_rng.nextDouble() - 0.5) * 4,
          (_rng.nextDouble() - 0.5) * 2.5,
        ),
        hue: 250 + _rng.nextDouble() * 60, // purple–indigo
      ));
    }
  }

  // ── Tick ────────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    for (final m in _motes) {
      m.base.add(m.drift * dt);
    }
  }

  // ── Render ──────────────────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    final cam = game.camera.viewfinder.position;

    for (final m in _motes) {
      final sx = m.base.x - cam.x * m.parallax;
      final sy = m.base.y - cam.y * m.parallax;

      final color =
          HSLColor.fromAHSL(1, m.hue, 0.5, 0.35).toColor();

      final paint = Paint()
        ..shader = Gradient.radial(
          Offset(sx, sy),
          m.radius,
          [
            color.withValues(alpha: m.alpha),
            color.withValues(alpha: 0),
          ],
        )
        ..blendMode = BlendMode.screen;
      canvas.drawCircle(Offset(sx, sy), m.radius, paint);
    }
  }
}

// ── Internal mote data ───────────────────────────────────────────────────────

class _Mote {
  _Mote({
    required this.base,
    required this.radius,
    required this.alpha,
    required this.parallax,
    required this.drift,
    required this.hue,
  });

  final Vector2 base;
  final double radius;
  final double alpha;
  final double parallax;
  final Vector2 drift;
  final double hue;
}
