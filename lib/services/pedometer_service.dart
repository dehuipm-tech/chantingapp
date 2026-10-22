import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class PedometerService {
  PedometerService._();
  static final PedometerService instance = PedometerService._();

  StreamSubscription<StepCount>? _sub;
  int _todaySteps = 0;
  int _baseSteps = -1; // 🔥 用來記錄基底步數
  bool _running = false;

  void Function()? _onStep;

  bool get isRunning => _running;
  int get todaySteps => _todaySteps;

  Future<bool> start({required void Function() onStep}) async {
    _onStep = onStep;

    if (_running) return true;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.activityRecognition.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          debugPrint('⚠️ 未授權活動辨識 (Android)');
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
    // 1. 第一次收到系統步數時，記錄為基底（例如 77 或 2611）
    if (_baseSteps == -1) {
      _baseSteps = event.steps;
      return; // 第一次不更新，首頁維持 0
    }

    // 2. 計算「從這次啟動後」走了幾步
    final current = event.steps - _baseSteps;

    // 3. 如果有新步數，就更新並觸發念佛
    if (current > _todaySteps) {
      final diff = current - _todaySteps;
      _todaySteps = current;
      for (int i = 0; i < diff; i++) {
        _onStep?.call(); 
      }
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _running = false;
    _baseSteps = -1; // 停止時重置基底
    _todaySteps = 0; // 停止時歸零
    debugPrint('⏹ 計步器已停止');
  }
}