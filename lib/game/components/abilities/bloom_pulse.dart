/// Visual effect for the Bloom Pulse ability — an expanding ring of
/// light that emanates from the player and awakens nearby bloom nodes
/// as it reaches them.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../config/game_config.dart';

class BloomPulse extends PositionComponent {
  BloomPulse({
    required super.position,
    this.onPulseExpand,
  });

  /// Called each frame with (center, currentRadius) so the game can
  /// awaken bloom nodes as the wave passes through them.
  final void Function(Vector2 center, double radius)? onPulseExpand;

  double _time = 0;
  double _currentRadius = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(GameConfig.bloomPulseRadius * 2.5);
    anchor = Anchor.center;
    priority = 5;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    final t = (_time / GameConfig.bloomPulseDuration).clamp(0.0, 1.0);
    // Ease-out curve for natural deceleration
    _currentRadius = GameConfig.bloomPulseRadius * (1 - pow(1 - t, 2));

    onPulseExpand?.call(position, _currentRadius);

    if (_time >= GameConfig.bloomPulseDuration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_time / GameConfig.bloomPulseDuration).clamp(0.0, 1.0);
    final alpha = pow(1 - t, 2).toDouble(); // fade as it expands
    final r = _currentRadius;
    final center = Offset(size.x / 2, size.y / 2);
    final color = GameConfig.bloomPulseColor;

    // 1) Filled inner glow
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = Gradient.radial(
          center,
          r,
          [
            color.withValues(alpha: alpha * 0.08),
            color.withValues(alpha: alpha * 0.02),
            color.withValues(alpha: 0),
          ],
          [0.0, 0.6, 1.0],
        )
        ..blendMode = BlendMode.plus,
    );

    // 2) Main ring
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = color.withValues(alpha: alpha * 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..blendMode = BlendMode.plus,
    );

    // 3) Inner echo ring
    if (r > 20) {
      canvas.drawCircle(
        center,
        r * 0.6,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..blendMode = BlendMode.plus,
      );
    }

    // 4) Bright core flash (only at start)
    if (t < 0.3) {
      final coreAlpha = (1 - t / 0.3) * 0.6;
      canvas.drawCircle(
        center,
        15 * (1 - t / 0.3),
        Paint()
          ..shader = Gradient.radial(
            center,
            15,
            [
              color.withValues(alpha: coreAlpha),
              color.withValues(alpha: 0),
            ],
          )
          ..blendMode = BlendMode.plus,
      );
    }
  }
}
