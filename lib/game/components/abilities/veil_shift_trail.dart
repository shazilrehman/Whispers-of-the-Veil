/// Visual trail effect for the Veil Shift ability.
///
/// Renders a line of fading dots from [start] to [end] plus a soft
/// burst at the destination. Added to the world and self-removes
/// after the animation completes.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../config/game_config.dart';

class VeilShiftTrail extends Component {
  VeilShiftTrail({required this.start, required this.end});

  final Vector2 start;
  final Vector2 end;
  double _time = 0;

  @override
  void onMount() {
    super.onMount();
    priority = 4;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_time >= GameConfig.veilShiftTrailDuration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final dur = GameConfig.veilShiftTrailDuration;
    final t = (_time / dur).clamp(0.0, 1.0);
    final fadeAlpha = pow(1 - t, 2).toDouble();
    final color = GameConfig.veilShiftColor;
    final dx = end.x - start.x;
    final dy = end.y - start.y;

    // ── Trail dots ─────────────────────────────────────────────────────
    for (int i = 0; i < 15; i++) {
      final f = i / 14.0;
      final px = start.x + dx * f;
      final py = start.y + dy * f;
      final dotAlpha = (fadeAlpha * (1.0 - f * 0.3)).clamp(0.0, 1.0);
      if (dotAlpha < 0.01) continue;

      final r = 2.5 * (1 - f * 0.4);
      final pos = Offset(px, py);

      // Glow halo
      canvas.drawCircle(
        pos,
        r * 5,
        Paint()
          ..shader = Gradient.radial(pos, r * 5, [
            color.withValues(alpha: dotAlpha * 0.12),
            color.withValues(alpha: 0),
          ])
          ..blendMode = BlendMode.plus,
      );

      // Core dot
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..color = color.withValues(alpha: dotAlpha * 0.65)
          ..blendMode = BlendMode.plus,
      );
    }

    // ── Destination burst ──────────────────────────────────────────────
    if (t < 0.55) {
      final bT = t / 0.55;
      final bR = 40 * bT;
      final bAlpha = (1 - bT) * 0.35;
      final ep = Offset(end.x, end.y);

      canvas.drawCircle(
        ep,
        bR,
        Paint()
          ..shader = Gradient.radial(ep, bR, [
            color.withValues(alpha: bAlpha * 0.5),
            color.withValues(alpha: 0),
          ])
          ..blendMode = BlendMode.plus,
      );

      // Bright core at destination
      if (bT < 0.3) {
        canvas.drawCircle(
          ep,
          8 * (1 - bT / 0.3),
          Paint()
            ..color = color.withValues(alpha: (1 - bT / 0.3) * 0.7)
            ..blendMode = BlendMode.plus,
        );
      }
    }
  }
}
