// lib/screens/procrastination_screen.dart

import 'package:flutter/material.dart';
import '../services/procrastination_service.dart';
import '../models/procrastination_alert.dart';
import '../models/procrastination_analysis.dart';

class ProcrastinationScreen extends StatefulWidget {
  const ProcrastinationScreen({Key? key}) : super(key: key);

  @override
  State<ProcrastinationScreen> createState() => _ProcrastinationScreenState();
}

class _ProcrastinationScreenState extends State<ProcrastinationScreen> {
  final ProcrastinationService _service = ProcrastinationService();

  List<ProcrastinationAlert> _alerts = [];
  ProcrastinationAnalysis? _analysis;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Use instance methods on _service (keeps it consistent whether methods are instance or static)
      final alerts = await _service.getUnreadAlerts();
      final analysis = await _service.getAnalysis();

      setState(() {
        _alerts = alerts;
        _analysis = analysis;
      });
    } catch (e) {
      // show error (keep message short)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _detectNow() async {
    setState(() => _isLoading = true);

    try {
      await _service.detectProcrastination();
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Đã quét xong!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Phát Hiện Trì Hoãn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Analysis Card
                  if (_analysis != null) _buildAnalysisCard(),
                  const SizedBox(height: 16),

                  // Detect Button
                  _buildDetectButton(),
                  const SizedBox(height: 24),

                  // Alerts List
                  _buildAlertsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildAnalysisCard() {
    final analysis = _analysis!;

    final Color bgColor;
    if (analysis.isDanger) {
      bgColor = Colors.red.shade50;
    } else if (analysis.isWarning) {
      bgColor = Colors.orange.shade50;
    } else {
      bgColor = Colors.green.shade50;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: analysis.isDanger
              ? [Colors.red.shade400, Colors.red.shade600]
              : analysis.isWarning
                  ? [Colors.orange.shade400, Colors.orange.shade600]
                  : [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                analysis.statusIcon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Phân Tích AI',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            analysis.message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Tổng', analysis.totalHabits.toString()),
              _buildStatItem('Nguy hiểm', analysis.dangerHabits.toString()),
              _buildStatItem('Cảnh báo', analysis.warningHabits.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildDetectButton() {
    return ElevatedButton.icon(
      onPressed: _detectNow,
      icon: const Icon(Icons.search),
      label: const Text('Quét Ngay Bây Giờ'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cảnh Báo (${_alerts.length})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_alerts.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await _service.markAllAlertsAsRead();
                  await _loadData();
                },
                child: const Text('Đánh dấu tất cả'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_alerts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: const [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'Không có cảnh báo nào! 🎉',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          )
        else
          ..._alerts.map((alert) => _buildAlertCard(alert)).toList(),
      ],
    );
  }

  Widget _buildAlertCard(ProcrastinationAlert alert) {
    Color borderColor;
    Color bgColor;

    if (alert.isCritical) {
      borderColor = Colors.red;
      bgColor = Colors.red.shade50;
    } else if (alert.isWarning) {
      borderColor = Colors.orange;
      bgColor = Colors.orange.shade50;
    } else {
      borderColor = Colors.blue;
      bgColor = Colors.blue.shade50;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  alert.severityIcon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.habitName ?? 'Thói quen',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    await _service.markAlertAsRead(alert.id);
                    await _loadData();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert.message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '${alert.daysDelayed} ngày chưa hoàn thành',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
