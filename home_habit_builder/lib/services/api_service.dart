import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'http://192.168.1.26:8000/api/v1';
  // --- AI Config (Gemini Only) ---
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY']?.trim() ?? '';

  static bool get hasValidGeminiKey {
    final key = geminiApiKey;
    // Đảm bảo key hợp lệ, đủ dài, và có prefix đúng chuẩn
    return key.isNotEmpty && key.startsWith('AIza') && key.length >= 35;
  }

  /// 🌐 Hàm tạo URL đầy đủ cho ảnh hoặc file trong storage Laravel
  static String fixUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    // Nếu đã là URL tuyệt đối
    if (path.startsWith('http')) return path;
    // Loại bỏ /api/v1 để trỏ ra public
    final base = (dotenv.env['BASE_URL'] ?? '').replaceFirst('/api/v1', '');
    return '$base/storage/$path';
  }

// ==================== LẤY TOKEN ====================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token'); // phải là access_token
    print('🔑 Token in PlantService.getToken(): $token');
    return token;
  }

  // ==================== ĐĂNG KÝ ====================
  static Future<String> register(
    String name,
    String email,
    String password,
    String cfPassword,
    int age,
    String gender,
  ) async {
    final url = Uri.parse('$baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': cfPassword,
          'age': age,
          'gender': gender,
        }),
      );
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return 'Lỗi server hoặc sai đường dẫn API.\n${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}';
      }
      if (response.statusCode == 201 || response.statusCode == 200) {
        return 'Đăng ký thành công';
      } else {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Đăng ký thất bại';
      }
    } catch (e) {
      return 'Lỗi kết nối hoặc dữ liệu trả về không hợp lệ: $e';
    }
  }

  // ==================== ĐĂNG NHẬP ====================
  static Future<String> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', token);
        }
        return 'Đăng nhập thành công';
      } else {
        return 'Sai tài khoản hoặc mật khẩu';
      }
    } catch (e) {
      return 'Lỗi kết nối: $e';
    }
  }

  // ==================== ĐĂNG XUẤT ====================
  static Future<void> logout() async {
    final token = await getToken();
    if (token == null) return;
    final url = Uri.parse('$baseUrl/logout');
    try {
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  // ==================== LẤY THÔNG TIN USER ====================
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final token = await getToken();
    if (token == null) return null;
    final url = Uri.parse('$baseUrl/me');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map<String, dynamic> ? data : null;
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> getUserName() async {
    final token = await getToken();
    if (token == null) return null;
    final url = Uri.parse('$baseUrl/me');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['name'] ?? data['email'] ?? 'bạn';
      }
    } catch (_) {}
    return null;
  }

  // ==================== LẤY USER ID ====================
  static Future<int?> getUserId() async {
    final info = await getUserInfo();
    if (info == null) return null;

    // Kiểm tra các key phổ biến mà API có thể trả về
    if (info.containsKey('id')) return info['id'];
    if (info.containsKey('user_id')) return info['user_id'];

    return null;
  }
  // ==================== STREAK API ====================

  /// Lấy thông tin streak của user
  static Future<Map<String, dynamic>?> getStreakInfo() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/streak/info'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Get streak info error: $e');
      return null;
    }
  }

  /// Cập nhật streak khi hoàn thành thói quen
  static Future<Map<String, dynamic>?> updateStreak() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/streak/update'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Update streak error: $e');
      return null;
    }
  }

  /// Sử dụng khôi phục streak (freeze)
  static Future<Map<String, dynamic>?> useStreakFreeze() async {
    final token = await getToken();
    if (token == null) return null;

    final url = Uri.parse('$baseUrl/streak/freeze');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('useStreakFreeze error: $e');
    }
    return null;
  }

  /// 🔔 Kiểm tra cần cảnh báo streak không
  static Future<Map<String, dynamic>?> checkStreakWarning() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/streak/warning'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Check streak warning error: $e');
      return null;
    }
  }

  // ==================== CẬP NHẬT THÔNG TIN USER ====================
  static Future<String> updateUserInfo({
    required String name,
    required String avatarUrl,
    File? avatarFile,
    String? password,
    String? oldPassword,
  }) async {
    final token = await getToken();
    if (token == null) return 'Chưa đăng nhập';

    final url = Uri.parse('$baseUrl/me');

    try {
      if (avatarFile == null &&
          oldPassword != null &&
          oldPassword.isNotEmpty &&
          password != null &&
          password.isNotEmpty) {
        final response = await http.put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'name': name,
            'old_password': oldPassword,
            'password': password,
            'password_confirmation': password,
          }),
        );

        if (response.statusCode == 200) {
          return 'Cập nhật thành công';
        } else {
          final data = jsonDecode(response.body);
          if (data['errors'] != null) {
            final errors = data['errors'] as Map<String, dynamic>;
            return errors.values.first[0] ?? 'Cập nhật thất bại';
          }
          return data['message'] ?? 'Mật khẩu cũ không đúng';
        }
      }

      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['_method'] = 'PUT';

      if (name.isNotEmpty) {
        request.fields['name'] = name;
      }

      if (avatarFile != null) {
        try {
          if (!kIsWeb) {
            request.files.add(
              await http.MultipartFile.fromPath('avatar', avatarFile.path),
            );
          } else {
            final bytes = await avatarFile.readAsBytes();
            final b64 = base64Encode(bytes);
            request.fields['avatar_base64'] = b64;
          }
        } catch (e) {
          return 'Tải ảnh không thành công: $e';
        }
      } else if (avatarUrl.isNotEmpty) {
        request.fields['avatar'] = avatarUrl;
      }

      if (oldPassword != null &&
          oldPassword.isNotEmpty &&
          password != null &&
          password.isNotEmpty) {
        request.fields['old_password'] = oldPassword;
        request.fields['password'] = password;
        request.fields['password_confirmation'] = password;
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return 'Cập nhật thành công';
      } else {
        final data = jsonDecode(body);
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          return errors.values.first[0] ?? 'Cập nhật thất bại';
        }
        return data['message'] ?? 'Cập nhật thất bại';
      }
    } catch (e) {
      return 'Lỗi kết nối: $e';
    }
  }

  // ==================== THÊM THÓI QUEN ====================
  static Future<String> addHabit(
    String name,
    String description,
    String diem,
    String repeatType,
    String repeatData, {
    int durationDays = 1,
    int totalXp = 0,
    bool isChallenge = false,
  }) async {
    final token = await getToken();
    if (token == null) return 'Chưa đăng nhập';
    final url = Uri.parse('$baseUrl/habits');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'ten_thoi_quen': name,
          'mo_ta': description,
          'diem': int.tryParse(diem) ?? 0,
          'repeat_type': repeatType,
          'repeat_data': repeatData,
          'duration_days': durationDays,
          'total_xp': totalXp,
          'is_challenge': isChallenge,
        }),
      );
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return 'Lỗi server hoặc sai đường dẫn API.\n${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}';
      }
      if (response.statusCode == 201 || response.statusCode == 200) {
        return 'Thêm thành công';
      } else {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Thêm thất bại';
      }
    } catch (e) {
      return 'Lỗi kết nối hoặc dữ liệu trả về không hợp lệ: $e';
    }
  }

//
  static Future<bool> createHabit(Map<String, dynamic> habitData) async {
    final token = await getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/habits');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode(habitData),
      );

      // Trả true nếu tạo thành công
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== LẤY CHI TIẾT 1 THÓI QUEN ====================
  static Future<Map<String, dynamic>?> getHabit(int id) async {
    final token = await getToken();
    if (token == null) return null;
    final url = Uri.parse('$baseUrl/habits/$id');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data['habit'] ?? data;
        }
      }
    } catch (_) {}
    return null;
  }

  // ==================== CẬP NHẬT THÓI QUEN ====================
  static Future<String> updateHabit(
    int id, {
    required String name,
    String? description,
    String? diem,
    String? repeatType,
    String? repeatData,
    int? durationDays,
    bool? isChallenge,
  }) async {
    final token = await getToken();
    if (token == null) return 'Chưa đăng nhập';

    final url = Uri.parse('$baseUrl/habits/$id');
    try {
      final Map<String, dynamic> payload = {'ten_thoi_quen': name};

      if (description != null) payload['mo_ta'] = description;
      if (diem != null) payload['diem'] = diem;
      if (repeatType != null) payload['repeat_type'] = repeatType;
      if (repeatData != null) payload['repeat_data'] = repeatData;
      if (durationDays != null) payload['duration_days'] = durationDays;
      if (isChallenge != null) payload['is_challenge'] = isChallenge ? 1 : 0;

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return 'Cập nhật thành công';
      }

      final data = jsonDecode(response.body);
      return data['message'] ?? 'Lỗi cập nhật';
    } catch (e) {
      return 'Lỗi kết nối: $e';
    }
  }

  // ==================== LẤY DANH SÁCH THÓI QUEN ====================
  static Future<List<dynamic>?> getHabits() async {
    final token = await getToken();
    if (token == null) return null;

    final url = Uri.parse('$baseUrl/habits');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('ApiService.getHabits -> ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Backend Laravel trả về { "habits": [...] }
        if (data['habits'] is List) {
          final habits = data['habits'] as List;

          // Debug: In ra 1 habit để xem structure
          if (habits.isNotEmpty) {
            print('📋 Sample habit structure:');
            print('  - id: ${habits[0]['id']}');
            print('  - ten_thoi_quen: ${habits[0]['ten_thoi_quen']}');
            print('  - completed_dates: ${habits[0]['completed_dates']}');
            print('  - completed_date: ${habits[0]['completed_date']}');
            print('  - completed_days: ${habits[0]['completed_days']}');
          }

          return habits;
        }
        return null;
      }
      return null;
    } catch (e) {
      print('Error fetching habits: $e');
      return null;
    }
  }

  // ==================== HOÀN THÀNH THÓI QUEN ====================
  static Future<Map<String, dynamic>?> completeHabit(int habitId) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('❌ No token found');
        return null;
      }

      print('🚀 Calling API: /habits/$habitId/complete');

      final response = await http.post(
        Uri.parse('$baseUrl/habits/$habitId/complete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('❌ Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Complete habit error: $e');
      return null;
    }
  }

  // ==================== XÓA THÓI QUEN ====================
  static Future<bool> deleteHabit(int id) async {
    final token = await getToken();
    if (token == null) return false;
    final url = Uri.parse('$baseUrl/habits/$id');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

// ==================== AI ĐỀ XUẤT NHẬN XÉT THÓI QUEN ====================

  static Future<String> getAiSuggestion(String name, String description) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return '';

    final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey");

    final prompt = """
Bạn là chuyên gia phát triển thói quen. Dựa trên thông tin:
Tên: $name
Mô tả: $description

Hãy đưa ra nhận xét xem thói quen tốt hay không và gợi ý cách duy trì nó.
Chỉ trả về đúng 1 đoạn văn ngắn, không có JSON.
""";

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (res.statusCode != 200) return '';

    try {
      final data = jsonDecode(res.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
    } catch (_) {
      return '';
    }
  }

// ==================== AI ĐỀ XUẤT THÓI QUEN ====================
  static Future<List<Map<String, dynamic>>> getAIHabitSuggestions() async {
    try {
      final userInfo = await getUserInfo();
      if (userInfo == null) return _getDefaultSuggestions();

      final age = userInfo['age'] ?? 25;
      final gender = (userInfo['gender'] ?? 'Nam').toString();

      // 🔹 Kiểm tra cache
      final cached =
          await _getCachedSuggestions(age, gender, maxAgeSeconds: 3600);
      if (cached != null) {
        print('📦 Dùng cache Gemini');
        return cached;
      }

      // 🔹 Gọi Gemini (chỉ Gemini, không fallback OpenAI/HF)
      if (hasValidGeminiKey) {
        print('🤖 Gọi Gemini để gợi ý thói quen');
        final res = await _getGeminiSuggestionsSDK(age, gender);
        if (res.isNotEmpty) {
          await _setCachedSuggestions(age, gender, res);
          return res;
        }
      }

      print('⚠️ Không có Gemini key hoặc lỗi => dùng local fallback');
      return _getSmartSuggestions(age, gender);
    } catch (e) {
      print('getAIHabitSuggestions error: $e');
      return _getDefaultSuggestions();
    }
  }

// ==================== CACHE ====================
  static Future<void> _setCachedSuggestions(
      int age, String gender, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'ai_suggestions_${age}_${gender.toLowerCase()}';
    await prefs.setString(key, jsonEncode(items));
    await prefs.setInt('${key}_ts', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<List<Map<String, dynamic>>?> _getCachedSuggestions(
      int age, String gender,
      {int maxAgeSeconds = 3600}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'ai_suggestions_${age}_${gender.toLowerCase()}';
    final raw = prefs.getString(key);
    final ts = prefs.getInt('${key}_ts') ?? 0;
    if (raw == null) return null;
    if (DateTime.now().millisecondsSinceEpoch - ts > maxAgeSeconds * 1000) {
      return null;
    }
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return list;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearCachedSuggestions({int? age, String? gender}) async {
    final prefs = await SharedPreferences.getInstance();
    if (age != null && gender != null) {
      final key = 'ai_suggestions_${age}_${gender.toLowerCase()}';
      await prefs.remove(key);
      await prefs.remove('${key}_ts');
      print('🧹 Đã xóa cache Gemini cho $age/$gender');
      return;
    }
    for (final k in prefs
        .getKeys()
        .where((k) => k.startsWith('ai_suggestions_'))
        .toList()) {
      await prefs.remove(k);
      await prefs.remove('${k}_ts');
    }
    print('🧹 Đã xóa toàn bộ cache Gemini');
  }

// ==================== GEMINI - FIX MODEL SELECTION ====================

// 🔥 XÓA HÀM _findGenerativeModel (không cần nữa)
// Thay vào đó, LUÔN DÙNG gemini-2.0-flash-exp (model miễn phí tốt nhất)

  static Future<List<Map<String, dynamic>>> _getGeminiSuggestionsSDK(
      int age, String gender) async {
    try {
      final key = geminiApiKey;
      if (key.isEmpty) {
        print('❌ Thiếu GEMINI_API_KEY trong .env');
        return _getSmartSuggestions(age, gender);
      }

      // 🔥 CỐ ĐỊNH MODEL: gemini-2.0-flash-exp (miễn phí, nhanh)
      const modelName = 'gemini-2.0-flash-exp';
      print('⚙️ Sử dụng Gemini model: $modelName');

      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$key');

      final prompt = '''
Bạn là chuyên gia huấn luyện thói quen. Hãy gợi ý 5 thói quen phù hợp với người:
- Tuổi: $age
- Giới tính: $gender

Yêu cầu:
- Thực tế, có ích cho sức khỏe, học tập hoặc phát triển bản thân.
- Độ khó: 0=Dễ, 1=Trung bình, 2=Khó.
- Trả về đúng JSON mảng, không thêm văn bản mô tả khác.
Ví dụ:
[
  {"ten_thoi_quen":"Tên","mo_ta":"Mô tả","difficulty_index":0}
]
''';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
        if (text != null && text.isNotEmpty) {
          // Parse JSON từ response
          final match = RegExp(r'\[[\s\S]*\]').firstMatch(text);
          if (match != null) {
            final parsed = jsonDecode(match.group(0)!) as List;
            print('✅ Gemini trả về ${parsed.length} gợi ý');
            return parsed
                .map((e) => Map<String, dynamic>.from(e as Map))
                .take(5)
                .toList();
          }
        }
      } else if (response.statusCode == 429) {
        // 🔥 XỬ LÝ LỖI QUOTA
        print('⚠️ Gemini quota exceeded (429). Dùng fallback cục bộ.');
        final data = jsonDecode(response.body);
        print('Details: ${data['error']['message']}');
        return _getSmartSuggestions(age, gender);
      } else {
        print('❌ Gemini API error: ${response.statusCode} - ${response.body}');
      }

      return _getSmartSuggestions(age, gender);
    } catch (e) {
      print('❌ Lỗi khi gọi Gemini: $e');
      return _getSmartSuggestions(age, gender);
    }
  }

// ==================== GỌI API THEO THỜI GIAN TRONG NGÀY ====================
  static Future<List<Map<String, dynamic>>> getPersonalizedHabitSuggestions({
    required String gender,
    required int age,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return [];

    // 🔥 DÙNG gemini-2.0-flash-exp thay vì gemini-2.0-flash
    const modelName = 'gemini-2.0-flash-exp';
    final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey");

    final prompt = """
Hãy gợi ý các thói quen tốt phù hợp với một người $gender, $age tuổi,
chia thành 3 phần:
- Buổi sáng (giúp khởi đầu năng lượng)
- Buổi trưa (giúp duy trì tập trung)
- Buổi tối (giúp thư giãn và ngủ ngon)

Mỗi phần gồm 3 thói quen, có:
- Tên thói quen
- Mô tả ngắn (1 câu)
- Lợi ích chính (1 câu)

Trả kết quả ở dạng JSON:
{
  "morning": [{"ten_thoi_quen": "...", "mo_ta": "...", "loi_ich": "..."}],
  "noon": [...],
  "evening": [...]
}
""";

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final text =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? "";

        // Parse JSON từ response
        final match = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (match != null) {
          final parsed = jsonDecode(match.group(0)!);

          List<Map<String, dynamic>> suggestions = [];
          for (final key in ['morning', 'noon', 'evening']) {
            final habits = parsed[key];
            if (habits is List) {
              suggestions.addAll(List<Map<String, dynamic>>.from(habits));
            }
          }
          return suggestions;
        }
      } else if (res.statusCode == 429) {
        print('⚠️ Gemini quota exceeded (getPersonalizedHabitSuggestions)');
        return [];
      }
    } catch (e) {
      print('❌ getPersonalizedHabitSuggestions error: $e');
    }

    return [];
  }

// ==================== AI ĐƯA RA LỜI KHUYÊN ====================

// ==================== PHÁT HIỆN TRÌ HOÃN ====================
//   static Future<bool> detectProcrastination(
//       Map<String, dynamic> userStats) async {
//     final apiKey = dotenv.env['GEMINI_API_KEY'];
//     if (apiKey == null || apiKey.isEmpty) return false;

//     // 🔥 DÙNG gemini-2.0-flash-exp
//     const modelName = 'gemini-2.0-flash-exp';
//     final url = Uri.parse(
//         "https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey");

//     final prompt = """
// Dữ liệu người dùng:
// $userStats

// Nếu người này đang có dấu hiệu trì hoãn (bỏ qua hoặc giảm tần suất thực hiện thói quen), trả về "true".
// Ngược lại, trả về "false".
// Chỉ trả về JSON: {"procrastinating": true/false}
// """;

//     try {
//       final res = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           "contents": [
//             {
//               "parts": [
//                 {"text": prompt}
//               ]
//             }
//           ]
//         }),
//       );

//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final text =
//             data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? "";
//         final match = RegExp(r'\{[\s\S]*\}').firstMatch(text);
//         if (match != null) {
//           final parsed = jsonDecode(match.group(0)!);
//           return parsed['procrastinating'] == true;
//         }
//       } else if (res.statusCode == 429) {
//         print('⚠️ Gemini quota exceeded (detectProcrastination)');
//         return false;
//       }
//     } catch (e) {
//       print('❌ detectProcrastination error: $e');
//     }

//     return false;
//   }

  static Future<Map<String, dynamic>> getUserStats() async {
    final token = await getToken();
    if (token == null) return {};

    final url =
        Uri.parse('$baseUrl/users/stats'); // 🔹 Đổi nếu API backend khác
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('⚠️ getUserStats lỗi: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      debugPrint('❌ getUserStats exception: $e');
      return {};
    }
  }

// ==================== FALLBACK GỢI Ý ====================
  static List<Map<String, dynamic>> _getSmartSuggestions(
      int age, String gender) {
    print('💡 Fallback: gợi ý cục bộ theo tuổi=$age, giới tính=$gender');
    List<Map<String, dynamic>> suggestions = [];

    if (age < 18) {
      suggestions.addAll([
        {
          'ten_thoi_quen': 'Đọc sách 30 phút',
          'mo_ta': 'Rèn luyện tư duy và mở rộng kiến thức',
          'difficulty_index': 1,
        },
        {
          'ten_thoi_quen': 'Học bài trước khi ngủ',
          'mo_ta': 'Ôn tập kiến thức đã học trong ngày',
          'difficulty_index': 0,
        },
        {
          'ten_thoi_quen': 'Tập thể dục 15 phút',
          'mo_ta': 'Tăng cường sức khỏe và tập trung học tốt hơn',
          'difficulty_index': 1,
        },
      ]);
    } else if (age >= 18 && age < 30) {
      suggestions.addAll([
        {
          'ten_thoi_quen': 'Học kỹ năng mới 1 giờ',
          'mo_ta': 'Đầu tư cho tương lai nghề nghiệp',
          'difficulty_index': 2,
        },
        {
          'ten_thoi_quen': 'Tập gym 45 phút',
          'mo_ta': 'Duy trì vóc dáng và sức khỏe',
          'difficulty_index': 2,
        },
        {
          'ten_thoi_quen': 'Thiền 10 phút',
          'mo_ta': 'Giảm stress và tăng tập trung',
          'difficulty_index': 0,
        },
      ]);
    } else if (age >= 30 && age < 50) {
      suggestions.addAll([
        {
          'ten_thoi_quen': 'Dậy sớm 6h sáng',
          'mo_ta': 'Tăng năng suất làm việc cả ngày',
          'difficulty_index': 2,
        },
        {
          'ten_thoi_quen': 'Uống 2 lít nước/ngày',
          'mo_ta': 'Duy trì sức khỏe và làn da đẹp',
          'difficulty_index': 1,
        },
        {
          'ten_thoi_quen': 'Đi bộ 30 phút',
          'mo_ta': 'Phòng ngừa bệnh tật và giữ dáng',
          'difficulty_index': 1,
        },
      ]);
    } else {
      suggestions.addAll([
        {
          'ten_thoi_quen': 'Đi bộ nhẹ nhàng 20 phút',
          'mo_ta': 'Tăng cường tuần hoàn máu và sức khỏe xương khớp',
          'difficulty_index': 0,
        },
        {
          'ten_thoi_quen': 'Đọc báo/sách mỗi sáng',
          'mo_ta': 'Duy trì sự minh mẫn và sảng khoái tinh thần',
          'difficulty_index': 0,
        },
        {
          'ten_thoi_quen': 'Uống thuốc đúng giờ',
          'mo_ta': 'Chăm sóc sức khỏe và ngăn ngừa biến chứng',
          'difficulty_index': 0,
        },
      ]);
    }

    if (gender == 'Nữ') {
      suggestions.add({
        'ten_thoi_quen': 'Dưỡng da buổi tối',
        'mo_ta': 'Giữ làn da khỏe đẹp và tươi trẻ',
        'difficulty_index': 0,
      });
    } else if (gender == 'Nam') {
      suggestions.add({
        'ten_thoi_quen': 'Tập cơ bụng 10 phút',
        'mo_ta': 'Xây dựng cơ bụng săn chắc',
        'difficulty_index': 1,
      });
    }

    suggestions.add({
      'ten_thoi_quen': 'Viết nhật ký cảm xúc',
      'mo_ta': 'Ghi lại suy nghĩ và cảm xúc mỗi ngày',
      'difficulty_index': 1,
    });

    return suggestions.take(5).toList();
  }

  static List<Map<String, dynamic>> _getDefaultSuggestions() {
    return [
      {
        'ten_thoi_quen': 'Uống nước mỗi sáng',
        'mo_ta': 'Bắt đầu ngày mới với 1 ly nước ấm',
        'difficulty_index': 0,
      },
      {
        'ten_thoi_quen': 'Đọc sách 20 phút',
        'mo_ta': 'Rèn luyện tư duy và kiến thức',
        'difficulty_index': 1,
      },
      {
        'ten_thoi_quen': 'Tập thể dục 30 phút',
        'mo_ta': 'Tăng cường sức khỏe và năng lượng',
        'difficulty_index': 2,
      },
      {
        'ten_thoi_quen': 'Thiền 10 phút',
        'mo_ta': 'Giảm stress và cân bằng cảm xúc',
        'difficulty_index': 0,
      },
      {
        'ten_thoi_quen': 'Ngủ đủ 8 tiếng',
        'mo_ta': 'Đảm bảo giấc ngủ chất lượng',
        'difficulty_index': 2,
      },
    ];
  }

  // ==================== PLANT XP ====================

  // Nếu bạn có hệ thống token, chỉnh hàm này để trả về token hợp lệ
  static Future<String?> getApiToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Lấy plant_xp của user từ backend
  static Future<Map<String, dynamic>?> getPlantXp() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/plant/xp'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Get plant XP error: $e');
      return null;
    }
  }

  /// Reset XP
  static Future<bool> resetPlantXp() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/plant/reset'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Reset plant error: $e');
      return false;
    }
  }

  // Cập nhật plant_xp cho user
  static Future<bool> updatePlantXp(int xp) async {
    try {
      final token = await getToken();
      final url = Uri.parse('$baseUrl/plant/xp');
      final resp = await http.post(url,
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          body: jsonEncode({'xp': xp}));

      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ==================== UPLOAD AVATAR ====================

  static Future<Map<String, dynamic>?> uploadAvatar({
    File? file,
    Uint8List? webBytes,
    String? filename,
  }) async {
    final token = await getToken();
    if (token == null) return null;
    final uri = Uri.parse('$baseUrl/me/avatar');
    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      if (kIsWeb) {
        if (webBytes == null) return null;
        final part = http.MultipartFile.fromBytes(
          'avatar',
          webBytes,
          filename: filename ?? 'avatar.png',
        );
        request.files.add(part);
      } else {
        if (file == null) return null;
        final part = await http.MultipartFile.fromPath(
          'avatar',
          file.path,
          filename: filename ?? file.path.split(Platform.pathSeparator).last,
        );
        request.files.add(part);
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return (data is Map<String, dynamic>) ? (data['user'] ?? data) : null;
      }
    } catch (e) {
      print('uploadAvatar error: $e');
    }
    return null;
  }

  // ==================== HTTP GET ====================
  static Future<dynamic> get(String endpoint) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No token found'};

      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('⚠️ GET ${response.statusCode}: ${response.body}');
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      print('❌ GET error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

// ==================== HTTP POST ====================
  static Future<dynamic> post(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No token found'};

      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print('⚠️ POST ${response.statusCode}: ${response.body}');
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      print('❌ POST error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
  // ==================== PROCRASTINATION API ====================

  /// Lấy danh sách alerts chưa đọc
  static Future<List<Map<String, dynamic>>> getProcrastinationAlerts() async {
    try {
      final token = await getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/procrastination/alerts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final alerts = data['data']['alerts'] as List;
          return alerts.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Get alerts error: $e');
      return [];
    }
  }

  /// Lấy phân tích tổng quan
  static Future<Map<String, dynamic>?> getProcrastinationAnalysis() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/procrastination/analysis'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('❌ Get analysis error: $e');
      return null;
    }
  }

  /// Đánh dấu alert đã đọc
  static Future<bool> markAlertAsRead(int alertId) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/procrastination/alerts/$alertId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Mark as read error: $e');
      return false;
    }
  }

  /// Phát hiện trì hoãn ngay bây giờ
  static Future<List<Map<String, dynamic>>> detectProcrastination() async {
    try {
      final token = await getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/procrastination/detect'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final alerts = data['data']['alerts'] as List;
          return alerts.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Detect procrastination error: $e');
      return [];
    }
  }
}
