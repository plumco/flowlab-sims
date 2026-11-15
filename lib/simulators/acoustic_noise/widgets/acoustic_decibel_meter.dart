import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/acoustic_models.dart';
import '../services/acoustic_mic_service.dart';

class AcousticDecibelMeter extends StatefulWidget {
  final double currentDb;
  final AcousticMode mode;
  final PipeAcousticProfile selectedPipe;
  final bool isLiveActive;
  final double liveJitterDb;
  final VoidCallback onToggleLiveMode;
  final AcousticMicReading? micReading;
  final VoidCallback? onStartMic;
  final VoidCallback? onStopMic;
  final VoidCallback? onGenerateReport;

  const AcousticDecibelMeter({
    super.key,
    required this.currentDb,
    required this.mode,
    required this.selectedPipe,
    required this.isLiveActive,
    required this.liveJitterDb,
    required this.onToggleLiveMode,
    this.micReading,
    this.onStartMic,
    this.onStopMic,
    this.onGenerateReport,
  });

  @override
  State<AcousticDecibelMeter> createState() => _AcousticDecibelMeterState();
}

class _AcousticDecibelMeterState extends State<AcousticDecibelMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _dbAnimation;
  double _oldDb = 15.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _oldDb = _getTargetDb();
    _dbAnimation = Tween<double>(begin: _oldDb, end: _oldDb).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  double _getTargetDb() {
    if (widget.mode == AcousticMode.liveSiteSoundTest) {
      if (widget.micReading != null && widget.micReading!.isActive) {
        return widget.micReading!.currentDb.clamp(5.0, 95.0);
      }
      if (widget.micReading != null && widget.micReading!.sampleCount > 0 && !widget.micReading!.isActive) {
        return widget.micReading!.avgDb.clamp(5.0, 95.0);
      }
      if (widget.isLiveActive) {
        return (widget.currentDb + widget.liveJitterDb).clamp(5.0, 55.0);
      }
    }
    return widget.currentDb.clamp(5.0, 95.0);
  }

  @override
  void didUpdateWidget(covariant AcousticDecibelMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    final double newTarget = _getTargetDb();
    if ((_dbAnimation.value - newTarget).abs() > 0.05) {
      _oldDb = _dbAnimation.value;
      _dbAnimation = Tween<double>(begin: _oldDb, end: newTarget).animate(
        CurvedAnimation(
          parent: _animController,
          curve: widget.mode == AcousticMode.liveSiteSoundTest ? Curves.linear : Curves.easeOutCubic,
        ),
      );
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isMicActive = widget.micReading?.isActive ?? false;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final double displayDb = _dbAnimation.value;
        final Color zoneColor = _getZoneColor(displayDb);
        final String zoneText = _getZoneText(displayDb);
        final String zoneStandard = _getZoneStandard(displayDb);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: zoneColor.withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Row: Meter Name & Mode Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: zoneColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            widget.mode == AcousticMode.liveSiteSoundTest
                                ? Icons.mic_rounded
                                : Icons.speed_rounded,
                            color: zoneColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ACOUSTIC SOUND LEVEL METER',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                widget.mode == AcousticMode.liveSiteSoundTest
                                    ? 'Live Device Microphone SPL Sensor'
                                    : 'Precision Sound Pressure Level L_sc,A',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Mode Toggle Button / Badge
                  InkWell(
                    onTap: widget.onToggleLiveMode,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.mode == AcousticMode.liveSiteSoundTest
                            ? (isMicActive || widget.isLiveActive
                                ? AppColors.danger.withValues(alpha: 0.15)
                                : AppColors.warning.withValues(alpha: 0.15))
                            : AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.mode == AcousticMode.liveSiteSoundTest
                              ? (isMicActive || widget.isLiveActive ? AppColors.danger : AppColors.warning)
                              : AppColors.primary,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.mode == AcousticMode.liveSiteSoundTest && (isMicActive || widget.isLiveActive))
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: const BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Icon(
                            widget.mode == AcousticMode.liveSiteSoundTest
                                ? (isMicActive || widget.isLiveActive ? Icons.mic : Icons.mic_off)
                                : Icons.tune_rounded,
                            size: 14,
                            color: widget.mode == AcousticMode.liveSiteSoundTest
                                ? (isMicActive || widget.isLiveActive ? AppColors.danger : AppColors.warning)
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            widget.mode == AcousticMode.liveSiteSoundTest
                                ? (isMicActive || widget.isLiveActive ? 'LIVE MIC ACTIVE' : 'LIVE PAUSED')
                                : 'SIMULATION MODE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: widget.mode == AcousticMode.liveSiteSoundTest
                                  ? (isMicActive || widget.isLiveActive ? AppColors.danger : AppColors.warning)
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Analog Circular Needle Gauge
              SizedBox(
                height: 220,
                width: 280,
                child: CustomPaint(
                  painter: _GaugePainter(
                    dbValue: displayDb,
                    isDark: isDark,
                    isLive: widget.mode == AcousticMode.liveSiteSoundTest && (isMicActive || widget.isLiveActive),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Digital High-Visibility Readout
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    displayDb.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      color: zoneColor,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'dB(A)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Dynamic 3-Zone Classification Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: zoneColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: zoneColor, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      displayDb <= 24.0
                          ? Icons.verified_rounded
                          : (displayDb <= 30.0 ? Icons.check_circle_outline : Icons.warning_amber_rounded),
                      size: 16,
                      color: zoneColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$zoneStandard: $zoneText',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: zoneColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3-Zone Legend Guide
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  _zoneLegendItem(
                    color: AppColors.success,
                    range: '0 - 24 dB',
                    label: 'VDI 4100 SSt III Luxury',
                    isActive: displayDb <= 24.0,
                    isDark: isDark,
                  ),
                  _zoneLegendItem(
                    color: AppColors.warning,
                    range: '25 - 30 dB',
                    label: 'DIN 4109 Standard',
                    isActive: displayDb > 24.0 && displayDb <= 30.0,
                    isDark: isDark,
                  ),
                  _zoneLegendItem(
                    color: AppColors.danger,
                    range: '> 30 dB',
                    label: 'Noise Disturbance',
                    isActive: displayDb > 30.0,
                    isDark: isDark,
                  ),
                ],
              ),

              // Mode B Real Microphone & On-Site Testing Station
              if (widget.mode == AcousticMode.liveSiteSoundTest) ...[
                const SizedBox(height: 16),
                _buildLiveMicControlCard(context: context, isDark: isDark),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveMicControlCard({required BuildContext context, required bool isDark}) {
    final reading = widget.micReading ?? AcousticMicReading.empty();
    final bool isMicActive = reading.isActive;
    final bool hasData = reading.sampleCount > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMicActive
              ? AppColors.danger.withValues(alpha: 0.6)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isMicActive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status line
          Row(
            children: [
              if (isMicActive) ...[
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'RECORDING LIVE SOUND UNDER PIPE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.danger,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '⏱️ ${reading.durationSec}s',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ] else if (hasData) ...[
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'SITE TEST RECORDING COMPLETED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.success,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                Text(
                  '${reading.durationSec}s &bull; ${reading.sampleCount} frames',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ] else ...[
                const Icon(Icons.mic_none_rounded, color: AppColors.accent, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'REAL HARDWARE MICROPHONE INPUT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Error alert if mic was blocked
          if (reading.errorMsg.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.danger),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reading.errorMsg,
                      style: const TextStyle(fontSize: 11, color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Metrics row if test has data
          if (hasData) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131D2D) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('MIN FLOOR', '${reading.minDb.toStringAsFixed(1)} dB', AppColors.success),
                  Container(width: 1, height: 26, color: Colors.grey.withValues(alpha: 0.2)),
                  _statItem('AVG L_Aeq', '${reading.avgDb.toStringAsFixed(1)} dB', AppColors.accent),
                  Container(width: 1, height: 26, color: Colors.grey.withValues(alpha: 0.2)),
                  _statItem('MAX PEAK', '${reading.maxDb.toStringAsFixed(1)} dB', AppColors.warning),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Place your laptop or mobile phone beneath the drainage pipe or shaft. Click "Start Live Mic Test" to capture real live sound in real-time.',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Control buttons
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (isMicActive) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: widget.onStopMic,
                  icon: const Icon(Icons.stop_circle_rounded, size: 18),
                  label: const Text('Stop Test & Lock dB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                ),
              ] else ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: widget.onStartMic,
                  icon: const Icon(Icons.mic_rounded, size: 18),
                  label: Text(
                    hasData ? 'Restart Mic Test' : 'Start Live Mic Test',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5),
                  ),
                ),
              ],

              // On-Site Test Report Generation Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: widget.onGenerateReport,
                icon: const Icon(Icons.assignment_rounded, size: 18),
                label: const Text(
                  'Generate Site Report (PDF/Print)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }

  Widget _zoneLegendItem({
    required Color color,
    required String range,
    required String label,
    required bool isActive,
    required bool isDark,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive ? color : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                range,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isActive ? color : (isDark ? AppColors.darkText : AppColors.lightText),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getZoneColor(double db) {
    if (db <= 24.0) return AppColors.success;
    if (db <= 30.0) return AppColors.warning;
    return AppColors.danger;
  }

  String _getZoneText(double db) {
    if (db <= 24.0) return 'Whisper Quiet Comfort';
    if (db <= 30.0) return 'Standard Sound Insulation';
    return 'Audible Noise Disturbance';
  }

  String _getZoneStandard(double db) {
    if (db <= 24.0) return 'VDI 4100 Level III';
    if (db <= 30.0) return 'DIN 4109 Standard';
    return 'Exceeds Standard';
  }
}

class _GaugePainter extends CustomPainter {
  final double dbValue;
  final bool isDark;
  final bool isLive;

  _GaugePainter({
    required this.dbValue,
    required this.isDark,
    required this.isLive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height * 0.82);
    final double radius = size.width * 0.42;

    const double startAngle = 140 * (math.pi / 180);
    const double sweepAngle = 260 * (math.pi / 180);
    const double maxDb = 50.0;

    final Paint trackPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(arcRect, startAngle, sweepAngle, false, trackPaint);

    final double zone1Fraction = 24.0 / maxDb;
    final double zone2Fraction = 30.0 / maxDb;

    final double zone1Sweep = sweepAngle * zone1Fraction;
    final double zone2Sweep = sweepAngle * (zone2Fraction - zone1Fraction);
    final double zone3Sweep = sweepAngle * (1.0 - zone2Fraction);

    final Paint zone1Paint = Paint()
      ..color = AppColors.success.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0;

    final Paint zone2Paint = Paint()
      ..color = AppColors.warning.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0;

    final Paint zone3Paint = Paint()
      ..color = AppColors.danger.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0;

    canvas.drawArc(arcRect, startAngle, zone1Sweep, false, zone1Paint);
    canvas.drawArc(arcRect, startAngle + zone1Sweep, zone2Sweep, false, zone2Paint);
    canvas.drawArc(arcRect, startAngle + zone1Sweep + zone2Sweep, zone3Sweep, false, zone3Paint);

    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final Paint tickPaintMajor = Paint()
      ..color = isDark ? Colors.white70 : Colors.black87
      ..strokeWidth = 2.0;

    final Paint tickPaintMinor = Paint()
      ..color = isDark ? Colors.white30 : Colors.black38
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 50; i += 2) {
      final double fraction = i / maxDb;
      final double angle = startAngle + (sweepAngle * fraction);
      final bool isMajor = (i % 10 == 0) || i == 24 || i == 30;

      final double tickLength = isMajor ? 10.0 : 5.0;
      final double innerR = radius - 16.0;
      final double outerR = innerR - tickLength;

      final Offset p1 = Offset(
        center.dx + innerR * math.cos(angle),
        center.dy + innerR * math.sin(angle),
      );
      final Offset p2 = Offset(
        center.dx + outerR * math.cos(angle),
        center.dy + outerR * math.sin(angle),
      );

      canvas.drawLine(p1, p2, isMajor ? tickPaintMajor : tickPaintMinor);

      if (isMajor) {
        final double labelR = outerR - 12.0;
        final Offset labelPos = Offset(
          center.dx + labelR * math.cos(angle),
          center.dy + labelR * math.sin(angle),
        );

        Color labelColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
        if (i == 24) labelColor = AppColors.success;
        if (i == 30) labelColor = AppColors.warning;

        textPainter.text = TextSpan(
          text: '$i',
          style: TextStyle(
            fontSize: (i == 24 || i == 30) ? 10.5 : 9.5,
            fontWeight: (i == 24 || i == 30) ? FontWeight.bold : FontWeight.w500,
            color: labelColor,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          labelPos - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
    }

    _drawThresholdMarker(
      canvas: canvas,
      center: center,
      radius: radius + 10.0,
      angle: startAngle + (sweepAngle * (24.0 / maxDb)),
      color: AppColors.success,
      label: 'VDI',
    );

    _drawThresholdMarker(
      canvas: canvas,
      center: center,
      radius: radius + 10.0,
      angle: startAngle + (sweepAngle * (30.0 / maxDb)),
      color: AppColors.warning,
      label: 'DIN',
    );

    final double clampedDb = dbValue.clamp(0.0, maxDb);
    final double needleFraction = clampedDb / maxDb;
    final double needleAngle = startAngle + (sweepAngle * needleFraction);

    final Paint needleShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final double needleLength = radius - 8.0;
    final Offset tipShadow = Offset(
      center.dx + needleLength * math.cos(needleAngle) + 2,
      center.dy + needleLength * math.sin(needleAngle) + 2,
    );
    canvas.drawLine(center + const Offset(2, 2), tipShadow, needleShadow);

    Color needleColor = isDark ? Colors.white : const Color(0xFF1E293B);
    if (dbValue <= 24) {
      needleColor = AppColors.success;
    } else if (dbValue <= 30) {
      needleColor = AppColors.warning;
    } else {
      needleColor = AppColors.danger;
    }

    final Paint needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final Offset needleTip = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );
    canvas.drawLine(center, needleTip, needlePaint);

    final Paint pivotOuter = Paint()..color = isDark ? Colors.white : Colors.black87;
    final Paint pivotInner = Paint()..color = needleColor;
    canvas.drawCircle(center, 9, pivotOuter);
    canvas.drawCircle(center, 5.5, pivotInner);
  }

  void _drawThresholdMarker({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double angle,
    required Color color,
    required String label,
  }) {
    final Offset markerPos = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );

    final Paint markerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(markerPos, 4.0, markerPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.dbValue != dbValue ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isLive != isLive;
  }
}
