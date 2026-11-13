import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/fixture_model.dart';
import '../../models/simulation_state.dart';
import '../../physics/drainage_physics_engine.dart';
import '../../providers/simulator_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../widgets/panels/charts_panel.dart';
import '../widgets/panels/parameters_panel.dart';
import '../widgets/panels/results_panel.dart';
import '../widgets/panels/visualizer_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _leftTabController;
  bool _isVisualizerFullScreen = false;
  TestRunStatus _lastKnownTestStatus = TestRunStatus.idle;
  bool _lastKnownMonteCarloCompleted = false;

  @override
  void initState() {
    super.initState();
    _leftTabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _leftTabController.dispose();
    super.dispose();
  }

  void _showExportCsvDialog(BuildContext context, SimulatorProvider provider) {
    final String csvData = provider.generateCsv();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.table_chart_rounded, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Simulation Peak Data (CSV)'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Floor-by-floor dynamic peak pressure and residual trap seal data:',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SelectableText(
                  csvData,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csvData));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV copied to clipboard!')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy to Clipboard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTestCompletedDialog(BuildContext context, SimulatorProvider provider) {
    final maxCap = DrainagePhysicsEngine.getMaxCapacity(provider.params.stackDiameter, provider.params.teeType);
    final bool isOverloaded = provider.totalDischargeFlow > maxCap;
    final bool isFullBuildingOverload = provider.activeReportType == FlowLabReportType.overloadStress;
    final isPass = (provider.verdict == StandardVerdict.pass) && !isOverloaded;
    final String sysDetail = switch (provider.params.prlOption) {
      2 => 'PRL System B (Stack Offset Loop)',
      3 => 'PRL System C (Straight Stack, Base Rejoin)',
      _ => 'PRL System A (Beside Stack, 45° Bends)',
    };
    final dyn = provider.currentDynamicState;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: provider.isDarkMode ? const Color(0xFF131B26) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: (isPass ? AppColors.success : AppColors.danger).withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isPass ? AppColors.success : AppColors.danger).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPass ? Icons.verified_rounded : Icons.warning_rounded,
                color: isPass ? AppColors.success : AppColors.danger,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFullBuildingOverload
                        ? '⚠️ Full Building Overload Test Complete!'
                        : 'EN 12056 Test Completed!',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    isFullBuildingOverload
                        ? 'All ${provider.params.floors} storeys discharged simultaneously · Table 12 overload evaluated'
                        : 'Simulation auto-paused at steady state · Data certified',
                    style: TextStyle(
                      fontSize: 11,
                      color: provider.isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close Window',
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Verdict Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: (isPass ? AppColors.success : AppColors.danger).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: (isPass ? AppColors.success : AppColors.danger).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(isPass ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isPass ? AppColors.success : AppColors.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isPass
                            ? 'PASS • FULLY COMPLIANT (Pressures within ±25 mm WG)'
                            : (isOverloaded
                                ? 'FAIL • OVERLOAD EXCEEDS TABLE 12 (${provider.totalDischargeFlow.toStringAsFixed(1)} L/s > ${maxCap.toStringAsFixed(1)} L/s Limit)'
                                : 'FAIL • DANGEROUS SEAL LOSS / SURGE EXCEEDED ±25 mm WG'),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isPass ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Test Metrics 3-Column Grid
              Row(
                children: [
                  Expanded(
                    child: _metricBox(
                      title: 'Peak Positive',
                      val: '+${dyn.peakAllPositive.toStringAsFixed(1)} mm',
                      sub: 'Limit: ≤ +25 mm',
                      isGood: dyn.peakAllPositive <= 25,
                      isDark: provider.isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _metricBox(
                      title: 'Peak Suction',
                      val: '-${dyn.peakAllNegative.toStringAsFixed(1)} mm',
                      sub: 'Limit: ≤ -25 mm',
                      isGood: dyn.peakAllNegative <= 25,
                      isDark: provider.isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _metricBox(
                      title: 'Ground Trap',
                      val: '${dyn.trapSealRetention[0].toStringAsFixed(0)} mm',
                      sub: '${(dyn.trapSealRetention[0] / provider.params.trapSealDepth * 100).toStringAsFixed(0)}% retained',
                      isGood: dyn.trapSealRetention[0] >= 25,
                      isDark: provider.isDarkMode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tested Architecture Summary
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: provider.isDarkMode ? Colors.black26 : Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _specRow('Building Height:', '${provider.params.floors} Storeys (${provider.buildingHeightM.toStringAsFixed(1)} m)', provider.isDarkMode),
                    _specRow('Flushing Load:', '${provider.params.nActive} Floors (${provider.totalDischargeFlow.toStringAsFixed(1)} L/s)', provider.isDarkMode),
                    _specRow('Terminal Velocity (Vt):', '${provider.terminalVelocity.toStringAsFixed(1)} m/s (Wyly-Eaton, Lt = ${provider.terminalLength.toStringAsFixed(1)} m)', provider.isDarkMode),
                    _specRow('PRL Arrangement:', sysDetail, provider.isDarkMode),
                    _specRow('Trap Seal Depth:', '${provider.params.trapSealDepth} mm initial depth', provider.isDarkMode),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(ctx, rootNavigator: true).pop();
              provider.resumeContinuousPlay();
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: const Text('Resume Play'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(ctx, rootNavigator: true).pop();
              provider.startOfficialTest();
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Run Again'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              provider.openPrintableReport();
            },
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text('View / Print PDF'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx, rootNavigator: true).pop();
              provider.downloadPdfReport();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📥 Official Test Report generated & downloaded (${provider.params.floors}F)!'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            ),
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Download Official PDF Report', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showMonteCarloCompletedDialog(BuildContext context, SimulatorProvider provider) {
    final dyn = provider.currentDynamicState;
    final double maxCap = DrainagePhysicsEngine.getMaxCapacity(provider.params.stackDiameter, provider.params.teeType);
    final double peakRushFlow = provider.peakConcurrentFlushes * provider.params.flowPerFloor;
    final bool isRushOverloaded = peakRushFlow > maxCap;
    final isCompliant = !isRushOverloaded && dyn.peakAllPositive <= 25 && dyn.peakAllNegative <= 25 && dyn.trapSealRetention[0] >= 25;

    final (String sysLetter, String sysDetail) = switch (provider.params.prlOption) {
      2 => ('System B', 'PRL System B (Offset Loop)'),
      3 => ('System C', 'PRL System C (Straight Stack, Base Rejoin)'),
      _ => ('System A', 'PRL System A (Beside Stack, 45° Bends)'),
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: provider.isDarkMode ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isCompliant ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFFEF4444).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompliant ? Icons.check_circle_rounded : Icons.warning_rounded,
                color: isCompliant ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎲 Morning Rush Sim Complete!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    '1-Hour Peak Morning Concurrency (07:30 - 08:30 AM Simulated)',
                    style: TextStyle(fontSize: 11, color: provider.isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close Window',
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCompliant ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCompliant ? const Color(0xFF10B981).withValues(alpha: 0.4) : const Color(0xFFEF4444).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCompliant ? Icons.verified_rounded : Icons.error_outline_rounded,
                      color: isCompliant ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isCompliant
                            ? 'PASS • REALISTIC TRAP INTEGRITY CERTIFIED (Zero Gas Leak)'
                            : (isRushOverloaded
                                ? 'FAIL • PEAK CONCURRENCY EXCEEDED TABLE 12 (${peakRushFlow.toStringAsFixed(1)} L/s > ${maxCap.toStringAsFixed(1)} L/s Limit)'
                                : 'FAIL • HAZARDOUS PRESSURE SURGE DETECTED UNDER RUSH LOAD'),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isCompliant ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _metricBox(
                      title: 'Peak Concurrency',
                      val: '${provider.peakConcurrentFlushes} Floors',
                      sub: '${(provider.peakConcurrentFlushes * provider.params.flowPerFloor).toStringAsFixed(1)} L/s instant load',
                      isGood: true,
                      isDark: provider.isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _metricBox(
                      title: 'Total Rush Flushes',
                      val: '${provider.totalFlushesTriggered}',
                      sub: 'Poisson arrival',
                      isGood: true,
                      isDark: provider.isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _metricBox(
                      title: 'Min Trap Seal',
                      val: '${dyn.trapSealRetention[0].toStringAsFixed(0)} mm',
                      sub: '${(dyn.trapSealRetention[0] / provider.params.trapSealDepth * 100).toStringAsFixed(0)}% retained',
                      isGood: dyn.trapSealRetention[0] >= 25,
                      isDark: provider.isDarkMode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: provider.isDarkMode ? Colors.black26 : Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _specRow('Building Height:', '${provider.params.floors} Storeys (${provider.buildingHeightM.toStringAsFixed(1)} m)', provider.isDarkMode),
                    _specRow('Wyly-Eaton Velocity (Vt):', '${provider.terminalVelocity.toStringAsFixed(1)} m/s (Fall Lt = ${provider.terminalLength.toStringAsFixed(1)} m)', provider.isDarkMode),
                    _specRow('Annular Water Film (tw):', '${provider.filmThicknessMm.toStringAsFixed(1)} mm (Air Core \u2205: ${provider.airCoreDiameterMm.toStringAsFixed(0)} mm, ${(provider.airCoreAreaFraction * 100).toStringAsFixed(0)}% Open)', provider.isDarkMode),
                    _specRow('PRL Arrangement:', sysDetail, provider.isDarkMode),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(ctx, rootNavigator: true).pop();
              provider.resumeContinuousPlay();
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: const Text('Resume Play'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(ctx, rootNavigator: true).pop();
              provider.startMonteCarloRush();
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Run Rush Again'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              provider.openPrintableMonteCarloReport();
            },
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text('View / Print PDF'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx, rootNavigator: true).pop();
              provider.downloadMonteCarloReport();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📥 Morning Rush Report generated & downloaded (${provider.params.floors}F)!'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            ),
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Download Official PDF Report', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _metricBox({
    required String title,
    required String val,
    required String sub,
    required bool isGood,
    required bool isDark,
  }) {
    final color = isGood ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
          const SizedBox(height: 2),
          Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          Text(sub, style: TextStyle(fontSize: 9.5, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, SimulatorProvider provider) {
    final verdict = provider.verdict;
    final isPass = verdict == StandardVerdict.pass;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: AppColors.accent),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Engineering Test Report (EN 12056)'),
            ),
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generate and export an official performance report for this ${provider.params.floors}-storey building stack:',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isPass ? AppColors.success : AppColors.danger).withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${provider.params.floors} Floors (${(provider.params.floors * provider.params.floorHeight).toStringAsFixed(1)} m total height)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isPass ? AppColors.success : AppColors.danger).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isPass ? 'PASS • EN 12056' : 'HAZARD DETECTED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isPass ? AppColors.success : AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active Bathrooms: ${provider.params.nActive} / ${provider.params.floors} (${((provider.params.nActive / provider.params.floors) * 100).toStringAsFixed(0)}% load)',
                          style: const TextStyle(fontSize: 11),
                        ),
                        Text(
                          'Flow: ${provider.totalDischargeFlow.toStringAsFixed(1)} L/s (${(provider.totalDischargeFlow * 60).toStringAsFixed(0)} L/min)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Peak Positive: +${provider.currentDynamicState.peakAllPositive.toStringAsFixed(1)} mm WG',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: provider.currentDynamicState.peakAllPositive > 25 ? AppColors.danger : AppColors.success,
                          ),
                        ),
                        Text(
                          'Peak Suction: -${provider.currentDynamicState.peakAllNegative.toStringAsFixed(1)} mm WG',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: provider.currentDynamicState.peakAllNegative > 25 ? AppColors.danger : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Choose report export option:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(ctx, rootNavigator: true).pop();
              provider.openPrintableReport();
            },
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text('Print / View Report (with Schematics)'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx, rootNavigator: true).pop();
              provider.downloadPdfReport();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📥 Downloaded Huliot_FlowLab_Test_Report_${provider.params.floors}F.html'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Download Official PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftStatusBanner(SimulatorProvider prov, bool isDark) {
    if (prov.isTestRunning) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF0284C7).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accent, width: 1.2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'TEST IN PROGRESS: ${prov.testPhaseText}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: AppColors.accent),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(prov.testProgress * 100).toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.accent),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: prov.testProgress,
                minHeight: 3.5,
                backgroundColor: isDark ? Colors.white12 : Colors.black12,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
          ],
        ),
      );
    }

    if (prov.isTestCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF059669).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF10B981), width: 1.2),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF10B981)),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'TEST COMPLETE · CERTIFIED DATA READY',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Color(0xFF10B981)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              ),
              onPressed: () => _showTestCompletedDialog(context, prov),
              child: const Text('View Results 📄', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    final StandardVerdict verdict = prov.verdict;
    final SystemDynamicState dyn = prov.currentDynamicState;

    final (String label, Color color, IconData icon) = switch (verdict) {
      StandardVerdict.pass => ('PASS • EN 12056', AppColors.success, Icons.check_circle_rounded),
      StandardVerdict.marginal => ('MARGINAL WARNING', AppColors.warning, Icons.warning_rounded),
      StandardVerdict.fail => ('SEAL LOSS HAZARD', AppColors.danger, Icons.cancel_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Verdict Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Peak pressures
          Expanded(
            child: Text(
              '+${dyn.peakAllPositive.toStringAsFixed(1)} / -${dyn.peakAllNegative.toStringAsFixed(1)} mm WG',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Stack summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Text(
              '${prov.params.floors}F | ${prov.totalDischargeFlow.toStringAsFixed(1)} L/s',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SimulatorProvider prov = Provider.of<SimulatorProvider>(context);
    final bool isDark = prov.isDarkMode;

    if (_lastKnownTestStatus == TestRunStatus.running && prov.testStatus == TestRunStatus.completed) {
      _lastKnownTestStatus = prov.testStatus;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showTestCompletedDialog(context, prov);
        }
      });
    } else {
      _lastKnownTestStatus = prov.testStatus;
    }

    if (!_lastKnownMonteCarloCompleted && prov.isMonteCarloCompleted) {
      _lastKnownMonteCarloCompleted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showMonteCarloCompletedDialog(context, prov);
        }
      });
    } else if (!prov.isMonteCarloCompleted) {
      _lastKnownMonteCarloCompleted = false;
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppHeader(
        provider: prov,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onExportCsv: () => _showExportCsvDialog(context, prov),
        onExportPdf: () => _showReportDialog(context, prov),
      ),
      drawer: AppDrawer(provider: prov),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 950;

          if (isDesktop) {
            // Desktop Split Layout:
            // Left Column (38%): Parameters, Diagnostics, and Live Charts in 3 clean tabs
            // Right Column (62%): FULL HEIGHT CAD Visualizer (from header to bottom!)
            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Side (if not toggled full screen)
                  if (!_isVisualizerFullScreen)
                    Expanded(
                      flex: 38,
                      child: Column(
                        children: [
                          // Persistent Top Status & Compliance Bar
                          _buildLeftStatusBanner(prov, isDark),
                          const SizedBox(height: 8),

                          // Left Panel Tab Bar (3 tabs: Parameters, Diagnostics, Charts)
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            child: TabBar(
                              controller: _leftTabController,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicator: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                              tabs: const [
                                Tab(
                                  icon: Icon(Icons.tune_rounded, size: 14),
                                  text: 'Controls',
                                ),
                                Tab(
                                  icon: Icon(Icons.health_and_safety_rounded, size: 14),
                                  text: 'Trap Health',
                                ),
                                Tab(
                                  icon: Icon(Icons.analytics_rounded, size: 14),
                                  text: 'Live Charts',
                                ),
                                Tab(
                                  icon: Icon(Icons.receipt_long_rounded, size: 14),
                                  text: 'Audit Log',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Left Panel Tab Content (Takes full remaining vertical space)
                          Expanded(
                            child: TabBarView(
                              controller: _leftTabController,
                              children: [
                                // Tab 1: Building Height, Workload, Presets, Specs
                                ParametersPanel(provider: prov, isDarkMode: isDark),

                                // Tab 2: EN 12056 Verdict, KPIs, Interactive Floor Matrix (F1-FN), Recommendations
                                ResultsPanel(provider: prov, isDarkMode: isDark),

                                // Tab 3: Pressure vs Height Canvas Chart, Dynamic Waveforms
                                ChartsPanel(
                                  params: prov.params,
                                  staticResult: prov.currentResult,
                                  noPrlResult: prov.resultNoPrl,
                                  dynamicState: prov.currentDynamicState,
                                  isDarkMode: isDark,
                                ),

                                // Tab 4: Live Chronological Event Ledger & DU Schedule
                                _buildAuditLogTab(prov, isDark),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!_isVisualizerFullScreen)
                    const SizedBox(width: 10),

                  // Right Side: 100% Full Height Visualizer
                  Expanded(
                    flex: _isVisualizerFullScreen ? 100 : 62,
                    child: VisualizerPanel(
                      provider: prov,
                      isDarkMode: isDark,
                      isFullScreen: _isVisualizerFullScreen,
                      onToggleFullScreen: () {
                        setState(() {
                          _isVisualizerFullScreen = !_isVisualizerFullScreen;
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Mobile / Tablet Tabbed Layout
            return DefaultTabController(
              length: 5,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Visualizer', icon: Icon(Icons.architecture_rounded, size: 16)),
                      Tab(text: 'Controls', icon: Icon(Icons.tune_rounded, size: 16)),
                      Tab(text: 'Trap Health', icon: Icon(Icons.health_and_safety_rounded, size: 16)),
                      Tab(text: 'Charts', icon: Icon(Icons.analytics_rounded, size: 16)),
                      Tab(text: 'Audit Log', icon: Icon(Icons.receipt_long_rounded, size: 16)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: VisualizerPanel(
                            provider: prov,
                            isDarkMode: isDark,
                            isFullScreen: true,
                          ),
                        ),
                        ParametersPanel(provider: prov, isDarkMode: isDark),
                        ResultsPanel(provider: prov, isDarkMode: isDark),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ChartsPanel(
                            params: prov.params,
                            staticResult: prov.currentResult,
                            noPrlResult: prov.resultNoPrl,
                            dynamicState: prov.currentDynamicState,
                            isDarkMode: isDark,
                          ),
                        ),
                        _buildAuditLogTab(prov, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildAuditLogTab(SimulatorProvider prov, bool isDark) {
    final logs = prov.chronologicalEventLogs;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Discharge Unit (DU) Schedule per EN 12056-2
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.table_chart_rounded, size: 15, color: AppColors.accent),
                        SizedBox(width: 6),
                        Text(
                          'Typical Toilet 1 • DU Schedule (EN 12056)',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      'K = ${prov.params.kFactor} (${prov.params.occupancyType.toUpperCase()})',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Washbasin: 0.5 DU (0.5 L/s)', style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87)),
                    Text('WC (6L): 2.0 DU (1.8 L/s)', style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87)),
                    Text('Shower: 0.6 DU (0.6 L/s)', style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87)),
                  ],
                ),
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Cumulative DU: ${prov.buildingTotalDU.toStringAsFixed(1)} DU (${prov.params.floors}F)',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.accent),
                    ),
                    Text(
                      'Peak Design Q: ${prov.en12056DesignFlow.toStringAsFixed(2)} L/s (K=${prov.params.kFactor})',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'EN 12056 Table 12 Limit: Huliot Swept = ${prov.table12SweptCapacity.toStringAsFixed(1)} L/s vs Square = ${prov.table12SquareCapacity.toStringAsFixed(1)} L/s (+${prov.sweptCapacityHeadroomPercent.toStringAsFixed(1)}% headroom)',
                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF0284C7), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Audit Log Subheader
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_toggle_off_rounded, size: 14, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 5),
                  Text(
                    'Chronological Event Ledger (${logs.length} events)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                'Laptop Clock Sync',
                style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white54 : Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Events List
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hourglass_empty_rounded, size: 28, color: isDark ? Colors.white24 : Colors.black26),
                        const SizedBox(height: 6),
                        Text(
                          'No discharge events logged yet.\nRun Morning Rush or Standard Test to capture live timestamps.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10.5, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      // Reverse order: newest on top
                      final ev = logs[logs.length - 1 - index];
                      final isSafe = ev.minTrapSealMm >= 25.0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Sequence & Laptop Time
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '#${ev.seq.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent),
                                ),
                                Text(
                                  ev.timeFormatted,
                                  style: TextStyle(fontSize: 9.5, fontFamily: 'monospace', color: isDark ? Colors.white70 : Colors.black54),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),

                            // Floor & Fixture Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'F${ev.floor}',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Fixture Name & DU
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${ev.fixtureType.icon} ${ev.fixtureType.displayName} (${ev.du} DU)',
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Flow: ${ev.flowRateLs} L/s • Gap: ${ev.seq == 1 ? "Start" : "+${ev.timeGapSeconds.toStringAsFixed(1)}s"} • Stack: ${ev.instantaneousStackFlowLs.toStringAsFixed(1)} L/s',
                                    style: TextStyle(fontSize: 9.5, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Surge & Trap Seal
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '+${ev.peakPositiveSurgeMm.toStringAsFixed(1)} mm',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: ev.peakPositiveSurgeMm > 25 ? AppColors.danger : AppColors.success,
                                  ),
                                ),
                                Text(
                                  'Seal: ${ev.minTrapSealMm.toStringAsFixed(0)} mm',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: isSafe ? const Color(0xFF0284C7) : AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
