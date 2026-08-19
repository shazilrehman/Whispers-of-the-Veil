/// The Second Veil — a deeper, cooler biome unlocked after restoring
/// the First Veil.
///
/// Features an indigo–teal–silver palette, drifting mist, taller crystal
/// formations, and 12 interactive bloom nodes (9 regular + 3 hidden).
/// Includes a return portal to the First Veil.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../config/game_config.dart';
import '../../systems/audio_manager.dart';
import '../../systems/save_system.dart';
import '../collectibles/lumina_shard.dart';
import '../player/spirit_player.dart';
import '../ui/veil_portal.dart';
import 'decoration/crystal_mist.dart';
import 'decoration/second_veil_glow.dart';
import 'decoration/second_veil_wisps.dart';
import 'interactive/light_bloom_node.dart';

/// Configuration data for a single bloom node placement.
class _BloomPlacement {
  const _BloomPlacement(this.x, this.y, this.hue, this.radius,
      {this.hidden = false});
  final double x, y, hue, radius;
  final bool hidden;
}

class SecondVeil extends PositionComponent {
  SecondVeil({
    required this.player,
    required this.onShardCollected,
    required this.onVeilComplete,
    required this.onReturnPortal,
    this.preBloomedIndices = const {},
  }) : super(position: Vector2.zero());

  final SpiritPlayer player;
  final void Function() onShardCollected;
  final void Function() onVeilComplete;
  final void Function() onReturnPortal;
  final Set<int> preBloomedIndices;

  final Random _rng = Random();
  final List<LightBloomNode> _nodes = [];
  int _bloomedCount = 0;
  bool _completionFired = false;

  /// 12 nodes: 9 regular + 3 hidden. Cooler hues (teal, cyan, frost,
  /// silver, deep blue) to match the Second Veil palette.
  static const _placements = [
    // ── Regular nodes ───────────────────────────────────────────────────
    _BloomPlacement(400, 350, 195, 10),   // Teal Frost — NW
    _BloomPlacement(1100, 280, 210, 11),  // Cerulean Bloom — N-center
    _BloomPlacement(1800, 380, 180, 9),   // Cyan Crystal — NE
    _BloomPlacement(300, 850, 230, 10),   // Indigo Wisp — W
    _BloomPlacement(1100, 750, 200, 12),  // Deep Teal — center
    _BloomPlacement(1850, 820, 170, 9),   // Sea Frost — E
    _BloomPlacement(550, 1250, 215, 10),  // Silver Bloom — SW
    _BloomPlacement(1500, 1200, 190, 11), // Frost Ember — S-center
    _BloomPlacement(1900, 1350, 225, 9),  // Pale Indigo — SE

    // ── Hidden nodes ────────────────────────────────────────────────────
    _BloomPlacement(130, 1550, 240, 7, hidden: true),  // Deep Violet — BL
    _BloomPlacement(2050, 150, 175, 6, hidden: true),  // Ghost Teal — TR
    _BloomPlacement(1100, 1550, 205, 7, hidden: true), // Mist Silver — B-ctr
  ];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(GameConfig.secondVeilWidth, GameConfig.secondVeilHeight);

    // ── Environmental decorations ────────────────────────────────────────
    await add(SecondVeilGlow()..priority = -3);
    await add(CrystalMist(
      areaWidth: GameConfig.secondVeilWidth,
      areaHeight: GameConfig.secondVeilHeight,
    )..priority = -2);
    await add(SecondVeilWisps()..priority = -1);

    // ── Interactive bloom nodes ──────────────────────────────────────────
    for (int i = 0; i < _placements.length; i++) {
      final p = _placements[i];
      final node = LightBloomNode(
        position: Vector2(p.x, p.y),
        target: player,
        hue: p.hue,
        baseRadius: p.radius,
        hidden: p.hidden,
        onFirstBloom: (pos) => _onNodeBloomed(i, pos),
      );
      await add(node);
      _nodes.add(node);

      // Restore pre-bloomed state
      if (preBloomedIndices.contains(i)) {
        node.restoreRemembered();
        _bloomedCount++;
      }
    }

    // If all were already bloomed, mark completion without re-triggering
    if (_bloomedCount >= _placements.length) {
      _completionFired = true;
    }

    // ── Return portal (always available in the Second Veil) ─────────────
    await add(VeilPortal(
      position: Vector2(
        GameConfig.secondVeilWidth / 2,
        GameConfig.secondVeilHeight - 120,
      ),
      target: player,
      onActivated: onReturnPortal,
      label: 'Return to the First Veil',
    ));
  }

  // ── Node bloom callback ────────────────────────────────────────────────

  void _onNodeBloomed(int index, Vector2 pos) {
    AudioManager.playSfx(GameConfig.sfxBloomAwaken, volume: 0.6);

    // Slightly higher shard yields in the Second Veil
    final count = GameConfig.svShardDropMin +
        _rng.nextInt(GameConfig.svShardDropMax - GameConfig.svShardDropMin + 1);

    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final dist = 15 + _rng.nextDouble() * GameConfig.shardDriftRadius;
      final offset = Vector2(cos(angle) * dist, sin(angle) * dist);

      add(LuminaShard(
        position: pos + offset,
        target: player,
        onCollected: onShardCollected,
      ));
    }

    _bloomedCount++;
    _persistNodeState();
    _checkCompletion();
  }

  // ── Persistence ────────────────────────────────────────────────────────

  void _persistNodeState() {
    final indices = <int>{};
    for (int i = 0; i < _nodes.length; i++) {
      if (_nodes[i].isRemembered) indices.add(i);
    }
    SaveSystem.saveSecondBloomedNodes(indices);
  }

  // ── Completion ─────────────────────────────────────────────────────────

  void _checkCompletion() {
    if (!_completionFired && _bloomedCount >= _placements.length) {
      _completionFired = true;
      onVeilComplete();
    }
  }

  bool get isComplete => _completionFired;

  /// Force-awaken bloom nodes within [radius] of [center].
  void pulseAwaken(Vector2 center, double radius) {
    for (final node in _nodes) {
      if (node.position.distanceTo(center) <= radius) {
        node.forceAwaken();
      }
    }
  }

  /// Find the nearest unbloomed node to [from] within max range.
  Vector2? findNearestUnbloomed(Vector2 from) {
    LightBloomNode? nearest;
    double bestDist = double.infinity;
    for (final node in _nodes) {
      if (!node.isRemembered) {
        final dist = node.position.distanceTo(from);
        if (dist < bestDist && dist <= GameConfig.veilShiftMaxRange) {
          bestDist = dist;
          nearest = node;
        }
      }
    }
    return nearest?.position.clone();
  }

  // ── Render boundary fog ────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    final w = GameConfig.secondVeilWidth;
    final h = GameConfig.secondVeilHeight;
    final fog = GameConfig.biomeBoundaryFog;
    // Use the Second Veil's darker top color for fog
    final fogColor = GameConfig.svBgTop;

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
