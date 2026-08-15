/// Minimal Settings screen overlay with volume sliders.
///
/// Renders a gear icon when closed (top-right below the Sanctuary button).
/// When opened, displays a full-screen dark overlay with three horizontal
/// volume sliders (Master, Music, SFX). Drag on any slider to adjust.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' hide Gradient;

import '../../config/game_config.dart';
import '../../systems/audio_manager.dart';
import '../../systems/save_system.dart';

class SettingsScreen extends Component with HasGameReference {
  bool _isOpen = false;
  int _activeSlider = -1;
  double _time = 0;

  double masterVol = 0.7;
  double musicVol = 0.5;
  double sfxVol = 0.7;

  TextPainter? _titlePainter;
  final List<TextPainter?> _labelPainters = [null, null, null];
  List<TextPainter?> _valuePainters = [null, null, null];
  TextPainter? _hintPainter;

  bool get isOpen => _isOpen;

  void open() {
    _isOpen = true;
    _rebuildValueTexts();
  }

  void close() {
    _isOpen = false;
    _saveVolumes();
  }

  void toggle() => _isOpen ? close() : open();

  /// Apply loaded volumes without opening the screen.
  void setVolumes(double master, double music, double sfx) {
    masterVol = master;
    musicVol = music;
    sfxVol = sfx;
    AudioManager.masterVolume = master;
    AudioManager.musicVolume = music;
    AudioManager.sfxVolume = sfx;
  }

  // ── Layout helpers ─────────────────────────────────────────────────────

  double get _sliderW => GameConfig.settingsSliderWidth;
  double get _baseY => game.size.y * 0.36;
  double get _sliderX => (game.size.x - _sliderW) / 2;

  double _sliderY(int row) =>
      _baseY + row * GameConfig.settingsRowSpacing;

  // Gear icon position (below Sanctuary button)
  double get _gearX =>
      game.size.x - GameConfig.shardHudPadding - GameConfig.sanctuaryBtnSize / 2;
  double get _gearY =>
      GameConfig.shardHudPadding + GameConfig.sanctuaryBtnSize + 24;

  // ── Hit testing ────────────────────────────────────────────────────────

  bool isGearAt(Vector2 pos) {
    return pos.distanceTo(Vector2(_gearX, _gearY)) <
        GameConfig.settingsGearRadius + 10;
  }

  bool handleSliderTap(Vector2 pos) {
    if (!_isOpen) return false;
    for (int i = 0; i < 3; i++) {
      if (_isOnSlider(pos, i)) {
        _activeSlider = i;
        _updateSliderValue(pos.x);
        return true;
      }
    }
    return false;
  }

  void handleSliderDrag(Vector2 pos) {
    if (_activeSlider >= 0) _updateSliderValue(pos.x);
  }

  void handleSliderEnd() {
    if (_activeSlider >= 0) {
      _activeSlider = -1;
      _saveVolumes();
    }
  }

  bool _isOnSlider(Vector2 pos, int row) {
    final y = _sliderY(row);
    return pos.x >= _sliderX - 15 &&
        pos.x <= _sliderX + _sliderW + 15 &&
        (pos.y - y).abs() < 22;
  }

  void _updateSliderValue(double x) {
    final val = ((x - _sliderX) / _sliderW).clamp(0.0, 1.0);
    switch (_activeSlider) {
      case 0:
        masterVol = val;
        AudioManager.masterVolume = val;
      case 1:
        musicVol = val;
        AudioManager.musicVolume = val;
      case 2:
        sfxVol = val;
        AudioManager.sfxVolume = val;
    }
    AudioManager.applyBgmVolume();
    _rebuildValueTexts();
  }

  void _saveVolumes() {
    SaveSystem.saveVolumes(masterVol, musicVol, sfxVol);
  }

  // ── Text builders ─────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _titlePainter = _text(
      '⚙  Settings',
      const Color(0xCCEADDFF),
      20,
      FontWeight.w200,
      letterSpacing: 4,
    );
    const labels = ['Master', 'Music', 'SFX'];
    for (int i = 0; i < 3; i++) {
      _labelPainters[i] = _text(
        labels[i],
        const Color(0xAA9B8DCC),
        13,
        FontWeight.w300,
        letterSpacing: 1,
      );
    }
    _hintPainter = _text(
      'tap outside to close',
      const Color(0x55FFFFFF),
      12,
      FontWeight.w300,
      letterSpacing: 2,
    );
    _rebuildValueTexts();
  }

  void _rebuildValueTexts() {
    final vals = [masterVol, musicVol, sfxVol];
    _valuePainters = List.generate(3, (i) {
      return _text(
        '${(vals[i] * 100).round()}%',
        const Color(0xAA9B8DCC),
        13,
        FontWeight.w300,
      );
    });
  }

  TextPainter _text(
    String text,
    Color color,
    double fontSize,
    FontWeight weight, {
    double letterSpacing = 0,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: letterSpacing,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  // ── Update ─────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  // ── Render ─────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    _renderGearIcon(canvas);
    if (_isOpen) _renderOverlay(canvas);
  }

  void _renderGearIcon(Canvas canvas) {
    final cx = _gearX;
    final cy = _gearY;
    final r = GameConfig.settingsGearRadius;
    final pulse = 0.6 + 0.3 * sin(_time * 1.2);
    final color = GameConfig.sanctuaryColor;

    // Glow
    canvas.drawCircle(
      Offset(cx, cy),
      r * 2.5,
      Paint()
        ..shader = Gradient.radial(Offset(cx, cy), r * 2.5, [
          color.withValues(alpha: 0.08 * pulse),
          color.withValues(alpha: 0),
        ])
        ..blendMode = BlendMode.plus,
    );

    // Ring
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.55,
      Paint()
        ..color = color.withValues(alpha: 0.5 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..blendMode = BlendMode.plus,
    );

    // 6 gear teeth
    for (int i = 0; i < 6; i++) {
      final angle = i * pi / 3 + _time * 0.3;
      final tx = cx + cos(angle) * r;
      final ty = cy + sin(angle) * r;
      canvas.drawCircle(
        Offset(tx, ty),
        1.8,
        Paint()
          ..color = color.withValues(alpha: 0.4 * pulse)
          ..blendMode = BlendMode.plus,
      );
    }
  }

  void _renderOverlay(Canvas canvas) {
    final sw = game.size.x;
    final sh = game.size.y;

    // 1) Dark scrim
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sw, sh),
      Paint()..color = const Color(0xDD050510),
    );

    // 2) Title
    final cx = sw / 2;
    if (_titlePainter != null) {
      _titlePainter!.paint(
        canvas,
        Offset(cx - _titlePainter!.width / 2, _baseY - 65),
      );
    }

    // 3) Sliders
    final color = GameConfig.sanctuaryColor;
    final vals = [masterVol, musicVol, sfxVol];

    for (int i = 0; i < 3; i++) {
      final y = _sliderY(i);
      final sx = _sliderX;

      // Label
      if (_labelPainters[i] != null) {
        _labelPainters[i]!.paint(
          canvas,
          Offset(sx - _labelPainters[i]!.width - 14, y - 8),
        );
      }

      // Track background
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(sx, y - 2, _sliderW, 4),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0x22FFFFFF),
      );

      // Filled portion
      final fillW = _sliderW * vals[i];
      if (fillW > 0.5) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(sx, y - 2, fillW, 4),
            const Radius.circular(2),
          ),
          Paint()
            ..color = color.withValues(alpha: 0.55)
            ..blendMode = BlendMode.plus,
        );
      }

      // Knob
      final knobX = sx + fillW;
      canvas.drawCircle(
        Offset(knobX, y),
        6,
        Paint()
          ..shader = Gradient.radial(Offset(knobX, y), 6, [
            color.withValues(alpha: 0.6),
            color.withValues(alpha: 0.1),
          ])
          ..blendMode = BlendMode.plus,
      );
      canvas.drawCircle(
        Offset(knobX, y),
        3,
        Paint()
          ..color = GameConfig.sanctuaryCoreColor.withValues(alpha: 0.8)
          ..blendMode = BlendMode.plus,
      );

      // Value
      if (_valuePainters[i] != null) {
        _valuePainters[i]!.paint(
          canvas,
          Offset(sx + _sliderW + 14, y - 8),
        );
      }
    }

    // 4) Hint
    if (_hintPainter != null) {
      _hintPainter!.paint(
        canvas,
        Offset(cx - _hintPainter!.width / 2, sh - 50),
      );
    }
  }
}
