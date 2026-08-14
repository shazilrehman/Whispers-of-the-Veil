/// The First Veil — the opening biome of the game.
///
/// Manages the playable area boundary, spawns interactive light bloom
/// nodes (including hidden ones), environmental decorations, and
/// Lumina Shards on first bloom.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../config/game_config.dart';
import '../../systems/audio_manager.dart';
import '../collectibles/lumina_shard.dart';
import '../player/spirit_player.dart';
import 'decoration/ambient_wisps.dart';
import 'decoration/ground_glow.dart';
import 'interactive/light_bloom_node.dart';

/// Configuration data for a single bloom node placement.
class _BloomPlacement {
  const _BloomPlacement(this.x, this.y, this.hue, this.radius,
      {this.hidden = false});
  final double x, y, hue, radius;
  final bool hidden;
}

class FirstVeil extends PositionComponent {
  FirstVeil({
    required this.player,
    required this.onShardCollected,
  }) : super(position: Vector2.zero());

  final SpiritPlayer player;

  /// Called each time a Lumina Shard is picked up.
  final void Function() onShardCollected;

  final Random _rng = Random();

  /// Predefined bloom-node placements scattered around the biome.
  /// 13 total: 10 regular + 3 hidden (require deliberate exploration).
  static const _placements = [
    // ── Original 6 ─────────────────────────────────────────────────────
    _BloomPlacement(380, 320, 270, 9), // Purple Veil Lily — NW
    _BloomPlacement(1550, 280, 195, 10), // Cyan Crystal — NE
    _BloomPlacement(280, 920, 38, 8), // Amber Ember — W
    _BloomPlacement(1680, 880, 165, 11), // Teal Dream Moss — E
    _BloomPlacement(750, 1200, 305, 9), // Magenta Spirit Orchid — SW
    _BloomPlacement(1350, 1100, 220, 10), // Blue Moon Crystal — SE

    // ── New regular nodes ──────────────────────────────────────────────
    _BloomPlacement(200, 600, 15, 9), // Warm Rose — far left
    _BloomPlacement(1000, 450, 50, 10), // Golden Ember — upper center
    _BloomPlacement(600, 750, 140, 8), // Jade Mote — mid-west
    _BloomPlacement(1400, 650, 330, 10), // Coral Bloom — mid-east

    // ── Hidden nodes (very faint, require exploration) ─────────────────
    _BloomPlacement(120, 1380, 280, 7, hidden: true), // Dim Violet — BL corner
    _BloomPlacement(1880, 130, 200, 6, hidden: true), // Pale Frost — TR corner
    _BloomPlacement(980, 1420, 340, 7, hidden: true), // Dusk Rose — bottom center
  ];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(GameConfig.biomeWidth, GameConfig.biomeHeight);

    // ── Environmental decorations ────────────────────────────────────────
    await add(GroundGlow()..priority = -2);
    await add(AmbientWisps()..priority = -1);

    // ── Interactive bloom nodes ──────────────────────────────────────────
    for (final p in _placements) {
      await add(LightBloomNode(
        position: Vector2(p.x, p.y),
        target: player,
        hue: p.hue,
        baseRadius: p.radius,
        hidden: p.hidden,
        onFirstBloom: _spawnShards,
      ));
    }
  }

  // ── Shard spawning ─────────────────────────────────────────────────────
  void _spawnShards(Vector2 bloomPos) {
    AudioManager.playSfx(GameConfig.sfxBloomAwaken, volume: 0.6);

    final count = GameConfig.shardDropMin +
        _rng.nextInt(GameConfig.shardDropMax - GameConfig.shardDropMin + 1);

    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final dist = 15 + _rng.nextDouble() * GameConfig.shardDriftRadius;
      final offset = Vector2(cos(angle) * dist, sin(angle) * dist);

      add(LuminaShard(
        position: bloomPos + offset,
        target: player,
        onCollected: onShardCollected,
      ));
    }
  }

  /// Force-awaken all bloom nodes within [radius] of [center].
  void pulseAwaken(Vector2 center, double radius) {
    for (final child in children) {
      if (child is LightBloomNode &&
          child.position.distanceTo(center) <= radius) {
        child.forceAwaken();
      }
    }
  }

  /// Find the nearest unbloomed (not-yet-remembered) node to [from].
  /// Returns null if all nodes have been fully bloomed.
  Vector2? findNearestUnbloomed(Vector2 from) {
    LightBloomNode? nearest;
    double bestDist = double.infinity;
    for (final child in children) {
      if (child is LightBloomNode && !child.isRemembered) {
        final dist = child.position.distanceTo(from);
        if (dist < bestDist && dist <= GameConfig.veilShiftMaxRange) {
          bestDist = dist;
          nearest = child;
        }
      }
    }
    return nearest?.position.clone();
  }

  // ── Render boundary fog ────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    final w = GameConfig.biomeWidth;
    final h = GameConfig.biomeHeight;
    final fog = GameConfig.biomeBoundaryFog;
    final fogColor = GameConfig.bgTop;

    // Top edge
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, fog),
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, fog),
          [fogColor.withValues(alpha: 0.92), fogColor.withValues(alpha: 0)],
        ),
    );

    // Bottom edge
    canvas.drawRect(
      Rect.fromLTWH(0, h - fog, w, fog),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, h - fog),
          Offset(0, h),
          [fogColor.withValues(alpha: 0), fogColor.withValues(alpha: 0.92)],
        ),
    );

    // Left edge
    canvas.drawRect(
      Rect.fromLTWH(0, 0, fog, h),
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(fog, 0),
          [fogColor.withValues(alpha: 0.92), fogColor.withValues(alpha: 0)],
        ),
    );

    // Right edge
    canvas.drawRect(
      Rect.fromLTWH(w - fog, 0, fog, h),
      Paint()
        ..shader = Gradient.linear(
          Offset(w - fog, 0),
          Offset(w, 0),
          [fogColor.withValues(alpha: 0), fogColor.withValues(alpha: 0.92)],
        ),
    );
  }
}
