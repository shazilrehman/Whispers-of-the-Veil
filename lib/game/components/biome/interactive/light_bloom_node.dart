/// An interactive light object that reacts when the player's spirit
/// approaches. Transitions through dormant → awakening → bloomed → fading
/// states with multi-layer glow, particles, and pulsing animation.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' hide Gradient;

import '../../../config/game_config.dart';

class LightBloomNode extends PositionComponent {
  LightBloomNode({
    required super.position,
    required this.target,
    required this.hue,
    this.baseRadius = GameConfig.bloomBaseRadius,
    this.activationRadius = GameConfig.bloomActivationRadius,
    this.hidden = false,
    this.onFirstBloom,
  });

  /// The component whose proximity triggers the bloom.
  final PositionComponent target;

  /// HSL hue that defines the bloom's color identity (0–360).
  final double hue;
  final double baseRadius;
  final double activationRadius;

  /// Whether this is a hidden node with very faint dormant alpha.
  final bool hidden;

  /// Called once when the node reaches full bloom for the first time.
  final void Function(Vector2 position)? onFirstBloom;

  // ── State ──────────────────────────────────────────────────────────────
  double _intensity = 0; // 0 = dormant, 1 = fully bloomed
  double _time = 0;
  double _spawnTimer = 0;
  bool _isActive = false;
  bool _remembered = false; // true after first full bloom

  /// Whether this node has been fully bloomed at least once.
  bool get isRemembered => _remembered;

  final List<_BloomParticle> _particles = [];
  final Random _rng = Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Large enough to contain the outermost glow layer.
    size = Vector2.all(activationRadius * 1.4);
    anchor = Anchor.center;
    priority = 0;
  }

  // ── Update ──────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Proximity check
    _isActive = position.distanceTo(target.position) < activationRadius;

    // Animate intensity
    if (_isActive) {
      _intensity = min(1.0, _intensity + dt * GameConfig.bloomRiseSpeed);
      // Mark as remembered & fire shard callback once fully bloomed
      if (_intensity >= 0.95 && !_remembered) {
        _remembered = true;
        onFirstBloom?.call(position.clone());
      }
    } else {
      // Fade to remembered floor (or zero if never fully bloomed)
      final floor =
          _remembered ? GameConfig.bloomRememberedIntensity : 0.0;
      _intensity = max(floor, _intensity - dt * GameConfig.bloomFadeSpeed);
    }

    // Particles
    _updateParticles(dt);
  }

  /// Instantly awaken this node to full bloom (used by Bloom Pulse).
  /// Idempotent — safe to call multiple times.
  void forceAwaken() {
    _intensity = 1.0;
    if (!_remembered) {
      _remembered = true;
      onFirstBloom?.call(position.clone());
    }
  }

  // ── Particle management ────────────────────────────────────────────────
  void _updateParticles(double dt) {
    // Spawn when blooming
    if (_intensity > 0.25 &&
        _particles.length < GameConfig.bloomMaxParticles) {
      _spawnTimer += dt;
      final interval = 0.12 / _intensity; // faster at higher intensity
      if (_spawnTimer >= interval) {
        _spawnTimer = 0;
        _spawnBloomParticle();
      }
    }

    // Tick existing
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.age += dt;
      p.pos.add(p.vel * dt);
      // Slight deceleration
      p.vel.scale(1 - 0.4 * dt);
      if (p.age >= p.maxLife) {
        _particles.removeAt(i);
      }
    }
  }

  void _spawnBloomParticle() {
    final angle = _rng.nextDouble() * 2 * pi;
    final speed =
        GameConfig.bloomParticleSpeed * (0.4 + _rng.nextDouble() * 0.6);
    // Bias upward (negative Y in screen space)
    final vx = cos(angle) * speed * 0.6;
    final vy = -speed * (0.5 + _rng.nextDouble() * 0.5) +
        sin(angle) * speed * 0.3;

    _particles.add(_BloomParticle(
      pos: Vector2(0, 0), // local center
      vel: Vector2(vx, vy),
      maxLife: GameConfig.bloomParticleLife *
          (0.6 + _rng.nextDouble() * 0.4),
      radius: GameConfig.bloomParticleRadius *
          (0.5 + _rng.nextDouble() * 0.5),
    ));
  }

  // ── Render ──────────────────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final center = Offset(cx, cy);
    final i = _intensity;
    final pulse = 0.85 + 0.15 * sin(_time * 3.0);

    // Derive colors from hue
    final baseColor =
        HSLColor.fromAHSL(1, hue, 0.7, 0.5).toColor();
    final coreColor =
        HSLColor.fromAHSL(1, hue, 0.35, 0.82).toColor();

    // ─ 1) Dormant seed (always visible) ─────────────────────────────────
    final dormantA =
        hidden ? GameConfig.bloomHiddenDormantAlpha : GameConfig.bloomDormantAlpha;
    final seedAlpha = dormantA + i * 0.25;
    final seedR = baseRadius * (1 + i * 0.5);
    _glow(canvas, center, seedR * 2.5, baseColor, seedAlpha * 0.5);
    _glow(canvas, center, seedR, coreColor, seedAlpha);

    // Gentle dormant pulse ring
    if (i < 0.1) {
      final ringAlpha =
          dormantA * 0.4 * (0.5 + 0.5 * sin(_time * 1.8));
      final ringPaint = Paint()
        ..color = baseColor.withValues(alpha: ringAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..blendMode = BlendMode.plus;
      canvas.drawCircle(center, baseRadius * 3, ringPaint);
    }

    // ─ 2) Bloom layers (scale with intensity) ───────────────────────────
    if (i > 0.01) {
      // Large atmospheric halo
      final haloR = baseRadius * (3 + i * 6) * pulse;
      _glow(canvas, center, haloR, baseColor, i * 0.15 * pulse);

      // Outer glow
      final outerR = baseRadius * (2 + i * 4) * pulse;
      _glow(canvas, center, outerR, baseColor, i * 0.3 * pulse);

      // Mid glow
      final midR = baseRadius * (1.5 + i * 2);
      _glow(canvas, center, midR, coreColor, i * 0.55 * pulse);

      // Inner bright
      final innerR = baseRadius * (1 + i * 1.2);
      _glow(canvas, center, innerR, coreColor, i * 0.75 * pulse);

      // Hot core
      final cR = baseRadius * (0.4 + i * 0.5);
      canvas.drawCircle(
        center,
        cR,
        Paint()
          ..color = coreColor.withValues(alpha: i * 0.9 * pulse)
          ..blendMode = BlendMode.plus,
      );

      // Pulsing ring at bloom edge
      if (i > 0.5) {
        final ringR = baseRadius * (3 + i * 5) * pulse;
        final ringAlpha = (i - 0.5) * 0.3 * pulse;
        canvas.drawCircle(
          center,
          ringR,
          Paint()
            ..color = baseColor.withValues(alpha: ringAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..blendMode = BlendMode.plus,
        );
      }
    }

    // ─ 3) Particles ─────────────────────────────────────────────────────
    for (final p in _particles) {
      final t = (p.age / p.maxLife).clamp(0.0, 1.0);
      final envelope = sin(t * pi);
      final alpha = envelope * i;
      if (alpha < 0.01) continue;

      final offset = Offset(cx + p.pos.x, cy + p.pos.y);
      final r = p.radius * (0.6 + 0.4 * envelope);

      // Particle glow
      _glow(canvas, offset, r * 3, baseColor, alpha * 0.35);

      // Particle core
      canvas.drawCircle(
        offset,
        r,
        Paint()
          ..color = coreColor.withValues(alpha: alpha * 0.8)
          ..blendMode = BlendMode.plus,
      );
    }
  }

  /// Helper — single radial-gradient glow circle.
  void _glow(Canvas c, Offset at, double r, Color color, double alpha) {
    if (alpha < 0.005 || r < 0.5) return;
    c.drawCircle(
      at,
      r,
      Paint()
        ..shader = Gradient.radial(
          at,
          r,
          [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
        )
        ..blendMode = BlendMode.plus,
    );
  }
}

// ── Internal particle data ───────────────────────────────────────────────────

class _BloomParticle {
  _BloomParticle({
    required this.pos,
    required this.vel,
    required this.maxLife,
    required this.radius,
  });

  final Vector2 pos;
  final Vector2 vel;
  final double maxLife;
  final double radius;
  double age = 0;
}
