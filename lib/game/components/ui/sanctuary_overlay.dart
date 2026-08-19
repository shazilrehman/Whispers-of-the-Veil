/// The Eternal Sanctuary overlay.
///
/// Renders a small button icon at the top-right corner. When opened,
/// displays a full-screen ethereal overlay with a growing orb, shard
/// count, ability status, and dual-veil completion progress.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' hide Gradient;

import '../../config/game_config.dart';

class SanctuaryOverlay extends Component with HasGameReference {
  bool _isOpen = false;
  int _shards = 0;
  bool _bloomUnlocked = false;
  bool _shiftUnlocked = false;
  bool _veilComplete = false;
  bool _secondVeilComplete = false;
  bool _secondVeilUnlocked = false;
  int _currentVeil = 0;
  double _time = 0;

  TextPainter? _titlePainter;
  TextPainter? _shardPainter;
  TextPainter? _bloomPainter;
  TextPainter? _shiftPainter;
  TextPainter? _completionPainter;
  TextPainter? _secondCompletionPainter;
  TextPainter? _currentVeilPainter;
  TextPainter? _hintPainter;

  /// Whether the sanctuary overlay is currently visible.
  bool get isOpen => _isOpen;

  void open() => _isOpen = true;
  void close() => _isOpen = false;
  void toggle() => _isOpen = !_isOpen;

  void updateShards(int count) {
    _shards = count;
    _rebuildShardText();
  }

  void updateBloomAbility(bool unlocked) {
    _bloomUnlocked = unlocked;
    _rebuildAbilityText();
  }

  void updateShiftAbility(bool unlocked) {
    _shiftUnlocked = unlocked;
    _rebuildAbilityText();
  }

  void updateVeilComplete(bool complete) {
    _veilComplete = complete;
    _rebuildCompletionText();
  }

  void updateSecondVeilComplete(bool complete) {
    _secondVeilComplete = complete;
    _rebuildCompletionText();
  }

  void updateSecondVeilUnlocked(bool unlocked) {
    _secondVeilUnlocked = unlocked;
    _rebuildCompletionText();
  }

  void updateCurrentVeil(int veil) {
    _currentVeil = veil;
    _rebuildVeilText();
  }

  // ── Text builders ──────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _buildAllText();
  }

  void _buildAllText() {
    _titlePainter = _text(
      'ETERNAL SANCTUARY',
      GameConfig.sanctuaryCoreColor.withValues(alpha: 0.75),
      20,
      FontWeight.w300,
      letterSpacing: 6,
    );
    _rebuildShardText();
    _rebuildAbilityText();
    _rebuildCompletionText();
    _rebuildVeilText();
    _hintPainter = _text(
      'tap anywhere to close',
      const Color(0x55FFFFFF),
      12,
      FontWeight.w300,
      letterSpacing: 2,
    );
  }

  void _rebuildShardText() {
    _shardPainter = _text(
      '◇  $_shards  Lumina Shards',
      GameConfig.shardHudColor.withValues(alpha: 0.85),
      16,
      FontWeight.w400,
      letterSpacing: 1.5,
    );
  }

  void _rebuildAbilityText() {
    // Bloom Pulse
    final bStatus = _bloomUnlocked ? 'Awakened' : 'Locked';
    final bExtra = _bloomUnlocked
        ? ''
        : '  (${(GameConfig.bloomPulseThreshold - _shards).clamp(0, 99)} shards needed)';
    _bloomPainter = _text(
      '✦  Bloom Pulse: $bStatus$bExtra',
      _bloomUnlocked
          ? GameConfig.bloomPulseColor.withValues(alpha: 0.85)
          : const Color(0x66FFFFFF),
      14,
      FontWeight.w300,
      letterSpacing: 1,
    );

    // Veil Shift
    final sStatus = _shiftUnlocked ? 'Awakened' : 'Locked';
    final sExtra = _shiftUnlocked
        ? ''
        : '  (${(GameConfig.veilShiftThreshold - _shards).clamp(0, 99)} shards needed)';
    _shiftPainter = _text(
      '✦  Veil Shift: $sStatus$sExtra',
      _shiftUnlocked
          ? GameConfig.veilShiftColor.withValues(alpha: 0.85)
          : const Color(0x66FFFFFF),
      14,
      FontWeight.w300,
      letterSpacing: 1,
    );
  }

  void _rebuildCompletionText() {
    if (_veilComplete) {
      _completionPainter = _text(
        '✧  First Veil: Restored  ✧',
        GameConfig.shardCore.withValues(alpha: 0.85),
        14,
        FontWeight.w400,
        letterSpacing: 2,
      );
    } else {
      _completionPainter = null;
    }

    if (_secondVeilUnlocked) {
      if (_secondVeilComplete) {
        _secondCompletionPainter = _text(
          '✧  Second Veil: Restored  ✧',
          GameConfig.portalCoreColor.withValues(alpha: 0.85),
          14,
          FontWeight.w400,
          letterSpacing: 2,
        );
      } else {
        _secondCompletionPainter = _text(
          '◇  Second Veil: Awaiting  ◇',
          GameConfig.portalColor.withValues(alpha: 0.50),
          14,
          FontWeight.w300,
          letterSpacing: 2,
        );
      }
    } else {
      _secondCompletionPainter = null;
    }
  }

  void _rebuildVeilText() {
    final name = _currentVeil == 0 ? 'First Veil' : 'Second Veil';
    _currentVeilPainter = _text(
      '— Currently in the $name —',
      const Color(0x77FFFFFF),
      12,
      FontWeight.w300,
      letterSpacing: 1.5,
    );
  }

  TextPainter _text(
    String text,
    Color color,
    double fontSize,
    FontWeight weight, {
    double letterSpacing = 0,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: letterSpacing,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  // ── Update ──────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  // ── Hit testing ────────────────────────────────────────────────────────

  /// Returns true if [canvasPos] is within the sanctuary button area.
  bool isButtonAt(Vector2 canvasPos) {
    final bx =
        game.size.x - GameConfig.shardHudPadding - GameConfig.sanctuaryBtnSize;
    final by = GameConfig.shardHudPadding;
    final rect = Rect.fromLTWH(
      bx - 6,
      by - 6,
      GameConfig.sanctuaryBtnSize + 12,
      GameConfig.sanctuaryBtnSize + 12,
    );
    return rect.contains(Offset(canvasPos.x, canvasPos.y));
  }

  // ── Render ──────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    _renderButton(canvas);
    if (_isOpen) _renderOverlay(canvas);
  }

  void _renderButton(Canvas canvas) {
    final bx = game.size.x -
        GameConfig.shardHudPadding -
        GameConfig.sanctuaryBtnSize / 2;
    final by = GameConfig.shardHudPadding + GameConfig.sanctuaryBtnSize / 2;
    final r = GameConfig.sanctuaryBtnSize / 2;
    final center = Offset(bx, by);
    final pulse = 0.7 + 0.3 * sin(_time * 1.5);

    // Glow
    canvas.drawCircle(
      center,
      r * 2.5,
      Paint()
        ..shader = Gradient.radial(center, r * 2.5, [
          GameConfig.sanctuaryColor.withValues(alpha: 0.1 * pulse),
          GameConfig.sanctuaryColor.withValues(alpha: 0),
        ])
        ..blendMode = BlendMode.plus,
    );

    // 4-pointed star icon
    final path = Path()
      ..moveTo(bx, by - r) // top
      ..lineTo(bx + r * 0.2, by - r * 0.2)
      ..lineTo(bx + r, by) // right
      ..lineTo(bx + r * 0.2, by + r * 0.2)
      ..lineTo(bx, by + r) // bottom
      ..lineTo(bx - r * 0.2, by + r * 0.2)
      ..lineTo(bx - r, by) // left
      ..lineTo(bx - r * 0.2, by - r * 0.2)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color =
            GameConfig.sanctuaryCoreColor.withValues(alpha: 0.6 * pulse)
        ..blendMode = BlendMode.plus,
    );
  }

  void _renderOverlay(Canvas canvas) {
    final sw = game.size.x;
    final sh = game.size.y;
    final pulse = 0.85 + 0.15 * sin(_time * 2);

    // 1) Dark scrim
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sw, sh),
      Paint()..color = const Color(0xDD050510),
    );

    // 2) Central orb
    final cx = sw / 2;
    final cy = sh * 0.35;
    final ratio =
        (_shards / GameConfig.sanctuaryMaxShardsTotal).clamp(0.0, 1.0);
    final orbR = GameConfig.sanctuaryOrbMinRadius +
        (GameConfig.sanctuaryOrbMaxRadius -
                GameConfig.sanctuaryOrbMinRadius) *
            ratio;

    final sc = GameConfig.sanctuaryColor;
    final cc = GameConfig.sanctuaryCoreColor;

    // Atmospheric halo
    _glow(canvas, Offset(cx, cy), orbR * 4, sc, 0.08 * pulse);
    // Outer glow
    _glow(canvas, Offset(cx, cy), orbR * 2.2, sc, 0.22 * pulse);
    // Mid glow
    _glow(canvas, Offset(cx, cy), orbR * 1.3, cc, 0.4 * pulse);
    // Inner core
    _glow(canvas, Offset(cx, cy), orbR * 0.6, cc, 0.65 * pulse);
    // Bright dot
    canvas.drawCircle(
      Offset(cx, cy),
      orbR * 0.15,
      Paint()
        ..color = cc.withValues(alpha: 0.85 * pulse)
        ..blendMode = BlendMode.plus,
    );

    // Pulsing ring
    canvas.drawCircle(
      Offset(cx, cy),
      orbR * 1.8 * pulse,
      Paint()
        ..color = sc.withValues(alpha: 0.12 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..blendMode = BlendMode.plus,
    );

    // ── Extra visuals when abilities unlocked ───────────────────────
    if (_shiftUnlocked) {
      final vsC = GameConfig.veilShiftColor;

      // Second ring in cyan
      canvas.drawCircle(
        Offset(cx, cy),
        orbR * 2.3 * pulse,
        Paint()
          ..color = vsC.withValues(alpha: 0.08 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..blendMode = BlendMode.plus,
      );

      // 4 orbiting dots
      final orbitR = orbR * 2.0;
      for (int i = 0; i < 4; i++) {
        final angle = _time * 0.6 + i * pi / 2;
        final dx = cos(angle) * orbitR;
        final dy = sin(angle) * orbitR * 0.5;
        final dotColor = i.isEven ? sc : vsC;
        final dotAlpha = 0.35 * pulse;

        canvas.drawCircle(
          Offset(cx + dx, cy + dy),
          2.5,
          Paint()
            ..color = dotColor.withValues(alpha: dotAlpha)
            ..blendMode = BlendMode.plus,
        );
        _glow(canvas, Offset(cx + dx, cy + dy), 10, dotColor,
            dotAlpha * 0.3);
      }
    } else if (_bloomUnlocked) {
      final orbitR = orbR * 1.8;
      for (int i = 0; i < 2; i++) {
        final angle = _time * 0.5 + i * pi;
        final dx = cos(angle) * orbitR;
        final dy = sin(angle) * orbitR * 0.5;
        final dotAlpha = 0.25 * pulse;

        canvas.drawCircle(
          Offset(cx + dx, cy + dy),
          2.0,
          Paint()
            ..color = sc.withValues(alpha: dotAlpha)
            ..blendMode = BlendMode.plus,
        );
      }
    }

    // ── Second Veil glow ring when unlocked ────────────────────────
    if (_secondVeilUnlocked) {
      final pc = GameConfig.portalColor;
      canvas.drawCircle(
        Offset(cx, cy),
        orbR * 2.8 * pulse,
        Paint()
          ..color = pc.withValues(alpha: 0.06 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..blendMode = BlendMode.plus,
      );
    }

    // 3) Title
    _titlePainter?.paint(
      canvas,
      Offset(cx - (_titlePainter!.width / 2), cy - orbR - 50),
    );

    // Layout text below the orb
    double textY = cy + orbR + 24;
    const lineH = 24.0;

    // 4) Current veil indicator
    if (_currentVeilPainter != null) {
      _currentVeilPainter!.paint(
        canvas,
        Offset(cx - (_currentVeilPainter!.width / 2), textY),
      );
      textY += lineH;
    }

    // 5) Shard count
    _shardPainter?.paint(
      canvas,
      Offset(cx - (_shardPainter!.width / 2), textY),
    );
    textY += lineH + 4;

    // 6) Bloom Pulse status
    _bloomPainter?.paint(
      canvas,
      Offset(cx - (_bloomPainter!.width / 2), textY),
    );
    textY += lineH;

    // 7) Veil Shift status
    _shiftPainter?.paint(
      canvas,
      Offset(cx - (_shiftPainter!.width / 2), textY),
    );
    textY += lineH + 4;

    // 8) First Veil completion status
    if (_veilComplete && _completionPainter != null) {
      _completionPainter!.paint(
        canvas,
        Offset(cx - (_completionPainter!.width / 2), textY),
      );
      textY += lineH;

      // Completion golden ring
      canvas.drawCircle(
        Offset(cx, cy),
        orbR * 2.6 * pulse,
        Paint()
          ..color = GameConfig.shardCore.withValues(alpha: 0.06 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6
          ..blendMode = BlendMode.plus,
      );
    }

    // 9) Second Veil completion status
    if (_secondCompletionPainter != null) {
      _secondCompletionPainter!.paint(
        canvas,
        Offset(cx - (_secondCompletionPainter!.width / 2), textY),
      );
      textY += lineH;
    }

    // 10) Close hint
    _hintPainter?.paint(
      canvas,
      Offset(cx - (_hintPainter!.width / 2), sh - 50),
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
