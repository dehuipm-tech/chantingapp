import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart'; // 🔥 新增：檔案選擇器

import '../models/health_record.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final _hrCtrl = TextEditingController();
  final _bpCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  
  Map<String, HealthRecord> _records = {};

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final data = await StorageService.instance.getAllHealthRecords();
    setState(() {
      _records = data;
    });
  }

  Future<void> _loadRecordForDate() async {
    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final record = await StorageService.instance.getHealthRecord(dateStr);
    
    setState(() {
      if (record != null) {
        _hrCtrl.text = record.heartRate > 0 ? record.heartRate.toString() : '';
        _bpCtrl.text = record.bpSys > 0 ? '${record.bpSys}/${record.bpDia}' : '';
        _calCtrl.text = record.calories > 0 ? record.calories.toString() : '';
      } else {
        _hrCtrl.clear();
        _bpCtrl.clear();
        _calCtrl.clear();
      }
    });
  }

  Future<void> _saveRecord() async {
    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    
    final hr = int.tryParse(_hrCtrl.text) ?? 0;
    final cal = int.tryParse(_calCtrl.text) ?? 0;
    
    int sys = 0, dia = 0;
    final bpParts = _bpCtrl.text.split('/');
    if (bpParts.length == 2) {
      sys = int.tryParse(bpParts[0]) ?? 0;
      dia = int.tryParse(bpParts[1]) ?? 0;
    }

    if (hr == 0 && sys == 0 && cal == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請至少填一項')));
      return;
    }

    final record = HealthRecord(
      date: dateStr,
      heartRate: hr,
      bpSys: sys,
      bpDia: dia,
      calories: cal,
    );

    await StorageService.instance.saveHealthRecord(record);
    await _loadRecords();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 已儲存')));
      _hrCtrl.clear();
      _bpCtrl.clear();
      _calCtrl.clear();
    }
  }

  Future<void> _deleteRecord(String date) async {
    await StorageService.instance.deleteHealthRecord(date);
    await _loadRecords();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑 已刪除')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      appBar: AppBar(
        title: const Text('❤️ 健康紀錄'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 圖表
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📈 90天健康數據疊加圖', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 16),
                  HealthTrajectoryChart(
                    records: _records,
                    recentDates: _records.keys.toList()..sort(),
                  ),
                ],
              ),
            ),

            // 🔥 輸入表單
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('📅 日期', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMid)),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                            _loadRecordForDate();
                          }
                        },
                        child: Text(
                          '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  TextField(controller: _hrCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '❤️ 平均心跳 (bpm)', hintText: '例：72')),
                  const SizedBox(height: 12),
                  TextField(controller: _bpCtrl, decoration: const InputDecoration(labelText: '🩺 血壓 (mmHg)', hintText: '例：120/80')),
                  const SizedBox(height: 12),
                  TextField(controller: _calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '🔥 消耗熱量 (kcal)', hintText: '例：480')),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveRecord,
                      icon: const Icon(Icons.save),
                      label: const Text('儲存今日紀錄'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // 🔥 備份卡片
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSoft)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💾 健康紀錄備份', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  
                  // 下載備份
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _exportBackup,
                      icon: const Icon(Icons.download),
                      label: const Text('下載健康備份（換手機用）'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 🔥 新增：上傳備份
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _importBackup,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('上傳健康備份（還原資料）'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Text('💡 備份包含：心跳、血壓、熱量\n💡 換手機時，用這個備份檔帶走', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 🔥 列表
            const Text('📋 健康紀錄列表', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 12),

            if (_records.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('目前無健康紀錄', style: TextStyle(color: Colors.grey))))
            else
              ..._records.entries.map((entry) {
                final date = entry.key;
                final r = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('📅 $date', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                            const SizedBox(height: 4),
                            Text('❤️ ${r.heartRate} bpm · 🩺 ${r.bpText} · 🔥 ${r.calories} kcal', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () => _deleteRecord(date),
                      ),
                    ],
                  ),
                );
              }).toList(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackup() async {
    if (_records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ 沒有健康資料可備份')));
      return;
    }

    try {
      final Map<String, dynamic> backupData = {
        'version': '1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'health': _records.map((k, v) => MapEntry(k, v.toJson())),
      };

      final jsonString = jsonEncode(backupData);
      
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/health_backup.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: '健康紀錄備份',
        text: '您的健康紀錄備份檔（換手機用）',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ 備份失敗: $e')));
    }
  }

  // ============================================================
  // 🔥 新增：匯入健康備份
  // ============================================================
  Future<void> _importBackup() async {
    try {
      // 1. 讓使用者選擇 JSON 檔案
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return; // 使用者取消選擇
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      // 檢查備份檔格式是否正確
      if (backupData['health'] == null || backupData['health'] is! Map) {
        throw Exception('備份檔格式不正確，找不到 health 資料');
      }

      final Map<String, dynamic> healthData = backupData['health'];
      int importCount = 0;

      // 2. 逐筆透過 fromJson 轉換並寫入本地資料庫
      for (var entry in healthData.entries) {
        final date = entry.key;
        final recordMap = entry.value;
        
        if (recordMap is Map<String, dynamic>) {
          final record = HealthRecord.fromJson(date, recordMap);
          await StorageService.instance.saveHealthRecord(record);
          importCount++;
        }
      }

      await _loadRecords(); // 重新載入畫面

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ 成功匯入 $importCount 筆健康紀錄！'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 匯入失敗：$e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ============================================================
// 🔥 終極修正版：解決編譯錯誤 + 補齊左右 Y 軸標題
// ============================================================
class HealthTrajectoryChart extends StatelessWidget {
  final Map<String, HealthRecord> records;
  final List<String> recentDates;

  const HealthTrajectoryChart({
    Key? key,
    required this.records,
    required this.recentDates,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double totalHr = 0, totalSys = 0, totalDia = 0, totalCal = 0;
    int count = 0;

    for (var record in records.values) {
      if (record.heartRate > 0) {
        totalHr += record.heartRate;
        totalSys += record.bpSys;
        totalDia += record.bpDia;
        totalCal += record.calories;
        count++;
      }
    }

    final avgHr = count > 0 ? totalHr / count : 75.0;
    final avgSys = count > 0 ? totalSys / count : 120.0;
    final avgDia = count > 0 ? totalDia / count : 80.0;
    final avgCal = count > 0 ? totalCal / count : 300.0;

    return AspectRatio(
      aspectRatio: 1.7,
      child: Stack(
        children: [
          // ── 底層：熱量卡路里 (右軸) ──
          BarChart(
            BarChartData(
              alignment: BarChartAlignment.center,
              minY: 0,
              maxY: 500, 
              groupsSpace: 12,
              barTouchData: BarTouchData(enabled: false),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(
                  axisNameWidget: const Text(
                    '卡路里熱量 (kcal)',
                    style: TextStyle(color: Color(0xFF2A9D8F), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  axisNameSize: 16,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 100,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
                      style: const TextStyle(color: Color(0xFF2A9D8F), fontSize: 9),
                    ),
                  ),
                ),
              ),
              barGroups: [
                BarChartGroupData(x: 8, barRods: [BarChartRodData(toY: avgCal * 0.25, color: const Color(0xFFF4A261).withValues(alpha: 0.35), width: 10)]),
                BarChartGroupData(x: 12, barRods: [BarChartRodData(toY: avgCal * 0.30, color: const Color(0xFFF4A261).withValues(alpha: 0.35), width: 10)]),
                BarChartGroupData(x: 16, barRods: [BarChartRodData(toY: avgCal * 0.50, color: const Color(0xFF2A9D8F).withValues(alpha: 0.45), width: 18)]),
                BarChartGroupData(x: 19, barRods: [BarChartRodData(toY: avgCal * 0.35, color: const Color(0xFFF4A261).withValues(alpha: 0.35), width: 10)]),
              ],
            ),
          ),

          // ── 上層：心跳與血壓 (左軸) ──
          LineChart(
            LineChartData(
              minX: 0,
              maxX: 24, 
              minY: 40,
              maxY: 180,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  bottom: BorderSide(color: Colors.black54, width: 1),
                  left: BorderSide(color: Colors.black54, width: 1),
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 4,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          '${value.toInt()}:00',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: const Text(
                    '心跳 (bpm) / 血壓 (mmHg)',
                    style: TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  axisNameSize: 16,
                  sideTitles: SideTitles(
                    showTitles: true, 
                    interval: 20, 
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 9),
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              rangeAnnotations: RangeAnnotations(
                horizontalRangeAnnotations: [
                  HorizontalRangeAnnotation(y1: 60, y2: 90, color: const Color(0xFFF5EBEB).withValues(alpha: 0.6)),
                ],
              ),
              extraLinesData: ExtraLinesData(
                verticalLines: [
                  VerticalLine(x: 3, color: Colors.grey.shade200, strokeWidth: 0.8, dashArray: [4, 4]),
                  VerticalLine(x: 8.5, color: Colors.grey.shade300, strokeWidth: 0.8, dashArray: [4, 4]),
                  VerticalLine(x: 12.5, color: Colors.grey.shade300, strokeWidth: 0.8, dashArray: [4, 4]),
                  VerticalLine(x: 16.5, color: Colors.grey.shade300, strokeWidth: 0.8, dashArray: [4, 4]),
                  VerticalLine(x: 19.5, color: Colors.grey.shade300, strokeWidth: 0.8, dashArray: [4, 4]),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: _mapHeartRateToDaySchedule(avgHr),
                  isCurved: true,
                  color: const Color(0xFFE63946),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: [
                    FlSpot(8.0, avgSys),
                    FlSpot(8.0, avgDia),
                    FlSpot(22.0, avgSys - 3),
                    FlSpot(22.0, avgDia - 2),
                  ],
                  show: true,
                  barWidth: 0,
                  shadow: const Shadow(color: Colors.transparent),
                  belowBarData: BarAreaData(show: false),
                  color: const Color(0xFF1D3557),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(radius: 5, color: const Color(0xFF1D3557), strokeWidth: 1.5, strokeColor: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _mapHeartRateToDaySchedule(double baselineHr) {
    return [
      FlSpot(0, baselineHr - 15),
      FlSpot(4, baselineHr - 20),
      FlSpot(6, baselineHr - 18),
      FlSpot(8.5, baselineHr - 2),
      FlSpot(12.5, baselineHr + 1),
      FlSpot(14.5, baselineHr - 5),
      FlSpot(16.5, baselineHr + 45),
      FlSpot(18.5, baselineHr + 4),
      FlSpot(19.5, baselineHr - 1),
      FlSpot(22, baselineHr - 13),
      FlSpot(24, baselineHr - 15),
    ];
  }
}