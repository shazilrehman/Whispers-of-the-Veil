/// Ground glow patches and crystalline formations for the Second Veil.
///
/// Visually distinct from the First Veil — uses cooler indigo/teal hues,
/// taller crystal formations, and slightly larger glow patches to create
/// a deeper, more mysterious atmosphere.
library;

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' hide Gradient;

import '../../../config/game_config.dart';

class SecondVeilGlow extends Component {
  final List<_Patch> _patches = [];
  final List<_Crystal> _crystals = [];
  final Random _rng = Random();
  double _time = 0;

  // Cooler palette — indigo, teal, cerulean, frost
  static const _patchHues = [210.0, 190.0, 170.0, 230.0, 200.0, 185.0];
  static const _crystalHues = [200.0, 180.0, 215.0, 195.0, 225.0];

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _generatePatches();
    _generateCrystals();
  }

  void _generatePatches() {
    final w = GameConfig.secondVeilWidth;
    final h = GameConfig.secondVeilHeight;
    final margin = 120.0;

    for (int i = 0; i < GameConfig.svGroundGlowCount; i++) {
      _patches.add(_Patch(
        pos: Offset(
          margin + _rng.nextDouble() * (w - margin * 2),
          margin + _rng.nextDouble() * (h - margin * 2),
        ),
        radius: GameConfig.svGroundGlowMinRadius +
            _rng.nextDouble() *
                (GameConfig.svGroundGlowMaxRadius -
                    GameConfig.svGroundGlowMinRadius),
        hue: _patchHues[i % _patchHues.length],
        pulsePhase: _rng.nextDouble() * 2 * pi,
      ));
    }
  }

  void _generateCrystals() {
    final w = GameConfig.secondVeilWidth;
    final h = GameConfig.secondVeilHeight;
    final margin = 100.0;

    for (int i = 0; i < GameConfig.svCrystalCount; i++) {
      final height = GameConfig.svCrystalMinHeight +
          _rng.nextDouble() *
              (GameConfig.svCrystalMaxHeight - GameConfig.svCrystalMinHeight);
      _crystals.add(_Crystal(
        x: margin + _rng.nextDouble() * (w - margin * 2),
        y: margin + _rng.nextDouble() * (h - margin * 2),
        height: height,
        width: height * (0.15 + _rng.nextDouble() * 0.12),
        hue: _crystalHues[i % _crystalHues.length],
        pulsePhase: _rng.nextDouble() * 2 * pi,
        tilt: (_rng.nextDouble() - 0.5) * 0.25, // slight lean
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    _renderPatches(canvas);
    _renderCrystals(canvas);
  }

  void _renderPatches(Canvas canvas) {
    for (final p in _patches) {
      final pulse = 0.7 + 0.3 * sin(_time * 0.6 + p.pulsePhase);
      final alpha = GameConfig.svGroundGlowAlpha * pulse;
      final color = HSLColor.fromAHSL(1, p.hue, 0.45, 0.35).toColor();

      canvas.drawCircle(
        p.pos,
        p.radius,
        Paint()
          ..shader = Gradient.radial(p.pos, p.radius, [
            color.withValues(alpha: alpha),
            color.withValues(alpha: alpha * 0.3),
            color.withValues(alpha: 0),
          ], [
            0.0,
            0.5,
            1.0,
          ])
          ..blendMode = BlendMode.screen,
      );
    }
  }

  void _renderCrystals(Canvas canvas) {
    for (final c in _crystals) {
      final pulse = 0.75 + 0.25 * sin(_time * 1.0 + c.pulsePhase);
      final alpha = GameConfig.svCrystalAlpha * pulse;
      final color = HSLColor.fromAHSL(1, c.hue, 0.50, 0.50).toColor();

      canvas.save();
      canvas.translate(c.x, c.y);
      // Slight tilt for variety
      canvas.transform(Float64List.fromList([
        1, 0, 0, 0,
        c.tilt, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
      ]));

      // Elongated diamond — taller and narrower than First Veil
      final path = Path()
        ..moveTo(0, -c.height) // top
        ..lineTo(c.width * 0.5, -c.height * 0.1) // right upper
        ..lineTo(c.width * 0.35, c.height * 0.15) // right lower
        ..lineTo(0, c.height * 0.25) // bottom
        ..lineTo(-c.width * 0.35, c.height * 0.15) // left lower
        ..lineTo(-c.width * 0.5, -c.height * 0.1) // left upper
        ..close();

      // Inner fill
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.3)
          ..blendMode = BlendMode.plus,
      );

      // Edge glow
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..blendMode = BlendMode.plus,
      );

      // Glow behind
      final center = Offset(0, -c.height * 0.3);
      canvas.drawCircle(
        center,
        c.height * 0.9,
        Paint()
          ..shader = Gradient.radial(center, c.height * 0.9, [
            color.withValues(alpha: alpha * 0.18),
            color.withValues(alpha: 0),
          ])
          ..blendMode = BlendMode.plus,
      );

      canvas.restore();
    }
  }
}

class _Patch {
  _Patch({
    required this.pos,
    required this.radius,
    required this.hue,
    required this.pulsePhase,
  });
  final Offset pos;
  final double radius, hue, pulsePhase;
}

class _Crystal {
  _Crystal({
    required this.x,
    required this.y,
    required this.height,
    required this.width,
    required this.hue,
    required this.pulsePhase,
    required this.tilt,
  });
  final double x, y, height, width, hue, pulsePhase, tilt;
}
