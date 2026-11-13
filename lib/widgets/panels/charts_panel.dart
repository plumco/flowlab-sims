import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/simulation_params.dart';
import '../../models/simulation_state.dart';

class ChartsPanel extends StatelessWidget {
  final SimulationParams params;
  final StaticPhysicsResult staticResult;
  final StaticPhysicsResult noPrlResult;
  final SystemDynamicState dynamicState;
  final bool isDarkMode;

  const ChartsPanel({
    super.key,
    required this.params,
    required this.staticResult,
    required this.noPrlResult,
    required this.dynamicState,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card 1: Live Pressure Along Stack Height
        Expanded(
          flex: 6,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.show_chart_rounded, size: 18, color: AppColors.accent),
                          SizedBox(width: 6),
                          Text(
                            'Live Pressure Profile along Stack',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'EN 12056: ±25mm Limit',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Legend
                  Wrap(
                    spacing: 12,
                    children: [
                      _legendItem('Live Dynamic', AppColors.accent),
                      _legendItem('Design Peak', isDarkMode ? Colors.white60 : Colors.black54),
                      _legendItem('Without PRL', AppColors.warning),
                      _legendItem('Safe Limit (±25mm)', AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: CustomPaint(
                      painter: _StackPressureProfilePainter(
                        params: params,
                        staticResult: staticResult,
                        noPrlResult: noPrlResult,
                        dynamicState: dynamicState,
                        isDarkMode: isDarkMode,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Card 2: Pressure History Waveform
        Expanded(
          flex: 4,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.waves_rounded, size: 18, color: AppColors.info),
                      SizedBox(width: 6),
                      Text(
                        'Dynamic Peak Transient Oscillations',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Real-time damping oscillator response across all floors',
                    style: TextStyle(fontSize: 11, color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: CustomPaint(
                      painter: _PressureHistoryPainter(
                        history: dynamicState.pressureHistory,
                        isDarkMode: isDarkMode,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      ],
    );
  }
}

class _StackPressureProfilePainter extends CustomPainter {
  final SimulationParams params;
  final StaticPhysicsResult staticResult;
  final StaticPhysicsResult noPrlResult;
  final SystemDynamicState dynamicState;
  final bool isDarkMode;

  _StackPressureProfilePainter({
    required this.params,
    required this.staticResult,
    required this.noPrlResult,
    required this.dynamicState,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingX = 42.0;
    const double paddingY = 24.0;
    final double plotW = size.width - paddingX * 2;
    final double plotH = size.height - paddingY * 2;

    // Pressure bounds: -60 mm WG to +60 mm WG
    const double pMin = -60.0;
    const double pMax = 60.0;

    double pToX(double p) {
      final double norm = (p - pMin) / (pMax - pMin);
      return paddingX + norm.clamp(0.0, 1.0) * plotW;
    }

    double floorToY(int floor) {
      // Floor 1 (bottom) at plot bottom, Floor N (top) at plot top
      final double norm = (floor - 1) / max(1, params.floors - 1).toDouble();
      return paddingY + (1.0 - norm) * plotH;
    }

    // 1. Draw Safe Zone Box (-25 to +25 mm WG)
    final double safeX1 = pToX(-25);
    final double safeX2 = pToX(25);
    final Paint safeZonePaint = Paint()
      ..color = AppColors.success.withValues(alpha: isDarkMode ? 0.08 : 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTRB(safeX1, paddingY, safeX2, paddingY + plotH), safeZonePaint);

    // 2. Grid lines & Axis Labels
    final Paint gridPaint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.07)
      ..strokeWidth = 1.0;

    final Paint zeroAxis = Paint()
      ..color = (isDarkMode ? Colors.white30 : Colors.black26)
      ..strokeWidth = 1.2;

    // Zero pressure center line
    final double zeroX = pToX(0);
    canvas.drawLine(Offset(zeroX, paddingY), Offset(zeroX, paddingY + plotH), zeroAxis);

    // Pressure tick marks: -50, -25, 0, +25, +50
    for (final p in [-50, -25, 25, 50]) {
      final double x = pToX(p.toDouble());
      canvas.drawLine(Offset(x, paddingY), Offset(x, paddingY + plotH), gridPaint);
      _drawText(canvas, '${p > 0 ? "+" : ""}$p', Offset(x, paddingY + plotH + 4), isSmall: true);
    }

    // Floor labels at top and bottom
    _drawText(canvas, 'F${params.floors}', Offset(12, floorToY(params.floors)));
    _drawText(canvas, 'F1', Offset(12, floorToY(1)));

    // 3. Draw Without PRL Curve (Orange dashed)
    final Path noPrlPath = Path();
    for (int i = 0; i < params.floors; i++) {
      final int floor = i + 1;
      final double x = pToX(noPrlResult.pr[i]);
      final double y = floorToY(floor);
      if (i == 0) {
        noPrlPath.moveTo(x, y);
      } else {
        noPrlPath.lineTo(x, y);
      }
    }
    final Paint noPrlPaint = Paint()
      ..color = AppColors.warning.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(noPrlPath, noPrlPaint);

    // 4. Draw Design Static Peak Curve (White/Grey dashed)
    final Path designPath = Path();
    for (int i = 0; i < params.floors; i++) {
      final int floor = i + 1;
      final double x = pToX(staticResult.pr[i]);
      final double y = floorToY(floor);
      if (i == 0) {
        designPath.moveTo(x, y);
      } else {
        designPath.lineTo(x, y);
      }
    }
    final Paint designPaint = Paint()
      ..color = (isDarkMode ? Colors.white60 : Colors.black54)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(designPath, designPaint);

    // 5. Draw Live Dynamic Pressure Oscillating Curve (Glowing Cyan)
    final Path dynamicPath = Path();
    for (int i = 0; i < params.floors; i++) {
      final int floor = i + 1;
      final double currentTarget = dynamicState.targetPressure[i];
      final double x = pToX(currentTarget);
      final double y = floorToY(floor);
      if (i == 0) {
        dynamicPath.moveTo(x, y);
      } else {
        dynamicPath.lineTo(x, y);
      }
    }

    // Dynamic glow
    final Paint glowPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(dynamicPath, glowPaint);

    final Paint livePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawPath(dynamicPath, livePaint);

    // Points at each active floor
    final Paint dotPaint = Paint()..color = AppColors.waterFlow;
    for (int i = 0; i < params.floors; i++) {
      final double x = pToX(dynamicState.targetPressure[i]);
      final double y = floorToY(i + 1);
      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, {bool isSmall = false}) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          fontSize: isSmall ? 9.5 : 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(offset.dx - tp.width / 2, offset.dy));
  }

  @override
  bool shouldRepaint(covariant _StackPressureProfilePainter oldDelegate) => true;
}

class _PressureHistoryPainter extends CustomPainter {
  final List<Point<double>> history;
  final bool isDarkMode;

  _PressureHistoryPainter({
    required this.history,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final double w = size.width;
    final double h = size.height;
    final double midY = h / 2.0;

    // Draw baseline
    final Paint basePaint = Paint()
      ..color = (isDarkMode ? Colors.white24 : Colors.black26)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, midY), Offset(w, midY), basePaint);

    // Draw ±25 limit lines
    final Paint limitPaint = Paint()
      ..color = AppColors.success.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;
    const double scaleY = 1.4; // 1mm WG ≈ 1.4 px
    canvas.drawLine(Offset(0, midY - 25 * scaleY), Offset(w, midY - 25 * scaleY), limitPaint);
    canvas.drawLine(Offset(0, midY + 25 * scaleY), Offset(w, midY + 25 * scaleY), limitPaint);

    final Path maxPath = Path();
    final Path minPath = Path();

    final double stepX = w / max(1, history.length - 1);

    for (int i = 0; i < history.length; i++) {
      final double x = i * stepX;
      final double pMax = history[i].x;
      final double pMin = history[i].y;

      final double yPos = midY - pMax * scaleY;
      final double yNeg = midY - pMin * scaleY;

      if (i == 0) {
        maxPath.moveTo(x, yPos);
        minPath.moveTo(x, yNeg);
      } else {
        maxPath.lineTo(x, yPos);
        minPath.lineTo(x, yNeg);
      }
    }

    final Paint maxPaint = Paint()
      ..color = AppColors.pressurePositive
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final Paint minPaint = Paint()
      ..color = AppColors.pressureNegative
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawPath(maxPath, maxPaint);
    canvas.drawPath(minPath, minPaint);
  }

  @override
  bool shouldRepaint(covariant _PressureHistoryPainter oldDelegate) => true;
}
