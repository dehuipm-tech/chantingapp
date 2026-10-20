import 'package:flutter/material.dart';
import '../models/chant_record.dart';
import '../theme/app_colors.dart';

class QueueItem extends StatelessWidget {
  final ChantRecord record;
  final VoidCallback onToggleChant;
  final VoidCallback onToggleSteps;
  final Function(int) onEditChant;
  final Function(int) onEditSteps;
  final VoidCallback onDelete;

  const QueueItem({
    super.key,
    required this.record,
    required this.onToggleChant,
    required this.onToggleSteps,
    required this.onEditChant,
    required this.onEditSteps,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgWarm,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (record.checkedChant || record.checkedSteps)
              ? AppColors.primary
              : AppColors.borderSoft,
        ),
      ),
      child: Column(
        children: [
          // 日期與刪除按鈕
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📅 ${record.date}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // 念佛列
          _buildRow(
            label: '📿 念佛',
            unit: '聲',
            isChecked: record.checkedChant,
            value: record.editChant,
            onToggle: onToggleChant,
            onChanged: onEditChant,
          ),
          const SizedBox(height: 6),
          
          // 步數列
          _buildRow(
            label: '👣 步數',
            unit: '步',
            isChecked: record.checkedSteps,
            value: record.editSteps,
            onToggle: onToggleSteps,
            onChanged: onEditSteps,
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required String unit,
    required bool isChecked,
    required int value,
    required VoidCallback onToggle,
    required Function(int) onChanged,
  }) {
    return Row(
      children: [
        // 勾選框
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isChecked ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isChecked ? AppColors.primary : AppColors.borderLight,
              ),
            ),
            child: isChecked
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        
        // 標籤
        SizedBox(
          width: 55,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMid,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // 輸入框
        Expanded(
          child: TextField(
            controller: TextEditingController(text: value.toString()),
            keyboardType: TextInputType.number,
            enabled: isChecked,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.red,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              filled: true,
              fillColor: isChecked ? Colors.white : Colors.grey.shade200,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (val) {
              final num = int.tryParse(val) ?? 0;
              onChanged(num);
            },
          ),
        ),
        const SizedBox(width: 6),
        
        // 單位
        Text(unit, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
      ],
    );
  }
}