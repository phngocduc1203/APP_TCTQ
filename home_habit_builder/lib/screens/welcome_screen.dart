import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'habit_list_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final String name;
  const WelcomeScreen({super.key, required this.name});

  void _logout(BuildContext context) async {
    await ApiService.logout();
    // Quay lại màn đăng nhập
    // ignore: use_build_context_synchronously
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chào mừng')), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Chào mừng, $name!', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HabitListScreen()),
              ),
              child: const Text('Xem thói quen'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _logout(context),
              child: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    );
  }
}
