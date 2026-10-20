import 'audio_service.dart';
import 'vibration_service.dart';

enum FeedbackMode { sound, vibrate, both, silent }

class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  FeedbackMode _mode = FeedbackMode.both;
  FeedbackMode get mode => _mode;

  Future<void> init() async {
    await AudioService.instance.init();
    await VibrationService.instance.init();
  }

  void setMode(FeedbackMode m) {
    _mode = m;
  }

  void chant() {
    if (_mode == FeedbackMode.sound || _mode == FeedbackMode.both) {
      AudioService.instance.playWoodFish();
    }
    if (_mode == FeedbackMode.vibrate || _mode == FeedbackMode.both) {
      VibrationService.instance.vibrateChant();
    }
  }

  void start() {
    if (_mode == FeedbackMode.sound || _mode == FeedbackMode.both) {
      AudioService.instance.playWoodFish();
    }
    if (_mode == FeedbackMode.vibrate || _mode == FeedbackMode.both) {
      VibrationService.instance.vibrateStart();
    }
  }

  void pause() {
    if (_mode == FeedbackMode.vibrate || _mode == FeedbackMode.both) {
      VibrationService.instance.vibratePause();
    }
  }

  void resume() {
    if (_mode == FeedbackMode.vibrate || _mode == FeedbackMode.both) {
      VibrationService.instance.vibrateResume();
    }
  }

  void finish() {
    if (_mode == FeedbackMode.vibrate || _mode == FeedbackMode.both) {
      VibrationService.instance.vibrateFinish();
    }
  }
}