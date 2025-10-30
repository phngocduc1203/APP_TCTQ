import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 👈 thêm dòng này
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'edit_user_screen.dart';
import '../services/background_task_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentLang = 'vi';
  String _name = '';
  String? _avatarUrl;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final localLang = prefs.getString('app_lang');

    final user = await ApiService.getUserInfo();
    if (user != null) {
      setState(() {
        _name = (user['name'] ?? user['ten'] ?? '') as String;
        _avatarUrl = (user['avatar'] ?? '') as String?;
        _currentLang = localLang ?? (user['lang'] as String?) ?? _currentLang;
      });
    } else {
      setState(() {
        _currentLang = localLang ?? _currentLang;
      });
    }
  }

  /// ✅ Cập nhật ngôn ngữ app toàn cục + lưu local
  Future<void> _changeLanguage(String code) async {
    setState(() => _currentLang = code);

    // đổi ngôn ngữ toàn app
    MyApp.setLocaleGlobal(Locale(code));

    // lưu lại trong SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', code);

    // nếu muốn, có thể gọi API cập nhật ngôn ngữ người dùng:
    // await ApiService.updateUserLanguage(code);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.change_language)),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildHeader(),
          const Divider(),
          _buildLanguageTile(t),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(t.notifications),
            subtitle: const Text('Quản lý nhắc nhở'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.rate_review),
            title: Text(t.feedback),
            onTap: _openFeedback,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(t.about_app),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bug_report, color: Colors.orange),
            title: const Text('🧪 Test Notification'),
            subtitle: const Text('Test thông báo trì hoãn'),
            onTap: () async {
              await BackgroundTaskService.resetNotificationCache();
              await BackgroundTaskService.manualCheck();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Đã gửi test notification!')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(t.logout),
            onTap: () {
              ApiService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Text('Ngôn ngữ',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text(t.language_vietnamese),
                  value: 'vi',
                  groupValue: _currentLang,
                  onChanged: (v) => _changeLanguage(v ?? 'vi'),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text(t.language_english),
                  value: 'en',
                  groupValue: _currentLang,
                  onChanged: (v) => _changeLanguage(v ?? 'en'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final String? fullAvatarUrl = (_avatarUrl != null && _avatarUrl!.isNotEmpty)
        ? ApiService.fixUrl(_avatarUrl)
        : null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 30,
        backgroundImage:
            fullAvatarUrl != null ? NetworkImage(fullAvatarUrl!) : null,
        child:
            fullAvatarUrl == null ? const Icon(Icons.person, size: 30) : null,
      ),
      title: Text(
        _name.isNotEmpty ? _name : 'Người dùng',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: const Text('Xem & chỉnh sửa thông tin'),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () async {
          final changed = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  EditUserScreen(name: _name, avatarUrl: _avatarUrl ?? ''),
            ),
          );
          if (changed == true) _loadUser();
        },
      ),
    );
  }

  void _openFeedback() {
    // giữ nguyên code feedback của bạn
  }
}
