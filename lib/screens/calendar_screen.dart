import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';

import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/tab_provider.dart';
import '../models/daily_log.dart';
import '../theme/app_colors.dart';
import '../utils/lunar_helper.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  List<DailyLog> _monthLogs = [];
  Map<String, bool> _hasChantMap = {};
  Map<String, bool> _hasStepMap = {};

  final Set<String> _selectedLogIds = {};
  bool _isUploading = false;

  // ============================================================
  // 🟢 💡 關鍵新增：換頁自動刷新的【安全防範開關】
  // ============================================================
  bool _hasTriggeredPageRefresh = false; 

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

    // ============================================================
  // 🟢 完美修正版：讓最新的紀錄永遠置頂，解決新增功課看不到的痛點
  // ============================================================
    Future<void> _loadData() async {
    // 🔥 修正這裡：正確取得月份前綴 (例如 2026-10)
    final monthPrefix = '${_focusedDay.year}-${_focusedDay.month.toString().padLeft(2, '0')}';
    
    // 1. 取得本機所有紀錄
    final allLogs = await StorageService.instance.getAllLogs();
    
    // 2. 過濾出該月的紀錄
    final monthLogs = allLogs.where((log) => log.date.startsWith(monthPrefix)).toList();
    
    // 🔥 核心修正：將當月的紀錄依照「日期」與「時間」由新到舊排序
    // 這樣最新剛按完結束的紀錄，就會出現在最上面！
    monthLogs.sort((a, b) {
      int dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) return dateCompare;
      return b.time.compareTo(a.time);
    });
    
    final hasChantMap = <String, bool>{};
    final hasStepMap = <String, bool>{};

    for (var log in monthLogs) {
      if (log.item == '佛號' || log.item == '拜佛' || log.type == 'chant' || log.type == 'bow') {
        hasChantMap[log.date] = true;
      }
      if (log.item == '步數' || log.type == 'step') {
        hasStepMap[log.date] = true;
      }
    }

    if (!mounted) return;
    setState(() {
      _monthLogs = monthLogs;
      _hasChantMap = hasChantMap;
      _hasStepMap = hasStepMap;
      _selectedLogIds.clear();
    });
  }


    String _getFixedIcon(DailyLog log) {
    // 🔥 自動修正步數圖示（不管存什麼，只要是步數就給 👣）
    if (log.item == '步數' || log.type == 'step') {
      return '👣';
    }
    
    // 🔥 自動修正拜佛圖示（如果存到舊的 🙇 或空的，自動換成 💎）
    if (log.item == '拜佛' || log.type == 'bow') {
      return '💎';
    }
    
    // 佛號或其他預設
    return log.icon;
  }

    int? _lastActiveTabIndex; // 💡 提示：請確保此變數宣告在 _CalendarScreenState 最上方大括號內

    @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // ============================================================
    // 🟢 💡 終極安全大修正：使用「單次鎖」完美阻斷 setState 無限死循環！
    // ============================================================
    try {
      final tabProvider = context.watch<TabProvider>();
      
      // 當偵測到目前是月曆日誌分頁 (Index 1) 且開關尚未被開啟時，才允許背景加載一次
      if (tabProvider.currentIndex == 1) {
        if (!_hasTriggeredPageRefresh) {
          _hasTriggeredPageRefresh = true; // 🔒 立刻上鎖，不准第二遍 build 重複抓取
          
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _loadData(); // 🟢 安全刷新最新功課並置頂
          });
        }
      } else {
        // 離月曆分頁時，自動把解開鎖，準備下一次跳轉進來時刷新
        _hasTriggeredPageRefresh = false; 
      }
    } catch (e) {
      // 💡 防呆：如果上面的 TabProvider 監聽在特定情況下失靈，
      // 改用原生生命週期回調，但同樣加上「沒有選中任何東西時」才刷新的雙重保險
      if (_selectedLogIds.isEmpty && !_isUploading) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
      }
    }

   

    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      appBar: AppBar(
        title: const Text('📖 本機日誌（勾選合併上傳）'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2030),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                        _selectedLogIds.clear();
                      });
                    },
                    onPageChanged: (focusedDay) {
                      setState(() => _focusedDay = focusedDay);
                      _loadData();
                    },
                    locale: 'zh_TW',
                    availableCalendarFormats: const {CalendarFormat.month: '月'},
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    rowHeight: 65,
                    daysOfWeekHeight: 30,
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) => _buildCalendarCell(day),
                      todayBuilder: (context, day, focusedDay) => _buildCalendarCell(day, isToday: true),
                      selectedBuilder: (context, day, focusedDay) => _buildCalendarCell(day, isSelected: true),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildDayDetailSection(auth),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_selectedLogIds.isNotEmpty) _buildBottomUploadBar(auth),
        ],
      ),
    );
  }


    // 🔥 補在這裡！放在 _buildCalendarCell 的上方
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

 


  Widget _buildCalendarCell(DateTime day, {bool isToday = false, bool isSelected = false}) {
    final lunar = LunarHelper.getLunarDateString(day);
    final dateStr = _formatDate(day);
    
    final dayLogs = _monthLogs.where((log) => log.date == dateStr).toList();

    final isLunar1 = lunar.contains('初一');
    final isLunar15 = lunar.contains('十五');

    Color bgColor = Colors.transparent;
    Color textColor = const Color(0xFF1A1A1A); // 🔥 預設改為極深灰
    Color borderColor = Colors.transparent;

    if (isSelected) {
      bgColor = AppColors.primaryLight;
      borderColor = AppColors.orange;
    } else if (isToday) {
      bgColor = AppColors.primaryLight;
      borderColor = AppColors.primary;
    } else if (isLunar1) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade900; // 🔥 初一紅色加深
    } else if (isLunar15) {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade900; // 🔥 十五藍色加深
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 16, // 🔥 加大到 16
              fontWeight: FontWeight.w900, // 🔥 加粗
              color: textColor,
            ),
          ),
          Text(
            lunar,
            style: const TextStyle(fontSize: 9, color: AppColors.textHint), // 農曆稍微放大
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: dayLogs
                .map((log) => _getFixedIcon(log))
                .toSet()
                .map((icon) {
                  // 🔥 如果圖示是腳步，就替換成白色的 Icon
                  if (icon == '👣') {
                    return const Icon(Icons.directions_walk, size: 10, color: Colors.white);
                  }
                  // 其他圖示（📿、💎）維持原樣
                  return Text(icon, style: const TextStyle(fontSize: 8));
                })
                .toList(),
          ),
        ],
      ),
    );
  }

    Widget _buildDayDetailSection(AuthProvider auth) {
    if (_selectedDay == null) return const SizedBox();
    
    final lunarStr = LunarHelper.getLunarDateString(_selectedDay!);
    final lunarText = (lunarStr != '--') ? ' · 農曆 $lunarStr' : '';
    final dateStr = _formatDate(_selectedDay!);

    // 🔥 核心：精準過濾出「只屬於這一天」的紀錄
    final dayLogs = _monthLogs.where((log) => log.date == dateStr).toList()
      ..sort((a, b) => b.time.compareTo(a.time)); 

    // 計算當日總和
    int dayChant = 0;
    int daySteps = 0;
    int dayBows = 0;
    for (var log in dayLogs) {
      if (log.item == '佛號' || log.type == 'chant') dayChant += log.count;
      if (log.item == '步數' || log.type == 'step') daySteps += log.count;
      if (log.item == '拜佛' || log.type == 'bow') dayBows += log.count;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 標題：顯示完整的「年 / 月 / 日」
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '${_selectedDay!.year} 年 ${_selectedDay!.month} 月 ${_selectedDay!.day} 日$lunarText',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 三大數字看板
          Row(
            children: [
              _buildMiniSummaryBox('📿 念佛', '$dayChant', Colors.orange),
              const SizedBox(width: 6),
              _buildMiniSummaryBox('💎 拜佛', '$dayBows', Colors.white),
              const SizedBox(width: 6),
              _buildMiniSummaryBox('👣 步數', '$daySteps', Colors.green),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 當日詳細列表
          if (dayLogs.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('📭 當日無記錄', style: TextStyle(color: Colors.grey))))
          else ...[
            Text('📖 當日詳細紀錄 (${dayLogs.length} 筆)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSoft)),
            const SizedBox(height: 8),
            
                       
                       ...dayLogs.map((log) {
              bool isChecked = _selectedLogIds.contains(log.id);
              bool isSynced = log.isSynced;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  // 🔥 深色半透明背景
                  color: isSynced ? Colors.black.withOpacity(0.1) : const Color(0xFF5A3A7A).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isChecked ? const Color(0xFF9F7AEA) : Colors.transparent, 
                    width: isChecked ? 2.0 : 0
                  ),
                ),
                child: Row(
                  children: [
                    // 左側：勾選框
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: isSynced 
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : Checkbox(
                            value: isChecked,
                            activeColor: const Color(0xFF9F7AEA),
                            checkColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 2.5),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedLogIds.add(log.id);
                                } else {
                                  _selectedLogIds.remove(log.id);
                                }
                              });
                            },
                          ),
                    ),
                    
                    // 中間：文字資訊 (用 Expanded 避免溢出)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getFixedIcon(log)} ${log.item}：${log.count} ${log.item == '步數' ? '步' : '次'}',
                              style: TextStyle(
                                fontSize: 15, 
                                fontWeight: FontWeight.bold, 
                                color: isSynced ? Colors.black54 : Colors.white,
                                decoration: isSynced ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '⏱️ ${log.time} | ${log.remark}',
                              style: TextStyle(fontSize: 11, color: isSynced ? Colors.grey : Colors.white70),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isSynced)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text('(已上傳)', style: TextStyle(fontSize: 10, color: Colors.green)),
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    // 🔥 右側：原本的修改(藍色)與刪除(紅色)小按鈕
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _showEditDialog(log),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue, 
                                borderRadius: BorderRadius.circular(6)
                              ),
                              child: const Text('修改', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _deleteLog(log),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red, 
                                borderRadius: BorderRadius.circular(6)
                              ),
                              child: const Text('刪除', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniSummaryBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF5A3A7A).withOpacity(0.85), 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        child: Column(
          children: [
            // 標題文字
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            // 🔥 數字改成深色系並加粗，加上黑色陰影增加對比
            Text(
              value, 
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.w900, 
                color: color == Colors.orange ? Colors.orange.shade800 : color, // 如果是橘色，加深一點
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.5), offset: const Offset(0, 1), blurRadius: 3)
                ]
              ),
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildBottomUploadBar(AuthProvider auth) {
    int totalChants = 0;
    int totalBows = 0;
    int totalSteps = 0;

    // 💡 精準分類累加 (完全只依賴 log.item)
    for (var log in _monthLogs) {
      if (_selectedLogIds.contains(log.id)) {
        // 🔥 只認 item 名稱，避免 type 衝突
        if (log.item == '佛號') {
          totalChants += log.count;
        } else if (log.item == '拜佛') {
          totalBows += log.count;
        } else if (log.item == '步數') {
          totalSteps += log.count;
        }
      }
    }

    // 2. 組裝下方顯示的文字
    List<String> displayTexts = [];
    if (totalChants > 0) displayTexts.add('📿 佛號: $totalChants 次');
    if (totalBows > 0) displayTexts.add('💎 拜佛: $totalBows 次');
    if (totalSteps > 0) displayTexts.add('👣 步數: $totalSteps 步');

    String finalTotalText = displayTexts.isNotEmpty ? displayTexts.join(' | ') : '請選擇功課';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -3))],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('已選中 ${_selectedLogIds.length} 筆紀錄', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    finalTotalText,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4A2A6A)),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 140,
              height: 48,
              child: ElevatedButton(
                onPressed: (!auth.loggedIn || _isUploading) ? null : () => _handleBatchMergeUpload(auth, totalChants, totalBows, totalSteps),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 2,
                ),
                child: _isUploading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark))
                    : const Text('一鍵合併上傳', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

       Future<void> _handleBatchMergeUpload(AuthProvider auth, int chants, int bows, int steps) async {
    setState(() => _isUploading = true);
    final idsToSync = List<String>.from(_selectedLogIds);

    try {
      String secureGroupCode = auth.state.groupCode.isNotEmpty ? auth.state.groupCode : '01';

      // 🔥 1. 上傳佛號 (只傳佛號，不傳步數)
      if (chants > 0) {
        await ApiService.instance.postChantingRaw(
          memberNo: auth.state.memberNo,
          memberName: auth.state.memberName,
          item: '佛號',
          count: chants, // 只傳佛號數量
          groupCode: secureGroupCode,
          remark: '📲 本機日誌批量上傳',
          icon: '📿',
        );
      }

      // 🔥 2. 上傳拜佛
      if (bows > 0) {
        await ApiService.instance.postChantingRaw(
          memberNo: auth.state.memberNo,
          memberName: auth.state.memberName,
          item: '拜佛',
          count: bows, // 只傳拜佛數量
          groupCode: secureGroupCode,
          remark: '📲 本機日誌批量上傳',
          icon: '💎',
        );
      }

      // 🔥 3. 上傳步數 (獨立上傳)
      if (steps > 0) {
        await ApiService.instance.postChantingRaw(
          memberNo: auth.state.memberNo,
          memberName: auth.state.memberName,
          item: '步數',
          count: steps, // 只傳步數數量
          groupCode: secureGroupCode,
          remark: '📲 本機日誌批量上傳',
          icon: '👣',
        );
      }

      // 4. 標記為已上傳
      for (var log in _monthLogs) {
        if (idsToSync.contains(log.id)) {
          final updatedLog = DailyLog(
            id: log.id,
            date: log.date,
            time: log.time,
            type: log.type,
            item: log.item,
            icon: log.icon,
            count: log.count,
            remark: log.remark,
            isSynced: true, // 標記已上傳
          );
          await StorageService.instance.updateDailyLog(log.date, updatedLog);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 恭喜！選中紀錄已成功合併上傳！'), backgroundColor: Colors.green)
        );
      }
      setState(() => _selectedLogIds.clear());
      _loadData(); // 重新整理

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 上傳失敗: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ============================================================
  // 🔥 修改本機紀錄
  // ============================================================
  void _showEditDialog(DailyLog log) {
    final ctrl = TextEditingController(text: log.count.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('修改 ${log.item}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '修改次數'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('取消')
          ),
          ElevatedButton(
            onPressed: () async {
              final newCount = int.tryParse(ctrl.text) ?? log.count;
              
              final updatedLog = DailyLog(
                id: log.id,
                date: log.date,
                time: log.time,
                type: log.type,
                item: log.item,
                icon: log.icon, 
                count: newCount,
                remark: log.remark,
                isSynced: log.isSynced, 
              );
              
              await StorageService.instance.updateDailyLog(log.date, updatedLog);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadData(); 
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🔥 刪除本機紀錄
  // ============================================================
  Future<void> _deleteLog(DailyLog log) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除紀錄'),
        content: Text('確定要刪除這筆 ${log.item} 紀錄嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text('取消')
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('刪除', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await StorageService.instance.deleteDailyLog(log.date, log.id);
      _loadData(); 
    }
  }
}