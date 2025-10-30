// lib/models/procrastination_pattern.dart

class ProcrastinationPattern {
  final int id;
  final int userId;
  final int habitId;
  final int totalDelays;
  final int maxDelayDays;
  final double avgDelayDays;
  final int completionRate;
  final String patternType;
  final String? analysisMessage;

  ProcrastinationPattern({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.totalDelays,
    required this.maxDelayDays,
    required this.avgDelayDays,
    required this.completionRate,
    required this.patternType,
    this.analysisMessage,
  });

  factory ProcrastinationPattern.fromJson(Map<String, dynamic> json) {
    return ProcrastinationPattern(
      id: json['id'],
      userId: json['user_id'],
      habitId: json['habit_id'],
      totalDelays: json['total_delays'],
      maxDelayDays: json['max_delay_days'],
      avgDelayDays: (json['avg_delay_days'] ?? 0).toDouble(),
      completionRate: json['completion_rate'],
      patternType: json['pattern_type'],
      analysisMessage: json['analysis_message'],
    );
  }

  bool get isDanger => patternType == 'danger';
  bool get isWarning => patternType == 'warning';
  bool get isGood => patternType == 'good';
}
