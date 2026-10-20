class DailyLog {
  final String id;
  final String date;
  final String time;
  final String type;
  final String item;
  final String icon;      // 🔥 新增：圖示欄位
  int count;
  String remark;
  bool isSynced;

  DailyLog({
    required this.id,
    required this.date,
    required this.time,
    required this.type,
    required this.item,
    this.icon = '📿',     // 🔥 預設為佛號圖示
    this.count = 0,
    this.remark = '',
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date, 'time': time,
    'type': type, 'item': item, 'icon': icon, // 🔥 寫入 JSON
    'count': count, 'remark': remark,
    'isSynced': isSynced,
  };

  factory DailyLog.fromJson(Map<String, dynamic> json) => DailyLog(
    id: json['id'] ?? '',
    date: json['date'] ?? '',
    time: json['time'] ?? '',
    type: json['type'] ?? '',
    item: json['item'] ?? '',
    icon: json['icon'] ?? '📿', // 🔥 讀取 JSON
    count: json['count'] ?? 0,
    remark: json['remark'] ?? '',
    isSynced: json['isSynced'] ?? false,
  );
}