/// The player's luminous spirit — a soft glowing orb controlled via
/// drag-to-move / tap-to-move input, with Veil Shift dash support.
///
/// Renders a multi-layer radial bloom (halo → outer → mid → inner → core)
/// and gently bobs when idle.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../config/game_config.dart';

class SpiritPlayer extends PositionComponent {
  SpiritPlayer({required super.position, this.worldBounds});

  /// World position the spirit is smoothly gliding toward.
  Vector2? _target;
  double _time = 0;
  double _bobOffset = 0;
  bool _isMoving = false;

  /// Optional bounding rectangle (in world coordinates) the spirit
  /// is confined to. Mutable so veil transitions can update bounds.
  Rect? worldBounds;

  // ── Veil Shift dash ──────────────────────────────────────────────────
  bool _isDashing = false;
  Vector2? _dashStart;
  Vector2? _dashEnd;
  double _dashTimer = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Size must be large enough to contain the outermost halo render.
    size = Vector2.all(GameConfig.playerRadius * 14);
    anchor = Anchor.center;
    priority = 1; // render above aura particles
  }

  /// Set a new movement target. The spirit will smoothly glide there.
  void moveTo(Vector2 worldPos) {
    if (_isDashing) return; // ignore input during dash
    // Clamp target to world bounds so we never aim outside the biome.
    if (worldBounds != null) {
      worldPos.x = worldPos.x.clamp(worldBounds!.left, worldBounds!.right);
      worldPos.y = worldPos.y.clamp(worldBounds!.top, worldBounds!.bottom);
    }
    _target = worldPos.clone();
    _isMoving = true;
  }

  /// Instantly dash to [target] over a short animation.
  /// Used by the Veil Shift ability.
  void dashTo(Vector2 target) {
    // Clamp to bounds
    if (worldBounds != null) {
      target.x = target.x.clamp(worldBounds!.left, worldBounds!.right);
      target.y = target.y.clamp(worldBounds!.top, worldBounds!.bottom);
    }
    _isDashing = true;
    _dashStart = position.clone();
    _dashEnd = target.clone();
    _dashTimer = 0;
  }

  // ── Update ──────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // ── Veil Shift dash animation ─────────────────────────────────────
    if (_isDashing && _dashStart != null && _dashEnd != null) {
      _dashTimer += dt;
      final t =
          (_dashTimer / GameConfig.veilShiftDashDuration).clamp(0.0, 1.0);
      // Ease-out cubic
      final eased = 1 - pow(1 - t, 3).toDouble();
      position.setFrom(
        _dashStart! + (_dashEnd! - _dashStart!) * eased,
      );
      if (t >= 1.0) {
        _isDashing = false;
        _target = position.clone();
        _isMoving = false;
      }
      // Skip normal movement during dash
    } else {
      // ── Normal smooth movement ──────────────────────────────────────
      if (_target != null) {
        final diff = _target! - position;
        if (diff.length < 0.5) {
          _isMoving = false;
          _target = null;
        } else {
          final t = (GameConfig.playerSmoothFactor * dt).clamp(0.0, 1.0);
          var dx = diff.x * t;
          var dy = diff.y * t;

          // Cap per-frame movement to prevent overshoot at large distances
          final moveLen = sqrt(dx * dx + dy * dy);
          final maxMove = GameConfig.playerMaxSpeed * dt;
          if (moveLen > maxMove) {
            final scale = maxMove / moveLen;
            dx *= scale;
            dy *= scale;
          }

          position.x += dx;
          position.y += dy;
        }
      }
    }

    // Idle bob — visual-only offset that decays when moving
    if (_isMoving || _isDashing) {
      _bobOffset *= max(0, 1 - 5 * dt);
    } else {
      _bobOffset = sin(_time * GameConfig.playerIdleBobSpeed) *
          GameConfig.playerIdleBobAmplitude;
    }

    // Hard clamp to world bounds (safety net)
    if (worldBounds != null) {
      position.x = position.x.clamp(worldBounds!.left, worldBounds!.right);
      position.y = position.y.clamp(worldBounds!.top, worldBounds!.bottom);
    }
  }

  // ── Render ──────────────────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2 + _bobOffset);
    final pulse = 0.85 + 0.15 * sin(_time * GameConfig.playerPulseSpeed);
    final r = GameConfig.playerRadius * pulse;

    // 1) Large atmospheric halo
    _drawGlow(canvas, center, r * 6, GameConfig.playerHalo, 0.15 * pulse);

    // 2) Outer glow
    _drawGlow(canvas, center, r * 3, GameConfig.playerOuter, 0.45 * pulse);

    // 3) Mid glow
    _drawGlow(canvas, center, r * 1.8, GameConfig.playerMid, 0.6 * pulse);

    // 4) Inner glow
    _drawGlow(canvas, center, r * 1.0, GameConfig.playerInner, 0.8 * pulse);

    // 5) Bright core
    final corePaint = Paint()
      ..color = GameConfig.playerCore.withValues(alpha: 0.9 * pulse)
      ..blendMode = BlendMode.plus;
    canvas.drawCircle(center, r * 0.3, corePaint);
  }

  /// Helper — draws a single radial-gradient glow layer.
  void _drawGlow(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double alpha,
  ) {
    final paint = Paint()
      ..shader = Gradient.radial(
        center,
        radius,
        [
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0),
        ],
      )
      ..blendMode = BlendMode.plus;
    canvas.drawCircle(center, radius, paint);
  }
}
