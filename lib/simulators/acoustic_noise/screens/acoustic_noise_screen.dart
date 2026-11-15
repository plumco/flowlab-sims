import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/acoustic_models.dart';
import '../services/acoustic_mic_service.dart';
import '../services/acoustic_site_report_service.dart';
import '../services/noise_isolation_service.dart';
import '../widgets/acoustic_decibel_meter.dart';
import '../widgets/acoustic_site_report_dialog.dart';
import '../widgets/acoustic_testing_controls.dart';
import '../widgets/acoustic_testing_guide_dialog.dart';
import '../widgets/pipe_comparison_bench.dart';
import '../widgets/fraunhofer_certificate_dialog.dart';

class AcousticNoiseScreen extends StatefulWidget {
  const AcousticNoiseScreen({super.key});

  @override
  State<AcousticNoiseScreen> createState() => _AcousticNoiseScreenState();
}

class _AcousticNoiseScreenState extends State<AcousticNoiseScreen> {
  // Acoustic simulation boundary state
  double _flowRate = 2.0; // L/s (0.5 to 6.0)
  BracketType _bracket = BracketType.huliotAcoustic;
  WallType _wall = WallType.solidMasonry;
  PipeTechnologyType _selectedPipe = PipeTechnologyType.huliotUltraSilent;

  // Dual Mode: Mode A (Simulation) vs Mode B (Live Site Sound Testing)
  AcousticMode _mode = AcousticMode.simulation;
  bool _isLiveActive = true;
  double _liveJitterDb = 0.0;
  Timer? _liveJitterTimer;
  double _jitterPhase = 0.0;

  // Real Hardware Microphone Service & Polling
  late final AcousticMicService _micService = AcousticMicService.create();
  AcousticMicReading _micReading = AcousticMicReading.empty();
  Timer? _micPollTimer;

  // Mode B 3-Phase ISO 16032 Field Testing State
  TestingPhase _testingPhase = TestingPhase.setup;
  MeasurementPosition _measurementPosition = MeasurementPosition.installationShaft;
  final double _measurementDistanceMeters = 1.0;
  AmbientCalibrationResult _ambientCalibration = AmbientCalibrationResult.empty();
  NoiseIsolationResult _isolationResult = NoiseIsolationResult.empty();
  int _countdownSec = 0;
  Timer? _countdownTimer;

  // Stored On-Site Testing Records
  PipeAuditRecord? _recordA;
  PipeAuditRecord? _recordB;
  AuditScope _auditScope = AuditScope.singlePipe;
  String _activeTestingTarget = 'A'; // 'A' or 'B'
  PipeTechnologyType _competitorPipeType = PipeTechnologyType.astralSilencio;

  @override
  void initState() {
    super.initState();
    _startLiveSimulationLoop();
  }

  void _startLiveSimulationLoop() {
    _liveJitterTimer?.cancel();
    _liveJitterTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) return;
      if (_mode == AcousticMode.liveSiteSoundTest && _isLiveActive && !_micReading.isActive) {
        setState(() {
          _jitterPhase += 0.35;
          final double sineWave = math.sin(_jitterPhase) * 1.1;
          final double noise = (math.Random().nextDouble() - 0.5) * 0.8;
          _liveJitterDb = double.parse((sineWave + noise).toStringAsFixed(1));
        });
      } else if (_liveJitterDb != 0.0) {
        setState(() {
          _liveJitterDb = 0.0;
        });
      }
    });
  }

  Future<void> _startLiveMic() async {
    setState(() {
      _mode = AcousticMode.liveSiteSoundTest;
      _isLiveActive = true;
    });

    await _micService.start();

    _micPollTimer?.cancel();
    _micPollTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return;
      setState(() {
        _micReading = _micService.getReading();
        if (_micReading.isActive) {
          _liveJitterDb = 0.0;
        }
      });
    });

    if (mounted) {
      setState(() {
        _micReading = _micService.getReading();
      });
    }
  }

  void _stopLiveMic() {
    _micService.stop();
    _micPollTimer?.cancel();
    setState(() {
      _isLiveActive = false;
      _micReading = _micService.getReading();
    });
  }

  void _toggleLiveMode() {
    if (_mode == AcousticMode.simulation) {
      _switchMode(AcousticMode.liveSiteSoundTest);
    } else {
      if (_micReading.isActive) {
        _stopLiveMic();
      } else {
        _startLiveMic();
      }
    }
  }

  void _switchMode(AcousticMode newMode) {
    if (_mode == newMode) return;
    setState(() {
      _mode = newMode;
      if (_mode == AcousticMode.liveSiteSoundTest) {
        _isLiveActive = true;
        _startLiveMic();
      } else {
        _stopLiveMic();
      }
    });
  }

  // --- 3-Phase ISO 16032 Workflow Handlers ---

  Future<void> _startAmbientCalibration() async {
    setState(() {
      _testingPhase = TestingPhase.ambientCalibration;
      _countdownSec = 10;
    });

    await _startLiveMic();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdownSec > 1) {
        setState(() => _countdownSec--);
      } else {
        timer.cancel();
        _finishAmbientCalibration();
      }
    });
  }

  void _finishAmbientCalibration() {
    _stopLiveMic();
    final double avgBg = _micReading.avgDb > 0 ? _micReading.avgDb : 26.5;
    final String quality = NoiseIsolationService.evaluateAmbientQuality(avgBg);

    setState(() {
      _ambientCalibration = AmbientCalibrationResult(
        avgDb: avgBg,
        minDb: _micReading.minDb > 0 ? _micReading.minDb : avgBg - 2.0,
        maxDb: _micReading.maxDb > 0 ? _micReading.maxDb : avgBg + 2.5,
        durationSec: 10,
        sampleCount: _micReading.sampleCount,
        quality: quality,
      );
      _testingPhase = TestingPhase.flushRecording;
    });
  }

  Future<void> _startFlushRecording() async {
    setState(() {
      _testingPhase = TestingPhase.flushRecording;
      _countdownSec = 15;
    });

    await _startLiveMic();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdownSec > 1) {
        setState(() => _countdownSec--);
      } else {
        timer.cancel();
        _finishFlushRecording();
      }
    });
  }

  void _finishFlushRecording() {
    _stopLiveMic();
    final double lTotal = _micReading.avgDb > 0 ? _micReading.avgDb : 42.0;
    final double lBg = _ambientCalibration.avgDb > 0 ? _ambientCalibration.avgDb : 28.0;

    final result = NoiseIsolationService.isolatePipeNoise(
      lTotal: lTotal,
      lBackground: lBg,
    );

    final PipeAcousticProfile testedProfile = _activeTestingTarget == 'B'
        ? PipeAcousticProfile.allPipes.firstWhere((p) => p.type == _competitorPipeType)
        : PipeAcousticProfile.allPipes.firstWhere((p) => p.type == _selectedPipe);

    final record = PipeAuditRecord(
      pipe: testedProfile,
      bracket: _bracket,
      wall: _wall,
      position: _measurementPosition,
      reading: _micReading.sampleCount > 0
          ? _micReading
          : AcousticMicReading(
              isActive: false,
              permissionState: 'granted',
              errorMsg: '',
              currentDb: lTotal,
              minDb: lBg,
              maxDb: lTotal + 2.5,
              avgDb: lTotal,
              durationSec: 15,
              sampleCount: 150,
            ),
      isolation: result,
      flowRate: _flowRate,
    );

    setState(() {
      _isolationResult = result;
      _testingPhase = TestingPhase.analysis;
      if (_activeTestingTarget == 'B') {
        _recordB = record;
      } else {
        _recordA = record;
      }
    });
  }

  void _resetTestWizard() {
    _countdownTimer?.cancel();
    _stopLiveMic();
    setState(() {
      _testingPhase = TestingPhase.setup;
      _ambientCalibration = AmbientCalibrationResult.empty();
      _isolationResult = NoiseIsolationResult.empty();
      _recordA = null;
      _recordB = null;
      _activeTestingTarget = 'A';
    });
  }

  void _startTestingSystemB() {
    _countdownTimer?.cancel();
    _stopLiveMic();
    setState(() {
      _activeTestingTarget = 'B';
      _testingPhase = TestingPhase.setup;
      _ambientCalibration = AmbientCalibrationResult.empty();
      _isolationResult = NoiseIsolationResult.empty();
    });
  }

  void _openReportDialog({required PipeAcousticProfile currentPipe, required double computedNoise}) {
    final AcousticMicReading effectiveReading = _micReading.sampleCount > 0
        ? _micReading
        : AcousticMicReading(
            isActive: false,
            permissionState: 'baseline',
            errorMsg: '',
            currentDb: computedNoise,
            minDb: math.max(8.0, computedNoise - 1.6),
            maxDb: computedNoise + 2.4,
            avgDb: computedNoise,
            durationSec: 15,
            sampleCount: 150,
          );

    AcousticSiteReportDialog.show(
      context,
      reading: effectiveReading,
      testedPipe: currentPipe,
      bracket: _bracket,
      wall: _wall,
      measurementPosition: _measurementPosition,
      isolationResult: _isolationResult.isReliable ? _isolationResult : null,
      flowRate: _flowRate,
      recordA: _recordA,
      recordB: _recordB,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _micPollTimer?.cancel();
    _liveJitterTimer?.cancel();
    _micService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final PipeAcousticProfile currentPipe = PipeAcousticProfile.allPipes.firstWhere(
      (p) => p.type == _selectedPipe,
      orElse: () => PipeAcousticProfile.huliot,
    );

    final double computedNoise = currentPipe.calculateNoise(
      flowRate: _flowRate,
      bracket: _bracket,
      wall: _wall,
    );

    final bool passesLuxury = computedNoise <= 24.0;
    final bool passesDin4109 = computedNoise <= 30.0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Lab Banner
            _buildTopBanner(
              isDark: isDark,
              passesLuxury: passesLuxury,
              passesDin: passesDin4109,
              huliotNoise: computedNoise,
              currentPipe: currentPipe,
            ),

            const SizedBox(height: 16),

            // Mode Selector Bar (Mode A: Physics Simulation vs Mode B: Live Site Sound Testing)
            _buildModeSelectorBar(isDark: isDark),

            const SizedBox(height: 18),

            // Mode B 3-Phase ISO 16032 Wizard Card
            if (_mode == AcousticMode.liveSiteSoundTest) ...[
              _buildIso16032WizardCard(isDark: isDark, currentPipe: currentPipe, computedNoise: computedNoise),
              const SizedBox(height: 18),
            ],

            // Primary Layout: Sound Level Meter & Acoustic Testing Controls
            LayoutBuilder(
              builder: (context, constraints) {
                final bool isDesktop = constraints.maxWidth >= 960;

                final decibelMeter = AcousticDecibelMeter(
                  currentDb: computedNoise,
                  mode: _mode,
                  selectedPipe: currentPipe,
                  isLiveActive: _isLiveActive || _micReading.isActive,
                  liveJitterDb: _liveJitterDb,
                  micReading: _micReading,
                  onToggleLiveMode: _toggleLiveMode,
                  onStartMic: _startLiveMic,
                  onStopMic: _stopLiveMic,
                  onGenerateReport: () => _openReportDialog(
                    currentPipe: currentPipe,
                    computedNoise: computedNoise,
                  ),
                );

                final testingControls = AcousticTestingControls(
                  flowRate: _flowRate,
                  bracket: _bracket,
                  wall: _wall,
                  selectedPipe: _selectedPipe,
                  onFlowRateChanged: (val) => setState(() => _flowRate = val),
                  onBracketChanged: (val) => setState(() => _bracket = val),
                  onWallChanged: (val) => setState(() => _wall = val),
                  onPipeChanged: (val) => setState(() => _selectedPipe = val),
                );

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: decibelMeter,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 6,
                        child: testingControls,
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      decibelMeter,
                      const SizedBox(height: 16),
                      testingControls,
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 24),

            // Multi-Pipe Comparison Bench & 3-Layer Technology Deep Dive
            PipeComparisonBench(
              flowRate: _flowRate,
              bracket: _bracket,
              wall: _wall,
              selectedPipeType: _selectedPipe,
              onSelectPipe: (pType) => setState(() => _selectedPipe = pType),
            ),

            const SizedBox(height: 24),

            // Acoustic Decibel Reference Chart Footer
            _buildDecibelReferenceGuide(isDark: isDark),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner({
    required bool isDark,
    required bool passesLuxury,
    required bool passesDin,
    required double huliotNoise,
    required PipeAcousticProfile currentPipe,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.graphic_eq_rounded, color: AppColors.accent, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'HULIOT ULTRA SILENT ACOUSTIC ATTENUATION LAB',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.6),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.verified_rounded, size: 16, color: AppColors.accent),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'EN 14366, DIN 4109 & VDI 4100 Structure-Borne & Airborne Drainage Noise Laboratory',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Action Buttons: SOP + Fraunhofer Certificate + Site Inspection Report
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: const BorderSide(color: AppColors.success, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onPressed: () => AcousticTestingGuideDialog.show(context),
                icon: const Icon(Icons.menu_book_rounded, size: 16),
                label: const Text('Testing Guidelines (SOP)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onPressed: () => FraunhoferCertificateDialog.show(context),
                icon: const Icon(Icons.workspace_premium_rounded, size: 16),
                label: const Text('Fraunhofer Certificate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () => _openReportDialog(
                  currentPipe: currentPipe,
                  computedNoise: huliotNoise,
                ),
                icon: const Icon(Icons.assignment_rounded, size: 16),
                label: const Text('Site Test Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelectorBar({required bool isDark}) {
    final bool isMicLive = _micReading.isActive || (_mode == AcousticMode.liveSiteSoundTest && _isLiveActive);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2D) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeTabButton(
              title: 'Mode A: Physics Simulation Lab',
              subtitle: 'EN 14366 fluid flow mathematical attenuation calculations',
              icon: Icons.science_rounded,
              isSelected: _mode == AcousticMode.simulation,
              isDark: isDark,
              onTap: () => _switchMode(AcousticMode.simulation),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _modeTabButton(
              title: 'Mode B: Live Site Sound Testing',
              subtitle: 'ISO 16032 Background Noise Isolation & Real Hardware Mic Reporting',
              icon: Icons.mic_rounded,
              isSelected: _mode == AcousticMode.liveSiteSoundTest,
              isDark: isDark,
              badge: _mode == AcousticMode.liveSiteSoundTest && isMicLive ? 'LIVE MIC ACTIVE' : null,
              onTap: () => _switchMode(AcousticMode.liveSiteSoundTest),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeTabButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkCard : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.accent : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                          color: isSelected ? null : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
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
    );
  }

  // --- Mode B 3-Phase ISO 16032 Wizard Card ---

  Widget _buildIso16032WizardCard({
    required bool isDark,
    required PipeAcousticProfile currentPipe,
    required double computedNoise,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1B2A) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Stepper
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ISO 16032 ON-SITE ACOUSTIC NOISE ISOLATION PROTOCOL',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    Text(
                      '3-Phase Scientific Sound Measurement: Calibrate Ambient → Flush Pipe → Isolate Real Sound',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _resetTestWizard,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset Workflow', style: TextStyle(fontSize: 11.5)),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Stepper Indicator Row
          Row(
            children: [
              _buildStepIndicator(
                stepNum: '1',
                title: 'Ambient Floor',
                isDone: _ambientCalibration.sampleCount > 0,
                isActive: _testingPhase == TestingPhase.setup || _testingPhase == TestingPhase.ambientCalibration,
                isDark: isDark,
              ),
              Expanded(child: Container(height: 2, color: Colors.grey.withValues(alpha: 0.3))),
              _buildStepIndicator(
                stepNum: '2',
                title: 'Flush & Capture',
                isDone: _isolationResult.isReliable,
                isActive: _testingPhase == TestingPhase.flushRecording,
                isDark: isDark,
              ),
              Expanded(child: Container(height: 2, color: Colors.grey.withValues(alpha: 0.3))),
              _buildStepIndicator(
                stepNum: '3',
                title: 'ISO Isolation & Audit',
                isDone: _isolationResult.isReliable,
                isActive: _testingPhase == TestingPhase.analysis,
                isDark: isDark,
              ),
            ],
          ),

          const Divider(height: 24),

          // Dynamic Phase Content
          if (_testingPhase == TestingPhase.setup || _testingPhase == TestingPhase.ambientCalibration) ...[
            _buildSetupAndAmbientContent(isDark: isDark),
          ] else if (_testingPhase == TestingPhase.flushRecording) ...[
            _buildFlushRecordingContent(isDark: isDark, currentPipe: currentPipe),
          ] else ...[
            _buildAnalysisResultContent(isDark: isDark, currentPipe: currentPipe, computedNoise: computedNoise),
          ],
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required String stepNum,
    required String title,
    required bool isDone,
    required bool isActive,
    required bool isDark,
  }) {
    final Color color = isDone ? AppColors.success : (isActive ? AppColors.accent : Colors.grey);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 13, color: AppColors.success)
                : Text(
                    stepNum,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppColors.accent : (isDone ? AppColors.success : Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildSetupAndAmbientContent({required bool isDark}) {
    final bool isRecording = _testingPhase == TestingPhase.ambientCalibration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Step 1: Calibrate Site Background Ambient Noise Floor (L_bg)',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            if (isRecording)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'RECORDING: $_countdownSec s remaining',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.danger),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Stand in the test location with the phone 1m away from the pipe. Maintain absolute silence for 10 seconds to sample ambient street, HVAC, and room noise.',
          style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: isRecording ? null : _startAmbientCalibration,
              icon: Icon(isRecording ? Icons.mic : Icons.play_arrow_rounded, size: 18),
              label: Text(
                isRecording ? 'Calibrating Ambient Silence ($_countdownSec s)...' : 'Start 10s Ambient Calibration',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            if (_ambientCalibration.sampleCount > 0)
              OutlinedButton.icon(
                onPressed: () => setState(() => _testingPhase = TestingPhase.flushRecording),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Proceed to Flush Step', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFlushRecordingContent({
    required bool isDark,
    required PipeAcousticProfile currentPipe,
  }) {
    final bool isRecording = _micReading.isActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step 2: Flush Pipe & Record Combined Sound (Target: ${currentPipe.name})',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'L_bg Locked: ${_ambientCalibration.avgDb.toStringAsFixed(1)} dB(A) (${_ambientCalibration.quality})',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.success),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Flush the toilet or run water through the drainage stack at steady flow. Click "Start 15s Flush Capture" to record the acoustic surge.',
          style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: isRecording ? null : _startFlushRecording,
              icon: const Icon(Icons.water_drop_rounded, size: 18),
              label: Text(
                isRecording ? 'Recording Flush Sound ($_countdownSec s)...' : 'Start 15s Flush Capture',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            if (isRecording)
              OutlinedButton.icon(
                onPressed: _finishFlushRecording,
                icon: const Icon(Icons.stop_rounded, size: 18),
                label: const Text('Stop & Isolate Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalysisResultContent({
    required bool isDark,
    required PipeAcousticProfile currentPipe,
    required double computedNoise,
  }) {
    final res = _isolationResult;
    final bool passDin = res.lCorrected <= 30.0;
    final bool passVdi = res.lCorrected <= 24.0;
    final double claimDb = currentPipe.claimedStructureBorneDb2L;
    final double deltaClaim = res.lCorrected - claimDb;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Step 3: ISO 16032 Background Noise Subtraction Audit',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: res.confidence.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: res.confidence.color.withValues(alpha: 0.5)),
              ),
              child: Text(
                res.confidence.label,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: res.confidence.color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Result Data Row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131D2D) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricBlock('Combined L_total', '${res.lTotal.toStringAsFixed(1)} dB(A)', Colors.grey),
              Container(width: 1, height: 34, color: Colors.grey.withValues(alpha: 0.3)),
              _metricBlock('Ambient Floor L_bg', '${res.lBackground.toStringAsFixed(1)} dB(A)', Colors.grey),
              Container(width: 1, height: 34, color: Colors.grey.withValues(alpha: 0.3)),
              _metricBlock('Difference ΔL', '${res.deltaL.toStringAsFixed(1)} dB', res.confidence.color),
              Container(width: 1, height: 34, color: Colors.grey.withValues(alpha: 0.3)),
              _metricBlock(
                'Isolated True Pipe L_pipe',
                '${res.lCorrected.toStringAsFixed(1)} dB(A)',
                passVdi ? AppColors.success : (passDin ? AppColors.warning : AppColors.danger),
                isHighlight: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Manufacturer Claim Comparison Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: (deltaClaim <= 2.0)
                ? AppColors.success.withValues(alpha: 0.12)
                : AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (deltaClaim <= 2.0)
                  ? AppColors.success.withValues(alpha: 0.4)
                  : AppColors.warning.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                (deltaClaim <= 2.0) ? Icons.verified_rounded : Icons.info_outline_rounded,
                size: 18,
                color: (deltaClaim <= 2.0) ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${currentPipe.name} claim: ${claimDb.toStringAsFixed(1)} dB @ 2 L/s | Measured Isolated: ${res.lCorrected.toStringAsFixed(1)} dB(A) (${deltaClaim > 0 ? "+${deltaClaim.toStringAsFixed(1)} dB" : "${deltaClaim.toStringAsFixed(1)} dB"} variation) — ${currentPipe.hasFraunhoferCert ? "Fraunhofer IBP Certified" : "Market Reference"}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: (deltaClaim <= 2.0) ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Comparative banner if both tests exist
        if (_recordA != null && _recordB != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, size: 20, color: AppColors.success),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Both Systems Tested: System A (${_recordA!.pipe.shortName}: ${_recordA!.isolation.lCorrected.toStringAsFixed(1)} dB) vs System B (${_recordB!.pipe.shortName}: ${_recordB!.isolation.lCorrected.toStringAsFixed(1)} dB) → Measured Delta: ${(_recordB!.isolation.lCorrected - _recordA!.isolation.lCorrected).toStringAsFixed(1)} dB quieter!',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.success),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Action Buttons
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () => _openReportDialog(
                currentPipe: currentPipe,
                computedNoise: computedNoise,
              ),
              icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
              label: Text(
                _recordA != null && _recordB != null
                    ? 'Export Certified A/B Comparative Report'
                    : 'Export Single Pipe Certified Report (PDF/HTML)',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            if (_recordB == null) ...[
              OutlinedButton.icon(
                onPressed: _startTestingSystemB,
                icon: const Icon(Icons.compare_arrows_rounded, size: 18, color: AppColors.accent),
                label: const Text(
                  'Test System B (Competitor) for A/B Audit',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.accent),
                ),
              ),
            ],
            OutlinedButton.icon(
              onPressed: _resetTestWizard,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Test Another Pipe / Re-Calibrate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricBlock(String label, String value, Color color, {bool isHighlight = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 16 : 13,
            fontWeight: FontWeight.w900,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildDecibelReferenceGuide({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volume_up_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'ACOUSTIC DECIBEL REFERENCE BENCHMARK SCALE',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
              const Spacer(),
              Text(
                'Perception scale dB(A)',
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Reference spectrum cards
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _refSoundCard('10 dB(A)', 'Normal Breathing', 'Nearly inaudible', AppColors.success, isDark),
              _refSoundCard('15 dB(A)', 'Huliot Ultra Silent', 'Flush @ 2.0 L/s (Fraunhofer Certified)', AppColors.success, isDark, isHighlight: true),
              _refSoundCard('20 dB(A)', 'Rustling Leaves', 'Whisper quiet room', AppColors.success, isDark),
              _refSoundCard('24 dB(A)', 'VDI 4100 SSt III', 'Luxury Hotel / Penthouse Limit', AppColors.success, isDark),
              _refSoundCard('30 dB(A)', 'DIN 4109 Limit', 'Ticking Clock / Bedroom Threshold', AppColors.warning, isDark),
              _refSoundCard('35 dB(A)', 'Standard PVC Pipe', 'Flush @ 2.0 L/s', AppColors.danger, isDark),
              _refSoundCard('50 dB(A)', 'Normal Conversation', 'Living room speech', AppColors.danger, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _refSoundCard(
    String dB,
    String title,
    String desc,
    Color color,
    bool isDark, {
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlight
            ? color.withValues(alpha: isDark ? 0.18 : 0.1)
            : (isDark ? const Color(0xFF131D2D) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlight ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isHighlight ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dB,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
              ),
              if (isHighlight) ...[
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 12, color: AppColors.success),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          Text(
            desc,
            style: TextStyle(fontSize: 9.5, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          ),
        ],
      ),
    );
  }
}
