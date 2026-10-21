import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/lunar_helper.dart'; 

class CloudCalendarScreen extends StatefulWidget {
  const CloudCalendarScreen({super.key});

  @override
  State<CloudCalendarScreen> createState() => _CloudCalendarScreenState();
}

class _CloudCalendarScreenState extends State<CloudCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<String, dynamic> _cloudDailyRecords = {};
  bool _isLoading = false;

  int _selectedYear = DateTime.now().year;
  Map<String, dynamic> _yearRecords = {};
  List<dynamic> _yearItems = [];
  bool _isYearLoading = false;
  String? _lastLoadedMemberNo;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _loadYearStats();
    });
  }

  // 🔥 測試用：直接打 API 並印出 Log
  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (!auth.loggedIn) return;
    
    String groupCode = auth.state.groupCode.isNotEmpty ? auth.state.groupCode : '01';

    setState(() => _isLoading = true);
    
    try {
      final memberNo = auth.state.memberNo;
      final year = _focusedDay.year;
      final month = _focusedDay.month;
      
      final url = Uri.parse('https://tw-proxy-ei.dhp.com.tw/index.php?action=getMemberChantingDailyHistory&memberNo=$memberNo&year=$year&month=$month&group=$groupCode');
      print('🚀 [直接測試] 網址: $url');
      
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      
      print('📥 [直接測試] 回應碼: ${response.statusCode}');
      print('📥 [直接測試] 回應內容前100字: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}');
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _cloudDailyRecords = json['dailyRecords'] ?? {};
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        print('❌ 狀態碼錯誤: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ 連線例外: $e');
    }
  }

  // 🔥 測試用：直接打 API 並印出 Log
  Future<void> _loadYearStats() async {
    final auth = context.read<AuthProvider>();
    if (!auth.loggedIn) return;
    
    String groupCode = auth.state.groupCode.isNotEmpty ? auth.state.groupCode : '01';

    setState(() => _isYearLoading = true);
    
    try {
      final memberNo = auth.state.memberNo;
      final year = _selectedYear;
      
      final url = Uri.parse('https://tw-proxy-ei.dhp.com.tw/index.php?action=getMemberChantingHistory&memberNo=$memberNo&year=$year&group=$groupCode');
      print('🚀 [直接測試] 年度網址: $url');
      
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      
      print('📥 [直接測試] 年度回應碼: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _yearRecords = (json['records'] is Map) ? Map<String, dynamic>.from(json['records']) : {};
          _yearItems = (json['items'] is List) ? json['items'] : [];
          _isYearLoading = false;
        });
      } else {
        setState(() => _isYearLoading = false);
      }
    } catch (e) {
      setState(() => _isYearLoading = false);
      print('❌ 年度連線例外: $e');
    }
  }

  int _getAmount(String itemName, int month) {
    final itemRecs = _yearRecords[itemName];
    if (itemRecs == null) return 0;
    if (itemRecs is Map) {
      final v = itemRecs['$month'] ?? itemRecs[month.toString().padLeft(2, '0')] ?? itemRecs[month] ?? 0;
      return (v is num) ? v.toInt() : 0;
    }
    if (itemRecs is List) {
      for (final rec in itemRecs) {
        if (rec is Map) {
          final recMonth = (rec['month'] as num?)?.toInt();
          if (recMonth == month) {
            final v = rec['count'] ?? rec['amount'] ?? rec['value'] ?? 0;
            return (v is num) ? v.toInt() : 0;
          }
        }
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.loggedIn && auth.state.memberNo != _lastLoadedMemberNo) {
          _lastLoadedMemberNo = auth.state.memberNo;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadData();
            _loadYearStats();
          });
        }

        return Scaffold(
          backgroundColor: AppColors.bgWarm,
          appBar: AppBar(
            title: const Text('☁️ 雲端紀錄'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: !auth.loggedIn
              ? const Center(child: Text('請先登入才能查看雲端紀錄', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadData();
                    await _loadYearStats();
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(), 
                    children: [
                      // 1. 客製化月曆
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F5F0),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8DDD0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left, color: Color(0xFF8D6E63)),
                                  onPressed: () {
                                    setState(() {
                                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                                      _selectedDay = _focusedDay; 
                                    });
                                    _loadData(); 
                                  },
                                ),
                                Text(
                                  '${_focusedDay.year}年 ${_focusedDay.month}月',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right, color: Color(0xFF8D6E63)),
                                  onPressed: () {
                                    setState(() {
                                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                                      _selectedDay = _focusedDay;
                                    });
                                    _loadData(); 
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: ['日', '一', '二', '三', '四', '五', '六'].map((day) {
                                return Expanded(
                                  child: Center(
                                    child: Text(
                                      day,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF5D4037)),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 1,
                                crossAxisSpacing: 1,
                                childAspectRatio: 0.65,
                              ),
                              itemCount: _getDaysInMonth() + _getFirstDayOffset(),
                              itemBuilder: (context, index) {
                                final firstDayOffset = _getFirstDayOffset();
                                if (index < firstDayOffset) return const SizedBox();
                                
                                final day = index - firstDayOffset + 1;
                                final date = DateTime(_focusedDay.year, _focusedDay.month, day);
                                
                                return _buildCalendarCell(date);
                              },
                            ),
                          ],
                        ),
                      ),

                      // 2. 當日詳細資料
                      if (_isLoading)
                        const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildCloudDayDetail(),
                        ),

                      const SizedBox(height: 24),

                      // 3. 年度統計
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildYearStats(),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        );
      },
    );
  }

  int _getDaysInMonth() => DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);
  int _getFirstDayOffset() => DateTime(_focusedDay.year, _focusedDay.month, 1).weekday % 7;

  Widget _buildCalendarCell(DateTime day) {
    final lunar = LunarHelper.getLunarDateString(day);
    final lunarText = lunar.contains('--') ? '' : lunar.replaceAll('月', '');

    final dayStr = day.day.toString();
    final hasData = _cloudDailyRecords.containsKey(dayStr);

    final isLunar1 = lunar.contains('初一');
    final isLunar15 = lunar.contains('十五');
    final isSelected = _selectedDay != null && DateUtils.isSameDay(day, _selectedDay);
    final isToday = DateUtils.isSameDay(day, DateTime.now());

    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFFE8DDD0);
    Color dateColor = const Color(0xFF3D2B1A);
    double borderWidth = 2.0;

    if (isLunar1) {
      bgColor = const Color(0xFFFDE8E8);
      borderColor = const Color(0xFFE74C3C);
      dateColor = const Color(0xFFC0392B);
    } else if (isLunar15) {
      bgColor = const Color(0xFFE8F4FD);
      borderColor = const Color(0xFF3498DB);
      dateColor = const Color(0xFF2980B9);
    }

    if (isToday) {
      borderColor = const Color(0xFFF39C12);
      borderWidth = 3.0;
    }

    if (isSelected) {
      bgColor = const Color(0xFFF5EDE4);
      borderColor = const Color(0xFF8D6E63);
      borderWidth = 3.0;
    }

        return GestureDetector(
      onTap: () {
        setState(() => _selectedDay = day);
      },
      child: Container(
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: isSelected ? [
            BoxShadow(color: const Color(0xFF8D6E63).withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3))
          ] : null,
        ),
        // 🔥 改用 Column 並且設定 mainAxisAlignment: MainAxisAlignment.start，讓數字靠上
        child: Padding(
          padding: const EdgeInsets.only(top: 2), // 給上方一點點留白
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // 🔥 關鍵：讓內容從最上面開始排
            children: [
              Text(
                '${day.day}',
                style: TextStyle(fontSize: 15, height: 1.0, fontWeight: FontWeight.w700, color: dateColor), // 高度設 1.0 減少行距
              ),
              const SizedBox(height: 2), // 🔥 數字跟農曆之間的空隙
              Text(
                lunarText,
                style: const TextStyle(fontSize: 9, height: 1.0, color: Color(0xFFA08070)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2), // 🔥 農曆跟圖示之間的空隙
              if (hasData)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 1, // 圖示之間的左右間距
                  runSpacing: 1, // 圖示如果換行，上下的間距
                  children: () {
                    // 抓取所有圖示，並利用 .toSet() 去除重複
                    final List<String> allIcons = (_cloudDailyRecords[dayStr] as List? ?? [])
                        .map((r) => r['icon']?.toString() ?? '📿')
                        .toSet() 
                        .toList();

                    // 🔥 提高到最多顯示 6 個圖示
                    final int maxShow = 6;
                    final int showCount = allIcons.length > maxShow ? maxShow : allIcons.length;
                    
                    List<Widget> iconWidgets = [];
                    for (int i = 0; i < showCount; i++) {
                      // 🔥 圖示字體改為 8，並加上 height: 1.0 讓它更緊湊
                      iconWidgets.add(Text(allIcons[i], style: const TextStyle(fontSize: 8, height: 1.0)));
                    }
                    
                    // 如果超過 6 個，顯示 +N
                    if (allIcons.length > maxShow) {
                      iconWidgets.add(Text('+${allIcons.length - maxShow}', style: const TextStyle(fontSize: 8, height: 1.0, fontWeight: FontWeight.bold, color: Color(0xFF8D6E63))));
                    }
                    
                    return iconWidgets;
                  }(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloudDayDetail() {
    if (_selectedDay == null) return const SizedBox();

    final dayStr = _selectedDay!.day.toString();
    final dayRecords = _cloudDailyRecords[dayStr] ?? [];
    final lunarStr = LunarHelper.getLunarDateString(_selectedDay!);
    final lunarText = (lunarStr != '--') ? ' · 農曆 $lunarStr' : '';

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
          Text(
            '☁️ ${_selectedDay!.year}/${_selectedDay!.month}/${_selectedDay!.day}$lunarText 雲端紀錄',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),

          if (dayRecords.isEmpty)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('📭 無雲端紀錄',
                        style: TextStyle(color: Colors.grey))))
          else
            ...dayRecords.map((r) {
              final id = r['id']?.toString() ?? '';
              final itemName = r['item'] ?? '未知';
              final count = (r['count'] as num?)?.toInt() ?? 0;
              final remark = r['remark']?.toString() ?? '';
              final iconStr = r['icon'] ?? (itemName == '佛號' ? '📿' : '👣');
              
              final timeStr = r['time']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.bgWarm,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (timeStr.isNotEmpty)
                            Text(
                              timeStr,
                              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            '$iconStr $itemName：$count',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 2),
                          if (remark.isNotEmpty)
                            Text(
                              remark,
                              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                            ),
                        ],
                      ),
                    ),
                    
                    InkWell(
                      onTap: () => _showEditCloudDialog(
                          id, itemName, count.toString(), remark, iconStr),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '修改',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

      Widget _buildYearStats() {
    // 🔥 1. 把當月紀錄裡有出現的圖示，強制加進 yearItems 裡
    List<dynamic> displayItems = List.from(_yearItems);
    Set<String> existingNames = displayItems.map((e) => e['name'].toString()).toSet();

    _cloudDailyRecords.forEach((day, records) {
      for (var r in (records as List)) {
        final name = r['item']?.toString() ?? '';
        final icon = r['icon']?.toString() ?? '📿';
        if (name.isNotEmpty && !existingNames.contains(name)) {
          displayItems.add({
            'name': name,
            'icon': icon,
            'sortOrder': 99, // 預設排序
          });
          existingNames.add(name);
        }
      }
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ... 上方標題與按鈕保持不變 ...
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('📊 年度統計', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.chevron_left, size: 20), onPressed: () { setState(() => _selectedYear--); _loadYearStats(); }),
                      Text('$_selectedYear 年', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: () { setState(() => _selectedYear++); _loadYearStats(); }),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _exportToPdf,
                    icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.red),
                    label: const Text('匯出 PDF', style: TextStyle(color: Colors.red, fontSize: 13)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _exportToCsv,
                    icon: const Icon(Icons.table_view, size: 16, color: Colors.green),
                    label: const Text('匯出 CSV', style: TextStyle(color: Colors.green, fontSize: 13)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade50, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isYearLoading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (displayItems.isEmpty) 
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('無統計資料', style: TextStyle(color: Colors.grey))))
          else
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  horizontalMargin: 12,
                  headingRowColor: MaterialStateProperty.all(AppColors.primaryLight),
                  border: TableBorder.all(color: AppColors.borderLight),
                  columns: [
                    const DataColumn(
                      label: Text('品項', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...List.generate(12, (index) => DataColumn(
                      label: Text('${index + 1}月', style: const TextStyle(fontWeight: FontWeight.bold)),
                    )),
                    const DataColumn(
                      label: Text('總計', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.red)),
                    ),
                  ],
                  rows: [
                    ...displayItems.map((item) {
                      final itemName = item['name'] ?? '';
                      final itemIcon = item['icon'] ?? '📿';
                      int total = 0;
                      
                      for (int m = 1; m <= 12; m++) {
                        total += _getAmount(itemName, m);
                      }

                      return DataRow(
                        cells: [
                          // 🔥 第一欄：圖示 + 名稱
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(itemIcon, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  itemName, 
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          // 月份資料
                          ...List.generate(12, (index) {
                            final month = index + 1;
                            final amount = _getAmount(itemName, month);
                            return DataCell(
                              Text(
                                amount > 0 ? amount.toString() : '-',
                                style: TextStyle(color: amount > 0 ? AppColors.red : Colors.grey),
                              ),
                            );
                          }),
                          // 總計
                          DataCell(
                            Text(
                              total > 0 ? total.toString() : '-',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.red),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ), // 🔥 這個逗號很重要
        ],
      ),
    );
  }

  Future<void> _exportToCsv() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⏳ 正在產生 CSV 檔案...'), duration: Duration(seconds: 1)),
    );

    try {
      final List<List<dynamic>> rows = [];
      rows.add(['品項', ...List.generate(12, (i) => '${i + 1}月'), '總計']);

      for (var item in _yearItems) {
        final itemName = item['name'] ?? '';
        final itemIcon = item['icon'] ?? '📿';
        int total = 0;
        final row = <dynamic>['$itemIcon $itemName'];
        
        for (int m = 1; m <= 12; m++) {
          final amount = _getAmount(itemName, m);
          total += amount;
          row.add(amount > 0 ? amount : 0);
        }
        row.add(total);
        rows.add(row);
      }

      String csvData = '\uFEFF${const CsvEncoder().convert(rows)}';

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/念佛統計_$_selectedYear.csv';
      final file = File(path);
      await file.writeAsString(csvData);

      final result = await Share.shareXFiles(
        [XFile(path, mimeType: 'text/csv')],
        text: '這是 $_selectedYear 年的功課統計表 (CSV)',
        subject: '念佛統計表',
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('❌ 匯出失敗'),
          content: Text('發生錯誤：\n$e\n\n請確認手機有足夠空間。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('關閉')),
          ],
        ),
      );
    }
  }

  Future<void> _exportToPdf() async {
    try {
      final pdf = pw.Document();
      final fontData = await rootBundle.load('assets/fonts/NotoSansTC-Regular.ttf');
      final ttf = pw.Font.ttf(fontData);

      final headers = ['品項', ...List.generate(12, (i) => '${i + 1}月'), '總計'];
      final data = <List<String>>[];
      
      for (var item in _yearItems) {
        final itemName = item['name'] ?? '';
        final itemIcon = item['icon'] ?? '📿';
        int total = 0;
        final row = <String>['$itemIcon $itemName'];
        
        for (int m = 1; m <= 12; m++) {
          final amount = _getAmount(itemName, m);
          total += amount;
          row.add(amount > 0 ? amount.toString() : '-');
        }
        row.add(total.toString());
        data.add(row);
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('念佛計步 App - $_selectedYear 年度統計表', 
                  style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                pw.TableHelper.fromTextArray(
                  headers: headers,
                  data: data,
                  headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.brown300),
                  cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
                  cellAlignment: pw.Alignment.center,
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: '念佛統計_$_selectedYear.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ PDF 匯出失敗: $e')),
      );
    }
  }

      void _showEditCloudDialog(String id, String itemName, String oldCount,
      String oldRemark, [String icon = '📿']) {
    final countCtrl = TextEditingController(text: oldCount);
    final remarkCtrl = TextEditingController(text: oldRemark);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.edit, color: Color(0xFF5A3A7A), size: 24),
            const SizedBox(width: 8),
            Text('修改 $itemName', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: countCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '數量', 
                border: OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarkCtrl,
              decoration: const InputDecoration(
                labelText: '備註', 
                border: OutlineInputBorder()
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newCount = int.tryParse(countCtrl.text) ?? 0;
              final newRemark = remarkCtrl.text.trim();

              if (ctx.mounted) Navigator.pop(ctx); // 先關閉輸入框

              // 呼叫 API 修改
              final ok = await ApiService.instance.updateCloudRecord(
                id,
                newCount,
                newRemark,
                itemName: itemName,
                icon: icon,
                groupCode: context.read<AuthProvider>().state.groupCode, // 👈 加上這行
              );

              if (mounted) {
                if (ok) {
                  // 🔥 重新載入日曆與年度統計
                  _loadData();
                  _loadYearStats();

                  // 🔥 彈出修改成功的明細彈窗
                  showDialog(
                    context: context,
                    builder: (successCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 28),
                          SizedBox(width: 8),
                          Text('修改成功', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📿 品項：$icon $itemName', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          // 顯示數量變化
                          if (oldCount != newCount.toString())
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text('🔢 數量：$oldCount 遍 ➔ $newCount 遍', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text('🔢 數量：維持 $newCount 遍', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                            ),
                          
                          // 顯示備註變化
                          if (oldRemark != newRemark)
                            Text('📝 備註：${oldRemark.isEmpty ? "無" : oldRemark} ➔ ${newRemark.isEmpty ? "無" : newRemark}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(successCtx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A3A7A),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('我知道了'),
                        ),
                      ],
                    ),
                  );
                } else {
                  // 如果真的連線失敗
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ 修改失敗，請確認網路連線'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A3A7A),
              foregroundColor: Colors.white,
            ),
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }
}