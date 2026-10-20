import 'package:flutter/material.dart';

class LunarHelper {
  static final List<String> _lunarDays = [
    '初一','初二','初三','初四','初五','初六','初七','初八','初九','初十',
    '十一','十二','十三','十四','十五','十六','十七','十八','十九','二十',
    '廿一','廿二','廿三','廿四','廿五','廿六','廿七','廿八','廿九','三十'
  ];

  // 🟢 注意：這裡的 key 是「該農曆年的正月初一落在哪一天」
  static final Map<int, Map<String, DateTime>> _lunarMonthStart = {
    2026: {
      '正月': DateTime(2026, 2, 17),
      '二月': DateTime(2026, 3, 19),
      '三月': DateTime(2026, 4, 17),
      '四月': DateTime(2026, 5, 17),
      '五月': DateTime(2026, 6, 15),
      '六月': DateTime(2026, 7, 14),
      '七月': DateTime(2026, 8, 13),
      '八月': DateTime(2026, 9, 11),
      '九月': DateTime(2026, 10, 10), 
      '十月': DateTime(2026, 11, 9),
      '十一月': DateTime(2026, 12, 9),
      '臘月': DateTime(2027, 1, 8), // 跨年
    },
    // 如果你有 2025 的資料，記得補上，這樣 2026 年初才能查到 2025 的臘月
    2025: {
      '正月': DateTime(2025, 1, 29),
      '二月': DateTime(2025, 2, 28),
      '三月': DateTime(2025, 3, 29),
      '四月': DateTime(2025, 4, 28),
      '五月': DateTime(2025, 5, 27),
      '六月': DateTime(2025, 6, 25),
      '七月': DateTime(2025, 7, 25),
      '八月': DateTime(2025, 8, 23),
      '九月': DateTime(2025, 9, 22),
      '十月': DateTime(2025, 10, 21),
      '十一月': DateTime(2025, 11, 20),
      '臘月': DateTime(2025, 12, 20),
    }
    // 💡 2027、2028 依此類推...
  };

  static final Map<String, String> _lookup = {};
  static bool _built = false;

  static void _buildLookup() {
    if (_built) return;
    
    // 把所有年份的資料攤平，轉換成 DateTime 並排序
    List<MapEntry<String, DateTime>> allStarts = [];
    _lunarMonthStart.forEach((year, monthData) {
      monthData.forEach((monthName, date) {
        allStarts.add(MapEntry(monthName, date));
      });
    });
    // 依照時間先後排序
    allStarts.sort((a, b) => a.value.compareTo(b.value));

    for (int i = 0; i < allStarts.length; i++) {
      final start = allStarts[i];
      DateTime endDate;
      
      if (i + 1 < allStarts.length) {
        endDate = allStarts[i + 1].value;
      } else {
        // 如果是最後一個月，預設 30 天
        endDate = start.value.add(const Duration(days: 30));
      }

      var cur = start.value;
      int dayIndex = 0;
      while (cur.isBefore(endDate) && dayIndex < 30) {
        final key = _formatDateKey(cur);
        _lookup[key] = '${start.key}${_lunarDays[dayIndex]}';
        cur = cur.add(const Duration(days: 1));
        dayIndex++;
      }
    }
    _built = true;
  }

  static String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 取得該日期的農曆字串（例如：九月初十）
  static String getLunarDateString(DateTime date) {
    _buildLookup();
    final key = _formatDateKey(date);
    return _lookup[key] ?? '--';
  }
}