class HealthRecord {
  final String date;
  final int heartRate;
  final int bpSys;
  final int bpDia;
  final int calories;

  HealthRecord({
    required this.date,
    this.heartRate = 0,
    this.bpSys = 0,
    this.bpDia = 0,
    this.calories = 0,
  });

  String get bpText => (bpSys > 0 && bpDia > 0) ? '$bpSys/$bpDia' : '--/--';

  Map<String, dynamic> toJson() => {
    'date': date,
    'heartRate': heartRate,
    'bpSys': bpSys,
    'bpDia': bpDia,
    'calories': calories,
  };

  factory HealthRecord.fromJson(String date, Map<String, dynamic> json) {
    return HealthRecord(
      date: date,
      heartRate: json['heartRate'] ?? 0,
      bpSys: json['bpSys'] ?? 0,
      bpDia: json['bpDia'] ?? 0,
      calories: json['calories'] ?? 0,
    );
  }
}