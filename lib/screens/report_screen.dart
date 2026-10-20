import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';


class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = false;
  int _selectedYear = DateTime.now().year;

  Map<String, dynamic> _records = {};
  List<dynamic> _items = [];

  // 🔥 紀錄上次載入的會員編號，避免重複觸發
  String? _lastLoadedMemberNo;

  @override
  Widget build(BuildContext context) {
    // 🔥 使用 Consumer 監聽登入狀態
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // 如果已經登入，且和上次載入的會員不同，就自動載入
        if (auth.loggedIn && auth.state.memberNo != _lastLoadedMemberNo) {
          _lastLoadedMemberNo = auth.state.memberNo;
          // 使用 addPostFrameCallback 避免在 build 期間觸發 setState
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
        }

        return Scaffold(
          backgroundColor: AppColors.bgWarm,
          appBar: AppBar(
            title: const Text('📊 年度統計'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: !auth.loggedIn
              ? const Center(child: Text('請先登入以查看報告', style: TextStyle(color: Colors.grey)))
              : Column(
                  children: [
                    // 🔥 年份切換器
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                            onPressed: () => _changeYear(-1),
                          ),
                          Text(
                            '$_selectedYear 年',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                            onPressed: () => _changeYear(1),
                          ),
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _items.isEmpty
                              ? const Center(child: Text('📭 尚無統計資料 (或請確認 API 連線)', style: TextStyle(color: Colors.grey)))
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.borderSoft),
                                    ),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        headingRowColor: MaterialStateProperty.all(AppColors.primaryLight),
                                        border: TableBorder.all(color: AppColors.borderLight),
                                        columns: [
                                          const DataColumn(label: Text('月份', style: TextStyle(fontWeight: FontWeight.bold))),
                                          ..._items.map((item) => DataColumn(
                                            label: Text('${item['icon'] ?? '📿'} ${item['name'] ?? '佛號'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          )).toList(),
                                        ],
                                        rows: [
                                          // 1~12 月的資料
                                          ...List.generate(12, (index) {
                                            final month = index + 1;
                                            return DataRow(
                                              cells: [
                                                DataCell(Text('$month月')),
                                                ..._items.map((item) {
                                                  final itemName = item['name'] ?? '佛號';
                                                  final amount = (_records[itemName] != null && _records[itemName]['$month'] != null)
                                                      ? _records[itemName]['$month']
                                                      : 0;
                                                  return DataCell(
                                                    Text(
                                                      amount > 0 ? amount.toString() : '-',
                                                      style: TextStyle(color: amount > 0 ? AppColors.red : Colors.grey),
                                                    ),
                                                  );
                                                }).toList(),
                                              ],
                                            );
                                          }),
                                          // 總計列
                                          DataRow(
                                            color: MaterialStateProperty.all(const Color(0xFFEFEBE9)),
                                            cells: [
                                              const DataCell(Text('📊 總計', style: TextStyle(fontWeight: FontWeight.bold))),
                                              ..._items.map((item) {
                                                final itemName = item['name'] ?? '佛號';
                                                int total = 0;
                                                for (int m = 1; m <= 12; m++) {
                                                  final amount = (_records[itemName] != null && _records[itemName]['$m'] != null)
                                                      ? _records[itemName]['$m']
                                                      : 0;
                                                  total += (amount as num).toInt();
                                                }
                                                return DataCell(
                                                  Text(
                                                    total.toString(),
                                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.red),
                                                  ),
                                                );
                                              }).toList(),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    
    if (!auth.loggedIn) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = await ApiService.instance.fetchYearStats(auth.state.memberNo, _selectedYear);

      if (mounted) {
        setState(() {
          if (data != null) {
            _records = data['records'] ?? {};
            _items = data['items'] ?? [];
          } else {
            _records = {};
            _items = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ 年度統計載入失敗: $e');
      if (mounted) {
        setState(() {
          _records = {};
          _items = [];
          _isLoading = false;
        });
      }
    }
  }

  void _changeYear(int delta) {
    setState(() {
      _selectedYear += delta;
      _lastLoadedMemberNo = null; // 重置，強制重新載入
    });
    _loadData();
  }
}