import 'dart:async';
import 'dart:convert';

import '../models/procrastination_alert.dart';
import '../models/procrastination_analysis.dart';
import 'api_service.dart';

class ProcrastinationService {
  const ProcrastinationService();

  /// Trả về danh sách cảnh báo chưa đọc từ backend.
  Future<List<ProcrastinationAlert>> getUnreadAlerts() async {
    try {
      final res = await ApiService.get('/procrastination/alerts/unread');
      if (res == null) return <ProcrastinationAlert>[];
      final data = res['data'];
      if (data is List) {
        return data
            .map((e) =>
                ProcrastinationAlert.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return <ProcrastinationAlert>[];
    } catch (e) {
      // propagate to caller or return empty list
      rethrow;
    }
  }

  /// Trả về phân tích tổng quan từ backend.
  Future<ProcrastinationAnalysis?> getAnalysis() async {
    try {
      final res = await ApiService.get('/procrastination/analysis');
      if (res == null) return null;
      final data = res['data'];
      if (data is Map) {
        return ProcrastinationAnalysis.fromJson(
            Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Kích hoạt quét AI trên backend.
  Future<void> detectProcrastination() async {
    try {
      final res = await ApiService.post('/procrastination/detect', {});
      // nếu backend trả lỗi, ApiService nên ném exception; nếu trả success, chỉ return
      return;
    } catch (e) {
      rethrow;
    }
  }

  /// Đánh dấu tất cả cảnh báo là đã đọc trên backend.
  Future<void> markAllAlertsAsRead() async {
    try {
      await ApiService.post('/procrastination/alerts/mark-all-read', {});
      return;
    } catch (e) {
      rethrow;
    }
  }

  /// Đánh dấu 1 cảnh báo là đã đọc trên backend.
  Future<void> markAlertAsRead(int id) async {
    try {
      await ApiService.post('/procrastination/alerts/$id/mark-read', {});
      return;
    } catch (e) {
      rethrow;
    }
  }
}
