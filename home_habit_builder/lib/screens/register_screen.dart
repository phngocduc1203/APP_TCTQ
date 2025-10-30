import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final cfPasswordController = TextEditingController();
  final ageController = TextEditingController();

  String selectedGender = 'Nam';
  final List<String> genders = ['Nam', 'Nữ', 'Khác'];

  bool isLoading = false;
  String message = '';

  void handleRegister() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    // Validation
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        ageController.text.trim().isEmpty) {
      setState(() {
        isLoading = false;
        message = 'Vui lòng điền đầy đủ thông tin';
      });
      return;
    }

    if (passwordController.text != cfPasswordController.text) {
      setState(() {
        isLoading = false;
        message = 'Mật khẩu xác nhận không khớp';
      });
      return;
    }

    final age = int.tryParse(ageController.text.trim());
    if (age == null || age < 5 || age > 120) {
      setState(() {
        isLoading = false;
        message = 'Tuổi không hợp lệ (5-120)';
      });
      return;
    }

    final result = await ApiService.register(
      nameController.text.trim(),
      emailController.text.trim(),
      passwordController.text.trim(),
      cfPasswordController.text.trim(),
      age,
      selectedGender,
    );

    setState(() {
      isLoading = false;
      message = result;
    });

    if (result == 'Đăng ký thành công') {
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFFEDE7F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.spa, color: Color(0xFF6C63FF), size: 48),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Đăng ký',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tên
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Tên',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tuổi và Giới tính trên cùng 1 hàng
                        Row(
                          children: [
                            // Tuổi
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: ageController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Tuổi',
                                  prefixIcon: Icon(Icons.cake),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Giới tính
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: selectedGender,
                                decoration: const InputDecoration(
                                  labelText: 'Giới tính',
                                  prefixIcon: Icon(Icons.wc),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(16),
                                    ),
                                  ),
                                ),
                                items:
                                    genders.map((gender) {
                                      return DropdownMenuItem(
                                        value: gender,
                                        child: Text(gender),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedGender = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Mật khẩu
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Xác nhận mật khẩu
                        TextField(
                          controller: cfPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Xác nhận mật khẩu',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Nút đăng ký
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6C63FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              shadowColor: Color(0xFF6C63FF).withOpacity(0.3),
                            ),
                            onPressed: isLoading ? null : handleRegister,
                            child:
                                isLoading
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : const Text(
                                      'Đăng ký',
                                      style: TextStyle(fontSize: 18),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (message.isNotEmpty)
                          Text(
                            message,
                            style: TextStyle(
                              color:
                                  message == 'Đăng ký thành công'
                                      ? Colors.green
                                      : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const SizedBox(height: 10),

                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Bạn đã có tài khoản? Đăng nhập'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    cfPasswordController.dispose();
    ageController.dispose();
    super.dispose();
  }
}
