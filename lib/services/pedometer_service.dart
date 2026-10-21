import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class PedometerService {
  PedometerService._();
  static final PedometerService instance = PedometerService._();

  StreamSubscription<StepCount>? _sub;
  int _todaySteps = 0;
  bool _running = false;

  void Function()? _onStep;

  bool get isRunning => _running;
  int get todaySteps => _todaySteps; // 👈 這是你要的 Getter

  /// 啟動計步器
  Future<bool> start({required void Function() onStep}) async {
    // 🔥 不管有沒有在跑，永遠更新最新的 onStep 回呼！
    _onStep = onStep; 

    if (_running) return true; // 如果已經在跑，直接回傳成功，但已更新回呼

    try {
      // 1. 先使用 pedometer 套件本身請求權限（iOS 必須）
      final permission = await Pedometer.requestPermissions();
      if (!permission) {
        debugPrint('⚠️ 未授權計步器權限 (iOS)');
      }

      // 2. 如果是 Android，再請求 activityRecognition
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.activityRecognition.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          debugPrint('⚠️ 未授權活動辨識 (Android)，計步器不可用');
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