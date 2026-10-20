import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🔥 補上這個才能用 context.watch

import '../providers/chant_provider.dart';
import '../theme/app_colors.dart';

class CounterRing extends StatefulWidget {
  const CounterRing({super.key});

  @override
  State<CounterRing> createState() => _CounterRingState();
}

class _CounterRingState extends State<CounterRing> with SingleTickerProviderStateMixin {
  // 🔥 補上呼吸動畫控制器
  late AnimationController _breathCtrl;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chant = context.watch<ChantProvider>();

    // 呼吸動畫只在念佛/拜佛中運行
    if (chant.isRunning && !_breathCtrl.isAnimating) {
      _breathCtrl.repeat(reverse: true);
    } else if (!chant.isRunning && _breathCtrl.isAnimating) {
      _breathCtrl.stop();
      _breathCtrl.value = 0;
    }

    // 💡 🟢 精準判斷目前 Provider 內部是不是正處於「拜佛」模式
    final isBowingMode = chant.rhythm == RhythmMode.bow;

    return GestureDetector(
      // 允許手動點按加一聲/加一拜
      onTap: chant.isRunning ? () => chant.manualAddChant() : null,
      child: AnimatedBuilder(
        animation: _breathCtrl,
        builder: (context, child) {
          final scale = 1.0 + _breathCtrl.value * 0.04;
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width: 230,
          height: 230,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryDark, 
            border: Border.all(color: AppColors.accent, width: 8), 
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.3), 
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  chant.chantCount.toString(),
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentLight, 
                    letterSpacing: -2,
                  ),
                ),
                
                // 💡 🟢 動態切換計數單位文字
                Text(
                  isBowingMode ? '拜' : '聲 佛 號',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSoft, fontWeight: FontWeight.bold),
                ),
                
                const SizedBox(height: 8),
                Text(
                  _statusText(chant),
                  style: TextStyle(
                    fontSize: 12,
                    color: _statusColor(chant),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🟢 狀態文字與顏色判斷
  // ============================================================
  String _statusText(ChantProvider chant) {
    final isBowingMode = chant.rhythm == RhythmMode.bow;

    if (chant.isIdle) {
      return '尚未開始';
    }
    
    if (chant.isRunning) {
      if (chant.rhythm == RhythmMode.step) {
        return '念佛中… 手機可放口袋';
      }
      return isBowingMode ? '🙇 拜佛中…' : '📿 念佛中…';
    }

    return '⏸ 已暫停（可繼續）';
  }

  Color _statusColor(ChantProvider chant) {
    if (chant.isIdle) {
      return Colors.grey;
    }
    if (chant.isRunning) {
      return AppColors.green;
    }
    return AppColors.orange; // 暫停顏色
  }
}