/// Root [FlameGame] for Whispers of the Veil.
///
/// Sets up the world (player + aura), camera follow, ethereal background,
/// and routes all pointer input to the spirit player.
library;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'components/background/ethereal_background.dart';
import 'components/particles/glow_particle_system.dart';
import 'components/player/spirit_player.dart';
import 'config/game_config.dart';

class WhispersGame extends FlameGame {
  late SpiritPlayer player;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1) Ethereal background — added at game level (screen coordinates)
    //    so it stays fixed behind the world regardless of camera position.
    await add(EtherealBackground()..priority = -1);

    // 2) Player spirit in the world
    player = SpiritPlayer(position: Vector2.zero());
    await world.add(player);

    // 3) Aura particle system — also in the world so particles
    //    use world coordinates and trail behind the player naturally.
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

    // 4) Input overlay — captures all drag / tap events
    await add(_InputHandler());

    // 5) Camera follows the spirit with slight lag
    camera.follow(player, maxSpeed: GameConfig.cameraFollowSpeed, snap: true);
  }

  /// Convert canvas (screen) coordinates → world coordinates.
  Vector2 screenToWorld(Vector2 canvasPos) {
    return canvasPos - size / 2 + camera.viewfinder.position;
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
    _handlePointer(event.canvasPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _handlePointer(event.canvasEndPosition);
  }

  @override
  void onTapUp(TapUpEvent event) {
    _handlePointer(event.canvasPosition);
  }

  void _handlePointer(Vector2 canvasPos) {
    game.player.moveTo(game.screenToWorld(canvasPos));
  }
}
