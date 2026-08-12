/// Root [FlameGame] for Whispers of the Veil.
///
/// Manages game lifecycle: title screen → gameplay with audio,
/// shard tracking with persistence, Sanctuary overlay, and the
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
import 'screens/title_screen.dart';
import 'systems/audio_manager.dart';
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

  /// True while the title screen is displayed.
  bool isTitleActive = true;

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

    // ── Preload audio ────────────────────────────────────────────────────
    await AudioManager.preload([
      GameConfig.sfxShardCollect,
      GameConfig.sfxBloomAwaken,
      GameConfig.sfxBloomPulse,
      GameConfig.sfxUiClick,
      GameConfig.sfxAbilityUnlock,
      GameConfig.bgmAmbient,
    ]);

    // ── Game-level layers (screen coordinates) ───────────────────────────

    await add(EtherealBackground()..priority = -2);
    await add(ParallaxMotes()..priority = -1);

    // ── World-level content ──────────────────────────────────────────────

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

    _firstVeil = FirstVeil(
      player: player,
      onShardCollected: collectShard,
    )..priority = -1;
    await world.add(_firstVeil);

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

    _shardCounter = ShardCounter();
    await add(_shardCounter);

    _sanctuaryOverlay = SanctuaryOverlay()..priority = 8;
    await add(_sanctuaryOverlay);

    _abilityHud = AbilityHud()..priority = 9;
    await add(_abilityHud);

    await add(_InputHandler()..priority = 10);

    camera.follow(player, maxSpeed: GameConfig.cameraFollowSpeed);

    // ── Apply loaded state ───────────────────────────────────────────────
    _shardCounter.updateCount(luminaShards);
    _sanctuaryOverlay.updateShards(luminaShards);
    _sanctuaryOverlay.updateAbility(bloomPulseUnlocked);
    if (bloomPulseUnlocked) {
      _abilityHud.unlock(showNotification: false);
    }

    // ── Title screen (on top of everything) ──────────────────────────────
    await add(TitleScreen(onDismissed: _onTitleDone)..priority = 50);
  }

  // ── Title screen callback ──────────────────────────────────────────────

  void _onTitleDone() {
    isTitleActive = false;
    // Start ambient music after first user interaction (browser-safe)
    AudioManager.playBgm(GameConfig.bgmAmbient, volume: 0.4);
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

  void collectShard() {
    luminaShards++;
    _shardCounter.updateCount(luminaShards);
    _sanctuaryOverlay.updateShards(luminaShards);

    AudioManager.playSfx(GameConfig.sfxShardCollect, volume: 0.7);

    // Check ability unlock
    if (luminaShards >= GameConfig.bloomPulseThreshold &&
        !bloomPulseUnlocked) {
      bloomPulseUnlocked = true;
      _abilityHud.unlock();
      _sanctuaryOverlay.updateAbility(true);
      AudioManager.playSfx(GameConfig.sfxAbilityUnlock, volume: 0.8);
    }

    SaveSystem.save(luminaShards, bloomPulseUnlocked);
  }

  // ── Bloom Pulse ability ────────────────────────────────────────────────

  void activateBloomPulse() {
    if (!bloomPulseUnlocked || _pulseCooldown > 0) return;
    _pulseCooldown = GameConfig.bloomPulseCooldown;

    AudioManager.playSfx(GameConfig.sfxBloomPulse, volume: 0.6);

    world.add(BloomPulse(
      position: player.position.clone(),
      onPulseExpand: (center, radius) {
        _firstVeil.pulseAwaken(center, radius);
      },
    ));
  }

  // ── UI tap routing ─────────────────────────────────────────────────────

  bool handleUiTap(Vector2 canvasPos) {
    if (_sanctuaryOverlay.isButtonAt(canvasPos)) {
      _sanctuaryOverlay.toggle();
      AudioManager.playSfx(GameConfig.sfxUiClick, volume: 0.5);
      return true;
    }
    if (_abilityHud.isButtonAt(canvasPos)) {
      activateBloomPulse();
      return true;
    }
    return false;
  }

  void closeSanctuary() {
    if (_sanctuaryOverlay.isOpen) {
      _sanctuaryOverlay.close();
      AudioManager.playSfx(GameConfig.sfxUiClick, volume: 0.4);
    }
  }

  Vector2 screenToWorld(Vector2 canvasPos) {
    return canvasPos - size / 2 + camera.viewfinder.position;
  }

  void spawnRipple(Vector2 worldPos) {
    world.add(TapRipple(position: worldPos));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input handler
// ─────────────────────────────────────────────────────────────────────────────

class _InputHandler extends Component
    with DragCallbacks, TapCallbacks, HasGameReference<WhispersGame> {
  bool _isDraggingWorld = false;

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (game.isTitleActive) return;
    if (game.isSanctuaryOpen) {
      game.closeSanctuary();
      return;
    }
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
    if (game.isTitleActive) return;
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
