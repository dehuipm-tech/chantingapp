import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/daily_log.dart';
import '../services/feedback_service.dart';
import '../services/storage_service.dart';

enum ChantState { idle, running, paused }

// ✅ 新增 timer / bow
enum RhythmMode { step, timed, timer, bow }
enum TimedMode { sound, soundStep }

class ChantProvider extends ChangeNotifier {
  // ============ 核心狀態 ============
  int _chantCount = 0;
  int _stepCount = 0;
  ChantState _state = ChantState.idle;

  // ============ 節奏設定 ============
  RhythmMode _rhythm = RhythmMode.step;
  TimedMode _timedMode = TimedMode.sound;

  int _bpm = 60;
  int _stepsPerChant = 1;

  // ✅ 定時念佛
  int _timerMinutes = 30;

  // ✅ 拜佛
  int _bowCount = 108;
  int _bowMinutes = 30;

  // ============ 內部計時器 ============
  Timer? _woodenTimer;
  int _baseSteps = 0;
  int _elapsedSeconds = 0;

  // ============ Getter ============
  int get chantCount => _chantCount;
  int get stepCount => _stepCount;
  ChantState get state => _state;
  RhythmMode get rhythm => _rhythm;
  TimedMode get timedMode => _timedMode;
  int get bpm => _bpm;
  int get stepsPerChant => _stepsPerChant;
  int get timerMinutes => _timerMinutes;
  int get bowCount => _bowCount;
  int get bowMinutes => _bowMinutes;
  int get elapsedSeconds => _elapsedSeconds;

  bool get isRunning => _state == ChantState.running;
  bool get isPaused => _state == ChantState.paused;
  bool get isIdle => _state == ChantState.idle;

  bool get needPedometer {
    if (_rhythm == RhythmMode.step) return true;
    if (_rhythm == RhythmMode.timed) return _timedMode == TimedMode.soundStep;
    return false; // timer / bow 不需要計步器
  }

  // ============ 初始化 ============
  Future<void> init() async {
    _stepCount = await StorageService.instance.loadStepCount();
    _chantCount = await StorageService.instance.loadChantCount();
    notifyListeners();
  }

  // ============ 設定 ============
  void setRhythm(RhythmMode r) {
    if (_state == ChantState.running) return;
    if (_rhythm == r) return;
    _rhythm = r;
    notifyListeners();
  }

  void setTimedMode(TimedMode m) {
    if (_state == ChantState.running) return;
    if (_timedMode == m) return;
    _timedMode = m;
    notifyListeners();
  }

  void setBpm(int bpm) {
    if (_state == ChantState.running) return;
    _bpm = bpm.clamp(30, 200);
    notifyListeners();
  }

  void setStepsPerChant(int n) {
    if (_state == ChantState.running) return;
    _stepsPerChant = n.clamp(1, 10);
    notifyListeners();
  }

  // ✅ 定時念佛設定
  void setTimerMinutes(int m) {
    if (_state == ChantState.running) return;
    _timerMinutes = m.clamp(1, 600);
    notifyListeners();
  }

  // ✅ 拜佛設定
  void setBowCount(int c) {
    if (_state == ChantState.running) return;
    _bowCount = c.clamp(1, 9999);
    notifyListeners();
  }

  void setBowMinutes(int m) {
    if (_state == ChantState.running) return;
    _bowMinutes = m.clamp(1, 600);
    notifyListeners();
  }

  // ============ 念佛控制 ============
  Future<void> start() async {
    if (_state != ChantState.idle) return;

    _state = ChantState.running;
    _chantCount = 0;
    _baseSteps = _stepCount;
    _elapsedSeconds = 0;

    FeedbackService.instance.start();

    switch (_rhythm) {
      case RhythmMode.step:
        // 靠 PedometerService 的 onStep
        break;
      case RhythmMode.timed:
        _startWoodenTimer(intervalMs: (60000 / _bpm).round());
        break;
      case RhythmMode.timer:
        _startTimerMode();
        break;
      case RhythmMode.bow:
        _startBowMode();
        break;
    }

    await StorageService.instance.saveChantCount(_chantCount);
    notifyListeners();
  }

  Future<void> pause() async {
    if (_state != ChantState.running) return;
    _state = ChantState.paused;
    _stopWoodenTimer();
    FeedbackService.instance.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    if (_state != ChantState.paused) return;
    _state = ChantState.running;
    FeedbackService.instance.resume();

    switch (_rhythm) {
      case RhythmMode.step:
        break;
      case RhythmMode.timed:
        _startWoodenTimer(intervalMs: (60000 / _bpm).round());
        break;
      case RhythmMode.timer:
        _resumeTimerMode();
        break;
      case RhythmMode.bow:
        _resumeBowMode();
        break;
    }
    notifyListeners();
  }

  Future<void> finish() async {
    if (_state == ChantState.idle) return;
    _stopWoodenTimer();
    _state = ChantState.idle;
    FeedbackService.instance.finish();

    // 🔥 寫入本機每日明細
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    if (_chantCount > 0) {
      await StorageService.instance.saveDailyLog(DailyLog(
        id: now.millisecondsSinceEpoch.toString(),
        date: dateStr,
        time: timeStr,
        type: 'chant',
        item: _rhythm == RhythmMode.bow ? '拜佛' : '佛號',
        count: _chantCount,
        remark: 'App自動記錄',
      ));
    }

    if (_stepCount > 0) {
      await StorageService.instance.saveDailyLog(DailyLog(
        id: '${now.millisecondsSinceEpoch}_steps',
        date: dateStr,
        time: timeStr,
        type: 'step',
        item: '步數',
        count: _stepCount,
        remark: 'App自動記錄',
      ));
    }

    await StorageService.instance.saveChantCount(_chantCount);
    await StorageService.instance.saveStepCount(_stepCount);
    notifyListeners();
  }

  void manualAddChant() {
    if (_state != ChantState.running) return;
    _chantCount++;
    FeedbackService.instance.chant();
    StorageService.instance.saveChantCount(_chantCount);
    notifyListeners();
  }

  // ============ 定速念佛 ============
  void _startWoodenTimer({required int intervalMs}) {
    _stopWoodenTimer();
    _woodenTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (_state != ChantState.running) return;
      _chantCount++;
      FeedbackService.instance.chant();
      StorageService.instance.saveChantCount(_chantCount);
      notifyListeners();
    });
  }

  void _stopWoodenTimer() {
    _woodenTimer?.cancel();
    _woodenTimer = null;
  }

  // ============ ✅ 定時念佛 ============
  void _startTimerMode() {
    _stopWoodenTimer();
    final intervalMs = (60000 / _bpm).round();
    _woodenTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (_state != ChantState.running) return;
      _chantCount++;
      FeedbackService.instance.chant();
      StorageService.instance.saveChantCount(_chantCount);

      // 每 1 秒計一次時間（依實際 bpm 換算比較精準）
      _elapsedSeconds += (intervalMs / 1000).round();
      if (_elapsedSeconds >= _timerMinutes * 60) {
        finish();
        return;
      }
      notifyListeners();
    });
  }

  void _resumeTimerMode() {
    // resume 時不重置 _elapsedSeconds，只重建 timer
    _startTimerMode();
  }

  // ============ ✅ 拜佛 ============
  void _startBowMode() {
    _stopWoodenTimer();
    final totalSec = _bowMinutes * 60;
    final secPerBow = (totalSec / _bowCount).round().clamp(1, 999999);
    _woodenTimer = Timer.periodic(Duration(seconds: secPerBow), (_) {
      if (_state != ChantState.running) return;
      _chantCount++;
      FeedbackService.instance.chant();
      StorageService.instance.saveChantCount(_chantCount);

      if (_chantCount >= _bowCount) {
        finish();
        return;
      }
      notifyListeners();
    });
  }

  void _resumeBowMode() {
    if (_chantCount >= _bowCount) return;
    _startBowMode();
  }

  // ============ 計步器回報 ============
  void onStep() {
    if (_state != ChantState.running) return;

    _stepCount++;
    StorageService.instance.saveStepCount(_stepCount);

    if (_rhythm == RhythmMode.step) {
      final diff = _stepCount - _baseSteps;
      if (diff > 0 && diff % _stepsPerChant == 0) {
        _chantCount++;
        FeedbackService.instance.chant();
        StorageService.instance.saveChantCount(_chantCount);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _stopWoodenTimer();
    super.dispose();
  }
}