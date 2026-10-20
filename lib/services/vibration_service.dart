import 'dart:io';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class VibrationService {
  VibrationService._();
  static final VibrationService instance = VibrationService._();

  bool _initialized = false;
  bool _hasVibrator = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _hasVibrator = await Vibration.hasVibrator() ?? false;
    } catch (_) {
      _hasVibrator = false;
    }
  }

  Future<void> vibrateChant() async {
    if (!_initialized) await init();
    if (!_hasVibrator) return;
    try {
      if (Platform.isIOS) {
        await HapticFeedback.mediumImpact();
      } else {
        await Vibration.vibrate(duration: 50);
      }
    } catch (_) {}
  }

  Future<void> vibrateStart() async {
    if (!_initialized) await init();
    if (!_hasVibrator) return;
    try {
      if (Platform.isIOS) {
        await HapticFeedback.heavyImpact();
      } else {
        await Vibration.vibrate(pattern: [50, 30, 50]);
      }
    } catch (_) {}
  }

  Future<void> vibratePause() async {
    if (!_initialized) await init();
    if (!_hasVibrator) return;
    try {
      if (Platform.isIOS) {
        await HapticFeedback.mediumImpact();
      } else {
        await Vibration.vibrate(pattern: [100, 50, 100]);
      }
    } catch (_) {}
  }

  Future<void> vibrateResume() async {
    if (!_initialized) await init();
    if (!_hasVibrator) return;
    try {
      if (Platform.isIOS) {
        await HapticFeedback.lightImpact();
      } else {
        await Vibration.vibrate(duration: 50);
      }
    } catch (_) {}
  }

  Future<void> vibrateFinish() async {
    if (!_initialized) await init();
    if (!_hasVibrator) return;
    try {
      if (Platform.isIOS) {
        await HapticFeedback.heavyImpact();
      } else {
        await Vibration.vibrate(pattern: [300, 100, 200, 100, 500]);
      }
    } catch (_) {}
  }
}