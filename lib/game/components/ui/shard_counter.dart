/// A minimal HUD element that displays the collected Lumina Shard count
/// in the top-left corner. Shows a small glowing diamond icon + number.
/// Pulses briefly when a new shard is collected.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' hide Gradient;

import '../../config/game_config.dart';

class ShardCounter extends PositionComponent {
  ShardCounter()
      : super(
          position: Vector2(
            GameConfig.shardHudPadding,
            GameConfig.shardHudPadding,
          ),
          size: Vector2(100, 30),
          priority: 10,
        );

  int _count = 0;
  double _pulseTimer = 0;
  TextPainter? _textPainter;

  /// Call this when the shard count changes.
  void updateCount(int count) {
    if (count == _count) return;
    _count = count;
    _pulseTimer = GameConfig.shardHudPulseDuration;
    _rebuildText();
  }

  void _rebuildText() {
    _textPainter = TextPainter(
      text: TextSpan(
        text: '× $_count',
        style: TextStyle(
          color: GameConfig.shardHudColor.withValues(alpha: 0.85),
          fontSize: GameConfig.shardHudFontSize,
          fontWeight: FontWeight.w300,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _rebuildText();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_pulseTimer > 0) _pulseTimer -= dt;
  }

  @override
  void render(Canvas canvas) {
    final r = GameConfig.shardIconRadius;
    final pulse = _pulseTimer > 0
        ? 1.0 +
            0.4 *
                sin((_pulseTimer / GameConfig.shardHudPulseDuration) * pi)
        : 1.0;

    final iconCx = r + 2;
    final iconCy = size.y / 2;
    final sr = r * pulse;

    // Icon glow
    canvas.drawCircle(
      Offset(iconCx, iconCy),
      sr * 3,
      Paint()
        ..shader = Gradient.radial(
          Offset(iconCx, iconCy),
          sr * 3,
          [
            GameConfig.shardGlow.withValues(alpha: 0.15 * pulse),
            GameConfig.shardGlow.withValues(alpha: 0),
          ],
        )
        ..blendMode = BlendMode.plus,
    );

    // Diamond icon
    final iconPath = Path()
      ..moveTo(iconCx, iconCy - sr) // top
      ..lineTo(iconCx + sr * 0.55, iconCy) // right
      ..lineTo(iconCx, iconCy + sr) // bottom
      ..lineTo(iconCx - sr * 0.55, iconCy) // left
      ..close();

    canvas.drawPath(
      iconPath,
      Paint()
        ..color = GameConfig.shardCore.withValues(alpha: 0.8 * pulse)
        ..blendMode = BlendMode.plus,
    );
    canvas.drawPath(
      iconPath,
      Paint()
        ..color = GameConfig.shardCore.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..blendMode = BlendMode.plus,
    );

    // Count text
    _textPainter?.paint(
      canvas,
      Offset(iconCx + r + 8, iconCy - (_textPainter!.height / 2)),
    );
  }
}
