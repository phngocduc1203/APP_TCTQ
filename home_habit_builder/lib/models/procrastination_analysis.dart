// lib/models/procrastination_analysis.dart

class ProcrastinationAnalysis {
  final String overallStatus;
  final String message;
  final int totalHabits;
  final int dangerHabits;
  final int warningHabits;
  final double avgDelayDays;

  ProcrastinationAnalysis({
    required this.overallStatus,
    required this.message,
    required this.totalHabits,
    required this.dangerHabits,
    required this.warningHabits,
    required this.avgDelayDays,
  });

  factory ProcrastinationAnalysis.fromJson(Map<String, dynamic> json) {
    return ProcrastinationAnalysis(
      overallStatus: json['overall_status'],
      message: json['message'],
      totalHabits: json['total_habits'],
      dangerHabits: json['danger_habits'],
      warningHabits: json['warning_habits'],
      avgDelayDays: (json['avg_delay_days'] ?? 0).toDouble(),
    );
  }

  bool get isDanger => overallStatus == 'danger';
  bool get isWarning => overallStatus == 'warning';
  bool get isGood => overallStatus == 'good';

  String get statusIcon {
    switch (overallStatus) {
      case 'danger':
        return '🔴';
      case 'warning':
        return '🟡';
      case 'good':
        return '🟢';
      default:
        return '⚪';
    }
  }
}
