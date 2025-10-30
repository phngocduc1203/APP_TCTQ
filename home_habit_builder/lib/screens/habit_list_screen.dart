import 'package:flutter/material.dart';
import 'package:home_habit_builder/services/plant_service.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'edit_habit_screen.dart';
import 'edit_user_screen.dart';
import '../services/notification_service.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
//import '../services/plant_service.dart';
import '../widgets/xp_gain_animation.dart';
import '../services/plant_update_service.dart';

typedef HabitsChangedCallback = void Function(List<dynamic> habits);

class HabitListScreen extends StatefulWidget {
  final HabitsChangedCallback? onHabitsChanged;
  const HabitListScreen({super.key, this.onHabitsChanged});

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  Timer? _midnightResetTimer;
  Timer? _notificationTimer;
  Timer? _streakCheckTimer;

  List<dynamic> allHabits = [];
  List<dynamic> filteredHabits = [];
  bool isLoading = true;
  String error = '';
  int selectedDay = 3;
  bool showAllHistory = false;
  int selectedTab = 0;
  final List<String> tabs = ['Tất cả', 'Thói quen', 'Nhiệm vụ'];
  String userName = '';
  String userAvatar = '';
  String? userEmail;

  // 🔥 STREAK STATE
  int consecutiveDays = 0;
  bool hasStreakToday = false;
  int streakFreezeUsed = 0;
  bool canUseFreeze = true;

  @override
  void initState() {
    super.initState();

    // Lấy danh sách thói quen và streak
    fetchHabits();
    fetchStreakInfo();

    // Lên lịch thông báo
    scheduleNoonNotification();
    scheduleMidnightReset();
    scheduleStreakCheck();
    NotificationService.scheduleDailyStreakCheck();

    // Lấy thông tin user
    ApiService.getUserInfo().then((user) {
      if (user != null && mounted) {
        setState(() {
          userName = user['name'] ?? userName;
          userEmail = user['email'] ?? userEmail;
          userAvatar = ApiService.fixUrl(user['avatar']);
        });

        // Chỉ sync XP nếu token đã có
        PlantService.getToken().then((token) {
          if (token != null && token.isNotEmpty) {
            _syncPlantXp();
          } else {
            print('⚠️ Token chưa có, sẽ chờ user login...');
          }
        });
      }
    });
  }

// =======================
// Sync XP cây
  Future<void> _syncPlantXp() async {
    final token = await PlantService.getToken();
    print('🔄 Loading plant data...');
    print('🔑 Token before XP sync: $token');

    if (token == null || token.isEmpty) {
      print('⚠️ Không thể sync XP vì token chưa có');
      return;
    }

    final xp = await PlantService.getXpFromServer();
    final localXp = await PlantService.getLocalXp();

    print('📥 XP from server: $xp');
    print('💾 XP from local: $localXp');

    final usedXp = xp > 0 ? xp : localXp;
    print('✅ Using XP: $usedXp');

    if (mounted) {
      setState(() {
        // cập nhật state hiển thị cây/XP ở đây
      });
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _midnightResetTimer?.cancel();
    _streakCheckTimer?.cancel();
    super.dispose();
  }

  // 🔔 LÊN LỊCH KIỂM TRA STREAK
  void scheduleStreakCheck() {
    _streakCheckTimer = Timer.periodic(const Duration(hours: 2), (timer) {
      checkStreakWarning();
    });
    Future.delayed(const Duration(seconds: 5), checkStreakWarning);
  }

  // 🔔 KIỂM TRA VÀ THÔNG BÁO STREAK
  Future<void> checkStreakWarning() async {
    final warning = await ApiService.checkStreakWarning();
    if (warning == null) return;

    final shouldNotify = warning['should_notify'] ?? false;
    if (!shouldNotify) return;

    final consecutiveDays = warning['consecutive_days'] ?? 0;
    final hoursRemaining = warning['hours_remaining'] ?? 0;
    final canUseFreeze = warning['can_use_freeze'] ?? false;
    final freezeRemaining = warning['freeze_remaining'] ?? 0;

    if (hoursRemaining <= 6 && hoursRemaining > 0) {
      await NotificationService.showStreakWarning(
        consecutiveDays: consecutiveDays,
        hoursRemaining: hoursRemaining,
        canUseFreeze: canUseFreeze,
        freezeRemaining: freezeRemaining,
      );
    }
  }

  // 🔥 LẤY THÔNG TIN STREAK
  Future<void> fetchStreakInfo() async {
    final info = await ApiService.getStreakInfo();
    if (info != null && mounted) {
      setState(() {
        consecutiveDays = info['consecutive_days'] ?? 0;
        streakFreezeUsed = info['streak_freeze_used'] ?? 0;
        canUseFreeze = info['can_use_freeze'] ?? true;

        final lastDate = info['last_completed_date']?.toString();
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        hasStreakToday = lastDate == today;
      });
    }
  }

  void scheduleMidnightReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final midnight =
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 0, 0, 0);
    final delay = midnight.difference(now);
    _midnightResetTimer = Timer(delay, () async {
      await resetHabitsForNewDay();
      scheduleMidnightReset();
    });
  }

  Future<void> resetHabitsForNewDay() async {
    await fetchHabits();
    await fetchStreakInfo();
    if (mounted) setState(() {});
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'CN';
      case 2:
        return 'T2';
      case 3:
        return 'T3';
      case 4:
        return 'T4';
      case 5:
        return 'T5';
      case 6:
        return 'T6';
      case 7:
        return 'T7';
      default:
        return '';
    }
  }

  bool _isHabitApplicableForDate(Map<String, dynamic> habit, DateTime date) {
    final startDateStr = habit['start_date']?.toString();
    if (startDateStr != null && startDateStr.isNotEmpty) {
      try {
        final startDate = DateTime.parse(startDateStr);
        if (date.isBefore(
            DateTime(startDate.year, startDate.month, startDate.day))) {
          return false;
        }
      } catch (_) {}
    }

    final repeatType = habit['repeat_type']?.toString() ?? 'daily';
    final repeatData = habit['repeat_data']?.toString() ?? '';

    if (repeatType == 'daily') {
      return true;
    } else if (repeatType == 'weekly') {
      int dayIndex = date.weekday == 7 ? 1 : date.weekday + 1;
      final days = repeatData.split(',').map((e) => e.trim()).toList();
      return days.contains(dayIndex.toString());
    } else if (repeatType == 'monthly') {
      final days = repeatData.split(',').map((e) => e.trim()).toList();
      return days.contains(date.day.toString());
    }

    return false;
  }

  void _filterHabitsBySelectedDay() {
    if (showAllHistory) {
      setState(() {
        filteredHabits = List.from(allHabits);
      });
      return;
    }

    final selectedDate = _getSelectedDate();
    setState(() {
      filteredHabits = allHabits.where((habit) {
        return _isHabitApplicableForDate(habit, selectedDate);
      }).toList();
    });
  }

  DateTime _getSelectedDate() {
    final now = DateTime.now();
    return now.add(Duration(days: selectedDay - 3));
  }

  // 🔥 CẬP NHẬT HÀM completeHabit - THÊM STREAK + PLANT + XP
  Future<void> completeHabit(int id) async {
    // ✅ Bước 1: Gọi API complete habit từ backend
    final result = await ApiService.completeHabit(id);
    if (!mounted || result == null) return;

    // ❌ Nếu lỗi
    if (result['success'] == false) {
      final message = result['message'] ?? 'Không thể hoàn thành';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // ✅ Bước 2: Lấy dữ liệu plant từ response
    final plantData = result['plant'];
    if (plantData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hoàn thành thành công!')),
      );
      await fetchHabits();
      return;
    }

    // ✅ Bước 3: Parse dữ liệu
    final xpGained = plantData['xp_gained'] as int? ?? 0;
    final bonusXp = plantData['bonus_xp'] as int? ?? 0;
    //final totalXpGained = plantData['total_xp_gained'] as int? ?? 0;
    final currentXp = plantData['xp'] as int? ?? 0;
    final plantConsecutiveDays = plantData['consecutive_days'] as int? ?? 0;
    final dailyXp = plantData['daily_xp'] as int? ?? 0;
    final dailyLimit = plantData['daily_limit'] as int? ?? 50;
    final remainingDaily = dailyLimit - dailyXp;
    final isMaxed = currentXp >= 1200;

    // ✅ Bước 4: Lưu vào local storage
    final prefs = await SharedPreferences.getInstance();
    if (plantData['last_update'] != null) {
      await prefs.setString('plant_last_watered', plantData['last_update']);
    }
    await prefs.setInt('plant_consecutive_days', plantConsecutiveDays);
    await prefs.setInt('plant_xp', currentXp);

    PlantUpdateService().notifyPlantUpdated();

    // ✅ Bước 5: Cập nhật streak UI
    final streakResult = await ApiService.updateStreak();
    if (streakResult != null && mounted) {
      final oldStreak = consecutiveDays;
      final newStreak = streakResult['consecutive_days'] ?? consecutiveDays;
      setState(() {
        consecutiveDays = newStreak;
        hasStreakToday = true;
      });

      // Thông báo milestone
      if (newStreak > oldStreak &&
          [3, 7, 14, 30, 50, 100, 200, 365].contains(newStreak)) {
        await NotificationService.showStreakMilestone(newStreak);
      }
    }

    // ✅ Bước 6: Tạo message
    String message = '✅ Hoàn thành! +$xpGained XP';

    if (plantConsecutiveDays >= 3) {
      message += ' | 🔥 Streak: $plantConsecutiveDays ngày';
    }

    if (remainingDaily > 0) {
      message += ' (Còn $remainingDaily XP hôm nay)';
    } else {
      message += ' (Đạt giới hạn hôm nay)';
    }

    if (bonusXp > 0) {
      message += ' | 💎 Bonus: +$bonusXp XP!';
    }

    if (isMaxed) {
      message = '🎉 Cây đã đạt cấp độ tối đa!';
    }

    // ✅ Bước 7: Hiển thị thông báo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (dailyXp / dailyLimit).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'XP hôm nay: $dailyXp/$dailyLimit | Tổng: $currentXp/1200',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        backgroundColor: isMaxed ? Colors.purple : Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // ✅ Bước 8: Hiển thị animation XP
    _showXpAnimation(xpGained, bonusXp > 0 ? bonusXp : null);

    // ✅ Bước 9: Refresh habits
    await fetchHabits();
    await fetchStreakInfo();
  }

  // 🎬 HÀM HIỂN THỊ ANIMATION XP
  void _showXpAnimation(int xp, int? bonus) {
    final overlay = Overlay.of(context);
    //if (overlay == null) return;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.4,
        left: MediaQuery.of(context).size.width * 0.5 - 60,
        child: XpGainAnimation(xp: xp, bonus: bonus),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  int get maxStreak => consecutiveDays;

  void scheduleNoonNotification() {
    final now = DateTime.now();
    final noon = DateTime(now.year, now.month, now.day, 12, 0, 0);
    Duration delay = noon.isAfter(now)
        ? noon.difference(now)
        : noon.add(const Duration(days: 1)).difference(now);
    _notificationTimer = Timer(delay, checkAndNotifyIncompleteHabits);
  }

  void checkAndNotifyIncompleteHabits() async {
    final incomplete = allHabits
        .where((h) => !_isCompletedOnDate(h, DateTime.now()))
        .map((h) => h['ten_thoi_quen'] ?? '')
        .toList();
    await NotificationService.showIncompleteHabitsNotification(
        List<String>.from(incomplete));
    scheduleNoonNotification();
  }

  Future<void> fetchHabits() async {
    setState(() {
      isLoading = true;
      error = '';
    });
    final result = await ApiService.getHabits();
    setState(() {
      isLoading = false;
      if (result == null) {
        error = 'Không lấy được danh sách thói quen.';
      } else {
        allHabits = result;
        _filterHabitsBySelectedDay();
        if (widget.onHabitsChanged != null) {
          widget.onHabitsChanged!(allHabits);
        }
      }
    });
  }

  void deleteHabit(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa thói quen này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      isLoading = true;
    });
    final success = await ApiService.deleteHabit(id);
    await fetchHabits();
    setState(() {
      isLoading = false;
    });
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa thất bại!')),
      );
    }
  }

  int _getCompletedDaysForDate(Map<String, dynamic> habit, DateTime date) {
    final completedDates = habit['completed_dates'];

    if (completedDates is List && completedDates.isNotEmpty) {
      final startDateStr = habit['start_date']?.toString();
      if (startDateStr == null || startDateStr.isEmpty) return 0;

      try {
        final startDate = DateTime.parse(startDateStr);
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(date.year, date.month, date.day);

        int count = 0;
        for (var completedDateStr in completedDates) {
          try {
            final completedDate = DateTime.parse(completedDateStr.toString());
            final completed = DateTime(
                completedDate.year, completedDate.month, completedDate.day);

            if (!completed.isBefore(start) && completed.isBefore(end)) {
              count++;
            }
          } catch (_) {}
        }

        return count;
      } catch (_) {
        return 0;
      }
    }

    if (habit.containsKey('completed_days')) {
      final val = habit['completed_days'];
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
    }

    return 0;
  }

  int _getTargetDays(Map<String, dynamic> habit, DateTime upToDate) {
    final startDateStr = habit['start_date']?.toString();
    if (startDateStr == null || startDateStr.isEmpty) return 0;

    try {
      final startDate = DateTime.parse(startDateStr);
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(upToDate.year, upToDate.month, upToDate.day);

      if (habit['is_challenge'] == 1 || habit['is_challenge'] == true) {
        if (habit.containsKey('duration_days')) {
          final val = habit['duration_days'];
          if (val is int) return val;
          if (val is String) return int.tryParse(val) ?? 0;
        }
        return 0;
      }

      final repeatType = habit['repeat_type']?.toString() ?? 'daily';
      final repeatData = habit['repeat_data']?.toString() ?? '';

      if (repeatType == 'daily') {
        return end.difference(start).inDays + 1;
      } else if (repeatType == 'weekly' && repeatData.isNotEmpty) {
        final selectedDays = repeatData
            .split(',')
            .map((e) => int.tryParse(e.trim()))
            .where((d) => d != null)
            .toSet();

        int count = 0;
        for (var date = start;
            date.isBefore(end.add(const Duration(days: 1)));
            date = date.add(const Duration(days: 1))) {
          int dayIndex = date.weekday == 7 ? 1 : date.weekday + 1;
          if (selectedDays.contains(dayIndex)) {
            count++;
          }
        }
        return count;
      } else if (repeatType == 'monthly' && repeatData.isNotEmpty) {
        final selectedDays = repeatData
            .split(',')
            .map((e) => int.tryParse(e.trim()))
            .where((d) => d != null)
            .toSet();

        int count = 0;
        for (var date = start;
            date.isBefore(end.add(const Duration(days: 1)));
            date = date.add(const Duration(days: 1))) {
          if (selectedDays.contains(date.day)) {
            count++;
          }
        }
        return count;
      }

      return 0;
    } catch (_) {
      return 0;
    }
  }

  bool _isMissedOnDate(Map<String, dynamic> habit, DateTime date) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (!dateOnly.isBefore(todayOnly)) {
      return false;
    }

    if (!_isHabitApplicableForDate(habit, date)) {
      return false;
    }

    return !_isCompletedOnDate(habit, date);
  }

  bool _isCompletedOnDate(Map<String, dynamic> habit, DateTime date) {
    final completedDates = habit['completed_dates'];
    if (completedDates is List && completedDates.isNotEmpty) {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      return completedDates.any((d) {
        try {
          final dStr = d.toString().substring(0, 10);
          return dStr == dateStr;
        } catch (_) {
          return false;
        }
      });
    }

    final completedDate = habit['completed_date']?.toString();
    if (completedDate == null || completedDate.isEmpty) return false;

    try {
      final completed = DateTime.parse(completedDate);
      return completed.year == date.year &&
          completed.month == date.month &&
          completed.day == date.day;
    } catch (_) {
      return false;
    }
  }

  Map<String, int> _getWeeklyProgress(
      Map<String, dynamic> habit, DateTime selectedDate) {
    final startOfWeek =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

    int totalDays = 0;
    int completedDays = 0;

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      if (_isHabitApplicableForDate(habit, date)) {
        totalDays++;
        if (_isCompletedOnDate(habit, date)) {
          completedDays++;
        }
      }
    }

    return {
      'completed': completedDays,
      'total': totalDays,
    };
  }

  Widget _buildHabitItem(Map<String, dynamic> habit, {DateTime? forDate}) {
    final selectedDate = forDate ?? _getSelectedDate();
    final today = DateTime.now();
    final isToday = selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;

    final isCompletedOnSelectedDate = _isCompletedOnDate(habit, selectedDate);
    final isMissed = _isMissedOnDate(habit, selectedDate);

    int completedDays = 0;
    int durationDays = 0;

    if (habit['is_challenge'] == 1 || habit['is_challenge'] == true) {
      durationDays = _getTargetDays(habit, selectedDate);
      completedDays = _getCompletedDaysForDate(
          habit, selectedDate.add(const Duration(days: 1)));
    } else {
      final weeklyProgress = _getWeeklyProgress(habit, selectedDate);
      completedDays = weeklyProgress['completed']!;
      durationDays = weeklyProgress['total']!;
    }

    final progressValue =
        durationDays > 0 ? (completedDays / durationDays).clamp(0.0, 1.0) : 0.0;
    final progressLabel = durationDays > 0
        ? '$completedDays/$durationDays ngày'
        : '$completedDays lần hoàn thành';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => EditHabitScreen(habit: habit)),
          ).then((result) {
            if (result == true && mounted) {
              fetchHabits();
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit['ten_thoi_quen'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          habit['mo_ta'] ?? '',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isToday && !showAllHistory)
                        IconButton(
                          icon: Icon(
                            isCompletedOnSelectedDate
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isCompletedOnSelectedDate
                                ? Colors.green
                                : Colors.blue,
                            size: 32,
                          ),
                          onPressed: isCompletedOnSelectedDate
                              ? null
                              : () async {
                                  await completeHabit(habit['id']);
                                },
                        )
                      else
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompletedOnSelectedDate
                                ? Colors.green.shade100
                                : isMissed
                                    ? Colors.red.shade100
                                    : Colors.transparent,
                          ),
                          child: Icon(
                            isCompletedOnSelectedDate
                                ? Icons.check
                                : isMissed
                                    ? Icons.close
                                    : Icons.circle_outlined,
                            color: isCompletedOnSelectedDate
                                ? Colors.green
                                : isMissed
                                    ? Colors.red
                                    : Colors.grey[400],
                            size: 24,
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 24),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Xóa thói quen'),
                              content: const Text(
                                  'Bạn có chắc muốn xóa thói quen này không?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Hủy')),
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Xóa')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            deleteHabit(habit['id']);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    progressLabel,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    '${(progressValue * 100).toInt()}%',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: Colors.grey[200],
                  color:
                      habit['is_challenge'] == 1 ? Colors.orange : Colors.blue,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllHistoryView() {
    final now = DateTime.now();
    final habitsByDate = <String, List<Map<String, dynamic>>>{};

    for (var habit in allHabits) {
      final startDateStr = habit['start_date']?.toString();
      if (startDateStr == null || startDateStr.isEmpty) continue;

      try {
        final startDate = DateTime.parse(startDateStr);
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(now.year, now.month, now.day);

        for (var date = start;
            date.isBefore(end.add(const Duration(days: 1)));
            date = date.add(const Duration(days: 1))) {
          if (_isHabitApplicableForDate(habit, date)) {
            final dateKey = DateFormat('yyyy-MM-dd').format(date);
            if (!habitsByDate.containsKey(dateKey)) {
              habitsByDate[dateKey] = [];
            }
            habitsByDate[dateKey]!.add({...habit, 'display_date': date});
          }
        }
      } catch (_) {}
    }

    final sortedDates = habitsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final date = DateTime.parse(dateKey);
        final habits = habitsByDate[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(date),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getDayName(date.weekday == 7 ? 1 : date.weekday + 1),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            ...habits.map((h) => _buildHabitItem(h, forDate: date)),
          ],
        );
      },
    );
  }

  String _avatarFullUrl(String avatar) {
    if (avatar.isEmpty) return '';
    if (avatar.startsWith('http')) return avatar;
    if (avatar.startsWith('/')) {
      return '${ApiService.baseUrl}$avatar';
    }
    return '${ApiService.baseUrl}/storage/$avatar';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.add(Duration(days: i - 3)));

    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditUserScreen(
                              name: userName,
                              avatarUrl: userAvatar,
                            ),
                          ),
                        );
                        if (result != null && result is Map) {
                          setState(() {
                            userName = result['name'] ?? userName;
                            userAvatar = result['avatarUrl'] ?? userAvatar;
                            userEmail = result['email'] ?? userEmail;
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 30,
                          child: ClipOval(
                            child: Builder(builder: (ctx) {
                              final url = _avatarFullUrl(userAvatar);
                              if (url.isEmpty) {
                                return const Icon(Icons.person,
                                    color: Colors.green, size: 32);
                              }
                              return Image.network(
                                url,
                                fit: BoxFit.cover,
                                width: 60,
                                height: 60,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.person,
                                        color: Colors.green, size: 32),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName.isEmpty ? 'Người dùng' : userName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 20,
                                color: (consecutiveDays >= 3 && hasStreakToday)
                                    ? Colors.orange
                                    : Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                consecutiveDays >= 3
                                    ? '$consecutiveDays ngày liên tiếp'
                                    : 'Chưa có streak',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      (consecutiveDays >= 3 && hasStreakToday)
                                          ? Colors.orange
                                          : Colors.white70,
                                ),
                              ),
                              if (consecutiveDays >= 3) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title:
                                            const Text('🛡️ Khôi phục Streak'),
                                        content: Text(
                                          'Bạn còn ${3 - streakFreezeUsed} lần khôi phục trong tháng này.\n\n'
                                          'Nếu bỏ lỡ 1 ngày, streak sẽ tự động khôi phục (nếu còn lượt).',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Đóng'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${3 - streakFreezeUsed}x',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error.isNotEmpty
                      ? Center(child: Text(error))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            showAllHistory = !showAllHistory;
                                          });
                                          _filterHabitsBySelectedDay();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: showAllHistory
                                                ? Colors.blue
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                                color: Colors.blue, width: 2),
                                            boxShadow: showAllHistory
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.blue
                                                          .withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ]
                                                : [],
                                          ),
                                          child: Text(
                                            'Tất cả',
                                            style: TextStyle(
                                              color: showAllHistory
                                                  ? Colors.white
                                                  : Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    ...List.generate(days.length, (i) {
                                      final d = days[i];
                                      final isSelected =
                                          i == selectedDay && !showAllHistory;
                                      final isToday = d.day == now.day &&
                                          d.month == now.month &&
                                          d.year == now.year;

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedDay = i;
                                              showAllHistory = false;
                                            });
                                            _filterHabitsBySelectedDay();
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            curve: Curves.easeOut,
                                            padding: EdgeInsets.symmetric(
                                              vertical: isSelected ? 12 : 10,
                                              horizontal: isSelected ? 16 : 14,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.blue
                                                  : isToday
                                                      ? Colors.blue.shade50
                                                      : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      isSelected ? 16 : 12),
                                              border: isToday && !isSelected
                                                  ? Border.all(
                                                      color: Colors.blue,
                                                      width: 2)
                                                  : null,
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.blue
                                                            .withOpacity(0.3),
                                                        blurRadius: 8,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  DateFormat('dd').format(d),
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : Colors.black87,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        isSelected ? 20 : 16,
                                                  ),
                                                ),
                                                Text(
                                                  _getDayName(d.weekday == 7
                                                      ? 1
                                                      : d.weekday + 1),
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : Colors.black54,
                                                    fontSize:
                                                        isSelected ? 14 : 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(tabs.length, (i) {
                                  final isSelected = i == selectedTab;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(tabs[i]),
                                      selected: isSelected,
                                      onSelected: (_) =>
                                          setState(() => selectedTab = i),
                                      selectedColor: Colors.blue,
                                      // giảm kích thước chữ ~2px và giảm padding để chip nhỏ hơn
                                      labelStyle: TextStyle(
                                        fontSize: isSelected ? 12 : 10,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6, horizontal: 10),
                                      backgroundColor: Colors.white,
                                      elevation: isSelected ? 2 : 0,
                                    ),
                                  );
                                }),
                              ),
                            ),
                            if (!showAllHistory && selectedDay != 3)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: Colors.blue.shade700,
                                          size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          selectedDay < 3
                                              ? 'Lịch sử ${DateFormat('dd/MM/yyyy').format(_getSelectedDate())}'
                                              : 'Dự kiến ${DateFormat('dd/MM/yyyy').format(_getSelectedDate())}',
                                          style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Expanded(
                              child: showAllHistory
                                  ? _buildAllHistoryView()
                                  : filteredHabits.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.event_busy,
                                                  size: 64,
                                                  color: Colors.grey[400]),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Không có thói quen cho ngày này',
                                                style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          itemCount: filteredHabits.length,
                                          itemBuilder: (context, index) {
                                            return _buildHabitItem(
                                                filteredHabits[index]);
                                          },
                                        ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
