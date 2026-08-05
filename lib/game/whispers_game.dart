/// Root [FlameGame] for Whispers of the Veil.
///
/// Sets up the first biome (world bounds + interactive objects),
/// parallax layers, camera follow, and routes all pointer input
/// to the spirit player.
library;

import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'components/background/ethereal_background.dart';
import 'components/background/parallax_motes.dart';
import 'components/biome/first_veil.dart';
import 'components/particles/glow_particle_system.dart';
import 'components/player/spirit_player.dart';
import 'components/ui/tap_ripple.dart';
import 'config/game_config.dart';

class WhispersGame extends FlameGame {
  late SpiritPlayer player;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // ── Game-level layers (screen coordinates) ───────────────────────────

    // 1) Ethereal background — fixed behind everything
    await add(EtherealBackground()..priority = -2);

    // 2) Parallax motes — two depth layers between bg and world
    await add(ParallaxMotes()..priority = -1);

    // ── World-level content ──────────────────────────────────────────────

    // 3) Player spirit — starts at the biome centre, clamped to bounds
    final pad = GameConfig.biomePlayerPadding;
    player = SpiritPlayer(
      position: Vector2(
        GameConfig.biomeWidth / 2,
        GameConfig.biomeHeight / 2,
      ),
      worldBounds: Rect.fromLTWH(
        pad,
        pad,
        GameConfig.biomeWidth - pad * 2,
        GameConfig.biomeHeight - pad * 2,
      ),
    );
    await world.add(player);

    // 4) First Veil biome — boundary fog + 6 interactive bloom nodes
    await world.add(FirstVeil(player: player)..priority = -1);

    // 5) Aura particle system — trails behind the player
    await world.add(
      GlowParticleSystem(
        target: player,
        particleCount: GameConfig.auraParticles,
        spawnRadius: GameConfig.auraSpawnRadius,
        driftSpeed: GameConfig.auraDriftSpeed,
        minRadius: GameConfig.auraMinRadius,
        maxRadius: GameConfig.auraMaxRadius,
        minLife: GameConfig.auraMinLife,
        maxLife: GameConfig.auraMaxLife,
      )..priority = 0,
    );

    // ── Input & camera ───────────────────────────────────────────────────

    // 6) Input overlay
    await add(_InputHandler());

    // 7) Camera follows with soft cinematic lag
    camera.follow(player, maxSpeed: GameConfig.cameraFollowSpeed);
  }

  /// Convert canvas (screen) coordinates → world coordinates.
  Vector2 screenToWorld(Vector2 canvasPos) {
    return canvasPos - size / 2 + camera.viewfinder.position;
  }

  /// Spawn a brief ripple at [worldPos] for visual feedback.
  void spawnRipple(Vector2 worldPos) {
    world.add(TapRipple(position: worldPos));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input handler
// ─────────────────────────────────────────────────────────────────────────────

/// Transparent full-screen overlay that captures all drag / tap events
/// and directs the spirit player toward the pointer location.
class _InputHandler extends Component
    with DragCallbacks, TapCallbacks, HasGameReference<WhispersGame> {
  /// Accept input anywhere on screen.
  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final worldPos = game.screenToWorld(event.canvasPosition);
    game.player.moveTo(worldPos);
    game.spawnRipple(worldPos);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    game.player.moveTo(game.screenToWorld(event.canvasEndPosition));
  }

  @override
  void onTapUp(TapUpEvent event) {
    final worldPos = game.screenToWorld(event.canvasPosition);
    game.player.moveTo(worldPos);
    game.spawnRipple(worldPos);
  }
}
