/// Premium title screen overlay.
///
/// Renders a dark gradient background with floating particles,
/// a central glow, the game title, and a pulsing "Enter the Veil"
/// subtitle. On tap, fades out to reveal the game world beneath.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart' hide Gradient;

import '../config/game_config.dart';

class TitleScreen extends Component
    with TapCallbacks, HasGameReference {
  TitleScreen({this.onDismissed});

  /// Called once the fade-out completes and the title is removed.
  final void Function()? onDismissed;

  bool _active = true;
  bool _fading = false;
  double _fadeTimer = 0;
  double _time = 0;

  static const double _fadeDuration = 1.8;

  TextPainter? _titlePainter;
  TextPainter? _subtitlePainter;

  final List<_TitleMote> _motes = [];
  final Random _rng = Random();

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _buildText();
    _generateMotes();
  }

  void _buildText() {
    _titlePainter = TextPainter(
      text: const TextSpan(
        text: 'Whispers of the Veil',
        style: TextStyle(
          color: Color(0xCCEADDFF),
          fontSize: 30,
          fontWeight: FontWeight.w200,
          letterSpacing: 5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    _subtitlePainter = TextPainter(
      text: const TextSpan(
        text: 'Enter the Veil',
        style: TextStyle(
          color: Color(0xAA9B8DCC),
          fontSize: 14,
          fontWeight: FontWeight.w300,
          letterSpacing: 4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  void _generateMotes() {
    for (int i = 0; i < 30; i++) {
      _motes.add(_TitleMote(
        pos: Vector2(
          _rng.nextDouble() * 900,
          _rng.nextDouble() * 700,
        ),
        vel: Vector2(
          (_rng.nextDouble() - 0.5) * 6,
          -_rng.nextDouble() * 4 - 1,
        ),
        radius: 0.5 + _rng.nextDouble() * 1.8,
        alpha: 0.04 + _rng.nextDouble() * 0.10,
        pulsePhase: _rng.nextDouble() * 2 * pi,
        pulseSpeed: 0.8 + _rng.nextDouble() * 1.2,
      ));
    }
  }

  // ── Input ──────────────────────────────────────────────────────────────

  @override
  bool containsLocalPoint(Vector2 point) => _active;

  @override
  void onTapUp(TapUpEvent event) {
    if (!_fading && _active) {
      _fading = true;
      _fadeTimer = 0;
    }
  }

  // ── Update ─────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Update motes
    for (final m in _motes) {
      m.pos.add(m.vel * dt);
      // Wrap
      if (m.pos.y < -10) m.pos.y += 720;
      if (m.pos.x < -10) m.pos.x += 820;
      if (m.pos.x > 820) m.pos.x -= 820;
    }

    // Fade transition
    if (_fading) {
      _fadeTimer += dt;
      if (_fadeTimer >= _fadeDuration) {
        _active = false;
        removeFromParent();
        onDismissed?.call();
      }
    }
  }

  // ── Render ──────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    if (!_active) return;
    final sw = game.size.x;
    final sh = game.size.y;
    final alpha =
        _fading ? max(0.0, 1.0 - _fadeTimer / _fadeDuration) : 1.0;

    // 1) Dark gradient background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sw, sh),
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, sh),
          [
            GameConfig.bgTop.withValues(alpha: alpha),
            GameConfig.bgMid.withValues(alpha: alpha),
            GameConfig.bgBot.withValues(alpha: alpha),
          ],
          [0.0, 0.5, 1.0],
        ),
    );

    // 2) Floating motes
    for (final m in _motes) {
      final pulse =
          0.5 + 0.5 * sin(_time * m.pulseSpeed + m.pulsePhase);
      final a = m.alpha * pulse * alpha;
      if (a < 0.005) continue;

      final pos = Offset(
        m.pos.x / 900 * sw,
        m.pos.y / 700 * sh,
      );

      canvas.drawCircle(
        pos,
        m.radius * 3,
        Paint()
          ..shader = Gradient.radial(pos, m.radius * 3, [
            GameConfig.glowOuter.withValues(alpha: a * 0.5),
            GameConfig.glowOuter.withValues(alpha: 0),
          ])
          ..blendMode = BlendMode.plus,
      );
      canvas.drawCircle(
        pos,
        m.radius,
        Paint()
          ..color = GameConfig.glowCore.withValues(alpha: a)
          ..blendMode = BlendMode.plus,
      );
    }

    // 3) Central glow
    final cx = sw / 2;
    final cy = sh * 0.40;
    final glowPulse = 0.85 + 0.15 * sin(_time * 1.2);

    _glow(canvas, Offset(cx, cy), 120, GameConfig.sanctuaryColor,
        0.06 * alpha * glowPulse);
    _glow(canvas, Offset(cx, cy), 60, GameConfig.sanctuaryCoreColor,
        0.12 * alpha * glowPulse);
    _glow(canvas, Offset(cx, cy), 25, GameConfig.sanctuaryCoreColor,
        0.25 * alpha * glowPulse);

    // 4) Title text
    if (_titlePainter != null) {
      final tx = cx - _titlePainter!.width / 2;
      final ty = cy - _titlePainter!.height / 2;
      canvas.saveLayer(
        Rect.fromLTWH(tx - 5, ty - 5, _titlePainter!.width + 10,
            _titlePainter!.height + 10),
        Paint()..color = Color.fromRGBO(0, 0, 0, alpha),
      );
      _titlePainter!.paint(canvas, Offset(tx, ty));
      canvas.restore();
    }

    // 5) Subtitle with pulse
    if (_subtitlePainter != null) {
      final subtitlePulse = 0.4 + 0.4 * sin(_time * 1.5);
      final subAlpha = alpha * subtitlePulse;
      final sx = cx - _subtitlePainter!.width / 2;
      final sy = cy + 50;
      canvas.saveLayer(
        Rect.fromLTWH(sx - 5, sy - 5, _subtitlePainter!.width + 10,
            _subtitlePainter!.height + 10),
        Paint()..color = Color.fromRGBO(0, 0, 0, subAlpha),
      );
      _subtitlePainter!.paint(canvas, Offset(sx, sy));
      canvas.restore();
    }
  }

  void _glow(Canvas c, Offset at, double r, Color color, double a) {
    if (a < 0.005) return;
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

class _TitleMote {
  _TitleMote({
    required this.pos,
    required this.vel,
    required this.radius,
    required this.alpha,
    required this.pulsePhase,
    required this.pulseSpeed,
  });
  final Vector2 pos;
  final Vector2 vel;
  final double radius, alpha, pulsePhase, pulseSpeed;
}
