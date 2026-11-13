import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/simulation_params.dart';
import '../../models/simulation_state.dart';

class DrainageStackPainter extends CustomPainter {
  final SimulationParams params;
  final SystemDynamicState dynamicState;
  final StaticPhysicsResult staticResult;
  final List<int> activeFloors;
  final List<double> waterParticles;
  final List<double> airParticles;
  final String viewMode; // 'full', 'fit', 'prl'
  final bool isDarkMode;
  final double scrollOffset;

  DrainageStackPainter({
    required this.params,
    required this.dynamicState,
    required this.staticResult,
    required this.activeFloors,
    required this.waterParticles,
    required this.airParticles,
    required this.viewMode,
    required this.isDarkMode,
    this.scrollOffset = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    final double floorPitch = 70.0;
    final double totalDrawnHeight = 90.0 + (params.floors - 1) * floorPitch + 120.0;

    // View mode transformation
    double scale = 1.0;
    double dy = -scrollOffset;

    if (viewMode == 'fit') {
      scale = min(size.width / 440.0, size.height / totalDrawnHeight);
      dy = 20.0;
    } else if (viewMode == 'prl') {
      scale = 1.4;
      dy = size.height - (totalDrawnHeight - 60.0) * scale;
    }

    canvas.translate((size.width - 440.0 * scale) / 2.0, dy);
    canvas.scale(scale, scale);

    // Grid / CAD background subtle guides
    _drawCadGrid(canvas, totalDrawnHeight);

    // Draw PRL base horizontal drain and transition
    _drawBaseDrainAndPrlRejoin(canvas, totalDrawnHeight);

    // Draw all floors from top to bottom
    for (int floorIndex = 0; floorIndex < params.floors; floorIndex++) {
      final int floorNumber = params.floors - floorIndex; // Floor N at top, 1 at bottom
      final double y = 70.0 + floorIndex * floorPitch;
      _drawFloor(canvas, floorNumber, y);
    }

    // Draw Stack Vertical Main Pipe
    _drawStackPipe(canvas, totalDrawnHeight);

    // Draw PRL Vertical Relief Pipe
    if (params.prlFitted) {
      _drawPrlPipe(canvas, totalDrawnHeight);
    }

    // Draw Animated Water & Air Flow Particles
    _drawFlowParticles(canvas, totalDrawnHeight, floorPitch);

    canvas.restore();
  }

  void _drawCadGrid(Canvas canvas, double totalHeight) {
    final Paint linePaint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    for (double x = 0; x <= 440; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, totalHeight), linePaint);
    }
  }

  void _drawFloor(Canvas canvas, int floorNumber, double y) {
    final int idx = floorNumber - 1;
    final bool isActive = activeFloors.contains(floorNumber);
    final double trapDispl = idx < dynamicState.trapDisplacement.length ? dynamicState.trapDisplacement[idx] : 0.0;
    final double trapSeal = idx < dynamicState.trapSealRetention.length ? dynamicState.trapSealRetention[idx] : 50.0;
    final bool sealLost = trapSeal < 25.0;

    // 1. Concrete Slab with Sunken Section
    final Paint slabPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF1E2837) : const Color(0xFFE2E8F0);
    final Paint slabBorder = Paint()
      ..color = isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Main floor slab: Left side (x: 40 to 180), Sunken portion (x: 180 to 280), Stack zone (x: 280 to 380)
    final Path slabPath = Path();
    slabPath.moveTo(40, y + 16);
    slabPath.lineTo(170, y + 16);
    // Sunken step down
    slabPath.lineTo(170, y + 26);
    slabPath.lineTo(275, y + 26);
    // Step back up to shaft
    slabPath.lineTo(275, y + 16);
    slabPath.lineTo(390, y + 16);
    slabPath.lineTo(390, y + 24);
    slabPath.lineTo(40, y + 24);
    slabPath.close();

    canvas.drawPath(slabPath, slabPaint);
    canvas.drawPath(slabPath, slabBorder);

    // Floor label badge
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: 'F$floorNumber',
        style: TextStyle(
          color: isActive ? AppColors.accent : (isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(8, y + 10));

    // Active flush indicator dot
    if (isActive) {
      final Paint flushDot = Paint()..color = AppColors.waterFlow;
      canvas.drawCircle(Offset(32, y + 16), 3.5, flushDot);
    }

    // 2. Sanitary Fixtures on Slab
    // WC (Toilet) at x: 100
    _drawWcFixture(canvas, 95, y);

    // Wash Basin (WB) at x: 155
    _drawWashBasinFixture(canvas, 145, y);

    // 3. Sunken Branch Pipe leading to Swept Tee
    final Paint branchPipe = Paint()
      ..color = (isDarkMode ? Colors.white70 : Colors.black87)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Path branchPath = Path();
    branchPath.moveTo(95, y + 16);
    branchPath.lineTo(95, y + 36); // WC drop
    branchPath.lineTo(240, y + 36); // Horizontal collector in sunken slab

    // Swept Tee Entry into vertical stack (x: 280)
    if (params.teeType == 'swept') {
      branchPath.cubicTo(260, y + 36, 275, y + 42, 280, y + 54);
    } else {
      branchPath.lineTo(280, y + 36); // 87.5° tee
    }
    canvas.drawPath(branchPath, branchPipe);

    // Swept Tee Fitting Marker (Green Huliot highlight)
    final Paint fittingHighlight = Paint()
      ..color = params.teeType == 'swept' ? AppColors.fittingCoupler : AppColors.danger
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(280, params.teeType == 'swept' ? y + 52 : y + 36), 4.5, fittingHighlight);

    // 4. Trap Seal (U-bend) under Fixture with live oscillation
    _drawTrapSeal(canvas, 145, y + 16, trapDispl, trapSeal, sealLost);
  }

  void _drawWcFixture(Canvas canvas, double x, double y) {
    final Paint fixturePaint = Paint()
      ..color = isDarkMode ? Colors.white70 : Colors.blueGrey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Tank + Bowl outline
    canvas.drawRect(Rect.fromLTWH(x - 8, y - 4, 6, 14), fixturePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x - 2, y + 2, 16, 10), const Radius.circular(5)),
      fixturePaint,
    );
  }

  void _drawWashBasinFixture(Canvas canvas, double x, double y) {
    final Paint fixturePaint = Paint()
      ..color = isDarkMode ? Colors.white70 : Colors.blueGrey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Basin rim
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x - 6, y + 2, 12, 6), const Radius.circular(2)),
      fixturePaint,
    );
  }

  void _drawTrapSeal(Canvas canvas, double x, double y, double displMm, double sealMm, bool sealLost) {
    final Paint trapBody = Paint()
      ..color = isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // U-bend path
    final Path uBend = Path();
    uBend.moveTo(x, y);
    uBend.lineTo(x, y + 8);
    uBend.arcToPoint(Offset(x + 10, y + 8), radius: const Radius.circular(5), clockwise: false);
    uBend.lineTo(x + 10, y + 4);
    uBend.lineTo(x + 22, y + 4);
    canvas.drawPath(uBend, trapBody);

    // Water level inside trap responding dynamically
    if (!sealLost && sealMm > 5.0) {
      final double normalizedDispl = (displMm / 50.0).clamp(-1.0, 1.0);
      final double leftWaterY = y + 8 - normalizedDispl * 4;
      final double rightWaterY = y + 8 + normalizedDispl * 4;

      final Paint waterPaint = Paint()
        ..color = sealMm < 30 ? AppColors.warning : AppColors.waterFlow
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(x, leftWaterY), Offset(x, y + 10), waterPaint);
      canvas.drawLine(Offset(x + 10, rightWaterY), Offset(x + 10, y + 10), waterPaint);
      canvas.drawLine(Offset(x + 1, y + 11), Offset(x + 9, y + 11), waterPaint);
    } else {
      // Seal blown out!
      final Paint lostPaint = Paint()
        ..color = AppColors.danger
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(Offset(x + 5, y + 8), 4, lostPaint);
    }
  }

  void _drawStackPipe(Canvas canvas, double totalHeight) {
    const double stackX = 280.0;
    final double pipeWidth = (params.stackDiameter / 110.0) * 14.0;

    // Pressure glow along pipe
    for (int i = 0; i < params.floors; i++) {
      final int floorNumber = params.floors - i;
      final double y = 70.0 + i * 70.0;
      final double p = staticResult.pr[floorNumber - 1];

      // Red for positive, Cyan/Blue for negative
      final Color glowColor = p > 0 ? AppColors.pressurePositive : AppColors.pressureNegative;
      final double glowOpacity = (p.abs() / 45.0).clamp(0.05, 0.45);

      final Paint glowPaint = Paint()
        ..color = glowColor.withValues(alpha: glowOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawRect(Rect.fromLTWH(stackX - pipeWidth / 2 - 6, y, pipeWidth + 12, 70), glowPaint);
    }

    // Outer pipe walls
    final Paint pipeWall = Paint()
      ..color = AppColors.pipeStack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawLine(Offset(stackX - pipeWidth / 2, 40), Offset(stackX - pipeWidth / 2, totalHeight - 60), pipeWall);
    canvas.drawLine(Offset(stackX + pipeWidth / 2, 40), Offset(stackX + pipeWidth / 2, totalHeight - 60), pipeWall);

    // Top of Stack Venting
    _drawStackTopVent(canvas, stackX, 40, pipeWidth);
  }

  void _drawStackTopVent(Canvas canvas, double x, double y, double w) {
    final Paint ventPaint = Paint()
      ..color = AppColors.pipeStack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (params.ventType == 'open') {
      // Open cowl
      final Path cowl = Path();
      cowl.moveTo(x - w, y - 8);
      cowl.lineTo(x + w, y - 8);
      cowl.lineTo(x, y - 18);
      cowl.close();
      canvas.drawPath(cowl, ventPaint);
      canvas.drawLine(Offset(x - w / 2, y), Offset(x - w / 2, y - 8), ventPaint);
      canvas.drawLine(Offset(x + w / 2, y), Offset(x + w / 2, y - 8), ventPaint);
    } else if (params.ventType == 'aav') {
      // AAV valve dome
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x - w / 2 - 3, y - 16, w + 6, 16), const Radius.circular(4)),
        ventPaint,
      );
      final TextPainter tp = TextPainter(
        text: const TextSpan(
          text: 'AAV',
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.accent),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - 9, y - 14));
    } else {
      // Blocked vent cap
      final Paint blockedPaint = Paint()..color = AppColors.danger;
      canvas.drawRect(Rect.fromLTWH(x - w / 2 - 2, y - 4, w + 4, 6), blockedPaint);
    }
  }

  void _drawPrlPipe(Canvas canvas, double totalHeight) {
    const double prlX = 330.0;
    final double prlWidth = (params.prlDiameter / 110.0) * 10.0;

    final Paint prlPaint = Paint()
      ..color = AppColors.pipePrl
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // Vertical relief pipe from top floor down to base
    canvas.drawLine(Offset(prlX - prlWidth / 2, 70), Offset(prlX - prlWidth / 2, totalHeight - 75), prlPaint);
    canvas.drawLine(Offset(prlX + prlWidth / 2, 70), Offset(prlX + prlWidth / 2, totalHeight - 75), prlPaint);

    // Cross Relief Connections at regular intervals
    for (int floorIndex = 0; floorIndex < params.floors; floorIndex += 4) {
      final double y = 90.0 + floorIndex * 70.0;
      canvas.drawLine(Offset(280 + 7, y), Offset(prlX - prlWidth / 2, y), prlPaint);
      // Huliot Green diamond coupler
      final Paint diamond = Paint()..color = AppColors.fittingCoupler;
      canvas.drawCircle(Offset((287 + prlX - prlWidth / 2) / 2, y), 3, diamond);
    }
  }

  void _drawBaseDrainAndPrlRejoin(Canvas canvas, double totalHeight) {
    const double stackX = 280.0;
    const double prlX = 330.0;
    final double baseY = totalHeight - 60.0;

    final Paint drainPaint = Paint()
      ..color = AppColors.pipeDrain
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;

    final Path drainPath = Path();
    drainPath.moveTo(stackX, baseY);

    switch (params.prlOption) {
      case 2: // System B: Offset with loop
        drainPath.cubicTo(stackX, baseY + 20, stackX + 40, baseY + 20, stackX + 50, baseY + 40);
        drainPath.lineTo(420, baseY + 40);
        break;
      case 3: // System C: Straight with base rejoin
        drainPath.quadraticBezierTo(stackX, baseY + 30, stackX + 60, baseY + 30);
        drainPath.lineTo(420, baseY + 30);
        break;
      default: // System A: 45° bends into horizontal
        drainPath.lineTo(stackX, baseY + 15);
        drainPath.cubicTo(stackX, baseY + 30, stackX + 30, baseY + 35, stackX + 50, baseY + 35);
        drainPath.lineTo(420, baseY + 35);
        break;
    }
    canvas.drawPath(drainPath, drainPaint);

    // PRL base connection back into drain
    if (params.prlFitted) {
      final Paint prlRejoin = Paint()
        ..color = AppColors.pipePrl
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      final Path rejoinPath = Path();
      rejoinPath.moveTo(prlX, totalHeight - 75);
      rejoinPath.quadraticBezierTo(prlX, baseY + 25, stackX + 45, baseY + 35);
      canvas.drawPath(rejoinPath, prlRejoin);
    }
  }

  void _drawFlowParticles(Canvas canvas, double totalHeight, double floorPitch) {
    const double stackX = 280.0;
    const double prlX = 330.0;
    final double startY = 60.0;
    final double stackLength = totalHeight - 120.0;

    final Paint waterDrop = Paint()
      ..color = AppColors.waterFlow
      ..style = PaintingStyle.fill;

    // Water flow drops descending stack
    for (final normY in waterParticles) {
      final double py = startY + normY * stackLength;
      // Oscillate slightly horizontally inside pipe core
      final double px = stackX + sin(normY * 20.0) * 3.5;
      canvas.drawCircle(Offset(px, py), 2.2, waterDrop);
    }

    // Air relief bubbles floating up inside PRL
    if (params.prlFitted) {
      final Paint airBubble = Paint()
        ..color = AppColors.airRelief.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      for (final normY in airParticles) {
        // Reverse direction: moving upwards
        final double py = startY + (1.0 - normY) * stackLength;
        final double px = prlX + cos(normY * 15.0) * 2.0;
        canvas.drawCircle(Offset(px, py), 1.8, airBubble);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrainageStackPainter oldDelegate) {
    return true; // Continuously animated at 30 FPS
  }
}
