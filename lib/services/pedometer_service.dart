import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class PedometerService {
  PedometerService._();
  static final PedometerService instance = PedometerService._();

  StreamSubscription<StepCount>? _sub;
  int _baseSteps = -1;
  int _todaySteps = 0;
  bool _running = false;

  void Function()? _onStep;

  bool get isRunning => _running;

  /// 啟動計步器
  Future<bool> start({required void Function() onStep}) async {
    if (_running) return true;
    _onStep = onStep;

    // 請求活動辨識權限 (Android 10+ 需要)
    try {
      final status = await Permission.activityRecognition.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        debugPrint('⚠️ 未授權活動辨識，計步器不可用');
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ 權限請求失敗（模擬器正常）: $e');
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
    if (_baseSteps == -1) {
      _baseSteps = event.steps;
    }

    final current = event.steps - _baseSteps;

    if (current > _todaySteps) {
      final diff = current - _todaySteps;
      _todaySteps = current;
      for (int i = 0; i < diff; i++) {
        _onStep?.call();
      }
    }
  }

  /// 停止計步器
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _running = false;
    debugPrint('⏹ 計步器已停止');
  }
}