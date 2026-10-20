import 'package:flutter/foundation.dart';
import '../models/chant_record.dart';
import '../services/storage_service.dart';

class QueueProvider extends ChangeNotifier {
  List<ChantRecord> _queue = [];
  List<ChantRecord> get queue => List.unmodifiable(_queue);

  // 計算待上傳的總聲數
  int get totalPendingChant {
    return _queue
        .where((q) => !q.synced && q.checkedChant)
        .fold(0, (sum, q) => sum + q.editChant);
  }

  // 計算待上傳的總步數
  int get totalPendingSteps {
    return _queue
        .where((q) => !q.synced && q.checkedSteps)
        .fold(0, (sum, q) => sum + q.editSteps);
  }

  Future<void> init() async {
    _queue = await StorageService.instance.loadQueue();
    notifyListeners();
  }

  Future<void> save() async {
    await StorageService.instance.saveQueue(_queue);
  }

  // 加入一筆新紀錄
  Future<void> addRecord(ChantRecord record) async {
    _queue.add(record);
    await save();
    notifyListeners();
  }

  // 清空佇列
  Future<void> clearQueue() async {
    _queue.clear();
    await save();
    notifyListeners();
  }

  // 🔥 以下是補齊的方法：
  
  // 切換勾選狀態 (type 填 'chant' 或 'steps')
  Future<void> toggleChecked(int index, String type) async {
    if (type == 'chant') {
      _queue[index].checkedChant = !_queue[index].checkedChant;
    } else {
      _queue[index].checkedSteps = !_queue[index].checkedSteps;
    }
    await save();
    notifyListeners();
  }

  // 修改數字
  Future<void> editNumber(int index, String type, int value) async {
    if (type == 'chant') {
      _queue[index].editChant = value.clamp(0, 9999999);
    } else {
      _queue[index].editSteps = value.clamp(0, 9999999);
    }
    await save();
    notifyListeners();
  }

  // 刪除單筆
  Future<void> removeRecord(int index) async {
    _queue.removeAt(index);
    await save();
    notifyListeners();
  }
}