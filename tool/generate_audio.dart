/// Procedural audio generator for Whispers of the Veil.
///
/// Generates WAV files (16-bit PCM, mono, 44100 Hz) for all game
/// sound effects and the ambient background music track.
///
/// Run with: dart tool/generate_audio.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int kRate = 44100;
const double kPi2 = 2 * pi;

void main() {
  Directory('assets/audio').createSync(recursive: true);

  _gen('assets/audio/shard_collect.wav', 0.45, _shardCollect);
  _gen('assets/audio/bloom_awaken.wav', 0.70, _bloomAwaken);
  _gen('assets/audio/bloom_pulse.wav', 0.55, _bloomPulse);
  _gen('assets/audio/ui_click.wav', 0.12, _uiClick);
  _gen('assets/audio/ability_unlock.wav', 1.20, _abilityUnlock);
  _gen('assets/audio/veil_shift.wav', 0.40, _veilShift);
  _gen('assets/audio/ambient_veil.wav', 14.0, _ambientDrone);

  print('Done — 7 audio files generated in assets/audio/');
}

// ─── Generator orchestrator ──────────────────────────────────────────────────

void _gen(String path, double dur, List<double> Function(int n) fn) {
  final n = (kRate * dur).toInt();
  final s = fn(n);
  _normalize(s, 0.82);
  _softLowPass(s, 0.35);
  _writeWav(path, s);
  print('  $path  ${(dur * 1000).round()}ms  ${File(path).lengthSync()} bytes');
}

// ─── Sound generators ────────────────────────────────────────────────────────

/// Rising crystalline chime.
List<double> _shardCollect(int n) {
  final s = List<double>.filled(n, 0);
  for (int i = 0; i < n; i++) {
    final t = i / kRate;
    // Rising frequency: C5 → B5
    final f = 523.25 + 467 * (t / (n / kRate));
    final env = _fastAttack(t) * exp(-t * 7);

    var v = sin(kPi2 * f * t) * 0.40;
    v += sin(kPi2 * f * 2.0 * t) * 0.18;
    v += sin(kPi2 * f * 3.0 * t) * 0.08;
    v += sin(kPi2 * f * 5.4 * t) * 0.04; // bell partial
    s[i] = v * env;
  }
  _addReverb(s, 4, 0.04, 0.45);
  return s;
}

/// Warm major chord swell.
List<double> _bloomAwaken(int n) {
  final s = List<double>.filled(n, 0);
  final dur = n / kRate;
  for (int i = 0; i < n; i++) {
    final t = i / kRate;
    final env = _adsr(t, 0.15, 0.15, 0.6, 0.35, dur);

    // C4 + E4 + G4 + C5 chord
    var v = sin(kPi2 * 261.63 * t) * 0.30;
    v += sin(kPi2 * 329.63 * t) * 0.22;
    v += sin(kPi2 * 392.00 * t) * 0.22;
    v += sin(kPi2 * 523.25 * t) * 0.10;
    // Slight detuned layer for warmth
    v += sin(kPi2 * 262.5 * t) * 0.08;
    s[i] = v * env;
  }
  _addReverb(s, 5, 0.05, 0.40);
  return s;
}

/// Sweeping whoosh with noise.
List<double> _bloomPulse(int n) {
  final rng = Random(42);
  final s = List<double>.filled(n, 0);
  for (int i = 0; i < n; i++) {
    final t = i / kRate;
    final env = _fastAttack(t) * exp(-t * 4);
    final f = 150 + 650 * pow(t / (n / kRate), 0.7);

    var v = sin(kPi2 * f * t) * 0.25;
    v += sin(kPi2 * f * 1.5 * t) * 0.10;
    // Noise whoosh
    v += (rng.nextDouble() * 2 - 1) * 0.20 * exp(-t * 5);
    s[i] = v * env;
  }
  _addReverb(s, 3, 0.03, 0.35);
  return s;
}

/// Soft high click.
List<double> _uiClick(int n) {
  final s = List<double>.filled(n, 0);
  for (int i = 0; i < n; i++) {
    final t = i / kRate;
    final env = exp(-t * 45);
    var v = sin(kPi2 * 1100 * t) * 0.30;
    v += sin(kPi2 * 1650 * t) * 0.15;
    s[i] = v * env;
  }
  return s;
}

/// Dramatic ascending chord for ability unlock.
List<double> _abilityUnlock(int n) {
  final s = List<double>.filled(n, 0);
  final dur = n / kRate;
  for (int i = 0; i < n; i++) {
    final t = i / kRate;
    final env = _adsr(t, 0.2, 0.2, 0.7, 0.6, dur);
    // Ascending: notes stagger in
    var v = sin(kPi2 * 261.63 * t) * 0.22; // C4 from start

    if (t > 0.15) {
      final e2 = _adsr(t - 0.15, 0.1, 0.1, 0.7, 0.5, dur - 0.15);
      v += sin(kPi2 * 329.63 * t) * 0.18 * e2; // E4
    }
    if (t > 0.30) {
      final e3 = _adsr(t - 0.30, 0.1, 0.1, 0.7, 0.4, dur - 0.30);
      v += sin(kPi2 * 392.0 * t) * 0.18 * e3; // G4
    }
    if (t > 0.45) {
      final e4 = _adsr(t - 0.45, 0.15, 0.1, 0.6, 0.3, dur - 0.45);
      v += sin(kPi2 * 523.25 * t) * 0.15 * e4; // C5
    }
    if (t > 0.60) {
      final e5 = _adsr(t - 0.60, 0.15, 0.1, 0.5, 0.25, dur - 0.60);
      v += sin(kPi2 * 659.25 * t) * 0.10 * e5; // E5
    }

    s[i] = v * env;
  }
  _addReverb(s, 6, 0.06, 0.42);
  return s;
}

/// Quick descending whoosh for teleport dash.
List<double> _veilShift(int n) {
  final rng = Random(77);
  final s = List<double>.filled(n, 0);
  final dur = n / kRate;
  for (int i = 0; i < n; i++) {
    final t = i / kRate;
    final env = _fastAttack(t) * exp(-t * 6);

    // Descending sweep: 1200 → 300 Hz
    final f = 1200 - 900 * pow(t / dur, 0.5);
    var v = sin(kPi2 * f * t) * 0.22;
    v += sin(kPi2 * f * 0.5 * t) * 0.10; // sub-octave

    // Noise whoosh
    v += (rng.nextDouble() * 2 - 1) * 0.18 * exp(-t * 4);

    s[i] = v * env;
  }
  _addReverb(s, 3, 0.02, 0.30);
  return s;
}

/// Evolving ambient drone (loopable).
List<double> _ambientDrone(int n) {
  final rng = Random(42);
  final s = List<double>.filled(n, 0);
  final dur = n / kRate;

  for (int i = 0; i < n; i++) {
    final t = i / kRate;

    // Layer 1 — low fundamental C2 with slow detune
    final f1 = 65.41;
    var v = sin(kPi2 * f1 * t) * 0.14;
    v += sin(kPi2 * f1 * 1.002 * t) * 0.10; // beating

    // Layer 2 — G2 fifth
    v += sin(kPi2 * 98.0 * t) * 0.07 *
        (0.6 + 0.4 * sin(kPi2 * 0.06 * t));

    // Layer 3 — C3 octave, slow AM
    v += sin(kPi2 * 130.81 * t) * 0.05 *
        (0.5 + 0.5 * sin(kPi2 * 0.08 * t));

    // Layer 4 — high shimmer E4
    v += sin(kPi2 * 329.63 * t) * 0.015 *
        (0.3 + 0.7 * sin(kPi2 * 0.11 * t + 1.2));

    // Overall breathing
    v *= 0.7 + 0.3 * sin(kPi2 * 0.04 * t);

    // Subtle noise texture
    v += (rng.nextDouble() * 2 - 1) * 0.008;

    // Crossfade for loop-seamless (1.5 s tails)
    final fadeIn = min(1.0, t / 1.5);
    final fadeOut = min(1.0, (dur - t) / 1.5);
    s[i] = v * fadeIn * fadeOut;
  }

  _addReverb(s, 5, 0.08, 0.30);
  return s;
}

// ─── DSP helpers ─────────────────────────────────────────────────────────────

double _fastAttack(double t) => min(1.0, t / 0.005);

double _adsr(double t, double a, double d, double s, double r, double dur) {
  if (t < 0) return 0;
  if (t < a) return t / a;
  if (t < a + d) return 1.0 - (1.0 - s) * (t - a) / d;
  if (t < dur - r) return s;
  if (t < dur) return s * (dur - t) / r;
  return 0;
}

void _normalize(List<double> s, double peak) {
  var mx = 0.0;
  for (final v in s) {
    if (v.abs() > mx) mx = v.abs();
  }
  if (mx < 0.001) return;
  final gain = peak / mx;
  for (int i = 0; i < s.length; i++) {
    s[i] *= gain;
  }
}

void _softLowPass(List<double> s, double alpha) {
  var prev = s[0];
  for (int i = 1; i < s.length; i++) {
    s[i] = prev + alpha * (s[i] - prev);
    prev = s[i];
  }
}

void _addReverb(List<double> s, int taps, double delay, double decay) {
  for (int t = 1; t <= taps; t++) {
    final d = (kRate * delay * t).toInt();
    final g = pow(decay, t).toDouble();
    for (int i = d; i < s.length; i++) {
      s[i] += s[i - d] * g;
    }
  }
}

// ─── WAV writer ──────────────────────────────────────────────────────────────

void _writeWav(String path, List<double> samples) {
  final n = samples.length;
  final dataSize = n * 2;
  final buf = ByteData(44 + dataSize);

  void ascii(int off, String s) {
    for (int i = 0; i < s.length; i++) {
      buf.setUint8(off + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  buf.setUint32(4, 36 + dataSize, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  buf.setUint32(16, 16, Endian.little);
  buf.setUint16(20, 1, Endian.little); // PCM
  buf.setUint16(22, 1, Endian.little); // mono
  buf.setUint32(24, kRate, Endian.little);
  buf.setUint32(28, kRate * 2, Endian.little);
  buf.setUint16(32, 2, Endian.little);
  buf.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  buf.setUint32(40, dataSize, Endian.little);

  for (int i = 0; i < n; i++) {
    buf.setInt16(44 + i * 2, (samples[i].clamp(-1.0, 1.0) * 32767).toInt(),
        Endian.little);
  }

  File(path).writeAsBytesSync(buf.buffer.asUint8List());
}
