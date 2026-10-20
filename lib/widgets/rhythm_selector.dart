import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chant_provider.dart';
import '../theme/app_colors.dart';

class RhythmSelector extends StatelessWidget {
  const RhythmSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChantProvider>(
      builder: (context, chant, _) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // ============ 標題 ============
              const Text(
                '📿 念佛節奏',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSoft,
                ),
              ),
              const SizedBox(height: 12),

              // ============ 1. 模式選擇 ============
              Row(
                children: [
                  Expanded(
                    child: _RhythmOption(
                      icon: '🚶',
                      name: '跟著步伐',
                      desc: '每步一聲',
                      isActive: chant.rhythm == RhythmMode.step,
                      onTap: () => chant.setRhythm(RhythmMode.step),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RhythmOption(
                      icon: '🎵',
                      name: '定速念佛',
                      desc: '聽聲跟著念',
                      isActive: chant.rhythm == RhythmMode.timed,
                      onTap: () => chant.setRhythm(RhythmMode.timed),
                    ),
                  ),
                ],
              ),

              // ============ 2+3. 只有定速念佛才顯示 ============
              if (chant.rhythm == RhythmMode.timed) ...[
                const SizedBox(height: 16),
                _buildDivider(),
                const SizedBox(height: 12),

                // 速度
                const Text(
                  '🎚️ 速度',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSoft,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSpeedRow(chant),

                const SizedBox(height: 14),

                // 念佛方式
                const Text(
                  '🎯 念佛方式',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSoft,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTimedModeRow(chant),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDivider() => Container(
        height: 1,
        color: AppColors.borderSoft,
      );

  Widget _buildSpeedRow(ChantProvider chant) {
    const speeds = [
      (30, '🐢', '慢', '30/分'),
      (60, '🧘', '正常', '60/分'),
      (90, '🚶', '快', '90/分'),
      (120, '🏃', '更快', '120/分'),
    ];
    return Row(
      children: speeds.map((s) {
        final (bpm, icon, name, desc) = s;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _SpeedOption(
              icon: icon,
              name: name,
              desc: desc,
              isActive: chant.bpm == bpm,
              onTap: () => chant.setBpm(bpm),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimedModeRow(ChantProvider chant) {
    // 🔊 只有聲音 / 🔊👣 聲音+步數
    return Row(
      children: [
        Expanded(
          child: _TimedModeOption(
            icon: '🔊',
            name: '只有聲音',
            desc: '不計步',
            isActive: chant.timedMode == TimedMode.sound,
            onTap: () => chant.setTimedMode(TimedMode.sound),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TimedModeOption(
            icon: '🔊👣',
            name: '聲音+步數',
            desc: '邊走邊念',
            isActive: chant.timedMode == TimedMode.soundStep,
            onTap: () => chant.setTimedMode(TimedMode.soundStep),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 模式選項（大顆的）
// ============================================================
class _RhythmOption extends StatelessWidget {
  final String icon;
  final String name;
  final String desc;
  final bool isActive;
  final VoidCallback onTap;

  const _RhythmOption({
    required this.icon,
    required this.name,
    required this.desc,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryLight : AppColors.bgWarm,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.borderLight,
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isActive ? AppColors.primary : AppColors.textMid,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 速度選項（小顆的）
// ============================================================
class _SpeedOption extends StatelessWidget {
  final String icon;
  final String name;
  final String desc;
  final bool isActive;
  final VoidCallback onTap;

  const _SpeedOption({
    required this.icon,
    required this.name,
    required this.desc,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryLight : AppColors.bgWarm,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.borderLight,
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 3),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? AppColors.primary : AppColors.textMid,
              ),
            ),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 念佛方式選項
// ============================================================
class _TimedModeOption extends StatelessWidget {
  final String icon;
  final String name;
  final String desc;
  final bool isActive;
  final VoidCallback onTap;

  const _TimedModeOption({
    required this.icon,
    required this.name,
    required this.desc,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryLight : AppColors.bgWarm,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.borderLight,
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isActive ? AppColors.primary : AppColors.textMid,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}