/// A particle system that spawns glowing orbs around a moving [target].
///
/// Particles are positioned in **world coordinates** so they naturally
/// trail behind the target when it moves, creating a living aura effect.
/// When the target is still the particles form a pulsating halo.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../config/game_config.dart';

class GlowParticleSystem extends Component {
  GlowParticleSystem({
    required this.target,
    this.particleCount = GameConfig.maxParticles,
    this.spawnRadius = GameConfig.particleSpawnRadius,
    this.driftSpeed = GameConfig.particleDriftSpeed,
    this.minRadius = GameConfig.particleMinRadius,
    this.maxRadius = GameConfig.particleMaxRadius,
    this.minLife = GameConfig.particleMinLife,
    this.maxLife = GameConfig.particleMaxLife,
  });

  /// The component whose position is used as the spawn centre.
  final PositionComponent target;

  final int particleCount;
  final double spawnRadius;
  final double driftSpeed;
  final double minRadius;
  final double maxRadius;
  final double minLife;
  final double maxLife;

  final List<_GlowParticle> _particles = [];
  final Random _rng = Random();

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _seedParticles();
  }

  // ── Seed initial batch ─────────────────────────────────────────────────
  void _seedParticles() {
    for (int i = 0; i < particleCount; i++) {
      _particles.add(_spawn(randomAge: true));
    }
  }

  // ── Spawn a single particle at the target's current position ───────────
  _GlowParticle _spawn({bool randomAge = false}) {
    final angle = _rng.nextDouble() * 2 * pi;
    final dist = _rng.nextDouble() * spawnRadius;
    final center = target.position;

    final life = minLife + _rng.nextDouble() * (maxLife - minLife);

    return _GlowParticle(
      position: Vector2(
        center.x + cos(angle) * dist,
        center.y + sin(angle) * dist,
      ),
      velocity: Vector2(
        cos(angle) * driftSpeed * (0.3 + _rng.nextDouble()),
        sin(angle) * driftSpeed * (0.3 + _rng.nextDouble()),
      ),
      radius: minRadius + _rng.nextDouble() * (maxRadius - minRadius),
      maxLife: life,
      age: randomAge ? _rng.nextDouble() * life : 0,
      pulsePhase: _rng.nextDouble() * 2 * pi,
    );
  }

  // ── Update ──────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      p.age += dt;
      p.position.add(p.velocity * dt);

      if (p.age >= p.maxLife) {
        _particles[i] = _spawn();
      }
    }
  }

  // ── Render ──────────────────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    for (final p in _particles) {
      final t = (p.age / p.maxLife).clamp(0.0, 1.0);
      // Smooth fade-in / fade-out envelope
      final envelope = sin(t * pi);
      // Subtle pulse on top
      final pulse = 0.85 + 0.15 * sin(p.age * 4 + p.pulsePhase);
      final alpha = (envelope * pulse).clamp(0.0, 1.0);

      if (alpha < 0.01) continue;

      final offset = Offset(p.position.x, p.position.y);
      final r = p.radius * (0.8 + 0.4 * envelope);

      // Outer glow halo
      final haloPaint = Paint()
        ..shader = Gradient.radial(
          offset,
          r * 4,
          [
            GameConfig.glowOuter.withValues(alpha: alpha * 0.35),
            GameConfig.glowOuter.withValues(alpha: 0),
          ],
        )
        ..blendMode = BlendMode.plus;
      canvas.drawCircle(offset, r * 4, haloPaint);

      // Inner glow
      final innerPaint = Paint()
        ..shader = Gradient.radial(
          offset,
          r * 2,
          [
            GameConfig.glowInner.withValues(alpha: alpha * 0.7),
            GameConfig.glowInner.withValues(alpha: 0),
          ],
        )
        ..blendMode = BlendMode.plus;
      canvas.drawCircle(offset, r * 2, innerPaint);

      // Bright core
      final corePaint = Paint()
        ..color = GameConfig.glowCore.withValues(alpha: alpha * 0.9)
        ..blendMode = BlendMode.plus;
      canvas.drawCircle(offset, r * 0.5, corePaint);
    }
  }
}

// ── Internal particle data ───────────────────────────────────────────────────

class _GlowParticle {
  _GlowParticle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.maxLife,
    required this.age,
    required this.pulsePhase,
  });

  final Vector2 position;
  final Vector2 velocity;
  final double radius;
  final double maxLife;
  double age;
  final double pulsePhase;
}
