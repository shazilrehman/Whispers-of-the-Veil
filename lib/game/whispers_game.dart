/// Root [FlameGame] for Whispers of the Veil.
///
/// Manages game lifecycle: title screen → gameplay with audio,
/// shard tracking with persistence, Sanctuary overlay, Settings screen,
/// both abilities (Bloom Pulse + Veil Shift), world state persistence,
/// and First Veil completion detection.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'components/abilities/bloom_pulse.dart';
import 'components/abilities/veil_shift_trail.dart';
import 'components/background/ethereal_background.dart';
import 'components/background/parallax_motes.dart';
import 'components/biome/first_veil.dart';
import 'components/particles/glow_particle_system.dart';
import 'components/player/spirit_player.dart';
import 'components/ui/ability_hud.dart';
import 'components/ui/completion_overlay.dart';
import 'components/ui/sanctuary_overlay.dart';
import 'components/ui/shard_counter.dart';
import 'components/ui/tap_ripple.dart';
import 'config/game_config.dart';
import 'screens/settings_screen.dart';
import 'screens/title_screen.dart';
import 'systems/audio_manager.dart';
import 'systems/save_system.dart';

class WhispersGame extends FlameGame {
  late SpiritPlayer player;
  late ShardCounter _shardCounter;
  late SanctuaryOverlay _sanctuaryOverlay;
  late AbilityHud _abilityHud;
  late SettingsScreen _settingsScreen;
  late FirstVeil _firstVeil;

  /// Total Lumina Shards the player has collected.
  int luminaShards = 0;

  /// Whether the Bloom Pulse ability has been unlocked.
  bool bloomPulseUnlocked = false;

  /// Whether the Veil Shift ability has been unlocked.
  bool veilShiftUnlocked = false;

  /// Whether the First Veil has been fully restored.
  bool veilComplete = false;

  /// True while the title screen is displayed.
  bool isTitleActive = true;

  double _pulseCooldown = 0;
  double _shiftCooldown = 0;

  /// Whether the Sanctuary overlay is open.
  bool get isSanctuaryOpen => _sanctuaryOverlay.isOpen;

  /// Whether the Settings overlay is open.
  bool get isSettingsOpen => _settingsScreen.isOpen;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // ── Load saved progress ──────────────────────────────────────────────
    final saved = await SaveSystem.load();
    luminaShards = saved.shards;
    bloomPulseUnlocked = saved.bloomPulseUnlocked;
    veilShiftUnlocked = saved.veilShiftUnlocked;

    final bloomedNodes = await SaveSystem.loadBloomedNodes();
    veilComplete = await SaveSystem.loadVeilComplete();

    final volumes = await SaveSystem.loadVolumes();

    // ── Preload audio ────────────────────────────────────────────────────
    await AudioManager.preload([
      GameConfig.sfxShardCollect,
      GameConfig.sfxBloomAwaken,
      GameConfig.sfxBloomPulse,
      GameConfig.sfxUiClick,
      GameConfig.sfxAbilityUnlock,
      GameConfig.sfxVeilShift,
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
      onVeilComplete: _onVeilComplete,
      preBloomedIndices: bloomedNodes,
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

    _settingsScreen = SettingsScreen()..priority = 11;
    await add(_settingsScreen);

    await add(_InputHandler()..priority = 10);

    camera.follow(player, maxSpeed: GameConfig.cameraFollowSpeed);

    // ── Apply loaded state ───────────────────────────────────────────────
    _shardCounter.updateCount(luminaShards);
    _sanctuaryOverlay.updateShards(luminaShards);
    _sanctuaryOverlay.updateBloomAbility(bloomPulseUnlocked);
    _sanctuaryOverlay.updateShiftAbility(veilShiftUnlocked);
    _sanctuaryOverlay.updateVeilComplete(veilComplete);
    if (bloomPulseUnlocked) {
      _abilityHud.unlockBloom(showNotification: false);
    }
    if (veilShiftUnlocked) {
      _abilityHud.unlockShift(showNotification: false);
    }

    // Apply saved volumes
    _settingsScreen.setVolumes(
        volumes.master, volumes.music, volumes.sfx);

    // ── Title screen (on top of everything) ──────────────────────────────
    await add(TitleScreen(onDismissed: _onTitleDone)..priority = 50);
  }

  // ── Title screen callback ──────────────────────────────────────────────

  void _onTitleDone() {
    isTitleActive = false;
    AudioManager.playBgm(GameConfig.bgmAmbient, volume: 0.4);
  }

  // ── Game loop ──────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);

    // Bloom Pulse cooldown
    if (_pulseCooldown > 0) {
      _pulseCooldown = max(0, _pulseCooldown - dt);
      _abilityHud.updateBloomCooldown(
        _pulseCooldown / GameConfig.bloomPulseCooldown,
      );
    }

    // Veil Shift cooldown
    if (_shiftCooldown > 0) {
      _shiftCooldown = max(0, _shiftCooldown - dt);
      _abilityHud.updateShiftCooldown(
        _shiftCooldown / GameConfig.veilShiftCooldown,
      );
    }
  }

  // ── Shard collection ───────────────────────────────────────────────────

  void collectShard() {
    luminaShards++;
    _shardCounter.updateCount(luminaShards);
    _sanctuaryOverlay.updateShards(luminaShards);

    AudioManager.playSfx(GameConfig.sfxShardCollect, volume: 0.7);

    // Check Bloom Pulse unlock
    if (luminaShards >= GameConfig.bloomPulseThreshold &&
        !bloomPulseUnlocked) {
      bloomPulseUnlocked = true;
      _abilityHud.unlockBloom();
      _sanctuaryOverlay.updateBloomAbility(true);
      AudioManager.playSfx(GameConfig.sfxAbilityUnlock, volume: 0.8);
    }

    // Check Veil Shift unlock
    if (luminaShards >= GameConfig.veilShiftThreshold &&
        !veilShiftUnlocked) {
      veilShiftUnlocked = true;
      _abilityHud.unlockShift();
      _sanctuaryOverlay.updateShiftAbility(true);
      AudioManager.playSfx(GameConfig.sfxAbilityUnlock, volume: 0.8);
    }

    SaveSystem.save(luminaShards, bloomPulseUnlocked, veilShiftUnlocked);
  }

  // ── Veil completion ────────────────────────────────────────────────────

  void _onVeilComplete() {
    if (veilComplete) return; // guard against duplicate

    veilComplete = true;
    SaveSystem.saveVeilComplete(true);
    _sanctuaryOverlay.updateVeilComplete(true);

    // Play the completion audio (reuse ability_unlock at full volume)
    AudioManager.playSfx(GameConfig.sfxAbilityUnlock, volume: 1.0);

    // Show the completion overlay
    add(CompletionOverlay()..priority = 40);
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

  // ── Veil Shift ability ─────────────────────────────────────────────────

  void activateVeilShift() {
    if (!veilShiftUnlocked || _shiftCooldown > 0) return;

    // Find nearest unbloomed node within range
    final target = _firstVeil.findNearestUnbloomed(player.position);
    if (target == null) return;

    _shiftCooldown = GameConfig.veilShiftCooldown;
    AudioManager.playSfx(GameConfig.sfxVeilShift, volume: 0.7);

    // Spawn light trail
    world.add(VeilShiftTrail(
      start: player.position.clone(),
      end: target,
    ));

    // Dash player to target
    player.dashTo(target);
  }

  // ── UI tap routing ─────────────────────────────────────────────────────

  bool handleUiTap(Vector2 canvasPos) {
    // Settings gear button
    if (_settingsScreen.isGearAt(canvasPos)) {
      _settingsScreen.toggle();
      AudioManager.playSfx(GameConfig.sfxUiClick, volume: 0.5);
      return true;
    }

    // Sanctuary button
    if (_sanctuaryOverlay.isButtonAt(canvasPos)) {
      _sanctuaryOverlay.toggle();
      AudioManager.playSfx(GameConfig.sfxUiClick, volume: 0.5);
      return true;
    }

    // Ability buttons
    if (_abilityHud.isBloomButtonAt(canvasPos)) {
      activateBloomPulse();
      return true;
    }
    if (_abilityHud.isShiftButtonAt(canvasPos)) {
      activateVeilShift();
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

  void closeSettings() {
    if (_settingsScreen.isOpen) {
      _settingsScreen.close();
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
  bool _isDraggingSlider = false;

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (game.isTitleActive) return;

    // Settings overlay intercepts first
    if (game.isSettingsOpen) {
      if (game._settingsScreen.handleSliderTap(event.canvasPosition)) {
        _isDraggingSlider = true;
        return;
      }
      game.closeSettings();
      return;
    }

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
    if (_isDraggingSlider) {
      game._settingsScreen.handleSliderDrag(event.canvasEndPosition);
      return;
    }
    if (!_isDraggingWorld) return;
    game.player.moveTo(game.screenToWorld(event.canvasEndPosition));
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (_isDraggingSlider) {
      game._settingsScreen.handleSliderEnd();
      _isDraggingSlider = false;
      return;
    }
    _isDraggingWorld = false;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (game.isTitleActive) return;
    if (game.isSettingsOpen) {
      game.closeSettings();
      return;
    }
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
