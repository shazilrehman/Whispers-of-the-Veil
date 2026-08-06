/// Root [FlameGame] for Whispers of the Veil.
///
/// Sets up the first biome, parallax layers, camera follow, shard
/// tracking with persistence, the Eternal Sanctuary overlay, and the
/// Bloom Pulse ability system.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'components/abilities/bloom_pulse.dart';
import 'components/background/ethereal_background.dart';
import 'components/background/parallax_motes.dart';
import 'components/biome/first_veil.dart';
import 'components/particles/glow_particle_system.dart';
import 'components/player/spirit_player.dart';
import 'components/ui/ability_hud.dart';
import 'components/ui/sanctuary_overlay.dart';
import 'components/ui/shard_counter.dart';
import 'components/ui/tap_ripple.dart';
import 'config/game_config.dart';
import 'systems/save_system.dart';

class WhispersGame extends FlameGame {
  late SpiritPlayer player;
  late ShardCounter _shardCounter;
  late SanctuaryOverlay _sanctuaryOverlay;
  late AbilityHud _abilityHud;
  late FirstVeil _firstVeil;

  /// Total Lumina Shards the player has collected.
  int luminaShards = 0;

  /// Whether the Bloom Pulse ability has been unlocked.
  bool bloomPulseUnlocked = false;

  double _pulseCooldown = 0;

  /// Whether the Sanctuary overlay is open.
  bool get isSanctuaryOpen => _sanctuaryOverlay.isOpen;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // ── Load saved progress ──────────────────────────────────────────────
    final saved = await SaveSystem.load();
    luminaShards = saved.shards;
    bloomPulseUnlocked = saved.abilityUnlocked;

    // ── Game-level layers (screen coordinates) ───────────────────────────

    // 1) Ethereal background
    await add(EtherealBackground()..priority = -2);

    // 2) Parallax motes
    await add(ParallaxMotes()..priority = -1);

    // ── World-level content ──────────────────────────────────────────────

    // 3) Player spirit
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

    // 4) First Veil biome
    _firstVeil = FirstVeil(
      player: player,
      onShardCollected: collectShard,
    )..priority = -1;
    await world.add(_firstVeil);

    // 5) Aura particle system
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

    // ── HUD & overlays ───────────────────────────────────────────────────

    // 6) Shard counter
    _shardCounter = ShardCounter();
    await add(_shardCounter);

    // 7) Sanctuary overlay (includes button)
    _sanctuaryOverlay = SanctuaryOverlay()..priority = 8;
    await add(_sanctuaryOverlay);

    // 8) Ability HUD
    _abilityHud = AbilityHud()..priority = 9;
    await add(_abilityHud);

    // 9) Input overlay (highest priority)
    await add(_InputHandler()..priority = 10);

    // 10) Camera follows with soft cinematic lag
    camera.follow(player, maxSpeed: GameConfig.cameraFollowSpeed);

    // ── Apply loaded state ───────────────────────────────────────────────
    _shardCounter.updateCount(luminaShards);
    _sanctuaryOverlay.updateShards(luminaShards);
    _sanctuaryOverlay.updateAbility(bloomPulseUnlocked);
    if (bloomPulseUnlocked) {
      _abilityHud.unlock(showNotification: false);
    }
  }

  // ── Game loop ──────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (_pulseCooldown > 0) {
      _pulseCooldown = max(0, _pulseCooldown - dt);
      _abilityHud.updateCooldown(
        _pulseCooldown / GameConfig.bloomPulseCooldown,
      );
    }
  }

  // ── Shard collection ───────────────────────────────────────────────────

  /// Increment the shard count, update all UI, check ability threshold.
  void collectShard() {
    luminaShards++;
    _shardCounter.updateCount(luminaShards);
    _sanctuaryOverlay.updateShards(luminaShards);

    // Check ability unlock
    if (luminaShards >= GameConfig.bloomPulseThreshold &&
        !bloomPulseUnlocked) {
      bloomPulseUnlocked = true;
      _abilityHud.unlock();
      _sanctuaryOverlay.updateAbility(true);
    }

    SaveSystem.save(luminaShards, bloomPulseUnlocked);
  }

  // ── Bloom Pulse ability ────────────────────────────────────────────────

  /// Activate the Bloom Pulse if unlocked and off cooldown.
  void activateBloomPulse() {
    if (!bloomPulseUnlocked || _pulseCooldown > 0) return;
    _pulseCooldown = GameConfig.bloomPulseCooldown;

    // Spawn visual pulse in the world
    world.add(BloomPulse(
      position: player.position.clone(),
      onPulseExpand: (center, radius) {
        _firstVeil.pulseAwaken(center, radius);
      },
    ));
  }

  // ── UI tap routing ─────────────────────────────────────────────────────

  /// Returns true if the tap was consumed by a UI element.
  bool handleUiTap(Vector2 canvasPos) {
    if (_sanctuaryOverlay.isButtonAt(canvasPos)) {
      _sanctuaryOverlay.toggle();
      return true;
    }
    if (_abilityHud.isButtonAt(canvasPos)) {
      activateBloomPulse();
      return true;
    }
    return false;
  }

  void closeSanctuary() => _sanctuaryOverlay.close();

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
/// Checks UI buttons first, blocking world movement when a button is hit
/// or the Sanctuary overlay is open.
class _InputHandler extends Component
    with DragCallbacks, TapCallbacks, HasGameReference<WhispersGame> {
  bool _isDraggingWorld = false;

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);

    // Block input when sanctuary is open
    if (game.isSanctuaryOpen) {
      game.closeSanctuary();
      return;
    }
    // Check UI buttons
    if (game.handleUiTap(event.canvasPosition)) return;

    _isDraggingWorld = true;
    final worldPos = game.screenToWorld(event.canvasPosition);
    game.player.moveTo(worldPos);
    game.spawnRipple(worldPos);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_isDraggingWorld) return;
    game.player.moveTo(game.screenToWorld(event.canvasEndPosition));
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _isDraggingWorld = false;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (game.isSanctuaryOpen) {
      game.closeSanctuary();
      return;
    }
    if (game.handleUiTap(event.canvasPosition)) return;

    final worldPos = game.screenToWorld(event.canvasPosition);
    game.player.moveTo(worldPos);
    game.spawnRipple(worldPos);
  }
}
