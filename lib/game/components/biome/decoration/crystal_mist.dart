/// Drifting translucent mist patches unique to the Second Veil.
///
/// Large, slow-moving elliptical clouds that give the biome a deeper,
/// more mysterious atmosphere compared to the First Veil.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' hide Gradient;

import '../../../config/game_config.dart';

class CrystalMist extends Component {
  CrystalMist({
    required this.areaWidth,
    required this.areaHeight,
  });

  final double areaWidth;
  final double areaHeight;

  final List<_MistCloud> _clouds = [];
  final Random _rng = Random();
  double _time = 0;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _generate();
  }

  void _generate() {
    final margin = 80.0;
    for (int i = 0; i < GameConfig.svMistCount; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      _clouds.add(_MistCloud(
        pos: Offset(
          margin + _rng.nextDouble() * (areaWidth - margin * 2),
          margin + _rng.nextDouble() * (areaHeight - margin * 2),
        ),
        vel: Offset(
          cos(angle) * GameConfig.svMistDriftSpeed *
              (0.3 + _rng.nextDouble() * 0.7),
          sin(angle) * GameConfig.svMistDriftSpeed *
              (0.3 + _rng.nextDouble() * 0.7),
        ),
        radius: GameConfig.svMistMinRadius +
            _rng.nextDouble() *
                (GameConfig.svMistMaxRadius - GameConfig.svMistMinRadius),
        stretch: 1.2 + _rng.nextDouble() * 0.8, // horizontal stretch
        pulsePhase: _rng.nextDouble() * 2 * pi,
        hue: 195 + _rng.nextDouble() * 40, // teal to indigo range
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    for (final c in _clouds) {
      c.pos = Offset(
        c.pos.dx + c.vel.dx * dt,
        c.pos.dy + c.vel.dy * dt,
      );

      // Soft wrap
      if (c.pos.dx < -c.radius) {
        c.pos = Offset(c.pos.dx + areaWidth + c.radius * 2, c.pos.dy);
      }
      if (c.pos.dx > areaWidth + c.radius) {
        c.pos = Offset(c.pos.dx - areaWidth - c.radius * 2, c.pos.dy);
      }
      if (c.pos.dy < -c.radius) {
        c.pos = Offset(c.pos.dx, c.pos.dy + areaHeight + c.radius * 2);
      }
      if (c.pos.dy > areaHeight + c.radius) {
        c.pos = Offset(c.pos.dx, c.pos.dy - areaHeight - c.radius * 2);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    for (final c in _clouds) {
      final pulse = 0.6 + 0.4 * sin(_time * 0.5 + c.pulsePhase);
      final alpha = GameConfig.svMistAlpha * pulse;
      final color = HSLColor.fromAHSL(1, c.hue, 0.35, 0.4).toColor();

      canvas.save();
      canvas.translate(c.pos.dx, c.pos.dy);
      canvas.scale(c.stretch, 1.0);

      canvas.drawCircle(
        Offset.zero,
        c.radius,
        Paint()
          ..shader = Gradient.radial(
            Offset.zero,
            c.radius,
            [
              color.withValues(alpha: alpha),
              color.withValues(alpha: alpha * 0.3),
              color.withValues(alpha: 0),
            ],
            [0.0, 0.5, 1.0],
          )
          ..blendMode = BlendMode.screen,
      );

      canvas.restore();
    }
  }
}

class _MistCloud {
  _MistCloud({
    required this.pos,
    required this.vel,
    required this.radius,
    required this.stretch,
    required this.pulsePhase,
    required this.hue,
  });

  Offset pos;
  final Offset vel;
  final double radius;
  final double stretch;
  final double pulsePhase;
  final double hue;
}
