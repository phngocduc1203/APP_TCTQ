// lib/widgets/lotus_plant_widget.dart
import 'package:flutter/material.dart';
//import 'dart:math' as math;
import '../services/plant_service.dart';

class LotusPlantWidget extends StatefulWidget {
  final int xp;
  final int maxXp;
  final bool showDetails;
  final PlantHealth health;

  const LotusPlantWidget({
    super.key,
    required this.xp,
    this.maxXp = 1200,
    this.showDetails = true,
    this.health = PlantHealth.healthy,
  });

  @override
  State<LotusPlantWidget> createState() => _LotusPlantWidgetState();
}

class _LotusPlantWidgetState extends State<LotusPlantWidget>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _glowController;
  late Animation<double> _progressAnim;
  late int _oldXp;

  @override
  void initState() {
    super.initState();
    _oldXp = widget.xp;

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _setAnimation();
    _progressController.forward();
  }

  void _setAnimation() {
    final begin = (_oldXp / widget.maxXp).clamp(0.0, 1.0);
    final end = (widget.xp / widget.maxXp).clamp(0.0, 1.0);
    _progressAnim = Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
  }

  Map<String, dynamic> _getStageInfo(int xp) {
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

  // ✅ Map stage name to image file name
  String _getImageStageName(String stage) {
    switch (stage) {
      case 'seed':
        return 'seed';
      case 'sprout':
        return 'sprout';
      case 'leaves':
        return 'young';
      case 'branches':
        return 'mature';
      case 'flower':
        return 'flower';
      default:
        return 'seed';
    }
  }

  @override
  void didUpdateWidget(covariant LotusPlantWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.xp != widget.xp || oldWidget.maxXp != widget.maxXp) {
      _oldXp = oldWidget.xp;
      _progressController.reset();
      _setAnimation();
      _progressController.forward(); // ✅ Animation sẽ chạy khi XP thay đổi
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stageInfo = _getStageInfo(widget.xp);
    final stage = stageInfo['stage'] as String;
    final color = stageInfo['color'] as Color;
    final isMaxed = widget.xp >= widget.maxXp;

    // ✅ Lấy tên file hình ảnh dựa trên stage và health
    final imageStageName = _getImageStageName(stage);
    final healthName = widget.health.name; // healthy, wilting, dead
    final imagePath = 'assets/lotus_${imageStageName}_$healthName.png';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Plant Image with Glow Effect
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: isMaxed
                    ? [
                        BoxShadow(
                          color: color
                              .withOpacity(0.3 + _glowController.value * 0.3),
                          blurRadius: 30 + _glowController.value * 20,
                          spreadRadius: 5,
                        ),
                      ]
                    : null,
              ),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) {
                  // Fallback nếu không tìm thấy hình
                  return Icon(
                    Icons.spa,
                    size: 120,
                    color: color,
                  );
                },
              ),
            );
          },
        ),

        if (widget.showDetails) ...[
          const SizedBox(height: 24),

          // Stage Name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Text(
              stageInfo['name'] as String,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            stageInfo['description'] as String,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 20),

          // XP Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kinh nghiệm',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${widget.xp}/${widget.maxXp}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: _progressAnim.value,
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color,
                                    color.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Next Stage Info
          if (!isMaxed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_upward,
                      size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Còn ${stageInfo['nextXp'] - widget.xp} XP để lên cấp',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade300, Colors.purple.shade400],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.star, size: 18, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Cây đã đạt cấp tối đa!',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
