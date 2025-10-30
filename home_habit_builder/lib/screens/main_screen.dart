import 'package:flutter/material.dart';
import 'package:home_habit_builder/screens/plant_screen.dart';

import 'habit_list_screen.dart';
import 'settings_screen.dart';
import 'add_habit_screen.dart';
//import '../widgets/lotus_plant_widget.dart';
import '../services/plant_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/procrastination_service.dart';
import 'dart:async';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<dynamic> _habits = [];
  int _persistentXp = 0;
  int _serverXp = 0;
  Timer? _procrastinationTimer;
  final _procrastinationService = const ProcrastinationService();
  int _unreadProcrastinationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadXpData();
    _startProcrastinationDetection(); // 🔥 thêm dòng này
  }

  void _startProcrastinationDetection() {
    // Gọi ngay khi mở app
    _detectProcrastination();

    // Sau đó cứ 30 phút kiểm tra lại
    _procrastinationTimer =
        Timer.periodic(const Duration(minutes: 30), (timer) {
      _detectProcrastination();
    });
  }

  Future<void> _detectProcrastination() async {
    try {
      await _procrastinationService.detectProcrastination();
      final alerts = await _procrastinationService.getUnreadAlerts();
      if (mounted) {
        setState(() {
          _unreadProcrastinationCount = alerts.length;
        });
      }

      // Nếu có cảnh báo mới, thêm thông báo vào NotificationService
      if (alerts.isNotEmpty) {
        await NotificationService.addNotification(
          title: 'AI phát hiện trì hoãn 🧠',
          body: 'Có ${alerts.length} dấu hiệu trì hoãn mới!',
        );
        setState(() {});
      }
    } catch (e) {
      print('Lỗi khi phát hiện trì hoãn: $e');
    }
  }

  @override
  void dispose() {
    _procrastinationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadXpData() async {
    final localXp = await PlantService.getLocalXp();
    final info = await ApiService.getUserInfo();
    int serverXp = 0;
    if (info != null && info['plant_xp'] != null) {
      final val = info['plant_xp'];
      serverXp = val is int ? val : int.tryParse(val.toString()) ?? 0;
    }

    if (mounted) {
      setState(() {
        _persistentXp = localXp;
        _serverXp = serverXp;
      });
    }
  }

  int get xp {
    final now = DateTime.now();
    return _habits
        .where((h) =>
            h['completed'] == true && h['completedDate'] == _dateString(now))
        .fold<int>(
          0,
          (sum, h) =>
              sum +
              (h['diem'] is int
                  ? h['diem'] as int
                  : int.tryParse(h['diem']?.toString() ?? '0') ?? 0),
        );
  }

  static String _dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<Widget> get _screens => [
        HabitListScreen(
          onHabitsChanged: (habits) async {
            setState(() => _habits = habits);
            await _loadXpData();
          },
        ),
        _buildNotificationScreen(),
        const SizedBox.shrink(), // Tab "Thêm" sẽ mở AddHabitScreen
        const PlantScreen(),
        const SettingsScreen(),
      ];

  Widget _buildNotificationScreen() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: NotificationService.getNotifications(),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFFEDE7F6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_active,
                          color: Color(0xFF6C63FF),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Thông báo',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_forever,
                            color: Colors.white),
                        onPressed: () async {
                          await NotificationService.clearNotifications();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F5FF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: notifications.isEmpty
                        ? const Center(
                            child: Text(
                              'Chưa có thông báo nào',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final n = notifications[index];
                              final time = DateTime.tryParse(n['time'] ?? '');
                              final timeStr = time != null
                                  ? '${time.hour}:${time.minute.toString().padLeft(2, '0')}'
                                  : '';
                              return _buildNotificationCard(
                                icon: Icons.notifications,
                                iconColor: Colors.deepPurple,
                                title: n['title'] ?? '',
                                subtitle: n['body'] ?? '',
                                time: timeStr,
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          // ✅ Nếu nhấn vào tab "Thêm" (index = 2), mở AddHabitScreen
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddHabitScreen()),
            ).then((_) {
              // Sau khi thêm habit xong, quay về tab Thói quen
              setState(() => _selectedIndex = 0);
            });
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.list), label: 'Thói quen'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_unreadProcrastinationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_unreadProcrastinationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Thông báo',
          ),
          const BottomNavigationBarItem(
              icon: Icon(Icons.add_circle), label: 'Thêm'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.local_florist), label: 'Cây'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
      ),

      // ✅ XÓA FloatingActionButton
    );
  }
}
