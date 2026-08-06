/// HUD element for the Bloom Pulse ability.
///
/// Shows a soft button at the bottom-center when unlocked, with a
/// radial cooldown indicator. Displays an unlock notification the
/// first time the ability is granted.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' hide Gradient;

import '../../config/game_config.dart';

class AbilityHud extends Component with HasGameReference {
  bool _unlocked = false;
  double _cooldownFraction = 0; // 0 = ready, 1 = full cooldown
  double _notifyTimer = -1; // ≥ 0 means notification is active
  double _time = 0;

  TextPainter? _notifyPainter;

  bool get isUnlocked => _unlocked;

  /// Unlock the ability, optionally showing a notification.
  void unlock({bool showNotification = true}) {
    _unlocked = true;
    if (showNotification) {
      _notifyTimer = 0;
      _notifyPainter = TextPainter(
        text: TextSpan(
          text: '✦  Bloom Pulse Awakened  ✦',
          style: TextStyle(
            color: GameConfig.bloomPulseColor,
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 3,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
  }

  /// Update the cooldown progress (0 = ready, 1 = just fired).
  void updateCooldown(double fraction) {
    _cooldownFraction = fraction.clamp(0.0, 1.0);
  }

  /// Returns true if [canvasPos] hits the ability button area.
  bool isButtonAt(Vector2 canvasPos) {
    if (!_unlocked) return false;
    final bx = game.size.x / 2;
    final by = game.size.y - 52;
    return canvasPos.distanceTo(Vector2(bx, by)) <
        GameConfig.abilityBtnRadius + 12;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Tick notification
    if (_notifyTimer >= 0) {
      _notifyTimer += dt;
      final total = GameConfig.notifyFadeIn +
          GameConfig.notifyHold +
          GameConfig.notifyFadeOut;
      if (_notifyTimer > total) _notifyTimer = -1;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_unlocked) return;
    _renderButton(canvas);
    if (_notifyTimer >= 0) _renderNotification(canvas);
  }

  // ── Button ──────────────────────────────────────────────────────────────

  void _renderButton(Canvas canvas) {
    final bx = game.size.x / 2;
    final by = game.size.y - 52;
    final r = GameConfig.abilityBtnRadius;
    final center = Offset(bx, by);
    final ready = _cooldownFraction <= 0;
    final baseAlpha = ready ? 0.8 : 0.25;
    final pulse = ready ? (0.8 + 0.2 * sin(_time * 2.5)) : 1.0;
    final color = GameConfig.bloomPulseColor;

    // Background glow
    canvas.drawCircle(
      center,
      r * 2.5,
      Paint()
        ..shader = Gradient.radial(center, r * 2.5, [
          color.withValues(alpha: baseAlpha * 0.15 * pulse),
          color.withValues(alpha: 0),
        ])
        ..blendMode = BlendMode.plus,
    );

    // Outer ring (dim)
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = color.withValues(alpha: baseAlpha * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..blendMode = BlendMode.plus,
    );

    // Cooldown arc — fills clockwise as cooldown recovers
    if (_cooldownFraction > 0) {
      final sweep = 2 * pi * (1 - _cooldownFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -pi / 2, // start top
        sweep,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..blendMode = BlendMode.plus,
      );
    } else {
      // Full ring when ready
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = color.withValues(alpha: baseAlpha * 0.6 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..blendMode = BlendMode.plus,
      );
    }

    // Center diamond icon
    final ir = r * 0.35;
    final icon = Path()
      ..moveTo(bx, by - ir)
      ..lineTo(bx + ir * 0.6, by)
      ..lineTo(bx, by + ir)
      ..lineTo(bx - ir * 0.6, by)
      ..close();

    canvas.drawPath(
      icon,
      Paint()
        ..color = color.withValues(alpha: baseAlpha * pulse)
        ..blendMode = BlendMode.plus,
    );
  }

  // ── Notification ───────────────────────────────────────────────────────

  void _renderNotification(Canvas canvas) {
    if (_notifyPainter == null) return;

    final t = _notifyTimer;
    final fi = GameConfig.notifyFadeIn;
    final hold = GameConfig.notifyHold;
    final fo = GameConfig.notifyFadeOut;

    double alpha;
    if (t < fi) {
      alpha = t / fi;
    } else if (t < fi + hold) {
      alpha = 1.0;
    } else {
      alpha = 1.0 - ((t - fi - hold) / fo).clamp(0.0, 1.0);
    }
    if (alpha < 0.01) return;

    final cx = game.size.x / 2;
    final cy = game.size.y * 0.25;

    // Glow behind text
    canvas.drawCircle(
      Offset(cx, cy),
      80,
      Paint()
        ..shader = Gradient.radial(Offset(cx, cy), 80, [
          GameConfig.bloomPulseColor.withValues(alpha: alpha * 0.15),
          GameConfig.bloomPulseColor.withValues(alpha: 0),
        ])
        ..blendMode = BlendMode.plus,
    );

    // Text with current alpha
    final dx = cx - _notifyPainter!.width / 2;
    final dy = cy - _notifyPainter!.height / 2;

    canvas.saveLayer(
      Rect.fromLTWH(dx - 10, dy - 10, _notifyPainter!.width + 20,
          _notifyPainter!.height + 20),
      Paint()..color = Color.fromRGBO(0, 0, 0, alpha),
    );
    _notifyPainter!.paint(canvas, Offset(dx, dy));
    canvas.restore();
  }
}
