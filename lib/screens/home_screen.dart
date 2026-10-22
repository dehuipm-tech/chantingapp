import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tab_provider.dart';
import '../providers/chant_provider.dart';
import '../providers/queue_provider.dart';
import '../services/pedometer_service.dart';
import '../widgets/counter_ring.dart';
import '../theme/app_colors.dart';
import '../models/chant_record.dart';
import '../models/health_record.dart';
import '../models/daily_log.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 0 = 跟著步伐, 1 = 定速念佛, 2 = 定時念佛, 3 = 拜佛
  int _selectedMode = 0;
  int _todaySteps = 0; // 👈 新增這個變數來儲存即時步數

  // 首頁大字卡生理數值
  String _todayBP = '--/--';
  String _todayHR = '--';
  String _todayCal = '0';

  // ================= 定速念佛設定 =================
  String _currentSpeed = '60/分';
  int _selectedSpeedIndex = 1;    
  int _selectedMethodIndex = 1; 

  // 🔥 新增：自訂速度
  String _customSpeedValue = ''; 
  final TextEditingController _speedCtrl = TextEditingController();  

  // ================= 定時念佛設定 =================
  int _selectedTimeIndex = 0;     
  String _customTimeValue = '';   
  final TextEditingController _timeCtrl = TextEditingController();
  int _selectedTimerSpeedIndex = 1; 
  int _timerSpeedPerMinute = 60;

  // 🔥 補上這兩個變數
  String _customTimeSpeedValue = ''; 
  final TextEditingController _timerSpeedCtrl = TextEditingController();


  // ================= 拜佛設定 =================
  int _selectedBowingIndex = 0;   
  String _customBowingValue = ''; 
  final TextEditingController _bowingCtrl = TextEditingController();
  
  int _selectedBowingTimeIndex = 0; 
  String _customBowingTimeValue = '';
  final TextEditingController _bowingTimeCtrl = TextEditingController();

  // 🔥 唯一的 initState
  @override
  void initState() {
    super.initState();
    _loadTodayHealth();
    
    // 🔥 啟動計步器，並即時更新首頁步數
    PedometerService.instance.start(onStep: () {
      if (mounted) {
        setState(() {
          _todaySteps = PedometerService.instance.todaySteps; 
        });
      }
    });
  }

  // 🔥 唯一的 _loadTodayHealth
  Future<void> _loadTodayHealth() async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final record = await StorageService.instance.getHealthRecord(dateStr);
    
    if (!mounted) return;
    setState(() {
      if (record != null) {
        _todayBP = record.bpSys > 0 ? '${record.bpSys}/${record.bpDia}' : '--/--';
        _todayHR = record.heartRate > 0 ? '${record.heartRate}' : '--';
        _todayCal = record.calories > 0 ? '${record.calories}' : '0';
      } else {
        _todayBP = '--/--';
        _todayHR = '--';
        _todayCal = '0';
      }
    });
  }

  @override
  void dispose() {
    _timeCtrl.dispose();
    _timerSpeedCtrl.dispose();
    _speedCtrl.dispose(); // 👈 補上這行
    _bowingCtrl.dispose();
    _bowingTimeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chant = context.watch<ChantProvider>();

    try {
      final tabProvider = context.watch<TabProvider>();
      if (tabProvider.currentIndex == 0) { 
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadTodayHealth());
      }
    } catch (_) {}

    return Scaffold(
      backgroundColor: Colors.transparent, // 🔥 確保背景透明 
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A2A6A), Color(0xFF5A3A7A)],
          ),
        ),
        child: SafeArea(
          bottom: false, // 🔥 確保漸層延伸到導覽列 
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
                  child: Column(
                    children: [
                      _buildTopNavBar(),
                      const SizedBox(height: 20),
                      
                      if (_selectedMode == 0) _buildStepModeHint(),
                      if (_selectedMode == 1) _buildSpeedModeSettings(),
                      if (_selectedMode == 2) _buildTimerSettings(),
                      if (_selectedMode == 3) _buildBowingSettings(),
                      
                      const SizedBox(height: 24),
                      const CounterRing(),
                      const SizedBox(height: 24),
                      _buildControlButtons(context, chant),
                      const SizedBox(height: 24),
                      
                      const SizedBox(height: 12),
                      _buildUploadCounter(context, chant),
                      const SizedBox(height: 12),
                      _buildGoUploadButton(context, chant),
                      const SizedBox(height: 24),
                      _buildStatsGrid(chant),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: AppColors.primaryDark,
      child: const Row(
        children: [
          Icon(Icons.grain, color: AppColors.accentLight, size: 24),
          SizedBox(width: 8),
          Text(
            '念佛計步',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.accentLight),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          _buildMainTab(0, '🏃', '跟著步伐'),
          const SizedBox(width: 8),
          _buildMainTab(1, '🎵', '定速念佛'),
          const SizedBox(width: 8),
          _buildMainTab(2, '⏱️', '定時念佛'),
          const SizedBox(width: 8),
          _buildMainTab(3, '🙇', '拜佛'),
        ],
      ),
    );
  }

  Widget _buildMainTab(int index, String emoji, String title) {
    bool isSelected = _selectedMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMode = index),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF3E8FF) : const Color(0xFF6B4B8B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? const Color(0xFF9F7AEA) : Colors.transparent, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF6B4B8B) : Colors.white)),
            ],
          ),
        ),
      ),
    );
  }



  // 面板：跟著步伐
  Widget _buildStepModeHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: const Row(
        children: [
          Icon(Icons.directions_walk, color: AppColors.accentLight, size: 36),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '自然隨意走，不需設定速度。每踏出一步，系統就會自動播放一聲佛號。',
              style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // 面板：定時念佛
  Widget _buildTimerSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _buildSectionTitle('設定時間 (分)'),
          Row(
            children: [
              _buildOptionBox('30 分', 0, _selectedTimeIndex, (v) => setState(() => _selectedTimeIndex = v)),
              const SizedBox(width: 8),
              _buildOptionBox('60 分', 1, _selectedTimeIndex, (v) => setState(() => _selectedTimeIndex = v)),
              const SizedBox(width: 8),
              _buildOptionBox('90 分', 2, _selectedTimeIndex, (v) => setState(() => _selectedTimeIndex = v)),
              const SizedBox(width: 8),
              _buildCustomOptionBox(
                _customTimeValue.isNotEmpty ? '$_customTimeValue 分' : '自訂',
                3, 
                _selectedTimeIndex, 
                () => _showInputDialog('自訂時間', _timeCtrl, '分', (val) {
                  setState(() {
                    _selectedTimeIndex = 3;
                    _customTimeValue = val;
                  });
                }, onCancel: () {
                  setState(() {
                    _customTimeValue = '';
                    if (_selectedTimeIndex == 3) _selectedTimeIndex = -1;
                  });
                })
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('速度'),
          Row(
            children: [
              _buildSpeedBox('🐢', '慢', '30/分', 0, isTimer: true),
              const SizedBox(width: 8),
              _buildSpeedBox('🚶', '正常', '60/分', 1, isTimer: true),
              const SizedBox(width: 8),
              _buildSpeedBox('🏃', '快', '90/分', 2, isTimer: true),
              const SizedBox(width: 8),
              // 🔥 把「更快」換成「自訂」
              _buildCustomOptionBox(
                _customTimeSpeedValue.isNotEmpty ? '$_customTimeSpeedValue/分' : '自訂',
                3, 
                _selectedTimerSpeedIndex, 
                () => _showInputDialog('自訂速度 (每分鐘幾聲)', _timerSpeedCtrl, '聲/分', (val) {
                  final bpm = int.tryParse(val) ?? 60;
                  setState(() {
                    _selectedTimerSpeedIndex = 3;
                    _customTimeSpeedValue = val;
                    _timerSpeedPerMinute = bpm;
                  });
                }, onCancel: () {
                  setState(() {
                    _customTimeSpeedValue = '';
                    _timerSpeedPerMinute = 60;
                    if (_selectedTimerSpeedIndex == 3) _selectedTimerSpeedIndex = 1;
                  });
                })
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 👇 定時念佛的預估視窗 👇
          _buildEstimateBox(
            chants: _selectedTimeMinutes() * _timerSpeedPerMinute,
            minutes: _selectedTimeMinutes(),
            mets: 1.3, // 念佛 METs
          ),
        ],
      ),
    );
  }

    // 面板：定速念佛
  Widget _buildSpeedModeSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _buildSectionTitle('速度'),
          Row(
            children: [
              _buildSpeedBox('🐢', '慢', '30/分', 0),
              const SizedBox(width: 8),
              _buildSpeedBox('🚶', '正常', '60/分', 1),
              const SizedBox(width: 8),
              _buildSpeedBox('🏃', '快', '90/分', 2),
              const SizedBox(width: 8),
              // 🔥 第四個方塊：自訂速度
              _buildCustomOptionBox(
                _customSpeedValue.isNotEmpty ? '$_customSpeedValue/分' : '自訂',
                3, 
                _selectedSpeedIndex, 
                () => _showInputDialog('自訂速度 (每分鐘幾聲)', _speedCtrl, '聲/分', (val) {
                  final bpm = int.tryParse(val) ?? 60;
                  setState(() {
                    _selectedSpeedIndex = 3;
                    _customSpeedValue = val;
                    _currentSpeed = '$bpm/分';
                  });
                }, onCancel: () {
                  setState(() {
                    _customSpeedValue = '';
                    _currentSpeed = '60/分';
                    if (_selectedSpeedIndex == 3) _selectedSpeedIndex = 1;
                  });
                })
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('念佛方式'),
          Row(
            children: [
              _buildMethodBox('🔈', '只有聲音', '不計步', 0),
              const SizedBox(width: 12),
              _buildMethodBox('🔈👣', '聲音+步數', '邊走邊念', 1),
            ],
          ),
          const SizedBox(height: 16),
          _buildSpeedEstimateBox(),
        ],
      ),
    );
  }

  // 面板：拜佛
  Widget _buildBowingSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _buildSectionTitle('選擇次數 (拜)'),
          Row(
            children: [
              _buildOptionBox('108 拜', 0, _selectedBowingIndex, (v) => setState(() => _selectedBowingIndex = v)),
              const SizedBox(width: 8),
              _buildOptionBox('200 拜', 1, _selectedBowingIndex, (v) => setState(() => _selectedBowingIndex = v)),
              const SizedBox(width: 8),
              _buildOptionBox('300 拜', 2, _selectedBowingIndex, (v) => setState(() => _selectedBowingIndex = v)),
              const SizedBox(width: 8),
              _buildCustomOptionBox(
                _customBowingValue.isNotEmpty ? '$_customBowingValue 拜' : '自訂',
                3, 
                _selectedBowingIndex, 
                () => _showInputDialog('自訂次數', _bowingCtrl, '拜', (val) {
                  setState(() {
                    _selectedBowingIndex = 3;
                    _customBowingValue = val;
                  });
                }, onCancel: () {
                  setState(() {
                    _customBowingValue = '';
                    if (_selectedBowingIndex == 3) _selectedBowingIndex = -1;
                  });
                })
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('預計花費時間 (分)'),
          Row(
            children: [
              _buildOptionBox('20 分', 0, _selectedBowingTimeIndex, (v) => setState(() => _selectedBowingTimeIndex = v)),
              const SizedBox(width: 8),
              _buildOptionBox('30 分', 1, _selectedBowingTimeIndex, (v) => setState(() => _selectedBowingTimeIndex = v)),
              const SizedBox(width: 8),
              _buildOptionBox('60 分', 2, _selectedBowingTimeIndex, (v) => setState(() => _selectedBowingTimeIndex = v)),
              const SizedBox(width: 8),
              _buildCustomOptionBox(
                _customBowingTimeValue.isNotEmpty ? '$_customBowingTimeValue 分' : '自訂',
                3, 
                _selectedBowingTimeIndex, 
                () => _showInputDialog('自訂時間', _bowingTimeCtrl, '分', (val) {
                  setState(() {
                    _selectedBowingTimeIndex = 3;
                    _customBowingTimeValue = val;
                  });
                }, onCancel: () {
                  setState(() {
                    _customBowingTimeValue = '';
                    if (_selectedBowingTimeIndex == 3) _selectedBowingTimeIndex = -1;
                  });
                })
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 👇 拜佛的預估視窗 👇
          _buildEstimateBox(
            chants: _selectedBowingCount(), 
            minutes: _selectedBowingMinutes(),
            mets: 3.0, // 拜佛 METs
          ),
        ],
      ),
    );
  }

  // --- 新增：預估結果視窗 ---
  Widget _buildEstimateBox({required int chants, required int minutes, required double mets}) {
    if (minutes <= 0) return const SizedBox.shrink(); 

    final hours = minutes / 60.0;
    final calories = (mets * 60 * hours).toStringAsFixed(1); // 預設體重 60kg

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9F7AEA), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text('📿 預計念佛', style: TextStyle(fontSize: 12, color: Color(0xFF6B4B8B))),
              const SizedBox(height: 4),
              Text('$chants 聲', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A2A6A))),
            ],
          ),
          Container(width: 1, height: 30, color: const Color(0xFF9F7AEA)),
          Column(
            children: [
              const Text('🔥 預計消耗', style: TextStyle(fontSize: 12, color: Color(0xFF6B4B8B))),
              const SizedBox(height: 4),
              Text('$calories kcal', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A2A6A))),
            ],
          ),
        ],
      ),
    );
  }


    // --- 新增：定速念佛預估視窗 (以 30 分鐘為基準) ---
  Widget _buildSpeedEstimateBox() {
    // 假設使用者在「只有聲音」模式下，我們用 30 分鐘來算
    // 假設使用者在「聲音+步數」模式下，我們用每分鐘大約 100 步來算 (30分鐘約 3000 步)
    
    final isStepMode = _selectedMethodIndex == 1;
    final bpm = _speedToInt(_currentSpeed);
    
    // 預估 30 分鐘的結果
    final estChants = bpm * 30;
    final estSteps = isStepMode ? 3000 : 0; // 如果你有計步器，大約抓個平均值
    final calories = (1.3 * 60 * 0.5).toStringAsFixed(1); // 預設 30 分鐘消耗

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9F7AEA), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            isStepMode ? '💡 預估：走 30 分鐘的成果' : '💡 預估：念 30 分鐘的成果',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6B4B8B)),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('📿 預計念佛', style: TextStyle(fontSize: 12, color: Color(0xFF6B4B8B))),
                  Text('$estChants 聲', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A2A6A))),
                ],
              ),
              if (isStepMode) ...[
                Container(width: 1, height: 25, color: const Color(0xFF9F7AEA)),
                Column(
                  children: [
                    const Text('👣 預計步數', style: TextStyle(fontSize: 12, color: Color(0xFF6B4B8B))),
                    Text('約 $estSteps 步', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A2A6A))),
                  ],
                ),
              ],
              Container(width: 1, height: 25, color: const Color(0xFF9F7AEA)),
              Column(
                children: [
                  const Text('🔥 預計消耗', style: TextStyle(fontSize: 12, color: Color(0xFF6B4B8B))),
                  Text('$calories kcal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A2A6A))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 輔助小標題 ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  // --- 速度方塊 ---
  Widget _buildSpeedBox(String emoji, String title, String subtitle, int index, {bool isTimer = false}) {
    bool isSelected = isTimer 
        ? _selectedTimerSpeedIndex == index 
        : _selectedSpeedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isTimer) {
              _selectedTimerSpeedIndex = index;
              _timerSpeedPerMinute = int.tryParse(subtitle.split('/').first) ?? 60;
            } else {
              _selectedSpeedIndex = index;
              _currentSpeed = subtitle;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF3E8FF) : const Color(0xFF6B4B8B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? const Color(0xFF9F7AEA) : Colors.transparent, width: 2),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF6B4B8B) : Colors.white)),
              Text(subtitle, style: TextStyle(fontSize: 11, color: isSelected ? const Color(0xFF805AD5) : Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  // --- 念佛方式方塊 ---
  Widget _buildMethodBox(String emoji, String title, String subtitle, int index) {
    bool isSelected = _selectedMethodIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMethodIndex = index;
          });
          final chant = context.read<ChantProvider>();
          if (index == 0) {
            chant.setTimedMode(TimedMode.sound);
          } else {
            chant.setTimedMode(TimedMode.soundStep);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF3E8FF) : const Color(0xFF6B4B8B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? const Color(0xFF9F7AEA) : Colors.transparent, width: 2),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF6B4B8B) : Colors.white)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: isSelected ? const Color(0xFF805AD5) : Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  // --- 選項方塊 ---
  Widget _buildOptionBox(String text, int index, int currentIndex, Function(int) onTap) {
    bool isSelected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF3E8FF) : const Color(0xFF6B4B8B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFF9F7AEA) : Colors.transparent, width: 2),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF6B4B8B) : Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  // --- 自訂方塊 ---
  Widget _buildCustomOptionBox(String text, int index, int currentIndex, VoidCallback onTap) {
    bool isSelected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF3E8FF) : const Color(0xFF6B4B8B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFF9F7AEA) : Colors.transparent, width: 2),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF6B4B8B) : Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  // 彈出輸入框
  void _showInputDialog(String title, TextEditingController ctrl, String suffix, Function(String) onConfirm, {VoidCallback? onCancel}) {
    ctrl.clear(); 
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(labelText: '請輸入數值', suffixText: suffix, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (onCancel != null) onCancel();
            }, 
            child: const Text('取消', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (ctrl.text.isNotEmpty) {
                onConfirm(ctrl.text);
              } else {
                if (onCancel != null) onCancel();
              }
            }, 
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  // ================= 下方按鈕與連動 =================
  Widget _buildControlButtons(BuildContext context, ChantProvider chant) {
    if (chant.isIdle) {
      return SizedBox(
        width: 330,
        child: ElevatedButton.icon(
          onPressed: () => _onStart(context),
          icon: const Icon(Icons.play_arrow_rounded, size: 24),
          label: const Text('開始念佛', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.primaryDark,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      );
    }

    return SizedBox(
      width: 330,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: chant.isRunning ? () => _onPause(context) : () => _onResume(context),
              icon: Icon(chant.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 20),
              label: Text(chant.isRunning ? '暫停' : '繼續', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: chant.isRunning ? AppColors.orange : AppColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _onFinish(context),
              icon: const Icon(Icons.stop_rounded, size: 20),
              label: const Text('結束', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onStart(BuildContext context) async {
    final chant = context.read<ChantProvider>();

    switch (_selectedMode) {
      case 0: // 跟著步伐
        chant.setRhythm(RhythmMode.step);
        break;
      case 1: // 定速念佛
        chant.setRhythm(RhythmMode.timed);
        chant.setBpm(_speedToInt(_currentSpeed));
        chant.setTimedMode(_selectedMethodIndex == 1 ? TimedMode.soundStep : TimedMode.sound);
        break;
      case 2: // 定時念佛
        chant.setRhythm(RhythmMode.timer);
        chant.setTimerMinutes(_selectedTimeMinutes());
        chant.setBpm(_timerSpeedPerMinute);
        break;
      case 3: // 拜佛
        chant.setRhythm(RhythmMode.bow);
        chant.setBowCount(_selectedBowingCount());
        chant.setBowMinutes(_selectedBowingMinutes());
        break;
    }

    await chant.start();

    if (chant.needPedometer) {
      await PedometerService.instance.start(onStep: () => chant.onStep());
    }
  }

  int _speedToInt(String speed) => int.tryParse(speed.split('/').first) ?? 60;

  int _selectedTimeMinutes() {
    switch (_selectedTimeIndex) {
      case 0: return 30;
      case 1: return 60;
      case 2: return 90;
      case 3: return int.tryParse(_customTimeValue) ?? 30;
      default: return 30;
    }
  }

  int _selectedBowingCount() {
    switch (_selectedBowingIndex) {
      case 0: return 108;
      case 1: return 200;
      case 2: return 300;
      case 3: return int.tryParse(_customBowingValue) ?? 108;
      default: return 108;
    }
  }

  int _selectedBowingMinutes() {
    switch (_selectedBowingTimeIndex) {
      case 0: return 20;
      case 1: return 30;
      case 2: return 60;
      case 3: return int.tryParse(_customBowingTimeValue) ?? 30;
      default: return 30;
    }
  }

  Future<void> _onPause(BuildContext context) async {
    final chant = context.read<ChantProvider>();
    await chant.pause();
    await PedometerService.instance.stop();
  }

  Future<void> _onResume(BuildContext context) async {
    final chant = context.read<ChantProvider>();
    await chant.resume();
    if (chant.needPedometer) {
      await PedometerService.instance.start(onStep: () => chant.onStep());
    }
  }

   

  Future<void> _onFinish(BuildContext context) async {
    final chant = context.read<ChantProvider>();
    final queue = context.read<QueueProvider>();

    if (chant.chantCount > 0 || chant.stepCount > 0) {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      // 1. 保持原有機制：建立雲端佇列紀錄
      final record = ChantRecord(
        date: dateStr,
        chantingCount: chant.chantCount,
        steps: chant.stepCount,
      );
      await queue.addRecord(record);

      // ============================================================
      // 💡 2. 核心大優化：根據「四種選中模式」動態決定本機品項與備註說明
      // ============================================================
      String localItemName = '佛號'; // 預設品項
      String localRemark = '';      // 預設備註
      String snackBarLabel = '念佛'; // 預設彈窗提示詞

      switch (_selectedMode) {
        case 0:
          localItemName = '佛號';
          localRemark = '🏃 跟著步伐 (隨步隨念)';
          snackBarLabel = '隨步念佛';
          break;
        case 1:
          localItemName = '佛號';
          localRemark = '🎵 定速念佛 (速度: $_currentSpeed)';
          snackBarLabel = '定速念佛';
          break;
        case 2:
          localItemName = '佛號';
          int mins = _selectedTimeIndex == 0 ? 30 : (_selectedTimeIndex == 1 ? 60 : (_selectedTimeIndex == 2 ? 90 : int.tryParse(_customTimeValue) ?? 30));
          localRemark = '⏱️ 定時念佛 ($mins分鐘 / 速度: $_timerSpeedPerMinute/分)';
          snackBarLabel = '定時念佛';
          break;
        case 3:
          // 🙇 關鍵：當模式是 3 時，品項名稱改成「拜佛」，備註寫上預計花費時間
          localItemName = '拜佛'; 
          int bows = _selectedBowingIndex == 0 ? 108 : (_selectedBowingIndex == 1 ? 200 : (_selectedBowingIndex == 2 ? 300 : int.tryParse(_customBowingValue) ?? 108));
          int bowMins = _selectedBowingTimeIndex == 0 ? 20 : (_selectedBowingTimeIndex == 1 ? 30 : (_selectedBowingTimeIndex == 2 ? 60 : int.tryParse(_customBowingTimeValue) ?? 30));
          localRemark = '🙇 拜佛功能 (目標: $bows拜 / 預計: $bowMins分鐘)';
          snackBarLabel = '拜佛修行';
          break;
      }

      // ── A. 將功課（佛號或拜佛）存入本機日誌 ──
      if (chant.chantCount > 0) {
        final chantLog = DailyLog(
          id: '${_selectedMode == 3 ? "bow" : "chant"}_${now.millisecondsSinceEpoch}',
          date: dateStr,
          time: timeStr,
          type: _selectedMode == 3 ? 'bow' : 'chant',
          item: localItemName,
          icon: _selectedMode == 3 ? '💎' : '📿', // 🔥 補上這行！拜佛給 💎，念佛給 📿
          count: chant.chantCount,
          remark: localRemark,
        );
        await StorageService.instance.updateDailyLog(dateStr, chantLog);
      }

      // ── B. 將走路步數同步存入本機日誌（只有在有踩出步伐時才存） ──
      if (chant.stepCount > 0) {
         final stepLog = DailyLog(
          id: 'step_${now.millisecondsSinceEpoch}',
          date: dateStr,
          time: timeStr,
          type: 'step',
          item: '步數',
          icon: '👣', // 🔥 補上這行！步數給 👣
          count: chant.stepCount,
          remark: '👣 念佛計步同步',
        );
        await StorageService.instance.updateDailyLog(dateStr, stepLog);
      }

      if (!context.mounted) return;
      
      // 彈出極具質感的綠色成功通知
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ $snackBarLabel ${chant.chantCount} 次已同步！\n👣 這次總共走了 ${chant.stepCount} 步！',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    await chant.finish();
    await PedometerService.instance.stop();
  // ============================================================
    // 🔥 核心修正：念佛結束後，清空自訂時間與自訂次數，恢復預設狀態
    // ============================================================
    if (mounted) {
      setState(() {
        // 1. 重置定時念佛的自訂時間
        _selectedTimeIndex = 0; // 預設回到 30 分
        _customTimeValue = '';  // 清空自訂數字
        _timeCtrl.clear();      // 清空輸入框

        // 2. 重置拜佛的自訂次數與時間
        _selectedBowingIndex = 0; // 預設回到 108 拜
        _customBowingValue = '';
        _bowingCtrl.clear();

        _selectedBowingTimeIndex = 0; // 預設回到 20 分
        _customBowingTimeValue = '';
        _bowingTimeCtrl.clear();
      });
    }
  }
    


  // 下方深色卡片
  Widget _buildSyncBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          const Text('尚未登入', style: TextStyle(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildUploadCounter(BuildContext context, ChantProvider chant) {
    final queue = context.watch<QueueProvider>();
    final pendingCount = queue.totalPendingChant + chant.chantCount; 

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text('📿 本次念佛', style: TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 6),
                Text('${chant.chantCount} 聲', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.borderSoft),
          Expanded(
            child: Column(
              children: [
                const Text('📤 待上傳', style: TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 6),
                Text('$pendingCount 聲', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildGoUploadButton(BuildContext context, ChantProvider chant) {
    final queue = context.watch<QueueProvider>();
    final hasData = queue.totalPendingChant > 0 || queue.totalPendingSteps > 0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        // 🔥 點擊後跳到「日曆分頁」(Index 1)
        onPressed: hasData ? () => context.read<TabProvider>().setIndex(1) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: hasData ? AppColors.accent : Colors.grey.shade600,
          foregroundColor: hasData ? AppColors.primaryDark : Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          hasData ? '📤 去上傳 (${queue.totalPendingChant} 聲)' : '📤 去上傳',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  
  // 💡 修正後的身心統計字卡區：直接顯示最新手動上傳的生理數值
  Widget _buildStatsGrid(ChantProvider chant) {
    return Column(
      children: [
        Row(
          children: [
            // 👇 把這裡的 chant.stepCount 改成 _todaySteps
            _buildStatBox('👣 今日步數', '$_todaySteps', '步'),
            const SizedBox(width: 10),
            _buildStatBox('❤️ 平均心跳', _todayHR, 'bpm'), // 🟢 連動顯示
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildStatBox('🩺 血壓', _todayBP, 'mmHg'),   // 🟢 連動顯示
            _buildStatBox('🔥 消耗熱量', _todayCal, 'kcal'), // 🟢 步數換算+累積顯示
          ],
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, String unit) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(unit, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}