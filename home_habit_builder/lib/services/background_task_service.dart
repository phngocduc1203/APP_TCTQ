// lib/services/background_task_service.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'api_service.dart';
import 'notification_service.dart';

class BackgroundTaskService {
  static Timer? _timer;
  static const _lastCheckKey = 'last_procrastination_check';

  /// Khởi động background task
  static Future<void> initialize() async {
    debugPrint('🚀 Initializing background task...');

    // ✅ Chỉ check 1 lần khi khởi động
    await _checkIfShouldNotify();

    // ✅ Schedule: Check mỗi ngày 1 lần
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(days: 1),
      (timer) => _checkIfShouldNotify(),
    );
  }

  /// Dừng background task
  static void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  /// Check xem có nên gửi notification không
  static Future<void> _checkIfShouldNotify() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toString().substring(0, 10);
      final lastSent = prefs.getString('last_notification_date');

      // ✅ Nếu hôm nay đã gửi rồi → skip
      if (lastSent == today) {
        debugPrint('⏭️ Hôm nay đã gửi notification rồi');
        return;
      }

      final now = DateTime.now();

      // ✅ Chỉ gửi vào 21:00 (đổi thành 9 để test)
      if (now.hour == 21) {
        // Đổi thành 9 để test ngay
        await _checkProcrastination();
        await prefs.setString('last_notification_date', today);
      } else {
        debugPrint(
            '⏰ Chưa đến giờ gửi notification (${now.hour}:${now.minute})');
      }
    } catch (e) {
      debugPrint('❌ Check notify error: $e');
    }
  }

  /// Check procrastination alerts
  static Future<void> _checkProcrastination() async {
    try {
      debugPrint('🔍 Bắt đầu check procrastination...');

      // Xóa cache cũ
      await _clearOldNotificationCache();

      // Kiểm tra token
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ No token, skipping check');
        return;
      }

      // Load alerts từ server
      final alerts = await ApiService.getProcrastinationAlerts();

      if (alerts.isEmpty) {
        debugPrint('✅ Không có alerts');
        return;
      }

      debugPrint('🔔 Gửi ${alerts.length} notifications');
      await _sendNotifications(alerts);
    } catch (e) {
      debugPrint('❌ Check procrastination error: $e');
    }
  }

  /// Gửi notifications (chống spam)
  static Future<void> _sendNotifications(List<dynamic> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().substring(0, 10);
    final sentToday = prefs.getStringList('sent_notifications_$today') ?? [];

    int sentCount = 0;

    for (final alert in alerts) {
      final alertId = alert['id'].toString();

      // ✅ Kiểm tra đã gửi chưa
      if (sentToday.contains(alertId)) {
        debugPrint('⏭️ Alert $alertId đã gửi rồi, skip');
        continue;
      }

      final habitName = alert['habit']?['ten_thoi_quen'] ?? 'Thói quen';
      final message = alert['message'] ?? 'Bạn có thông báo trì hoãn';
      final severity = alert['severity'] ?? 'info';

      String emoji = '📌';
      if (severity == 'critical') {
        emoji = '🔥';
      } else if (severity == 'warning') {
        emoji = '⚠️';
      } else if (severity == 'info') {
        emoji = '💡';
      }

      await NotificationService.showNotification(
        title: '$emoji $habitName',
        body: message,
      );

      // ✅ Lưu lại đã gửi
      sentToday.add(alertId);
      await prefs.setStringList('sent_notifications_$today', sentToday);

      sentCount++;
      debugPrint('✅ Đã gửi notification $sentCount/${alerts.length}');

      // Delay giữa các notification
      await Future.delayed(const Duration(milliseconds: 500));
    }

    debugPrint('✅ Hoàn thành gửi $sentCount notifications');
  }

  /// Lưu thời gian check cuối

  /// Lấy thời gian check cuối
  static Future<DateTime?> getLastCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_lastCheckKey);
    return str != null ? DateTime.tryParse(str) : null;
  }

  /// Xóa cache notification ngày cũ
  static Future<void> _clearOldNotificationCache() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().substring(0, 10);
    final allKeys = prefs.getKeys();

    for (final key in allKeys) {
      if (key.startsWith('sent_notifications_') && !key.endsWith(today)) {
        await prefs.remove(key);
        debugPrint('🧹 Cleaned old cache: $key');
      }
    }
  }

  /// Test: Trigger check thủ công (để debug)
  static Future<void> manualCheck() async {
    debugPrint('🧪 Manual check triggered');
    await _checkProcrastination();
  }

  /// Test: Reset cache để test lại
  static Future<void> resetNotificationCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_notification_date');
    final today = DateTime.now().toString().substring(0, 10);
    await prefs.remove('sent_notifications_$today');
    debugPrint('🔄 Reset cache thành công');
  }
}
