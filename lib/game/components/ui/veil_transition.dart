/// Full-screen fade overlay for transitioning between veils.
///
/// Fades out to dark, holds briefly while the game swaps the active
/// biome, then fades back in. Calls [onMidpoint] at the darkest moment
/// to perform the actual swap, and [onComplete] when fully done.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' hide Gradient;

import '../../config/game_config.dart';

class VeilTransition extends Component with HasGameReference {
  VeilTransition({
    required this.onMidpoint,
    this.onComplete,
    this.destinationName = 'The Second Veil',
  });

  /// Called at the darkest point — swap the biome here.
  final void Function() onMidpoint;

  /// Called when the full transition is done.
  final void Function()? onComplete;

  /// Name shown during the transition.
  final String destinationName;

  double _time = 0;
  bool _midpointFired = false;
  bool _active = true;

  TextPainter? _namePainter;

  static double get _totalDuration =>
      GameConfig.transitionFadeOut +
      GameConfig.transitionHold +
      GameConfig.transitionFadeIn;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _namePainter = TextPainter(
      text: TextSpan(
        text: destinationName,
        style: const TextStyle(
          color: Color(0xCCD0EEFF),
          fontSize: 22,
          fontWeight: FontWeight.w200,
          letterSpacing: 5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Fire midpoint callback at the darkest moment
    if (!_midpointFired &&
        _time >= GameConfig.transitionFadeOut) {
      _midpointFired = true;
      onMidpoint();
    }

    if (_time >= _totalDuration && _active) {
      _active = false;
      removeFromParent();
      onComplete?.call();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_active) return;
    final sw = game.size.x;
    final sh = game.size.y;

    final fo = GameConfig.transitionFadeOut;
    final hold = GameConfig.transitionHold;
    final fi = GameConfig.transitionFadeIn;

    double alpha;
    if (_time < fo) {
      // Fading to black
      alpha = _time / fo;
    } else if (_time < fo + hold) {
      // Fully dark
      alpha = 1.0;
    } else {
      // Fading back in
      alpha = 1.0 - ((_time - fo - hold) / fi).clamp(0.0, 1.0);
    }
    if (alpha < 0.005) return;

    // Dark scrim
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sw, sh),
      Paint()..color = Color.fromRGBO(2, 5, 12, alpha),
    );

    // Show destination name during the dark phase
    if (alpha > 0.7 && _namePainter != null) {
      final nameAlpha = ((alpha - 0.7) / 0.3).clamp(0.0, 1.0);
      final cx = sw / 2;
      final cy = sh * 0.45;

      // Soft glow behind text
      final portalColor = GameConfig.portalColor;
      canvas.drawCircle(
        Offset(cx, cy),
        80,
        Paint()
          ..shader = Gradient.radial(Offset(cx, cy), 80, [
            portalColor.withValues(alpha: nameAlpha * 0.08),
            portalColor.withValues(alpha: 0),
          ])
          ..blendMode = BlendMode.plus,
      );

      // Small glowing motes
      final rng = Random(77);
      for (int i = 0; i < 8; i++) {
        final mx = cx + (rng.nextDouble() - 0.5) * 200;
        final speed = 10 + rng.nextDouble() * 20;
        final phase = rng.nextDouble() * 6.28;
        final my = cy - (_time * speed + phase * 15) % (sh * 0.3);
        final mAlpha = nameAlpha * (0.05 + rng.nextDouble() * 0.05);

        canvas.drawCircle(
          Offset(mx, my),
          1.0 + rng.nextDouble(),
          Paint()
            ..color = portalColor.withValues(alpha: mAlpha)
            ..blendMode = BlendMode.plus,
        );
      }

      // Destination name
      final tx = cx - _namePainter!.width / 2;
      final ty = cy - _namePainter!.height / 2;
      canvas.saveLayer(
        Rect.fromLTWH(tx - 5, ty - 5, _namePainter!.width + 10,
            _namePainter!.height + 10),
        Paint()..color = Color.fromRGBO(0, 0, 0, nameAlpha * 0.85),
      );
      _namePainter!.paint(canvas, Offset(tx, ty));
      canvas.restore();
    }
  }
}
