/// Simple persistence layer using [SharedPreferences].
///
/// Saves and restores the player's Lumina Shard count and ability
/// unlock state across sessions.
library;

import 'package:shared_preferences/shared_preferences.dart';

abstract final class SaveSystem {
  static const _keyShards = 'lumina_shards';
  static const _keyAbility = 'bloom_pulse_unlocked';

  /// Persist current progress.
  static Future<void> save(int shards, bool abilityUnlocked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyShards, shards);
    await prefs.setBool(_keyAbility, abilityUnlocked);
  }

  /// Load saved progress. Returns defaults on first run.
  static Future<({int shards, bool abilityUnlocked})> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      shards: prefs.getInt(_keyShards) ?? 0,
      abilityUnlocked: prefs.getBool(_keyAbility) ?? false,
    );
  }
}
