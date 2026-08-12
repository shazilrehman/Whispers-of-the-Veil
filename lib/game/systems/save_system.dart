/// Simple persistence layer using [SharedPreferences].
///
/// Saves and restores the player's Lumina Shard count and ability
/// unlock states across sessions.
library;

import 'package:shared_preferences/shared_preferences.dart';

abstract final class SaveSystem {
  static const _keyShards = 'lumina_shards';
  static const _keyBloomPulse = 'bloom_pulse_unlocked';
  static const _keyVeilShift = 'veil_shift_unlocked';

  /// Persist current progress.
  static Future<void> save(
    int shards,
    bool bloomPulseUnlocked,
    bool veilShiftUnlocked,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyShards, shards);
    await prefs.setBool(_keyBloomPulse, bloomPulseUnlocked);
    await prefs.setBool(_keyVeilShift, veilShiftUnlocked);
  }

  /// Load saved progress. Returns defaults on first run.
  static Future<
      ({
        int shards,
        bool bloomPulseUnlocked,
        bool veilShiftUnlocked,
      })> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      shards: prefs.getInt(_keyShards) ?? 0,
      bloomPulseUnlocked: prefs.getBool(_keyBloomPulse) ?? false,
      veilShiftUnlocked: prefs.getBool(_keyVeilShift) ?? false,
    );
  }
}
