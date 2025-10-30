// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:home_habit_builder/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static Future<void> addNotification({
    required String title,
    required String body,
  }) async {
    final notifications = await getNotifications();
    final newNotification = {
      'title': title,
      'body': body,
      'time': DateTime.now().toIso8601String(),
    };
    notifications.add(newNotification);
    await _saveNotifications(notifications);
  }

  static Future<void> _saveNotifications(
      List<Map<String, dynamic>> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(notifications);
    await prefs.setString('notifications', jsonString);
  }

  // =============================================================
  // 🚀 1. Initialize notification system
  // =============================================================
  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Notification tapped: ${response.payload}');
      },
    );

    await _requestPermissions();
  }

  // -------------------------------------------------------------
  // Request OS notification permissions
  // -------------------------------------------------------------
  static Future<void> _requestPermissions() async {
    final androidImpl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      try {
        final granted = await androidImpl.requestNotificationsPermission();
        debugPrint('Android notification permission: $granted');
      } catch (e) {
        debugPrint('Error requesting Android permission: $e');
      }
    }

    final iosImpl = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      try {
        await iosImpl.requestPermissions(alert: true, badge: true, sound: true);
      } catch (e) {
        debugPrint('Error requesting iOS permission: $e');
      }
    }
  }

  // =============================================================
  // ✅ 2. Basic show notification
  // =============================================================
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'general_notification',
      'Thông báo chung',
      channelDescription: 'Các thông báo từ ứng dụng thói quen',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  // =============================================================
  // ⚡ 3. Immediate notification for incomplete habits
  // =============================================================
  static Future<void> showImmediate(List<String> habits) async {
    if (habits.isEmpty) return;

    const androidDetails = AndroidNotificationDetails(
      'habit_reminder',
      'Nhắc nhở thói quen',
      channelDescription: 'Thông báo nhắc nhở hoàn thành thói quen',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      0,
      '⏰ Còn ${habits.length} thói quen chưa hoàn thành',
      habits.take(3).join(', ') + (habits.length > 3 ? '...' : ''),
      details,
      payload: 'habit_reminder_now',
    );
  }

  static Future<void> showIncompleteHabitsNotification(List<String> habits) =>
      showImmediate(habits);

  // =============================================================
  // 🕒 4. Schedule one-time (timezone-aware)
  // =============================================================
  static Future<void> scheduleIncompleteHabitsNotification(
    List<String> habits, {
    required DateTime scheduledAt,
    int id = 300,
  }) async {
    if (habits.isEmpty) return;

    final tzDate = tz.TZDateTime.from(scheduledAt, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'habit_reminder_scheduled',
      'Nhắc nhở thói quen (Lên lịch)',
      channelDescription: 'Thông báo nhắc nhở hoàn thành thói quen đã lên lịch',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.zonedSchedule(
      id,
      '⏰ Còn ${habits.length} thói quen chưa hoàn thành',
      habits.take(3).join(', ') + (habits.length > 3 ? '...' : ''),
      tzDate,
      details,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'habit_reminder_scheduled',
    );
  }

  // =============================================================
  // 🔥 5. Streak Warning / Milestone Notifications
  // =============================================================
  static Future<void> showStreakWarning({
    required int consecutiveDays,
    required int hoursRemaining,
    required bool canUseFreeze,
    required int freezeRemaining,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'streak_warning',
      'Cảnh báo Streak',
      channelDescription: 'Thông báo khi streak sắp mất',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFFFF6B00),
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
        presentAlert: true, presentBadge: true, presentSound: true);
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    String message =
        'Còn $hoursRemaining giờ! Hoàn thành thói quen để giữ streak.';
    message += canUseFreeze
        ? ' (Còn $freezeRemaining lượt khôi phục)'
        : ' ⚠️ Hết lượt khôi phục!';

    await _notifications.show(
      1,
      '🔥 Streak $consecutiveDays ngày sắp mất!',
      message,
      details,
      payload: 'streak_warning',
    );
  }

  static Future<void> showStreakMilestone(int consecutiveDays) async {
    if (![3, 7, 14, 30, 50, 100, 200, 365].contains(consecutiveDays)) return;

    String emoji = '🔥';
    String title = 'Chúc mừng!';
    if (consecutiveDays >= 365) {
      emoji = '🏆';
      title = 'HUYỀN THOẠI!';
    } else if (consecutiveDays >= 100) {
      emoji = '💎';
      title = 'ĐỈNH CAO!';
    } else if (consecutiveDays >= 30) {
      emoji = '⭐';
      title = 'XUẤT SẮC!';
    }

    const androidDetails = AndroidNotificationDetails(
      'streak_milestone',
      'Cột mốc Streak',
      channelDescription: 'Thông báo khi đạt cột mốc streak',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      color: Color(0xFFFFD700),
    );

    const iosDetails = DarwinNotificationDetails(
        presentAlert: true, presentBadge: true, presentSound: true);
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      2,
      '$emoji $title',
      'Bạn đã đạt $consecutiveDays ngày liên tiếp! Tuyệt vời!',
      details,
      payload: 'streak_milestone',
    );
  }

  // =============================================================
  // ⏰ 6. Schedule Morning + Night Notifications
  // =============================================================
  static Future<void> scheduleMorningHabitReminder(
      List<String> incompleteHabits) async {
    await _notifications.cancel(200);
    if (incompleteHabits.isEmpty) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 8, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'habit_morning',
      'Nhắc thói quen buổi sáng',
      channelDescription: 'Thông báo các thói quen chưa hoàn thành (8h sáng)',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.zonedSchedule(
      200,
      '🌞 Thói quen hôm nay',
      'Bạn còn ${incompleteHabits.length} thói quen chưa hoàn thành!',
      scheduledDate,
      details,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'habit_morning',
    );
  }

  static Future<void> scheduleNightStreakWarning({
    required List<String> incompleteHabits,
    required int consecutiveDays,
    bool canUseFreeze = true,
    int freezeRemaining = 0,
  }) async {
    await _notifications.cancel(201);
    if (incompleteHabits.isEmpty) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 21, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'streak_night',
      'Cảnh báo Streak buổi tối',
      channelDescription: 'Cảnh báo nếu còn thói quen chưa hoàn thành (21h)',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFFF6B00),
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    String message =
        'Còn ${incompleteHabits.length} thói quen chưa làm hôm nay.';
    message += canUseFreeze
        ? ' (Còn $freezeRemaining lượt khôi phục)'
        : ' ⚠️ Hết lượt khôi phục!';

    await _notifications.zonedSchedule(
      201,
      '🔥 Streak $consecutiveDays ngày có nguy cơ mất!',
      message,
      scheduledDate,
      details,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'streak_night',
    );
  }

  static Future<void> rescheduleDailyNotifications({
    required List<String> incompleteHabits,
    required int consecutiveDays,
    bool canUseFreeze = true,
    int freezeRemaining = 0,
  }) async {
    await cancel(200);
    await cancel(201);
    await scheduleMorningHabitReminder(incompleteHabits);
    await scheduleNightStreakWarning(
      incompleteHabits: incompleteHabits,
      consecutiveDays: consecutiveDays,
      canUseFreeze: canUseFreeze,
      freezeRemaining: freezeRemaining,
    );
  }

  // =============================================================
  // ⏰ 6.5 Schedule daily streak check (21:00)
  // =============================================================
  static Future<void> scheduleDailyStreakCheck() async {
    await _notifications.cancel(101);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 21, 0, 0);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'streak_daily_check',
      'Kiểm tra Streak hàng ngày',
      channelDescription: 'Nhắc kiểm tra streak lúc 21:00',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.zonedSchedule(
      101,
      '🔥 Kiểm tra Streak!',
      'Hãy kiểm tra thói quen hôm nay để bảo vệ streak của bạn.',
      scheduledDate,
      details,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'streak_daily_check',
    );
  }

  // =============================================================
  // 🧠 7. Check & notify procrastination
  // =============================================================
  static Future<void> checkAndNotifyProcrastination(
      Map<String, dynamic> userStats) async {
    final alerts = await ApiService.detectProcrastination();
    if (alerts.isNotEmpty) {
      await showNotification(
        title: "Nhắc nhở duy trì thói quen 🌱",
        body:
            "Dường như bạn đang lơ là một chút... Hãy quay lại hoàn thành thói quen hôm nay nhé!",
      );
    }
  }

  // =============================================================
  // 🧹 8. Cancel / Get / Clear Notifications
  // =============================================================
  static Future<void> cancelAll() async => _notifications.cancelAll();
  static Future<void> cancel(int id) async => _notifications.cancel(id);

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();
    debugPrint('🔔 Có ${pending.length} thông báo đang được lên lịch');
    return pending
        .map((p) => {
              'id': p.id,
              'title': p.title,
              'body': p.body,
              'payload': p.payload,
            })
        .toList();
  }

  static Future<void> clearNotifications() async {
    await _notifications.cancelAll();
    debugPrint('🧹 Đã xóa tất cả thông báo');
  }
}
