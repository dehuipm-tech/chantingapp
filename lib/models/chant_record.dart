class ChantRecord {
  final String date;
  final int chantingCount;
  final int steps;
  final int stepsPerChant;
  bool checkedChant;
  bool checkedSteps;
  int editChant;
  int editSteps;
  bool synced;

  ChantRecord({
    required this.date,
    required this.chantingCount,
    required this.steps,
    this.stepsPerChant = 1,
    this.checkedChant = true,
    this.checkedSteps = true,
    int? editChant,
    int? editSteps,
    this.synced = false,
  })  : editChant = editChant ?? chantingCount,
        editSteps = editSteps ?? steps;

  Map<String, dynamic> toJson() => {
    'date': date,
    'chantingCount': chantingCount,
    'steps': steps,
    'stepsPerChant': stepsPerChant,
    'checkedChant': checkedChant,
    'checkedSteps': checkedSteps,
    'editChant': editChant,
    'editSteps': editSteps,
    'synced': synced,
  };

  factory ChantRecord.fromJson(Map<String, dynamic> json) => ChantRecord(
    date: json['date'] ?? '',
    chantingCount: json['chantingCount'] ?? 0,
    steps: json['steps'] ?? 0,
    stepsPerChant: json['stepsPerChant'] ?? 1,
    checkedChant: json['checkedChant'] ?? true,
    checkedSteps: json['checkedSteps'] ?? true,
    editChant: json['editChant'],
    editSteps: json['editSteps'],
    synced: json['synced'] ?? false,
  );
}