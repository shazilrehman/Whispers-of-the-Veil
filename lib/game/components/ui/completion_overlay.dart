/// "Veil Restored" completion overlay.
///
/// Displays a full-screen ethereal moment when all bloom nodes have
/// been awakened. Fades in, holds, then fades out and self-removes.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' hide Gradient;

import '../../config/game_config.dart';

class CompletionOverlay extends Component with HasGameReference {
  CompletionOverlay({
    this.onDismissed,
    this.title = 'The First Veil Has Been Restored',
    this.subtitle = 'All lights awakened',
  });

  final void Function()? onDismissed;
  final String title;
  final String subtitle;

  double _time = 0;
  bool _active = true;

  TextPainter? _titlePainter;
  TextPainter? _subtitlePainter;

  static double get _totalDuration =>
      GameConfig.completionFadeIn +
      GameConfig.completionHold +
      GameConfig.completionFadeOut;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Color(0xCCEADDFF),
          fontSize: 24,
          fontWeight: FontWeight.w200,
          letterSpacing: 4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    _subtitlePainter = TextPainter(
      text: TextSpan(
        text: subtitle,
        style: const TextStyle(
          color: Color(0xAA9B8DCC),
          fontSize: 14,
          fontWeight: FontWeight.w300,
          letterSpacing: 3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_time >= _totalDuration && _active) {
      _active = false;
      removeFromParent();
      onDismissed?.call();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_active) return;
    final sw = game.size.x;
    final sh = game.size.y;
    final cx = sw / 2;
    final cy = sh * 0.40;

    // Calculate alpha based on phase
    final fi = GameConfig.completionFadeIn;
    final hold = GameConfig.completionHold;
    final fo = GameConfig.completionFadeOut;

    double alpha;
    if (_time < fi) {
      alpha = _time / fi;
    } else if (_time < fi + hold) {
      alpha = 1.0;
    } else {
      alpha = 1.0 - ((_time - fi - hold) / fo).clamp(0.0, 1.0);
    }
    if (alpha < 0.005) return;

    // 1) Dark scrim
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sw, sh),
      Paint()..color = Color.fromRGBO(5, 5, 16, alpha * 0.88),
    );

    // 2) Expanding central glow
    final expandT =
        (_time / (fi + hold * 0.5)).clamp(0.0, 1.0);
    final pulse = 0.85 + 0.15 * sin(_time * 1.5);
    final sc = GameConfig.sanctuaryColor;
    final cc = GameConfig.sanctuaryCoreColor;

    _glow(canvas, Offset(cx, cy), 160 * expandT, sc,
        alpha * 0.10 * pulse);
    _glow(canvas, Offset(cx, cy), 80 * expandT, cc,
        alpha * 0.20 * pulse);
    _glow(canvas, Offset(cx, cy), 35 * expandT, cc,
        alpha * 0.35 * pulse);

    // 3) Bright core
    canvas.drawCircle(
      Offset(cx, cy),
      8 * expandT,
      Paint()
        ..color = cc.withValues(alpha: alpha * 0.7 * pulse)
        ..blendMode = BlendMode.plus,
    );

    // 4) Radiating ring
    final ringR = 50 + expandT * 80;
    canvas.drawCircle(
      Offset(cx, cy),
      ringR * pulse,
      Paint()
        ..color = sc.withValues(alpha: alpha * 0.12 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..blendMode = BlendMode.plus,
    );

    // 5) Title text
    if (_titlePainter != null) {
      final tx = cx - _titlePainter!.width / 2;
      final ty = cy + 50;
      canvas.saveLayer(
        Rect.fromLTWH(tx - 5, ty - 5, _titlePainter!.width + 10,
            _titlePainter!.height + 10),
        Paint()..color = Color.fromRGBO(0, 0, 0, alpha),
      );
      _titlePainter!.paint(canvas, Offset(tx, ty));
      canvas.restore();
    }

    // 6) Subtitle
    if (_subtitlePainter != null) {
      final subAlpha = alpha * (0.5 + 0.3 * sin(_time * 1.2));
      final sx = cx - _subtitlePainter!.width / 2;
      final sy = cy + 85;
      canvas.saveLayer(
        Rect.fromLTWH(sx - 5, sy - 5, _subtitlePainter!.width + 10,
            _subtitlePainter!.height + 10),
        Paint()..color = Color.fromRGBO(0, 0, 0, subAlpha),
      );
      _subtitlePainter!.paint(canvas, Offset(sx, sy));
      canvas.restore();
    }

    // 7) Floating motes rising
    final rng = Random(42);
    for (int i = 0; i < 12; i++) {
      final mx = cx + (rng.nextDouble() - 0.5) * 250;
      final speed = 15 + rng.nextDouble() * 25;
      final phase = rng.nextDouble() * 6.28;
      final my = cy + 40 - (_time * speed + phase * 20) % (sh * 0.5);
      final mAlpha = alpha * (0.08 + rng.nextDouble() * 0.08);
      final mr = 0.8 + rng.nextDouble() * 1.5;

      canvas.drawCircle(
        Offset(mx, my),
        mr,
        Paint()
          ..color = cc.withValues(alpha: mAlpha)
          ..blendMode = BlendMode.plus,
      );
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
