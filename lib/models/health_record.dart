class HealthRecord {
  final String date;
  final int heartRate;
  final int bpSys;
  final int bpDia;
  final int calories;
  final String remark; // 🔥 就是這裡！確保有remark這個欄位

  HealthRecord({
    required this.date,
    this.heartRate = 0,
    this.bpSys = 0,
    this.bpDia = 0,
    this.calories = 0,
    this.remark = '', // 🔥 確保建構子有接收 remark
  });

  String get bpText => (bpSys > 0 && bpDia > 0) ? '$bpSys/$bpDia' : '--/--';

  Map<String, dynamic> toJson() => {
    'date': date,
    'heartRate': heartRate,
    'bpSys': bpSys,
    'bpDia': bpDia,
    'calories': calories,
    'remark': remark, // 🔥 確保存檔時有寫入 remark
  };

  factory HealthRecord.fromJson(String date, Map<String, dynamic> json) {
    return HealthRecord(
      date: date,
      heartRate: json['heartRate'] ?? 0,
      bpSys: json['bpSys'] ?? 0,
      bpDia: json['bpDia'] ?? 0,
      calories: json['calories'] ?? 0,
      remark: json['remark'] ?? '', // 🔥 確保讀取時有防呆，避免舊資料崩潰
    );
  }
}
