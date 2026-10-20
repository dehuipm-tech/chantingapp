import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tab_provider.dart';
import '../providers/chant_provider.dart';
import '../providers/queue_provider.dart';
import '../services/pedometer_service.dart';
import '../widgets/rhythm_selector.dart';
import '../widgets/counter_ring.dart';
import '../theme/app_colors.dart';
import '../models/chant_record.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 0 = 跟著步伐, 1 = 念佛, 2 = 拜佛
  int _currentMode = 0;

  // 念佛設定
  bool _isTimerMode = true;
  int _timeMinutes = 30;
  String _chantSpeed = '中';
  int _estimatedChants = 0;

  // 拜佛設定
  int _bowingCount = 108;
  bool _isCustomBowing = false;
  final TextEditingController _customBowingCtrl = TextEditingController(text: '108');
  final List<int> _bowingTimes = [20, 30, 40, 60, 90];
  int _selectedBowingTime = 30;
  bool _isCustomTime = false;
  final TextEditingController _customTimeCtrl = TextEditingController(text: '30');
  int _bowingChants = 0;
  double _bowingCalories = 0.0;
  int _bowingIntervalSecs = 0;

  @override
  void initState() {
    super.initState();
    _calculateTimerChants();
    _calculateBowingLogic();
  }

  @override
  void dispose() {
    _customBowingCtrl.dispose();
    _customTimeCtrl.dispose();
    super.dispose();
  }

  void _calculateTimerChants() {
    int chantsPerMinute = 60;
    if (_chantSpeed == '慢') chantsPerMinute = 30;
    if (_chantSpeed == '快') chantsPerMinute = 90;
    if (_chantSpeed == '極快') chantsPerMinute = 120;
    setState(() {
      _estimatedChants = _timeMinutes * chantsPerMinute;
    });
  }

  void _calculateBowingLogic() {
    int actualCount = _isCustomBowing 
        ? (int.tryParse(_customBowingCtrl.text) ?? 108) 
        : _bowingCount;
    if (actualCount <= 0) actualCount = 1;

    int actualTime = _isCustomTime
        ? (int.tryParse(_customTimeCtrl.text) ?? 30)
        : _selectedBowingTime;
    if (actualTime <= 0) actualTime = 1;

    setState(() {
      _bowingCount = actualCount;
      _selectedBowingTime = actualTime;
      _bowingChants = actualCount;
      _bowingCalories = actualCount * 0.5;
      int totalSecs = actualTime * 60;
      _bowingIntervalSecs = (totalSecs / actualCount).round();
      if (_bowingIntervalSecs <= 0) _bowingIntervalSecs = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chant = context.watch<ChantProvider>();

    return Scaffold(
      // 🔮 使用紫羅蘭漸層背景
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A2A6A), Color(0xFF5A3A7A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🟣 自訂 AppBar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                color: AppColors.primaryDark,
                child: const Text(
                  '📿 念佛計步',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentLight,
                  ),
                ),
              ),

              // 🔥 模式切換 Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Row(
                  children: [
                    _buildTab(0, '👣 跟著步伐'),
                    _buildTab(1, '📿 念佛'),
                    _buildTab(2, '🙇 拜佛'),
                  ],
                ),
              ),
              
              // 主要內容
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildCurrentModeContent(chant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index, String text) {
    bool isActive = _currentMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentMode = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? AppColors.primaryDark : AppColors.textSoft,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentModeContent(ChantProvider chant) {
    switch (_currentMode) {
      case 0:
        return _buildStepMode(chant);
      case 1:
        return _buildChantMode();
      case 2:
        return _buildBowingMode();
      default:
        return const SizedBox();
    }
  }

  // ============================================================
  // 模式一：跟著步伐 (保留您原有的圓環與佇列)
  // ============================================================
  Widget _buildStepMode(ChantProvider chant) {
    return Column(
      children: [
        const RhythmSelector(),
        const SizedBox(height: 24),
        const CounterRing(),
        const SizedBox(height: 24),
        _buildButtons(context, chant),
        const SizedBox(height: 24),
        _buildSyncBar(),
        const SizedBox(height: 12),
        _buildUploadCounter(context, chant),
        const SizedBox(height: 12),
        _buildGoUploadButton(context, chant),
        const SizedBox(height: 24),
        _buildStatsGrid(chant),
      ],
    );
  }

  // ============================================================
  // 模式二：念佛 (定時 / 自由)
  // ============================================================
  Widget _buildChantMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDarkChoiceChip('⏱️ 定時', _isTimerMode, () => setState(() => _isTimerMode = true)),
            const SizedBox(width: 12),
            _buildDarkChoiceChip('⏳ 自由', !_isTimerMode, () => setState(() => _isTimerMode = false)),
          ],
        ),
        const SizedBox(height: 24),
        
        if (_isTimerMode) ...[
          const Text('⏱️ 設定時間 (分鐘)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.accentLight)),
          const SizedBox(height: 12),
          _buildDarkGridSelector([30, 60, 90, 120], _timeMinutes, '分', (val) {
            setState(() => _timeMinutes = val);
            _calculateTimerChants();
          }),
          const SizedBox(height: 24),
        ],

        const Text('🔊 選擇念佛速度', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.accentLight)),
        const SizedBox(height: 12),
        _buildDarkGridSelector(['慢', '中', '快', '極快'], _chantSpeed, '', (val) {
          setState(() => _chantSpeed = val);
          _calculateTimerChants();
        }),
        const SizedBox(height: 30),

        Center(
          child: Text(
            _isTimerMode ? '預計念佛 $_estimatedChants 聲' : '自由念佛，想停就停',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.accent),
          ),
        ),
        const SizedBox(height: 30),
        _buildStartButton('開始念佛', AppColors.accent, () {}),
      ],
    );
  }

  // ============================================================
  // 模式三：拜佛
  // ============================================================
  Widget _buildBowingMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🙇 選擇拜佛次數', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.accentLight)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...[108, 200, 300].map((count) {
              bool isSel = !_isCustomBowing && _bowingCount == count;
              return _buildDarkChoiceBox('$count 拜', isSel, () {
                setState(() {
                  _isCustomBowing = false;
                  _bowingCount = count;
                  _calculateBowingLogic();
                });
              });
            }),
            _buildDarkChoiceBox('自訂', _isCustomBowing, () {
              setState(() => _isCustomBowing = true);
              _showCustomDialog('自訂次數', _customBowingCtrl, '拜', () => _calculateBowingLogic());
            }),
          ],
        ),
        if (_isCustomBowing) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customBowingCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: '輸入次數',
              labelStyle: TextStyle(color: AppColors.textSoft),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderSoft)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
              suffixText: '拜',
              suffixStyle: TextStyle(color: AppColors.textSoft),
            ),
            onChanged: (val) => _calculateBowingLogic(),
          ),
        ],
        const SizedBox(height: 24),

        const Text('⏱️ 選擇預計花費時間', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.accentLight)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._bowingTimes.map((time) {
              bool isSel = !_isCustomTime && _selectedBowingTime == time;
              return _buildDarkChoiceBox('$time 分', isSel, () {
                setState(() {
                  _isCustomTime = false;
                  _selectedBowingTime = time;
                  _calculateBowingLogic();
                });
              });
            }),
            _buildDarkChoiceBox('自訂', _isCustomTime, () {
              setState(() => _isCustomTime = true);
              _showCustomDialog('自訂時間', _customTimeCtrl, '分', () => _calculateBowingLogic());
            }),
          ],
        ),
        if (_isCustomTime) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customTimeCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: '輸入分鐘數',
              labelStyle: TextStyle(color: AppColors.textSoft),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderSoft)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
              suffixText: '分',
              suffixStyle: TextStyle(color: AppColors.textSoft),
            ),
            onChanged: (val) => _calculateBowingLogic(),
          ),
        ],
        const SizedBox(height: 30),

        // 自動計算結果顯示
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('⏳ 預計時間', style: TextStyle(fontSize: 15, color: AppColors.textSoft)),
                  Text('$_selectedBowingTime 分鐘', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                ],
              ),
              const Divider(color: AppColors.borderSoft),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🥁 木魚節奏', style: TextStyle(fontSize: 15, color: AppColors.textSoft)),
                  Text('每 $_bowingIntervalSecs 秒一聲', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.accent)),
                ],
              ),
              const Divider(color: AppColors.borderSoft),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('📿 聲數 / 🔥 熱量', style: TextStyle(fontSize: 15, color: AppColors.textSoft)),
                  Text('$_bowingChants 聲 / ${_bowingCalories.toStringAsFixed(1)} 大卡', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.orange)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),
        _buildStartButton('開始拜佛', AppColors.blue, () {}),
      ],
    );
  }

  // ============================================================
  // 統一的 UI 輔助元件 (套用深紫色系)
  // ============================================================
  Widget _buildDarkChoiceChip(String text, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(text),
      selected: isSelected,
      onSelected: (val) => onTap(),
      selectedColor: AppColors.accent,
      backgroundColor: AppColors.bgCard,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryDark : AppColors.textSoft,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDarkChoiceBox(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.accent : AppColors.borderSoft),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.primaryDark : AppColors.textSoft,
          ),
        ),
      ),
    );
  }

  Widget _buildDarkGridSelector<T>(List<T> options, T selectedValue, String suffix, Function(T) onChanged) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((option) {
        bool isSelected = selectedValue == option;
        String text = suffix.isEmpty ? option.toString() : '$option $suffix';

        return GestureDetector(
          onTap: () => onChanged(option),
          child: Container(
            width: (MediaQuery.of(context).size.width - 56) / 2,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppColors.accent : AppColors.borderSoft),
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primaryDark : AppColors.textSoft,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStartButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.primaryDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showCustomDialog(String title, TextEditingController ctrl, String suffix, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(labelText: '請輸入數值', suffixText: suffix),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 以下保留您原有的所有方法 (完全沒動)
  // ============================================================
  Widget _buildButtons(BuildContext context, ChantProvider chant) {
    if (chant.isIdle) {
      return SizedBox(
        width: 330,
        child: ElevatedButton.icon(
          onPressed: () => _onStart(context),
          icon: const Icon(Icons.play_arrow_rounded, size: 24),
          label: const Text('開始念佛'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.primaryDark,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
              label: Text(chant.isRunning ? '暫停' : '繼續'),
              style: ElevatedButton.styleFrom(
                backgroundColor: chant.isRunning ? AppColors.orange : AppColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _onFinish(context),
              icon: const Icon(Icons.stop_rounded, size: 20),
              label: const Text('結束'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onStart(BuildContext context) async {
    final chant = context.read<ChantProvider>();
    await chant.start();
    if (chant.needPedometer) {
      await PedometerService.instance.start(onStep: () => chant.onStep());
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
      
      final record = ChantRecord(
        date: dateStr,
        chantingCount: chant.chantCount,
        steps: chant.stepCount,
      );

      await queue.addRecord(record);

      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已加入佇列，本次念佛 ${chant.chantCount} 聲')),
      );
    }

    await chant.finish();
    await PedometerService.instance.stop();
  }

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
          const Text('尚未登入', style: TextStyle(fontSize: 13, color: AppColors.textSoft)),
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
                const Text('📿 本次念佛', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                const SizedBox(height: 6),
                Text('${chant.chantCount} 聲', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.borderSoft),
          Expanded(
            child: Column(
              children: [
                const Text('📤 待上傳', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                const SizedBox(height: 6),
                Text('$pendingCount 聲', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primaryLight)),
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
        onPressed: hasData ? () => context.read<TabProvider>().setIndex(4) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: hasData ? AppColors.accent : Colors.grey.shade600,
          foregroundColor: hasData ? AppColors.primaryDark : Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          hasData ? '📤 去上傳 (${queue.totalPendingChant} 聲)' : '📤 去上傳',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(ChantProvider chant) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatBox('👣 今日步數', '${chant.stepCount}', '步'),
            const SizedBox(width: 10),
            _buildStatBox('❤️ 平均心跳', '--', 'bpm'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildStatBox('🩺 血壓', '--/--', 'mmHg'),
            _buildStatBox('🔥 消耗熱量', '0', 'kcal'),
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
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(unit, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}