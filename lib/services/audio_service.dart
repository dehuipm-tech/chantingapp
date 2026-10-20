import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final List<AudioPlayer> _pool = [];
  int _poolIndex = 0;
  static const int _poolSize = 3;

  Uint8List? _cachedWav;
  bool _initialized = false;
  double _volume = 0.7;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    for (int i = 0; i < _poolSize; i++) {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setVolume(_volume);
      _pool.add(p);
    }

    _cachedWav = _generateWoodFishWav();
  }

  void playWoodFish() {
    if (_cachedWav == null) {
      init().then((_) => _playInternal());
      return;
    }
    _playInternal();
  }

  void _playInternal() {
    final player = _pool[_poolIndex];
    _poolIndex = (_poolIndex + 1) % _poolSize;

    player.play(BytesSource(_cachedWav!), volume: _volume).catchError((e) {
      print('❌ 播放失敗: $e');
    });
  }

  Uint8List _generateWoodFishWav() {
    const sampleRate = 22050;
    const duration = 0.20;
    final numSamples = (sampleRate * duration).toInt();
    final dataSize = numSamples * 2;
    final fileSize = 36 + dataSize;
    final buffer = BytesBuilder();

    buffer.add('RIFF'.codeUnits);
    buffer.add(_int32ToBytes(fileSize));
    buffer.add('WAVE'.codeUnits);
    buffer.add('fmt '.codeUnits);
    buffer.add(_int32ToBytes(16));
    buffer.add(_int16ToBytes(1));
    buffer.add(_int16ToBytes(1));
    buffer.add(_int32ToBytes(sampleRate));
    buffer.add(_int32ToBytes(sampleRate * 2));
    buffer.add(_int16ToBytes(2));
    buffer.add(_int16ToBytes(16));
    buffer.add('data'.codeUnits);
    buffer.add(_int32ToBytes(dataSize));

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final freq1 = 220 * exp(-t * 12) + 80;
      final amp1 = exp(-t * 12);
      final freq2 = 1200 * exp(-t * 40) + 400;
      final amp2 = exp(-t * 40) * 0.3;
      final s1 = sin(2 * pi * freq1 * t) * amp1;
      final s2 = sin(2 * pi * freq2 * t) * amp2;
      final sample = ((s1 + s2) * 0.55 * 32767).clamp(-32768, 32767).toInt();
      buffer.add(_int16ToBytes(sample));
    }
    return buffer.toBytes();
  }

  Uint8List _int32ToBytes(int value) {
    return Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.little);
  }

  Uint8List _int16ToBytes(int value) {
    return Uint8List(2)..buffer.asByteData().setInt16(0, value, Endian.little);
  }
}