/// Soft floating light motes for the Second Veil biome.
///
/// Same particle behavior as [AmbientWisps] but tuned for the
/// Second Veil's cooler indigo–teal–silver palette and dimensions.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../config/game_config.dart';

class SecondVeilWisps extends Component {
  final List<_Wisp> _wisps = [];
  final Random _rng = Random();

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _generate();
  }

  void _generate() {
    final w = GameConfig.secondVeilWidth;
    final h = GameConfig.secondVeilHeight;
    final margin = 60.0;

    for (int i = 0; i < GameConfig.svWispCount; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      _wisps.add(_Wisp(
        pos: Vector2(
          margin + _rng.nextDouble() * (w - margin * 2),
          margin + _rng.nextDouble() * (h - margin * 2),
        ),
        vel: Vector2(
          cos(angle) * GameConfig.svWispDriftSpeed *
              (0.3 + _rng.nextDouble() * 0.7),
          sin(angle) * GameConfig.svWispDriftSpeed *
              (0.3 + _rng.nextDouble() * 0.7),
        ),
        radius: GameConfig.svWispMinRadius +
            _rng.nextDouble() *
                (GameConfig.svWispMaxRadius - GameConfig.svWispMinRadius),
        pulsePhase: _rng.nextDouble() * 2 * pi,
        pulseSpeed: 1.0 + _rng.nextDouble() * 1.5,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final w = GameConfig.secondVeilWidth;
    final h = GameConfig.secondVeilHeight;

    for (final m in _wisps) {
      m.pos.add(m.vel * dt);
      m.age += dt;

      if (m.pos.x < 0) m.pos.x += w;
      if (m.pos.x > w) m.pos.x -= w;
      if (m.pos.y < 0) m.pos.y += h;
      if (m.pos.y > h) m.pos.y -= h;
    }
  }

  @override
  void render(Canvas canvas) {
    for (final m in _wisps) {
      final pulse = 0.6 + 0.4 * sin(m.age * m.pulseSpeed + m.pulsePhase);
      final alpha = GameConfig.svWispAlpha * pulse;

      final offset = Offset(m.pos.x, m.pos.y);
      canvas.drawCircle(
        offset,
        m.radius * 4,
        Paint()
          ..shader = Gradient.radial(offset, m.radius * 4, [
            GameConfig.svGlowOuter.withValues(alpha: alpha * 0.4),
            GameConfig.svGlowOuter.withValues(alpha: 0),
          ])
          ..blendMode = BlendMode.plus,
      );

      canvas.drawCircle(
        offset,
        m.radius,
        Paint()
          ..color = GameConfig.svGlowCore.withValues(alpha: alpha)
          ..blendMode = BlendMode.plus,
      );
    }
  }
}

class _Wisp {
  _Wisp({
    required this.pos,
    required this.vel,
    required this.radius,
    required this.pulsePhase,
    required this.pulseSpeed,
  });

  final Vector2 pos;
  final Vector2 vel;
  final double radius;
  final double pulsePhase;
  final double pulseSpeed;
  double age = 0;
}
