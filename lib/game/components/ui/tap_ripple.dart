/// A short-lived expanding ring that appears at the point the player
/// taps / clicks, giving soft visual feedback for movement targets.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../config/game_config.dart';

class TapRipple extends PositionComponent {
  TapRipple({required super.position})
      : super(
          size: Vector2.all(GameConfig.rippleMaxRadius * 2),
          anchor: Anchor.center,
          priority: 2,
        );

  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_time >= GameConfig.rippleDuration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_time / GameConfig.rippleDuration).clamp(0.0, 1.0);

    // Ease-out expansion: fast start, gentle finish
    final easedT = 1 - pow(1 - t, 3).toDouble();
    final radius = GameConfig.rippleMaxRadius * easedT;

    // Fade out with a smooth curve
    final alpha = (1.0 - t) * (1.0 - t); // quadratic fade

    if (alpha < 0.01) return;

    final center = Offset(size.x / 2, size.y / 2);

    // Soft filled glow
    final fillPaint = Paint()
      ..shader = Gradient.radial(
        center,
        radius,
        [
          GameConfig.rippleColor.withValues(alpha: alpha * 0.3),
          GameConfig.rippleColor.withValues(alpha: 0),
        ],
      )
      ..blendMode = BlendMode.plus;
    canvas.drawCircle(center, radius, fillPaint);

    // Thin bright ring at the edge
    final ringPaint = Paint()
      ..color = GameConfig.rippleColor.withValues(alpha: alpha * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..blendMode = BlendMode.plus;
    canvas.drawCircle(center, radius * 0.85, ringPaint);
  }
}
