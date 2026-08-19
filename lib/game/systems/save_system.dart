/// Persistence layer using [SharedPreferences].
///
/// Saves and restores player progress (shards, abilities, bloomed nodes),
/// volume settings, completion state, and current veil.
library;

import 'package:shared_preferences/shared_preferences.dart';

abstract final class SaveSystem {
  static const _keyShards = 'lumina_shards';
  static const _keyBloomPulse = 'bloom_pulse_unlocked';
  static const _keyVeilShift = 'veil_shift_unlocked';
  static const _keyBloomedNodes = 'bloomed_nodes';
  static const _keyVeilComplete = 'veil_complete';
  static const _keyMasterVol = 'vol_master';
  static const _keyMusicVol = 'vol_music';
  static const _keySfxVol = 'vol_sfx';

  // Second Veil keys
  static const _keySecondBloomedNodes = 'second_bloomed_nodes';
  static const _keySecondVeilComplete = 'second_veil_complete';
  static const _keyCurrentVeil = 'current_veil';

  // ── Core progress ──────────────────────────────────────────────────────

  /// Persist core progress.
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

  /// Load core progress. Returns defaults on first run.
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

  // ── Bloomed node state (First Veil) ────────────────────────────────────

  /// Save which bloom node indices have been fully bloomed.
  static Future<void> saveBloomedNodes(Set<int> indices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyBloomedNodes,
      indices.map((i) => '$i').toList(),
    );
  }

  /// Load the set of previously bloomed node indices.
  static Future<Set<int>> loadBloomedNodes() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyBloomedNodes);
    if (list == null || list.isEmpty) return {};
    return list.map(int.parse).toSet();
  }

  // ── Bloomed node state (Second Veil) ───────────────────────────────────

  static Future<void> saveSecondBloomedNodes(Set<int> indices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keySecondBloomedNodes,
      indices.map((i) => '$i').toList(),
    );
  }

  static Future<Set<int>> loadSecondBloomedNodes() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keySecondBloomedNodes);
    if (list == null || list.isEmpty) return {};
    return list.map(int.parse).toSet();
  }

  // ── Veil completion ────────────────────────────────────────────────────

  static Future<void> saveVeilComplete(bool complete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVeilComplete, complete);
  }

  static Future<bool> loadVeilComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyVeilComplete) ?? false;
  }

  static Future<void> saveSecondVeilComplete(bool complete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySecondVeilComplete, complete);
  }

  static Future<bool> loadSecondVeilComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySecondVeilComplete) ?? false;
  }

  // ── Current veil ───────────────────────────────────────────────────────

  /// 0 = First Veil, 1 = Second Veil.
  static Future<void> saveCurrentVeil(int veilIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentVeil, veilIndex);
  }

  static Future<int> loadCurrentVeil() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCurrentVeil) ?? 0;
  }

  // ── Volume settings ────────────────────────────────────────────────────

  static Future<void> saveVolumes(
      double master, double music, double sfx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMasterVol, master);
    await prefs.setDouble(_keyMusicVol, music);
    await prefs.setDouble(_keySfxVol, sfx);
  }

  static Future<({double master, double music, double sfx})>
      loadVolumes() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      master: prefs.getDouble(_keyMasterVol) ?? 0.7,
      music: prefs.getDouble(_keyMusicVol) ?? 0.5,
      sfx: prefs.getDouble(_keySfxVol) ?? 0.7,
    );
  }
}
