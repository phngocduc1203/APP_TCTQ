class ProcrastinationAlert {
  final int id;
  final int userId;
  final int habitId;
  final int daysDelayed;
  final String severity;
  final String message;
  final bool isRead;
  final DateTime sentAt;
  final String? habitName;

  ProcrastinationAlert({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.daysDelayed,
    required this.severity,
    required this.message,
    required this.isRead,
    required this.sentAt,
    this.habitName,
  });

  factory ProcrastinationAlert.fromJson(Map<String, dynamic> json) {
    return ProcrastinationAlert(
      id: json['id'],
      userId: json['user_id'],
      habitId: json['habit_id'],
      daysDelayed: json['days_delayed'],
      severity: json['severity'],
      message: json['message'],
      isRead: json['is_read'] ?? false,
      sentAt: DateTime.parse(json['sent_at']),
      habitName: json['habit']?['ten_thoi_quen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'habit_id': habitId,
      'days_delayed': daysDelayed,
      'severity': severity,
      'message': message,
      'is_read': isRead,
      'sent_at': sentAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isCritical => severity == 'critical';
  bool get isWarning => severity == 'warning';
  bool get isInfo => severity == 'info';

  String get severityIcon {
    switch (severity) {
      case 'critical':
        return '🔥';
      case 'warning':
        return '⚠️';
      case 'info':
        return '💡';
      default:
        return '📌';
    }
  }
}
