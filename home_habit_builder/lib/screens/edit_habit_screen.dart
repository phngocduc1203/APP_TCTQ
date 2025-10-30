import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditHabitScreen extends StatefulWidget {
  final Map<String, dynamic> habit;
  const EditHabitScreen({super.key, required this.habit});

  @override
  State<EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends State<EditHabitScreen> {
  late TextEditingController nameController;
  late TextEditingController descController;
  late bool isChallenge;
  late int selectedDuration;
  late String repeatType;
  Set<int> selectedWeekdays = {};
  Set<int> selectedMonthdays = {};
  bool showNextMonth = false;
  int daysInMonth = 31;

  // Giả lập số ngày đã hoàn thành (ví dụ: hôm qua đã làm 1 ngày)
  Set<DateTime> completedDays = {};

  static const List<String> weekdayNames = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN'
  ];

  @override
  void initState() {
    super.initState();
    final h = widget.habit;

    nameController =
        TextEditingController(text: h['ten_thoi_quen'] ?? h['name'] ?? '');
    descController = TextEditingController(text: h['mo_ta'] ?? '');
    isChallenge = (h['is_challenge'] == true) || (h['type'] == 'challenge');
    selectedDuration = (h['duration_days'] is int)
        ? h['duration_days'] as int
        : int.tryParse('${h['duration_days']}') ?? 7;
    repeatType = (h['repeat_type'] as String?) ?? 'daily';

    // Weekly
    if (h['repeat_data'] is String && (h['repeat_data'] as String).isNotEmpty) {
      try {
        selectedWeekdays = (h['repeat_data'] as String)
            .split(',')
            .map((s) => int.tryParse(s) ?? 0)
            .where((v) => v > 0)
            .toSet();
      } catch (_) {}
    }

    _calculateDaysInMonth();
  }

  void _calculateDaysInMonth() {
    final now = DateTime.now();
    final baseMonth = showNextMonth
        ? (now.month == 12
            ? DateTime(now.year + 1, 1)
            : DateTime(now.year, now.month + 1))
        : DateTime(now.year, now.month);
    final nextMonth = (baseMonth.month == 12)
        ? DateTime(baseMonth.year + 1, 1, 1)
        : DateTime(baseMonth.year, baseMonth.month + 1, 1);
    final lastDay = nextMonth.subtract(const Duration(days: 1)).day;

    setState(() {
      daysInMonth = lastDay;
    });
  }

  int get totalDays =>
      selectedWeekdays.length + selectedMonthdays.length + completedDays.length;
  double get progress =>
      completedDays.isEmpty ? 0 : completedDays.length / totalDays;

  Future<void> _save() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên thói quen')),
      );
      return;
    }

    final success = await ApiService.updateHabit(
      widget.habit['id'] as int,
      name: name,
      description: descController.text.trim(),
      repeatType: repeatType,
      repeatData: repeatType == 'weekly'
          ? selectedWeekdays.join(',')
          : repeatType == 'monthly'
              ? selectedMonthdays.join(',')
              : null,
      durationDays: selectedDuration,
      isChallenge: isChallenge,
    );

    if (success == 'Cập nhật thành công') {
      Navigator.pop(context, totalDays); // gửi tổng ngày đã chọn
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
    }
  }

  void _selectAllWeekdays(int minDays) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final twoWeeks =
        List.generate(14, (i) => startOfWeek.add(Duration(days: i)));

    setState(() {
      selectedWeekdays.clear();
      for (int i = 0; i < twoWeeks.length; i++) {
        if (!twoWeeks[i].isBefore(DateTime(now.year, now.month, now.day))) {
          selectedWeekdays.add(i + 1);
        }
      }
      while (selectedWeekdays.length < minDays) {
        selectedWeekdays.add(selectedWeekdays.length + 1);
      }
    });
  }

  void _selectAllMonthdays(int minDays) {
    final now = DateTime.now();
    final displayMonth = showNextMonth ? now.month + 1 : now.month;
    final displayYear = (displayMonth > 12) ? now.year + 1 : now.year;
    final daysInMonth = DateTime(displayYear, (displayMonth % 12) + 1, 0).day;

    setState(() {
      selectedMonthdays.clear();
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(displayYear, displayMonth, day);
        final isPast = !showNextMonth &&
            date.isBefore(DateTime(now.year, now.month, now.day));
        if (!isPast) selectedMonthdays.add(day);
      }

      while (selectedMonthdays.length < minDays) {
        selectedMonthdays.add(selectedMonthdays.length + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final minDays = 3;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Chỉnh sửa thói quen',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Lưu',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên thói quen'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Mô tả'),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Đây là thử thách (Challenge)?'),
              value: isChallenge,
              onChanged: (v) => setState(() => isChallenge = v),
              activeColor: Colors.deepPurple,
            ),
            const SizedBox(height: 16),
            if (isChallenge) ...[
              const Text('Số ngày cam kết'),
              const SizedBox(height: 8),
              DropdownButton<int>(
                value: selectedDuration,
                items: [7, 14, 21, 30, 60]
                    .map((d) =>
                        DropdownMenuItem(value: d, child: Text('$d ngày')))
                    .toList(),
                onChanged: (v) => setState(() {
                  if (v != null) selectedDuration = v;
                }),
              ),
            ] else ...[
              const Text('Lặp lại'),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'daily', label: Text('Hàng ngày')),
                  ButtonSegment(value: 'weekly', label: Text('Hàng tuần')),
                  ButtonSegment(value: 'monthly', label: Text('Hàng tháng')),
                ],
                selected: {repeatType},
                onSelectionChanged: (s) => setState(() => repeatType = s.first),
              ),
              if (repeatType == 'weekly') ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    final now = DateTime.now();
                    final startOfWeek =
                        now.subtract(Duration(days: now.weekday - 1));
                    final date = startOfWeek.add(Duration(days: i));
                    final isPast =
                        date.isBefore(DateTime(now.year, now.month, now.day));
                    final selected = selectedWeekdays.contains(day);

                    return FilterChip(
                      label: Text(weekdayNames[i]),
                      selected: selected,
                      onSelected: isPast
                          ? null
                          : (v) {
                              setState(() {
                                if (v)
                                  selectedWeekdays.add(day);
                                else
                                  selectedWeekdays.remove(day);
                              });
                            },
                    );
                  }),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _selectAllWeekdays(minDays),
                    icon: const Icon(Icons.select_all, size: 16),
                    label: const Text('Chọn tất cả / Đủ ngày tối thiểu'),
                  ),
                ),
              ],
              if (repeatType == 'monthly') ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(daysInMonth, (i) {
                    final day = i + 1;
                    final now = DateTime.now();
                    final date = DateTime(now.year, now.month, day);
                    final isPast =
                        date.isBefore(DateTime(now.year, now.month, now.day));
                    final selected = selectedMonthdays.contains(day);

                    return GestureDetector(
                      onTap: isPast
                          ? null
                          : () {
                              setState(() {
                                if (selected)
                                  selectedMonthdays.remove(day);
                                else
                                  selectedMonthdays.add(day);
                              });
                            },
                      child: Container(
                        width: 45,
                        height: 45,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? Colors.deepPurple : Colors.white,
                          border: Border.all(
                            color: selected
                                ? Colors.deepPurple
                                : Colors.deepPurple.shade100,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$day',
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.deepPurple,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _selectAllMonthdays(minDays),
                    icon: const Icon(Icons.select_all, size: 16),
                    label: const Text('Chọn tất cả / Đủ ngày tối thiểu'),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 16),
            Text('Tiến độ: ${completedDays.length} / $totalDays ngày'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.deepPurple.shade100,
              color: Colors.deepPurple,
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }
}
