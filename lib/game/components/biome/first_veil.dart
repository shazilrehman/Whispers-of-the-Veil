/// The First Veil — the opening biome of the game.
///
/// Manages the playable area boundary, spawns interactive light bloom
/// nodes, and renders soft boundary fog at the edges.
library;

import 'dart:ui';

import 'package:flame/components.dart';

import '../../config/game_config.dart';
import '../player/spirit_player.dart';
import 'interactive/light_bloom_node.dart';

/// Configuration data for a single bloom node placement.
class _BloomPlacement {
  const _BloomPlacement(this.x, this.y, this.hue, this.radius);
  final double x, y, hue, radius;
}

class FirstVeil extends PositionComponent {
  FirstVeil({required this.player}) : super(position: Vector2.zero());

  final SpiritPlayer player;

  /// Predefined bloom-node placements scattered around the biome.
  static const _placements = [
    // Purple Veil Lily — northwest
    _BloomPlacement(380, 320, 270, 9),
    // Cyan Crystal — northeast
    _BloomPlacement(1550, 280, 195, 10),
    // Amber Ember — west
    _BloomPlacement(280, 920, 38, 8),
    // Teal Dream Moss — east
    _BloomPlacement(1680, 880, 165, 11),
    // Magenta Spirit Orchid — south-center-left
    _BloomPlacement(750, 1200, 305, 9),
    // Blue Moon Crystal — south-center-right
    _BloomPlacement(1350, 1100, 220, 10),
  ];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(GameConfig.biomeWidth, GameConfig.biomeHeight);

    // Spawn interactive bloom nodes
    for (final p in _placements) {
      await add(LightBloomNode(
        position: Vector2(p.x, p.y),
        target: player,
        hue: p.hue,
        baseRadius: p.radius,
      ));
    }
  }

  // ── Render boundary fog ────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    final w = GameConfig.biomeWidth;
    final h = GameConfig.biomeHeight;
    final fog = GameConfig.biomeBoundaryFog;
    final fogColor = GameConfig.bgTop;

    // Top edge — dark fading down
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, fog),
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, fog),
          [fogColor.withValues(alpha: 0.92), fogColor.withValues(alpha: 0)],
        ),
    );

    // Bottom edge — dark fading up
    canvas.drawRect(
      Rect.fromLTWH(0, h - fog, w, fog),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, h - fog),
          Offset(0, h),
          [fogColor.withValues(alpha: 0), fogColor.withValues(alpha: 0.92)],
        ),
    );

    // Left edge — dark fading right
    canvas.drawRect(
      Rect.fromLTWH(0, 0, fog, h),
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(fog, 0),
          [fogColor.withValues(alpha: 0.92), fogColor.withValues(alpha: 0)],
        ),
    );

    // Right edge — dark fading left
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
