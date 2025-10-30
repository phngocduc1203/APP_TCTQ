import 'dart:async';
import 'package:flutter/material.dart';
import '../services/plant_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/lotus_plant_widget.dart';
import '../services/plant_update_service.dart';
import '../l10n/app_localizations.dart';

class PlantScreen extends StatefulWidget {
  const PlantScreen({super.key});

  @override
  State<PlantScreen> createState() => _PlantScreenState();
}

class _PlantScreenState extends State<PlantScreen> with WidgetsBindingObserver {
  int currentXp = 0;
  int dailyXp = 0;
  int consecutiveDays = 0;
  bool isLoading = true;
  PlantHealth health = PlantHealth.healthy;
  DateTime? lastActionDate;
  StreamSubscription? _plantUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _loadPlantData();
    _plantUpdateSubscription = PlantUpdateService().plantUpdates.listen((_) {
      _loadPlantData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _plantUpdateSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPlantData();
    }
  }

  Future<void> _loadPlantData() async {
    setState(() => isLoading = true);

    try {
      final xpFromServer = await PlantService.getXpFromServer();
      final prefs = await SharedPreferences.getInstance();
      final xpFromLocal = prefs.getInt('plant_xp') ?? 0;
      final xp = xpFromServer > 0 ? xpFromServer : xpFromLocal;

      final consecutive = await PlantService.getConsecutiveDays();
      final daily = await PlantService.getDailyXp();

      final lastStr = prefs.getString('plant_last_watered');
      DateTime? lastDate;
      if (lastStr != null) {
        try {
          lastDate = DateTime.parse(lastStr);
        } catch (e) {
          lastDate = null;
        }
      }

      setState(() {
        currentXp = xp;
        dailyXp = daily;
        consecutiveDays = consecutive;
        lastActionDate = lastDate;
        isLoading = false;
      });

      _updateHealthFromLastAction();
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _updateHealthFromLastAction() async {
    if (lastActionDate == null) {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getString('plant_last_watered');
      if (last != null) {
        try {
          lastActionDate = DateTime.parse(last);
        } catch (e) {
          setState(() => health = PlantHealth.wilted);
          return;
        }
      } else {
        setState(() => health = PlantHealth.wilted);
        return;
      }
    }

    final diffDays = DateTime.now().difference(lastActionDate!).inDays;

    if (diffDays >= 3) {
      setState(() => health = PlantHealth.dead);
    } else if (diffDays >= 1) {
      setState(() => health = PlantHealth.wilted);
    } else {
      setState(() => health = PlantHealth.healthy);
    }
  }

  Future<void> _showResetDialog() async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('⚠️ ${t.resetPlant}'),
        content: Text(
          t.confirmResetPlant, // bạn cần thêm key này vào arb: "Bạn có chắc muốn đặt lại cây về trạng thái ban đầu?\n\nMọi tiến trình sẽ bị xóa!"
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t.resetPlant),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await PlantService.resetXp();
      if (ok) {
        await PlantService().resetLocalData();
        final prefs = await SharedPreferences.getInstance();
        final lastStr = prefs.getString('plant_last_watered');
        DateTime? newLastDate = lastStr != null
            ? DateTime.tryParse(lastStr) ?? DateTime.now()
            : DateTime.now();

        setState(() {
          currentXp = 0;
          dailyXp = 0;
          consecutiveDays = 0;
          health = PlantHealth.healthy;
          lastActionDate = newLastDate;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.resetPlantSuccess),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.resetPlantFail)),
          );
        }
      }
    }
  }

  Map<String, dynamic> _getStageInfoWithColor(int xp) {
    final stageInfo = PlantService.getStageInfo(xp);
    Color color;
    switch (stageInfo['stage']) {
      case 'seed':
        color = Colors.brown;
        break;
      case 'sprout':
        color = Colors.lightGreen;
        break;
      case 'leaves':
        color = Colors.green;
        break;
      case 'branches':
        color = Colors.teal;
        break;
      case 'flower':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }
    return {...stageInfo, 'color': color};
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final stageInfo = _getStageInfoWithColor(currentXp);
    final progressPercent = ((currentXp / PlantService.maxXp) * 100).toInt();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.myPlant),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlantData,
            tooltip: t.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            onPressed: _showResetDialog,
            tooltip: t.resetPlant,
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPlantData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Plant Widget
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: LotusPlantWidget(
                          xp: currentXp,
                          maxXp: PlantService.maxXp,
                          showDetails: true,
                          health: health,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Stats Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.calendar_today,
                              title: t.today,
                              value: '$dailyXp/${PlantService.dailyMaxXp}',
                              subtitle: t.xp,
                              color: Colors.blue,
                              progress: dailyXp / PlantService.dailyMaxXp,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.local_fire_department,
                              title: t.streak,
                              value: '$consecutiveDays',
                              subtitle: t.days,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.trending_up,
                              title: t.progress,
                              value: '$progressPercent%',
                              subtitle: t.completed,
                              color: Colors.green,
                              progress: currentXp / PlantService.maxXp,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.stars,
                              title: t.totalXp,
                              value: '$currentXp',
                              subtitle: '/${PlantService.maxXp}',
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Growth Tips
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (stageInfo['color'] as Color).withOpacity(0.1),
                              (stageInfo['color'] as Color).withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                (stageInfo['color'] as Color).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: stageInfo['color'] as Color,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  t.growthTips,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: stageInfo['color'] as Color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTipItem(
                              icon: Icons.check_circle_outline,
                              text: t.tipCompleteHabit(PlantService.xpPerHabit),
                            ),
                            _buildTipItem(
                              icon: Icons.flash_on,
                              text: t.tipDailyLimit(PlantService.dailyMaxXp),
                            ),
                            _buildTipItem(
                              icon: Icons.local_fire_department,
                              text:
                                  t.tipStreakBonus(PlantService.streakBonusXp),
                            ),
                            _buildTipItem(
                              icon: Icons.timer,
                              text: t.tipDaysToMax(
                                  ((PlantService.maxXp - currentXp) /
                                          PlantService.dailyMaxXp)
                                      .ceil()),
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Stage Timeline
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.stages,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildStageItem(
                                'seed', t.stageSeed, 0, 200, Colors.brown),
                            _buildStageItem('sprout', t.stageSprout, 200, 450,
                                Colors.lightGreen),
                            _buildStageItem('leaves', t.stageLeaves, 450, 750,
                                Colors.green),
                            _buildStageItem('branches', t.stageBranches, 750,
                                1050, Colors.teal),
                            _buildStageItem('flower', t.stageFlower, 1050, 1200,
                                Colors.purple,
                                isLast: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    double? progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipItem({
    required IconData icon,
    required String text,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageItem(
    String stage,
    String name,
    int minXp,
    int maxXp,
    Color color, {
    bool isLast = false,
  }) {
    final isCompleted = currentXp >= maxXp;
    final isActive = currentXp >= minXp && currentXp < maxXp;
    final progress = isActive
        ? ((currentXp - minXp) / (maxXp - minXp)).clamp(0.0, 1.0)
        : isCompleted
            ? 1.0
            : 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted || isActive ? color : Colors.grey[200],
                  border: Border.all(
                    color: isActive ? color : Colors.grey[300]!,
                    width: isActive ? 3 : 2,
                  ),
                ),
                child: Icon(
                  isCompleted ? Icons.check : Icons.circle,
                  color:
                      isCompleted || isActive ? Colors.white : Colors.grey[400],
                  size: isCompleted ? 24 : 16,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: isCompleted ? color : Colors.grey[300],
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isCompleted || isActive ? color : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$minXp - $maxXp XP',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${((progress * 100).toInt())}% ${AppLocalizations.of(context)!.completed}',
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
