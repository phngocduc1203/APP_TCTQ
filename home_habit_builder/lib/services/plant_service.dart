// lib/services/plant_service.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

enum PlantHealth { healthy, wilted, dead }

class PlantService {
  static const _keyXp = 'plant_xp';
  static const _keyLastWatered = 'plant_last_watered';
  static const _keyConsecutiveDays = 'plant_consecutive_days';
  static const String baseUrl = 'http://192.168.1.26:8000/api/v1';

  // ✅ SỬA: ĐỒNG NHẤT MAX XP
  static const int maxXp = 1200; // ← Đổi từ 120 → 1200
  static const int dailyMaxXp = 200;
  static const int xpPerHabit = 50;
  static const int streakBonusXp = 10;
  // ✅ SỬA: ĐỒNG BỘ SERVER
  // static Future<String?> _getToken() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   return prefs.getString('auth_token');
  // }

  // 🔓 Public helper để lấy token từ SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? prefs.getString('token');
    print('🔑 Token in PlantService.getToken(): $token');
    return token;
  }

  // ✅ SỬA: ĐỒNG NHẤT STAGES
  static Map<String, dynamic> getStageInfo(int xp) {
    if (xp < 200) {
      return {
        'stage': 'seed',
        'name': 'Hạt giống',
        'description': 'Cây của bạn đang nảy mầm',
        'nextStage': 'Mọc mầm',
        'nextXp': 200,
        'progress': (xp / 200).clamp(0.0, 1.0),
      };
    }
    if (xp < 450) {
      return {
        'stage': 'sprout',
        'name': 'Mọc mầm',
        'description': 'Chồi non đang phát triển',
        'nextStage': 'Mọc lá',
        'nextXp': 450,
        'progress': ((xp - 200) / 250).clamp(0.0, 1.0),
      };
    }
    if (xp < 750) {
      return {
        'stage': 'leaves',
        'name': 'Mọc lá',
        'description': 'Cây đang xanh tốt',
        'nextStage': 'Mọc cành',
        'nextXp': 750,
        'progress': ((xp - 450) / 300).clamp(0.0, 1.0),
      };
    }
    if (xp < 1050) {
      return {
        'stage': 'branches',
        'name': 'Mọc cành',
        'description': 'Cây đang lớn mạnh',
        'nextStage': 'Ra hoa',
        'nextXp': 1050,
        'progress': ((xp - 750) / 300).clamp(0.0, 1.0),
      };
    }
    return {
      'stage': 'flower',
      'name': 'Ra hoa',
      'description': 'Cây của bạn đã hoàn thiện!',
      'nextStage': null,
      'nextXp': maxXp,
      'progress': ((xp - 1050) / 150).clamp(0.0, 1.0),
    };
  }

  static Future<Map<String, dynamic>> addXp(int amount) async {
    if (amount <= 0) return {'success': false, 'message': 'XP không hợp lệ'};

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Kiểm tra daily limit
    final dailyXp = await getDailyXp();
    if (dailyXp >= dailyMaxXp) {
      return {
        'success': false,
        'message': 'Đã đạt giới hạn XP hôm nay ($dailyMaxXp XP)',
        'totalXp': await getLocalXp(),
        'dailyXp': dailyXp,
      };
    }

    final actualXp =
        (dailyXp + amount > dailyMaxXp) ? dailyMaxXp - dailyXp : amount;

    // ✅ Cập nhật streak TRƯỚC
    await _updateConsecutiveDays(prefs, todayStr);

    // Sau đó set lastWatered
    await prefs.setString(_keyLastWatered, todayStr);

    // Tính XP mới
    final currentXp = await getLocalXp();
    var newXp = (currentXp + actualXp).clamp(0, maxXp);

    // Tính streak bonus
    final consecutive = await getConsecutiveDays();
    int bonusXp = 0;
    if (consecutive > 0 && consecutive % 7 == 0) {
      bonusXp = streakBonusXp;
      newXp = (newXp + bonusXp).clamp(0, maxXp);
    }

    // ✅ LƯU LOCAL TRƯỚC KHI SYNC
    await prefs.setInt(_keyXp, newXp);
    final newDailyXp = dailyXp + actualXp;
    await prefs.setInt('daily_xp_$todayStr', newDailyXp);

    // ✅ ĐỒNG BỘ VỚI SERVER
    print('🔄 Syncing XP to server: $newXp'); // ← Debug log
    final syncSuccess = await syncXpToServer(newXp);
    print('✅ Sync result: $syncSuccess'); // ← Debug log

    return {
      'success': true,
      'xpGained': actualXp,
      'bonusXp': bonusXp,
      'totalXp': newXp,
      'dailyXp': newDailyXp,
      'remainingDaily': dailyMaxXp - newDailyXp,
      'consecutive': consecutive,
      'isMaxed': newXp >= maxXp,
      'syncSuccess': syncSuccess,
      'message': bonusXp > 0
          ? '+$actualXp XP + $bonusXp bonus (Streak $consecutive ngày)!'
          : actualXp < amount
              ? 'Đạt giới hạn hôm nay! +$actualXp XP'
              : '+$actualXp XP',
    };
  }

  // ✅ GIỮ NGUYÊN _updateConsecutiveDays (đã đúng logic)
  static Future<void> _updateConsecutiveDays(
      SharedPreferences prefs, String todayStr) async {
    final lastWatered = prefs.getString(_keyLastWatered);
    if (lastWatered != null && lastWatered != todayStr) {
      try {
        final lastDate = DateTime.parse(lastWatered);
        final today = DateTime.parse(todayStr);
        final diff = today.difference(lastDate).inDays;

        if (diff == 1) {
          final consecutive = (prefs.getInt(_keyConsecutiveDays) ?? 0) + 1;
          await prefs.setInt(_keyConsecutiveDays, consecutive);
        } else if (diff > 1) {
          await prefs.setInt(_keyConsecutiveDays, 1);
        }
      } catch (_) {
        await prefs.setInt(_keyConsecutiveDays, 1);
      }
    } else if (lastWatered == null) {
      await prefs.setInt(_keyConsecutiveDays, 1);
    }
  }

  // ✅ CÁC HÀM KHÁC GIỮ NGUYÊN
  static Future<int> getLocalXp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyXp) ?? 0;
  }

  static Future<int> getDailyXp() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_keyLastWatered);
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    if (lastDate == todayStr) {
      return prefs.getInt('daily_xp_$todayStr') ?? 0;
    }
    return 0;
  }

  static Future<int> getConsecutiveDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyConsecutiveDays) ?? 0;
  }

  static Future<double> getProgress() async {
    final xp = await getLocalXp();
    return (xp / maxXp).clamp(0.0, 1.0);
  }

  Future<void> resetLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyXp);
    await prefs.remove(_keyLastWatered);
    await prefs.remove(_keyConsecutiveDays);

    final keys =
        prefs.getKeys().where((k) => k.startsWith('daily_xp_')).toList();
    for (var key in keys) {
      await prefs.remove(key);
    }
  }

  /// ✅ SỬA: GỬI XP TỔNG (không phải tăng thêm)
  static Future<bool> syncXpToServer(int totalXp) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final res = await http.post(
        Uri.parse('$baseUrl/plant/update-xp'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: {'xp': totalXp.toString()},
      );

      print('🌿 syncXpToServer → ${res.statusCode}');
      return res.statusCode == 200;
    } catch (e) {
      print('syncXpToServer error: $e');
      return false;
    }
  }

  /// ✅ SỬA: LẤY XP TỪ SERVER
  static Future<int> getXpFromServer() async {
    try {
      final token = await getToken();
      if (token == null) {
        print('❌ No token for getXpFromServer');
        return 0;
      }

      final res = await http.get(
        Uri.parse('$baseUrl/plant/xp'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('🌿 getXpFromServer → ${res.statusCode}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final xp = data['xp'] ?? 0;
        print('🌱 XP from server: $xp');
        return xp;
      }
      return 0;
    } catch (e) {
      print('getXpFromServer error: $e');
      return 0;
    }
  }

  static Future<bool> resetXp() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final res = await http.post(
        Uri.parse('$baseUrl/plant/reset'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('🌿 resetXp → ${res.statusCode}');
      return res.statusCode == 200;
    } catch (e) {
      print('resetXp error: $e');
      return false;
    }
  }

  /// ✅ THÊM: Kiểm tra xem người dùng có nhận được bonus streak không
  static Future<Map<String, dynamic>> checkStreakBonus() async {
    final consecutive = await getConsecutiveDays();
    final isBonusDay = consecutive > 0 && consecutive % 7 == 0;
    return {
      'consecutive': consecutive,
      'isBonusDay': isBonusDay,
      'bonusXp': isBonusDay ? streakBonusXp : 0,
    };
  }
}
