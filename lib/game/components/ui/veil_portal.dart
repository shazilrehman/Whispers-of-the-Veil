/// A swirling portal that allows travel between veils.
///
/// Renders as a softly pulsing ring of light with orbiting motes.
/// Activates via proximity — when the player approaches, triggers
/// a veil transition callback.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' hide Gradient;

import '../../config/game_config.dart';

class VeilPortal extends PositionComponent {
  VeilPortal({
    required super.position,
    required this.target,
    required this.onActivated,
    this.label = 'Enter the Next Veil',
  });

  /// The component whose proximity triggers the portal.
  final PositionComponent target;

  /// Called once when the portal is activated.
  final void Function() onActivated;

  /// Label drawn near the portal when the player is close.
  final String label;

  double _time = 0;
  bool _activated = false;
  bool _playerNear = false;
  TextPainter? _labelPainter;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(GameConfig.portalActivationRadius * 2.5);
    anchor = Anchor.center;
    priority = 3;

    _labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: GameConfig.portalCoreColor.withValues(alpha: 0.7),
          fontSize: 12,
          fontWeight: FontWeight.w300,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    if (_activated) return;

    final dist = position.distanceTo(target.position);
    _playerNear = dist < GameConfig.portalActivationRadius * 1.5;

    if (dist < GameConfig.portalActivationRadius * 0.6) {
      _activated = true;
      onActivated();
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final center = Offset(cx, cy);
    final r = GameConfig.portalBaseRadius;
    final pulse = 0.75 + 0.25 * sin(_time * GameConfig.portalPulseSpeed);
    final color = GameConfig.portalColor;
    final core = GameConfig.portalCoreColor;

    // 1) Large atmospheric glow
    _glow(canvas, center, r * 8 * pulse, color, 0.06 * pulse);

    // 2) Mid glow
    _glow(canvas, center, r * 4 * pulse, color, 0.14 * pulse);

    // 3) Inner glow
    _glow(canvas, center, r * 2, core, 0.25 * pulse);

    // 4) Bright core
    canvas.drawCircle(
      center,
      r * 0.5,
      Paint()
        ..color = core.withValues(alpha: 0.6 * pulse)
        ..blendMode = BlendMode.plus,
    );

    // 5) Swirling ring
    final ringR = r * 3 * pulse;
    canvas.drawCircle(
      center,
      ringR,
      Paint()
        ..color = color.withValues(alpha: 0.18 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..blendMode = BlendMode.plus,
    );

    // Second ring, slightly offset
    canvas.drawCircle(
      center,
      ringR * 1.4,
      Paint()
        ..color = color.withValues(alpha: 0.08 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..blendMode = BlendMode.plus,
    );

    // 6) Orbiting motes
    for (int i = 0; i < 6; i++) {
      final angle = _time * 0.8 + i * pi / 3;
      final orbitR = r * 3.5;
      final mx = cx + cos(angle) * orbitR;
      final my = cy + sin(angle) * orbitR * 0.6; // elliptical
      final mAlpha = 0.25 * pulse;

      canvas.drawCircle(
        Offset(mx, my),
        1.8,
        Paint()
          ..color = core.withValues(alpha: mAlpha)
          ..blendMode = BlendMode.plus,
      );
      _glow(canvas, Offset(mx, my), 8, color, mAlpha * 0.3);
    }

    // 7) Label when player is near
    if (_playerNear && _labelPainter != null && !_activated) {
      final labelAlpha = 0.5 + 0.3 * sin(_time * 1.5);
      final lx = cx - _labelPainter!.width / 2;
      final ly = cy + r * 5;

      canvas.saveLayer(
        Rect.fromLTWH(lx - 5, ly - 5, _labelPainter!.width + 10,
            _labelPainter!.height + 10),
        Paint()..color = Color.fromRGBO(0, 0, 0, labelAlpha),
      );
      _labelPainter!.paint(canvas, Offset(lx, ly));
      canvas.restore();
    }
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
