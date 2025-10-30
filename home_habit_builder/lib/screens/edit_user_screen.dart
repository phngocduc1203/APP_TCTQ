import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class EditUserScreen extends StatefulWidget {
  final String name;
  final String avatarUrl;
  const EditUserScreen({
    super.key,
    required this.name,
    required this.avatarUrl,
  });

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  late TextEditingController nameController;
  late TextEditingController oldPasswordController;
  late TextEditingController passwordController;

  String? _previewAvatarUrl;
  File? _localAvatarFile;
  Uint8List? _webAvatarBytes;
  bool _uploadingAvatar = false;
  bool _avatarChanged = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    oldPasswordController = TextEditingController();
    passwordController = TextEditingController();
    _previewAvatarUrl = widget.avatarUrl;
  }

  @override
  void dispose() {
    nameController.dispose();
    oldPasswordController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Chọn và upload ảnh ngay lập tức
  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (picked == null) return;

    setState(() {
      _uploadingAvatar = true;
    });

    try {
      Map<String, dynamic>? result;

      if (kIsWeb) {
        // Web: đọc bytes
        final bytes = await picked.readAsBytes();
        result = await ApiService.uploadAvatar(
          webBytes: bytes,
          filename: picked.name,
        );
      } else {
        // Mobile: dùng File
        final file = File(picked.path);
        result = await ApiService.uploadAvatar(
          file: file,
          filename: picked.name,
        );
      }

      if (result != null) {
        // Lấy URL avatar mới từ response
        String? newAvatarUrl;
        if (result['avatar'] != null) {
          newAvatarUrl = result['avatar'].toString();
        } else if (result['user'] != null && result['user']['avatar'] != null) {
          newAvatarUrl = result['user']['avatar'].toString();
        }

        if (newAvatarUrl != null) {
          setState(() {
            _previewAvatarUrl = newAvatarUrl;
            _avatarChanged = true;
            _uploadingAvatar = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã cập nhật avatar thành công!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        throw Exception('Upload thất bại');
      }
    } catch (e) {
      setState(() {
        _uploadingAvatar = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi upload avatar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Lưu thông tin khác (tên, mật khẩu)
  Future<void> _saveInfo() async {
    // Chỉ update nếu có thay đổi
    final nameChanged = nameController.text != widget.name;
    final passwordChanged = passwordController.text.isNotEmpty &&
        oldPasswordController.text.isNotEmpty;

    if (!nameChanged && !passwordChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có thay đổi nào')),
      );
      return;
    }

    final result = await ApiService.updateUserInfo(
      name: nameChanged ? nameController.text : '',
      avatarUrl: '',
      avatarFile: null,
      password: passwordChanged ? passwordController.text : null,
      oldPassword: passwordChanged ? oldPasswordController.text : null,
    );

    if (mounted) {
      if (result == 'Cập nhật thành công') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật thông tin!'),
            backgroundColor: Colors.green,
          ),
        );

        // Trả về dữ liệu mới
        Navigator.pop(context, {
          'name': nameController.text,
          'avatarUrl': _previewAvatarUrl ?? widget.avatarUrl,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      }
    }
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.deepPurple.shade100,
            backgroundImage:
                _previewAvatarUrl != null && _previewAvatarUrl!.isNotEmpty
                    ? NetworkImage(_previewAvatarUrl!)
                    : null,
            child: (_previewAvatarUrl == null || _previewAvatarUrl!.isEmpty)
                ? const Icon(Icons.person, color: Colors.white, size: 40)
                : null,
          ),
          if (_uploadingAvatar)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
            ),
          if (!_uploadingAvatar)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin'),
        actions: [
          TextButton(
            onPressed: _saveInfo,
            child: const Text(
              'Lưu',
              style: TextStyle(
                color: Color.fromARGB(255, 11, 3, 3),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildAvatar(),
              const SizedBox(height: 8),
              Text(
                'Nhấn vào ảnh để thay đổi',
                style: TextStyle(
                  color: const Color.fromARGB(255, 0, 0, 0),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 32),

              // Tên
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Tên',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Mật khẩu cũ
              TextField(
                controller: oldPasswordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu cũ (nếu muốn đổi)',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),

              // Mật khẩu mới
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 32),

              // Nút Đăng xuất
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xác nhận'),
                        content: const Text('Bạn có chắc muốn đăng xuất?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Đăng xuất'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await ApiService.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
