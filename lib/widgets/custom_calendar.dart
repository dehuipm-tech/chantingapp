import 'package:flutter/material.dart';
import '../helpers/lunar_helper.dart'; // 確保你有匯入你的農曆工具

class CustomCalendar extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDaySelected;

  const CustomCalendar({
    super.key,
    required this.initialDate,
    required this.onDaySelected,
  });

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  late DateTime _displayedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(widget.initialDate.year, widget.initialDate.month, 1);
    _selectedDay = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    // 這裡的顏色完全對應你 HTML 的 CSS
    const Color bgColor = Color(0xFFF8F5F0);
    const Color borderColor = Color(0xFFE8DDD0);
    const Color activeBorderColor = Color(0xFF8D6E63);
    const Color activeBgColor = Color(0xFFF5EDE4);
    const Color redBorderColor = Color(0xFFE74C3C);
    const Color redBgColor = Color(0xFFFDE8E8);
    const Color blueBorderColor = Color(0xFF3498DB);
    const Color blueBgColor = Color(0xFFE8F4FD);
    const Color todayBorderColor = Color(0xFFF39C12);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // 星期標題
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['日', '一', '二', '三', '四', '五', '六'].map((day) {
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EBE6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          
          // 日曆格子
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.75, // 調整格子高度比例
            ),
            itemCount: _getDaysInMonth() + _getFirstDayOffset(),
            itemBuilder: (context, index) {
              final firstDayOffset = _getFirstDayOffset();
              if (index < firstDayOffset) {
                return const SizedBox(); // 空白格子
              }
              
              final day = index - firstDayOffset + 1;
              final date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
              final isToday = _isSameDay(date, DateTime.now());
              final isSelected = _selectedDay != null && _isSameDay(date, _selectedDay!);
              
              // 取得農曆字串
              final lunarStr = LunarHelper.getLunarDateString(date);
              final isLunar1 = lunarStr.contains('初一');
              final isLunar15 = lunarStr.contains('十五');

              // 這裡的狀態優先級完全對應你 HTML 的 CSS
              Color cellBg = Colors.white;
              Color cellBorder = borderColor;
              Color dateColor = const Color(0xFF3D2B1A);

              if (isLunar1) {
                cellBg = redBgColor;
                cellBorder = redBorderColor;
                dateColor = const Color(0xFFC0392B);
              } else if (isLunar15) {
                cellBg = blueBgColor;
                cellBorder = blueBorderColor;
                dateColor = const Color(0xFF2980B9);
              }

              if (isToday) {
                cellBorder = todayBorderColor;
              }

              if (isSelected) {
                cellBg = activeBgColor;
                cellBorder = activeBorderColor;
              }

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = date;
                  });
                  widget.onDaySelected(date);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: cellBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: cellBorder,
                      width: (isToday || isSelected) ? 3 : 2, // 今日或選中框加粗
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '$day',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: dateColor,
                        ),
                      ),
                      Text(
                        lunarStr,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFFA08070),
                        ),
                      ),
                      const Spacer(),
                      // 這裡可以預留給小圖示（如：📿👣）
                      // if (hasRecord) Text('📿', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  int _getDaysInMonth() {
    return DateUtils.getDaysInMonth(_displayedMonth.year, _displayedMonth.month);
  }

  int _getFirstDayOffset() {
    return DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday % 7;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}