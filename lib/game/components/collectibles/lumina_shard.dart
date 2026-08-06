/// A collectible Lumina Shard that floats near a bloom node after
/// its first awakening. The player picks it up via proximity.
///
/// On collection the shard brightens, scales up, and fades out before
/// removing itself and notifying the game.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../config/game_config.dart';

class LuminaShard extends PositionComponent {
  LuminaShard({
    required super.position,
    required this.target,
    required this.onCollected,
  });

  /// The player spirit — used for proximity pickup.
  final PositionComponent target;

  /// Called once when this shard is collected.
  final void Function() onCollected;

  double _time = 0;
  double _bobOffset = 0;
  bool _collecting = false;
  double _collectTimer = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(GameConfig.shardRadius * 12);
    anchor = Anchor.center;
    priority = 2;
    // Random starting phase so grouped shards don't bob in sync
    _time = Random().nextDouble() * 4;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // ── Collection animation ────────────────────────────────────────────
    if (_collecting) {
      _collectTimer += dt;
      if (_collectTimer >= GameConfig.shardCollectDuration) {
        removeFromParent();
      }
      return;
    }

    // ── Idle bob ────────────────────────────────────────────────────────
    _bobOffset =
        sin(_time * GameConfig.shardBobSpeed) * GameConfig.shardBobAmplitude;

    // ── Proximity pickup ────────────────────────────────────────────────
    if (position.distanceTo(target.position) < GameConfig.shardPickupRadius) {
      _collecting = true;
      onCollected();
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2 + _bobOffset;
    final center = Offset(cx, cy);

    // Collection animation multipliers
    double scale = 1.0;
    double alpha = 1.0;
    if (_collecting) {
      final t =
          (_collectTimer / GameConfig.shardCollectDuration).clamp(0.0, 1.0);
      scale = 1 + t * 2.5; // expand
      alpha = 1 - t; // fade
    }

    final pulse = 0.8 + 0.2 * sin(_time * 3);
    final r = GameConfig.shardRadius * scale;

    // 1) Outer glow halo
    _glow(canvas, center, r * 5 * pulse, GameConfig.shardGlow,
        alpha * 0.18 * pulse);

    // 2) Mid glow
    _glow(canvas, center, r * 2.5, GameConfig.shardGlow,
        alpha * 0.35 * pulse);

    // 3) Inner glow
    _glow(canvas, center, r * 1.3, GameConfig.shardCore,
        alpha * 0.6 * pulse);

    // 4) Diamond shape (rotated square)
    final path = Path()
      ..moveTo(cx, cy - r) // top
      ..lineTo(cx + r * 0.55, cy) // right
      ..lineTo(cx, cy + r) // bottom
      ..lineTo(cx - r * 0.55, cy) // left
      ..close();

    // Fill
    canvas.drawPath(
      path,
      Paint()
        ..color = GameConfig.shardCore.withValues(alpha: alpha * 0.7 * pulse)
        ..blendMode = BlendMode.plus,
    );

    // Edge stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = GameConfig.shardCore.withValues(alpha: alpha * 0.4 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..blendMode = BlendMode.plus,
    );

    // 5) Bright core dot
    canvas.drawCircle(
      center,
      r * 0.2,
      Paint()
        ..color = GameConfig.shardCore.withValues(alpha: alpha * 0.9 * pulse)
        ..blendMode = BlendMode.plus,
    );
  }

  void _glow(Canvas c, Offset at, double r, Color color, double a) {
    if (a < 0.005 || r < 0.5) return;
    c.drawCircle(
      at,
      r,
      Paint()
        ..shader = Gradient.radial(
          at,
          r,
          [color.withValues(alpha: a), color.withValues(alpha: 0)],
        )
        ..blendMode = BlendMode.plus,
    );
  }
}
