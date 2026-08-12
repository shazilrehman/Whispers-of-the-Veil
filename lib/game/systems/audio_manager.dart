/// Thin wrapper around [FlameAudio] that provides master/music/SFX
/// volume controls and graceful degradation when audio files are
/// missing or the platform doesn't support audio.
library;

import 'package:flame_audio/flame_audio.dart';

abstract final class AudioManager {
  static double masterVolume = 0.7;
  static double musicVolume = 0.5;
  static double sfxVolume = 0.7;

  /// Pre-load audio files for faster playback. Failures are ignored.
  static Future<void> preload(List<String> files) async {
    for (final f in files) {
      try {
        await FlameAudio.audioCache.load(f);
      } catch (_) {}
    }
  }

  /// Play a one-shot sound effect.
  static Future<void> playSfx(String file, {double volume = 1.0}) async {
    try {
      await FlameAudio.play(
        file,
        volume: volume * sfxVolume * masterVolume,
      );
    } catch (_) {}
  }

  /// Start looping background music (replaces any current BGM).
  static Future<void> playBgm(String file, {double volume = 1.0}) async {
    try {
      await FlameAudio.bgm.play(
        file,
        volume: volume * musicVolume * masterVolume,
      );
    } catch (_) {}
  }

  /// Stop background music.
  static Future<void> stopBgm() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {}
  }
}
