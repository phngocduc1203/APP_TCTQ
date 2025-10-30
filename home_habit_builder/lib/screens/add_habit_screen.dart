import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final nameController = TextEditingController();
  final descController = TextEditingController();

  String habitType = 'daily';
  int selectedDifficulty = 0;
  int get totalSelectedDays {
    if (repeatType == 'weekly') return selectedWeekdays.length;
    if (repeatType == 'monthly') return selectedMonthdays.length;
    return 0;
  }

  static const List<Map<String, dynamic>> difficulties = [
    {'label': 'Dễ', 'xp': 5, 'canDaily': true},
    {
      'label': 'Trung bình',
      'xp': 10,
      'canDaily': false,
      'weekMin': 4,
      'monthMin': 14
    },
    {'label': 'Khó', 'xp': 20, 'canDaily': false, 'weekMin': 5, 'monthMin': 21},
    {
      'label': 'Rất khó',
      'xp': 30,
      'canDaily': false,
      'weekMin': 7,
      'monthMin': 28
    },
  ];

  int selectedDuration = 7;
  static const List<Map<String, dynamic>> durations = [
    {'days': 7, 'label': '1 tuần', 'xp': 210},
    {'days': 14, 'label': '2 tuần', 'xp': 420},
    {'days': 21, 'label': '21 ngày', 'xp': 630},
    {'days': 30, 'label': '1 tháng', 'xp': 900},
    {'days': 60, 'label': '2 tháng', 'xp': 1800},
    {'days': 90, 'label': '3 tháng', 'xp': 2700},
  ];

  String repeatType = 'daily';
  Set<int> selectedWeekdays = {};
  Set<int> selectedMonthdays = {};
  static const List<String> weekdayNames = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN'
  ];

  bool isLoading = false;
  bool showAISuggestions = false;

  // 🔥 THÊM 2 DANH SÁCH GỢI Ý RIÊNG BIỆT
  List<Map<String, dynamic>> personalizedSuggestions =
      []; // Gợi ý cá nhân (5 thói quen)
  List<Map<String, dynamic>> timeSuggestions =
      []; // Gợi ý theo thời gian (sáng/trưa/tối)

  String aiQuickSuggestion = '';
  bool isLoadingSuggestions = false; // Loading indicator cho AI

  int daysInMonth = 31;
  bool showNextMonth = false;

  @override
  void initState() {
    super.initState();
    _calculateDaysInMonth();
    _loadAllAISuggestions(); // 🔥 Load cả 2 loại gợi ý
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

  // 🔥 HÀM MỚI: Load cả 2 loại gợi ý AI
  Future<void> _loadAllAISuggestions() async {
    setState(() => isLoadingSuggestions = true);

    try {
      // Lấy thông tin user (nếu có)
      final userInfo = await ApiService.getUserInfo();
      final gender = (userInfo?['gender'] ?? 'Nam').toString();
      final age = userInfo?['age'] ?? 25;

      // 1️⃣ Gợi ý cá nhân hóa (5 thói quen với fallback)
      final personalized = await ApiService.getAIHabitSuggestions();

      // 2️⃣ Gợi ý theo thời gian (sáng/trưa/tối)
      final timeBase = await ApiService.getPersonalizedHabitSuggestions(
        gender: gender,
        age: age,
      );

      if (mounted) {
        setState(() {
          personalizedSuggestions = personalized;
          timeSuggestions = timeBase;
          isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      print('❌ Load AI suggestions error: $e');
      setState(() => isLoadingSuggestions = false);
    }
  }

  void applySuggestion(Map<String, dynamic> suggestion) {
    setState(() {
      nameController.text = suggestion['ten_thoi_quen'] ?? '';
      descController.text = suggestion['mo_ta'] ?? '';

      // 🔥 Tự động set độ khó nếu có
      if (suggestion.containsKey('difficulty_index')) {
        selectedDifficulty = suggestion['difficulty_index'] ?? 0;
      }

      showAISuggestions = false;
      _updateRepeatTypeBasedOnDifficulty();
    });

    // 🔥 Scroll lên đầu để user thấy đã apply
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Đã áp dụng: ${suggestion['ten_thoi_quen']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _updateRepeatTypeBasedOnDifficulty() {
    final diff = difficulties[selectedDifficulty];
    if (diff['canDaily'] == true) {
      repeatType = 'daily';
      selectedWeekdays.clear();
      selectedMonthdays.clear();
    } else {
      if (repeatType == 'daily') {
        repeatType = 'weekly';
      }
      selectedWeekdays.clear();
      selectedMonthdays.clear();
    }
  }

  int _getMinimumDays() {
    final diff = difficulties[selectedDifficulty];
    if (repeatType == 'weekly') return diff['weekMin'] ?? 0;
    if (repeatType == 'monthly') return diff['monthMin'] ?? 0;
    return 0;
  }

  bool _canSaveHabit() {
    if (habitType == 'challenge') return true;
    if (repeatType == 'daily') return true;

    final minDays = _getMinimumDays();
    if (repeatType == 'weekly') return selectedWeekdays.length >= minDays;
    if (repeatType == 'monthly') return selectedMonthdays.length >= minDays;
    return false;
  }

  int _calculateTotalXP() {
    if (habitType == 'challenge') {
      final duration =
          durations.firstWhere((d) => d['days'] == selectedDuration);
      return duration['xp'] as int;
    }
    return difficulties[selectedDifficulty]['xp'] as int;
  }

  Future<void> handleAdd() async {
    if (!_canSaveHabit()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn đủ ngày theo độ khó')),
      );
      return;
    }

    setState(() => isLoading = true);

    final habitData = {
      'ten_thoi_quen': nameController.text.trim(),
      'mo_ta': descController.text.trim(),
      'diem': difficulties[selectedDifficulty]['xp'],
      'repeat_type': repeatType,
      'repeat_data': repeatType == 'weekly'
          ? selectedWeekdays.join(',')
          : repeatType == 'monthly'
              ? selectedMonthdays.join(',')
              : null,
      'duration_days': selectedDuration,
      'is_challenge': habitType == 'challenge',
      'total_xp': _calculateTotalXP(),
    };

    final success = await ApiService.createHabit(habitData);
    setState(() => isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Thêm thói quen thành công!')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Không thể thêm thói quen.')));
    }
  }

  // ------------------- HIỂN THỊ UI -------------------
  @override
  Widget build(BuildContext context) {
    final canSave = _canSaveHabit();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm thói quen mới'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // 🔥 NÚT REFRESH AI
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới gợi ý AI',
            onPressed: isLoadingSuggestions ? null : _loadAllAISuggestions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('Tên thói quen', nameController),
            const SizedBox(height: 12),
            _buildTextField('Mô tả', descController, maxLines: 3),
            const SizedBox(height: 16),
            _buildHabitTypeSelector(),
            const SizedBox(height: 16),
            habitType == 'normal'
                ? _buildDifficultySelector()
                : _buildChallengeOptions(),
            const SizedBox(height: 16),
            if (habitType == 'normal') _buildRepeatSelector(),
            const SizedBox(height: 16),
            if (habitType == 'normal' && repeatType == 'weekly')
              _buildWeeklyPicker(_getMinimumDays()),
            if (habitType == 'normal' && repeatType == 'monthly')
              _buildMonthlyPicker(_getMinimumDays()),
            if (habitType == 'challenge') _buildXPInfo(),
            const SizedBox(height: 16),
            _buildSaveButton(canSave),
            const SizedBox(height: 24),

            // 🔥 PHẦN GỢI Ý AI MỚI (2 loại)
            _buildAISuggestionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) async {
            if (label == 'Tên thói quen' && value.isNotEmpty) {
              final suggestion =
                  await ApiService.getAiSuggestion(value, descController.text);
              if (mounted) {
                setState(() {
                  aiQuickSuggestion = suggestion;
                });
              }
            }
          },
        ),
        if (label == 'Mô tả' && aiQuickSuggestion.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.deepPurple.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: Colors.deepPurple, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      aiQuickSuggestion,
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // 🔥 PHẦN GỢI Ý AI MỚI - TÁCH THÀNH 2 TAB
  Widget _buildAISuggestionsSection() {
    if (isLoadingSuggestions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Đang tải gợi ý AI...',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Nếu cả 2 đều rỗng
    if (personalizedSuggestions.isEmpty && timeSuggestions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 40),
              const SizedBox(height: 8),
              const Text(
                'Không thể tải gợi ý AI',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Vui lòng kiểm tra kết nối hoặc API key',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadAllAISuggestions,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.deepPurple,
              tabs: const [
                Tab(icon: Icon(Icons.star), text: 'Gợi ý cho bạn'),
                Tab(icon: Icon(Icons.access_time), text: 'Theo thời gian'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 400, // Giới hạn chiều cao
            child: TabBarView(
              children: [
                _buildPersonalizedTab(),
                _buildTimeBasedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 1: Gợi ý cá nhân hóa (5 thói quen)
  Widget _buildPersonalizedTab() {
    if (personalizedSuggestions.isEmpty) {
      return const Center(
        child: Text('Không có gợi ý cá nhân hóa',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: personalizedSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = personalizedSuggestions[index];
        final difficulty = suggestion['difficulty_index'] ?? 0;
        final diffLabel = difficulties[difficulty]['label'];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getDifficultyColor(difficulty),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              suggestion['ten_thoi_quen'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(suggestion['mo_ta'] ?? ''),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(difficulty).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        diffLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: _getDifficultyColor(difficulty),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.add_circle, color: Colors.deepPurple),
            onTap: () => applySuggestion(suggestion),
          ),
        );
      },
    );
  }

  // TAB 2: Gợi ý theo thời gian (sáng/trưa/tối)
  Widget _buildTimeBasedTab() {
    if (timeSuggestions.isEmpty) {
      return const Center(
        child: Text('Không có gợi ý theo thời gian',
            style: TextStyle(color: Colors.grey)),
      );
    }

    Map<String, List<Map<String, dynamic>>> grouped = {
      'morning': [],
      'noon': [],
      'evening': [],
    };

    for (final s in timeSuggestions) {
      final name = (s['ten_thoi_quen'] ?? '').toString().toLowerCase();
      if (name.contains('sáng')) {
        grouped['morning']!.add(s);
      } else if (name.contains('trưa')) {
        grouped['noon']!.add(s);
      } else if (name.contains('tối')) {
        grouped['evening']!.add(s);
      } else {
        grouped['morning']!.add(s);
      }
    }

    return ListView(
      children: [
        for (final entry in grouped.entries)
          if (entry.value.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                entry.key == 'morning'
                    ? '🌅 Buổi sáng'
                    : entry.key == 'noon'
                        ? '🌞 Buổi trưa'
                        : '🌙 Buổi tối',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            ...entry.value.map((s) => Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(
                      s['ten_thoi_quen'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['mo_ta'] ?? ''),
                        if (s['loi_ich'] != null &&
                            s['loi_ich'].toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '✨ ${s['loi_ich']}',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: const Icon(Icons.add_circle_outline,
                        color: Colors.deepPurple),
                    onTap: () => applySuggestion(s),
                  ),
                )),
          ],
      ],
    );
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.red;
      case 3:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildHabitTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Loại thói quen',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            ChoiceChip(
              label: const Text('Thông thường'),
              selected: habitType == 'normal',
              onSelected: (val) => setState(() => habitType = 'normal'),
              selectedColor: Colors.deepPurple,
              labelStyle: TextStyle(
                  color:
                      habitType == 'normal' ? Colors.white : Colors.deepPurple),
            ),
            ChoiceChip(
              label: const Text('Thử thách'),
              selected: habitType == 'challenge',
              onSelected: (val) => setState(() => habitType = 'challenge'),
              selectedColor: Colors.orange,
              labelStyle: TextStyle(
                  color:
                      habitType == 'challenge' ? Colors.white : Colors.orange),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Độ khó',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(difficulties.length, (i) {
            final diff = difficulties[i];
            return ChoiceChip(
              label: Text('${diff['label']} (+${diff['xp']} XP)'),
              selected: selectedDifficulty == i,
              onSelected: (val) {
                setState(() {
                  selectedDifficulty = i;
                  _updateRepeatTypeBasedOnDifficulty();
                });
              },
              selectedColor: Colors.deepPurple,
              labelStyle: TextStyle(
                color:
                    selectedDifficulty == i ? Colors.white : Colors.deepPurple,
              ),
              backgroundColor: Colors.deepPurple.shade50,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRepeatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lặp lại',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Hàng ngày'),
              selected: repeatType == 'daily',
              onSelected: (val) => setState(() => repeatType = 'daily'),
              selectedColor: Colors.deepPurple,
              labelStyle: TextStyle(
                  color:
                      repeatType == 'daily' ? Colors.white : Colors.deepPurple),
            ),
            ChoiceChip(
              label: const Text('Hàng tuần'),
              selected: repeatType == 'weekly',
              onSelected: (val) => setState(() => repeatType = 'weekly'),
              selectedColor: Colors.deepPurple,
              labelStyle: TextStyle(
                  color: repeatType == 'weekly'
                      ? Colors.white
                      : Colors.deepPurple),
            ),
            ChoiceChip(
              label: const Text('Hàng tháng'),
              selected: repeatType == 'monthly',
              onSelected: (val) {
                setState(() {
                  repeatType = 'monthly';
                  _calculateDaysInMonth();
                });
              },
              selectedColor: Colors.deepPurple,
              labelStyle: TextStyle(
                  color: repeatType == 'monthly'
                      ? Colors.white
                      : Colors.deepPurple),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyPicker(int minDays) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final twoWeeks =
        List.generate(14, (i) => startOfWeek.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn ngày trong 2 tuần tới (ít nhất $minDays ngày)',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: twoWeeks.asMap().entries.map((entry) {
            final i = entry.key;
            final date = entry.value;
            final isPast =
                date.isBefore(DateTime(now.year, now.month, now.day));
            final weekdayName = weekdayNames[date.weekday - 1];
            final display = '$weekdayName\n${date.day}';
            final index = i + 1;
            final isSelected = selectedWeekdays.contains(index);

            return GestureDetector(
              onTap: isPast
                  ? null
                  : () {
                      setState(() {
                        if (isSelected) {
                          selectedWeekdays.remove(index);
                        } else {
                          selectedWeekdays.add(index);
                        }
                      });
                    },
              child: Container(
                width: 48,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isPast
                      ? Colors.grey.shade200
                      : (isSelected ? Colors.deepPurple : Colors.white),
                  border: Border.all(
                    color: isPast
                        ? Colors.grey
                        : (isSelected
                            ? Colors.deepPurple
                            : Colors.deepPurple.shade100),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  display,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isPast
                        ? Colors.grey
                        : (isSelected ? Colors.white : Colors.deepPurple),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                for (int i = 0; i < twoWeeks.length; i++) {
                  final date = twoWeeks[i];
                  if (!date.isBefore(DateTime(now.year, now.month, now.day))) {
                    selectedWeekdays.add(i + 1);
                  }
                }

                int currentCount = selectedWeekdays.length;
                if (currentCount < minDays) {
                  int extra = minDays - currentCount;
                  for (int i = 0; i < extra; i++) {
                    selectedWeekdays.add(14 + i + 1);
                  }
                }
              });
            },
            icon: const Icon(Icons.select_all, size: 16),
            label: const Text('Chọn tất cả / Đủ ngày tối thiểu'),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyPicker(int minDays) {
    final now = DateTime.now();
    final currentDay = now.day;
    final currentMonth = now.month;
    final currentYear = now.year;

    final displayMonth = showNextMonth ? currentMonth + 1 : currentMonth;
    final displayYear = (displayMonth > 12) ? currentYear + 1 : currentYear;
    final daysInMonth = DateTime(displayYear, (displayMonth % 12) + 1, 0).day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              showNextMonth
                  ? 'Chọn ngày trong THÁNG SAU'
                  : 'Chọn ngày trong THÁNG NÀY',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  showNextMonth = !showNextMonth;
                });
              },
              child: Text(showNextMonth ? '← Tháng này' : 'Tháng sau →'),
            ),
          ],
        ),
        Text(
          '(ít nhất $minDays ngày, các ngày đã qua bị khóa)',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(daysInMonth, (i) {
            final day = i + 1;
            final date = DateTime(displayYear, displayMonth, day);
            final isPast = !showNextMonth &&
                date.isBefore(DateTime(currentYear, currentMonth, currentDay));
            final isSelected = selectedMonthdays.contains(day);

            return GestureDetector(
              onTap: isPast
                  ? null
                  : () {
                      setState(() {
                        if (isSelected) {
                          selectedMonthdays.remove(day);
                        } else {
                          selectedMonthdays.add(day);
                        }
                      });
                    },
              child: Container(
                width: 45,
                height: 45,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isPast
                      ? Colors.grey.shade200
                      : (isSelected ? Colors.deepPurple : Colors.white),
                  border: Border.all(
                    color: isPast
                        ? Colors.grey
                        : (isSelected
                            ? Colors.deepPurple
                            : Colors.deepPurple.shade100),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isPast
                        ? Colors.grey
                        : (isSelected ? Colors.white : Colors.deepPurple),
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                for (int day = 1; day <= daysInMonth; day++) {
                  final date = DateTime(displayYear, displayMonth, day);
                  final isPast = !showNextMonth &&
                      date.isBefore(
                          DateTime(currentYear, currentMonth, currentDay));
                  if (!isPast) selectedMonthdays.add(day);
                }

                int currentCount = selectedMonthdays.length;
                if (currentCount < minDays) {
                  int extra = minDays - currentCount;
                  for (int i = 0; i < extra; i++) {
                    selectedMonthdays.add(daysInMonth + i + 1);
                  }
                }
              });
            },
            icon: const Icon(Icons.select_all, size: 16),
            label: const Text('Chọn tất cả'),
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Thời lượng thử thách',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(durations.length, (i) {
            final dur = durations[i];
            return ChoiceChip(
              label: Text('${dur['label']} (+${dur['xp']} XP)'),
              selected: selectedDuration == dur['days'],
              onSelected: (selected) {
                setState(() {
                  selectedDuration = dur['days'];
                });
              },
              selectedColor: Colors.orange,
              labelStyle: TextStyle(
                color: selectedDuration == dur['days']
                    ? Colors.white
                    : Colors.orange,
                fontSize: 12,
              ),
              backgroundColor: Colors.orange.shade50,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildXPInfo() {
    final xp = _calculateTotalXP();
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text('Tổng XP: +$xp',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.deepPurple)),
      ),
    );
  }

  Widget _buildSaveButton(bool canSave) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : (canSave ? handleAdd : null),
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.check_circle_outline),
        label: Text(isLoading ? 'Đang lưu...' : 'Lưu thói quen'),
        style: ElevatedButton.styleFrom(
          backgroundColor: canSave
              ? const Color(0xFF270267)
              : const Color(0xFF270267).withOpacity(0.5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
