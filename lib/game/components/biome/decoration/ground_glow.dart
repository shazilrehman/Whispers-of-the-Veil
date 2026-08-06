/// Static environmental decorations: soft ground glow patches and
/// faint crystalline formations scattered across the biome.
///
/// These are non-interactive visual elements that fill the space
/// between bloom nodes and make the world feel more alive.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' hide Gradient;

import '../../../config/game_config.dart';

class GroundGlow extends Component {
  final List<_Patch> _patches = [];
  final List<_Crystal> _crystals = [];
  final Random _rng = Random();
  double _time = 0;

  static const _patchHues = [265.0, 220.0, 180.0, 290.0, 200.0];
  static const _crystalHues = [260.0, 210.0, 240.0, 280.0];

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _generatePatches();
    _generateCrystals();
  }

  // ── Generate ground glow patches ───────────────────────────────────────
  void _generatePatches() {
    final w = GameConfig.biomeWidth;
    final h = GameConfig.biomeHeight;
    final margin = 120.0;

    for (int i = 0; i < GameConfig.groundGlowCount; i++) {
      _patches.add(_Patch(
        pos: Offset(
          margin + _rng.nextDouble() * (w - margin * 2),
          margin + _rng.nextDouble() * (h - margin * 2),
        ),
        radius: GameConfig.groundGlowMinRadius +
            _rng.nextDouble() *
                (GameConfig.groundGlowMaxRadius -
                    GameConfig.groundGlowMinRadius),
        hue: _patchHues[i % _patchHues.length],
        pulsePhase: _rng.nextDouble() * 2 * pi,
      ));
    }
  }

  // ── Generate crystal formations ────────────────────────────────────────
  void _generateCrystals() {
    final w = GameConfig.biomeWidth;
    final h = GameConfig.biomeHeight;
    final margin = 100.0;

    for (int i = 0; i < GameConfig.crystalCount; i++) {
      final height = GameConfig.crystalMinHeight +
          _rng.nextDouble() *
              (GameConfig.crystalMaxHeight - GameConfig.crystalMinHeight);
      _crystals.add(_Crystal(
        x: margin + _rng.nextDouble() * (w - margin * 2),
        y: margin + _rng.nextDouble() * (h - margin * 2),
        height: height,
        width: height * (0.2 + _rng.nextDouble() * 0.15),
        hue: _crystalHues[i % _crystalHues.length],
        pulsePhase: _rng.nextDouble() * 2 * pi,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  // ── Render ──────────────────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    _renderPatches(canvas);
    _renderCrystals(canvas);
  }

  void _renderPatches(Canvas canvas) {
    for (final p in _patches) {
      final pulse = 0.7 + 0.3 * sin(_time * 0.8 + p.pulsePhase);
      final alpha = GameConfig.groundGlowAlpha * pulse;
      final color =
          HSLColor.fromAHSL(1, p.hue, 0.5, 0.35).toColor();

      canvas.drawCircle(
        p.pos,
        p.radius,
        Paint()
          ..shader = Gradient.radial(
            p.pos,
            p.radius,
            [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          )
          ..blendMode = BlendMode.screen,
      );
    }
  }

  void _renderCrystals(Canvas canvas) {
    for (final c in _crystals) {
      final pulse = 0.75 + 0.25 * sin(_time * 1.2 + c.pulsePhase);
      final alpha = GameConfig.crystalAlpha * pulse;
      final color =
          HSLColor.fromAHSL(1, c.hue, 0.55, 0.5).toColor();

      // Diamond path
      final path = Path()
        ..moveTo(c.x, c.y - c.height) // top
        ..lineTo(c.x + c.width * 0.5, c.y) // right
        ..lineTo(c.x, c.y + c.height * 0.2) // bottom (short)
        ..lineTo(c.x - c.width * 0.5, c.y) // left
        ..close();

      // Fill
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.35)
          ..blendMode = BlendMode.plus,
      );

      // Stroke
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..blendMode = BlendMode.plus,
      );

      // Glow behind crystal
      final center = Offset(c.x, c.y - c.height * 0.3);
      canvas.drawCircle(
        center,
        c.height * 0.8,
        Paint()
          ..shader = Gradient.radial(
            center,
            c.height * 0.8,
            [
              color.withValues(alpha: alpha * 0.2),
              color.withValues(alpha: 0),
            ],
          )
          ..blendMode = BlendMode.plus,
      );
    }
  }
}

// ── Data classes ─────────────────────────────────────────────────────────────

class _Patch {
  _Patch({
    required this.pos,
    required this.radius,
    required this.hue,
    required this.pulsePhase,
  });

  final Offset pos;
  final double radius;
  final double hue;
  final double pulsePhase;
}

class _Crystal {
  _Crystal({
    required this.x,
    required this.y,
    required this.height,
    required this.width,
    required this.hue,
    required this.pulsePhase,
  });

  final double x, y, height, width, hue, pulsePhase;
}
