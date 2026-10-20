import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chant_record.dart';
import '../models/daily_log.dart'; 
import '../models/health_record.dart'; // 🔥 補上這個 import

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ============ 念佛數 (今日總計) ============
  Future<void> saveChantCount(int count) async {
    final p = await _p;
    final today = _todayKey();
    final data = _loadMap(p, 'chant_records');
    data[today] = count;
    await p.setString('chant_records', jsonEncode(data));
  }

  Future<int> loadChantCount() async {
    final p = await _p;
    final today = _todayKey();
    final data = _loadMap(p, 'chant_records');
    return (data[today] ?? 0) as int;
  }

  // ============ 步數 (今日總計) ============
  Future<void> saveStepCount(int steps) async {
    final p = await _p;
    final today = _todayKey();
    final data = _loadMap(p, 'step_records');
    data[today] = steps;
    await p.setString('step_records', jsonEncode(data));
  }

  Future<int> loadStepCount() async {
    final p = await _p;
    final today = _todayKey();
    final data = _loadMap(p, 'step_records');
    return (data[today] ?? 0) as int;
  }

  // ============ 待上傳佇列 ============
  Future<void> saveQueue(List<ChantRecord> queue) async {
    final p = await _p;
    final list = queue.map((e) => e.toJson()).toList();
    await p.setString('chanting_queue', jsonEncode(list));
  }

  Future<List<ChantRecord>> loadQueue() async {
    final p = await _p;
    final s = p.getString('chanting_queue');
    if (s == null) return [];
    try {
      final list = jsonDecode(s) as List;
      return list.map((e) => ChantRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // 🔥 每日詳細紀錄 (DailyLog)
  // ============================================================
  
  Future<void> saveDailyLog(DailyLog log) async {
    final p = await _p;
    final data = _loadMap(p, 'daily_logs'); 
    final dayList = data[log.date] as List? ?? [];
    dayList.add(log.toJson());
    data[log.date] = dayList;
    await p.setString('daily_logs', jsonEncode(data));
  }

  Future<List<DailyLog>> getLogsByDate(String date) async {
    final p = await _p;
    final data = _loadMap(p, 'daily_logs');
    final list = data[date] as List? ?? [];
    return list.map((e) => DailyLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteDailyLog(String date, String id) async {
    final p = await _p;
    final data = _loadMap(p, 'daily_logs');
    final list = data[date] as List?;
    
    if (list != null) {
      list.removeWhere((e) => e['id'] == id);
      data[date] = list;
      await p.setString('daily_logs', jsonEncode(data));
    }
  }

  Future<void> updateDailyLog(String date, DailyLog newLog) async {
    final p = await _p;
    final data = _loadMap(p, 'daily_logs');
    final list = data[date] as List?;
    
    if (list != null) {
      final index = list.indexWhere((e) => e['id'] == newLog.id);
      if (index != -1) {
        list[index] = newLog.toJson();
        data[date] = list;
        await p.setString('daily_logs', jsonEncode(data));
      }
    }
  }

  // 取得本機所有明細（給年度報告或月曆總覽用）
  Future<List<DailyLog>> getAllLogs() async {
    final p = await _p;
    final data = _loadMap(p, 'daily_logs');
    final List<DailyLog> allLogs = [];

    for (var dateKey in data.keys) {
      final dayList = data[dateKey] as List?;
      if (dayList != null) {
        for (var item in dayList) {
          allLogs.add(DailyLog.fromJson(item as Map<String, dynamic>));
        }
      }
    }
    return allLogs;
  }

  // ============================================================
  // ❤️ 健康紀錄 (HealthRecord)
  // ============================================================
  
  Future<void> saveHealthRecord(HealthRecord record) async {
    final p = await _p;
    final data = _loadMap(p, 'health_records');
    data[record.date] = record.toJson();
    await p.setString('health_records', jsonEncode(data));
  }

    // 🔥 新增：批次儲存健康紀錄（避免迴圈卡頓）
  Future<void> saveHealthRecordsBatch(List<HealthRecord> records) async {
    final p = await _p;
    final data = _loadMap(p, 'health_records');
    
    for (var record in records) {
      data[record.date] = record.toJson();
    }
    
    // 一次寫入硬碟，速度極快
    await p.setString('health_records', jsonEncode(data));
  }

  Future<HealthRecord?> getHealthRecord(String date) async {
    final p = await _p;
    final data = _loadMap(p, 'health_records');
    if (data[date] != null) {
      return HealthRecord.fromJson(date, data[date] as Map<String, dynamic>);
    }
    return null;
  }

  Future<Map<String, HealthRecord>> getAllHealthRecords() async {
    final p = await _p;
    final data = _loadMap(p, 'health_records');
    return data.map((k, v) => MapEntry(k, HealthRecord.fromJson(k, v as Map<String, dynamic>)));
  }

  Future<void> deleteHealthRecord(String date) async {
    final p = await _p;
    final data = _loadMap(p, 'health_records');
    data.remove(date);
    await p.setString('health_records', jsonEncode(data));
  }

  // ============ 內部工具 ============
  Map<String, dynamic> _loadMap(SharedPreferences p, String key) {
    final s = p.getString(key);
    if (s == null) return {};
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}