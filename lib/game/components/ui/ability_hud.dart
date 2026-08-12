/// HUD element for both player abilities (Bloom Pulse + Veil Shift).
///
/// Shows soft buttons at the bottom-center of the screen with radial
/// cooldown indicators. Displays an unlock notification when either
/// ability is first granted.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' hide Gradient;

import '../../config/game_config.dart';

class AbilityHud extends Component with HasGameReference {
  // ── Bloom Pulse state ──────────────────────────────────────────────────
  bool _bloomUnlocked = false;
  double _bloomCooldown = 0;

  // ── Veil Shift state ───────────────────────────────────────────────────
  bool _shiftUnlocked = false;
  double _shiftCooldown = 0;

  // ── Notification ───────────────────────────────────────────────────────
  double _notifyTimer = -1;
  TextPainter? _notifyPainter;
  Color _notifyColor = GameConfig.bloomPulseColor;
  double _time = 0;

  // ── Accessors ──────────────────────────────────────────────────────────
  bool get isBloomUnlocked => _bloomUnlocked;
  bool get isShiftUnlocked => _shiftUnlocked;

  int get _count => (_bloomUnlocked ? 1 : 0) + (_shiftUnlocked ? 1 : 0);

  // ── Unlock ─────────────────────────────────────────────────────────────

  void unlockBloom({bool showNotification = true}) {
    _bloomUnlocked = true;
    if (showNotification) {
      _showNotify('✦  Bloom Pulse Awakened  ✦', GameConfig.bloomPulseColor);
    }
  }

  void unlockShift({bool showNotification = true}) {
    _shiftUnlocked = true;
    if (showNotification) {
      _showNotify('✦  Veil Shift Awakened  ✦', GameConfig.veilShiftColor);
    }
  }

  void _showNotify(String text, Color color) {
    _notifyTimer = 0;
    _notifyColor = color;
    _notifyPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.w300,
          letterSpacing: 3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  // ── Cooldown updates ───────────────────────────────────────────────────

  void updateBloomCooldown(double fraction) =>
      _bloomCooldown = fraction.clamp(0.0, 1.0);

  void updateShiftCooldown(double fraction) =>
      _shiftCooldown = fraction.clamp(0.0, 1.0);

  // ── Hit testing ────────────────────────────────────────────────────────

  bool isBloomButtonAt(Vector2 canvasPos) {
    if (!_bloomUnlocked) return false;
    return canvasPos.distanceTo(Vector2(_bloomBtnX, _btnY)) <
        GameConfig.abilityBtnRadius + 12;
  }

  bool isShiftButtonAt(Vector2 canvasPos) {
    if (!_shiftUnlocked) return false;
    return canvasPos.distanceTo(Vector2(_shiftBtnX, _btnY)) <
        GameConfig.abilityBtnRadius + 12;
  }

  // ── Button positions ───────────────────────────────────────────────────

  double get _btnY => game.size.y - 52;

  double get _bloomBtnX {
    if (_count <= 1) return game.size.x / 2;
    return game.size.x / 2 - 34;
  }

  double get _shiftBtnX {
    if (_count <= 1) return game.size.x / 2;
    return game.size.x / 2 + 34;
  }

  // ── Update ─────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    if (_notifyTimer >= 0) {
      _notifyTimer += dt;
      final total = GameConfig.notifyFadeIn +
          GameConfig.notifyHold +
          GameConfig.notifyFadeOut;
      if (_notifyTimer > total) _notifyTimer = -1;
    }
  }

  // ── Render ─────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    if (_bloomUnlocked) {
      _renderButton(
        canvas,
        _bloomBtnX,
        _btnY,
        GameConfig.bloomPulseColor,
        _bloomCooldown,
      );
    }
    if (_shiftUnlocked) {
      _renderButton(
        canvas,
        _shiftBtnX,
        _btnY,
        GameConfig.veilShiftColor,
        _shiftCooldown,
      );
    }
    if (_notifyTimer >= 0) _renderNotification(canvas);
  }

  // ── Shared button renderer ─────────────────────────────────────────────

  void _renderButton(
    Canvas canvas,
    double bx,
    double by,
    Color color,
    double cooldown,
  ) {
    final r = GameConfig.abilityBtnRadius;
    final center = Offset(bx, by);
    final ready = cooldown <= 0;
    final baseAlpha = ready ? 0.8 : 0.25;
    final pulse = ready ? (0.8 + 0.2 * sin(_time * 2.5)) : 1.0;

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

    // Cooldown arc
    if (cooldown > 0) {
      final sweep = 2 * pi * (1 - cooldown);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -pi / 2,
        sweep,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..blendMode = BlendMode.plus,
      );
    } else {
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
          _notifyColor.withValues(alpha: alpha * 0.15),
          _notifyColor.withValues(alpha: 0),
        ])
        ..blendMode = BlendMode.plus,
    );

    // Text with alpha
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
