import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class PedometerService {
  PedometerService._();
  static final PedometerService instance = PedometerService._();

  StreamSubscription<StepCount>? _sub;
  int _todaySteps = 0;
  int _baseSteps = -1;
  bool _running = false;

  void Function()? _onStep;

  bool get isRunning => _running;
  int get todaySteps => _todaySteps;

  Future<bool> start({required void Function() onStep}) async {
    // 1. 永遠更新最新的回呼
    _onStep = onStep;

    if (_running) return true;

    // 2. 每次啟動都重置
    _baseSteps = -1;
    _todaySteps = 0;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.activityRecognition.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          debugPrint('⚠️ Android 未授權活動辨識');
          return false;
        }
      }
    } catch (e) {
      debugPrint('⚠️ 權限請求失敗: $e');
    }

    try {
      _sub = Pedometer.stepCountStream.listen(
        _handleStepCount,
        onError: (e) {
          debugPrint('❌ 計步器錯誤: $e');
          _running = false;
        },
        cancelOnError: false,
      );
      _running = true;
      debugPrint('✅ 計步器已啟動');
      return true;
    } catch (e) {
      debugPrint('❌ 計步器啟動失敗: $e');
      _running = false;
      return false;
    }
  }

  void _handleStepCount(StepCount event) {
    // 🔥 第一次收到步數，記為基底，首頁顯示 0
    if (_baseSteps == -1) {
      _baseSteps = event.steps;
      return;
    }

    // 🔥 計算從啟動到現在走了幾步
    final current = event.steps - _baseSteps;

    if (current > _todaySteps) {
      final diff = current - _todaySteps;
      _todaySteps = current;

      // 🔥 每一步都觸發回呼（首頁更新、念佛加次數）
      for (int i = 0; i < diff; i++) {
        _onStep?.call();
      }
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _running = false;
    _baseSteps = -1;
    _todaySteps = 0;
    debugPrint('⏹ 計步器已停止');
  }
}