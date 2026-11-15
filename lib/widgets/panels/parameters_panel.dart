import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../models/simulation_params.dart';
import '../../models/simulation_state.dart';
import '../../providers/simulator_provider.dart';

class ParametersPanel extends StatelessWidget {
  final SimulatorProvider provider;
  final bool isDarkMode;

  const ParametersPanel({
    super.key,
    required this.provider,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final SimulationParams p = provider.params;
    final bool isTesting = provider.isTestRunning || provider.isMonteCarloRunning;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simulation Testing Mode Selector: Standard EN 12056 vs Morning Rush (Monte Carlo)
          _buildSimulationModeCard(context, provider),
          const SizedBox(height: 12),

          // Visual Parameter Lock Banner during Active Test Run
          if (isTesting)
            _buildParameterLockBanner(context),

          // Parameter Controls (Locked & Dimmed during Active Testing for certified scientific accuracy)
          IgnorePointer(
            ignoring: isTesting,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isTesting ? 0.60 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Fixed Building Height (Floors) & Floor Height (m)
                  _buildFloorsStepper(context, p),
                  const SizedBox(height: 12),

                  // Section 1B: Building Occupancy & EN 12056 Table 12 Capacity Headroom
                  _buildOccupancyAndStandardsCard(context, provider),
                  const SizedBox(height: 12),

                  // Section 2: Real-time Hydraulic Workload Card
                  _buildWorkloadCard(context, p),
                  const SizedBox(height: 12),

                  // Section 3: Engineering Scenarios (Preserves User Floors!)
                  _buildPresetsRow(context, p),
                  const SizedBox(height: 14),

                  // Section 4: PRL Systems A, B, C
                  _buildSystemCards(context, p),
                  const SizedBox(height: 14),

                  // Section 5: Key Specifications Grid (Now includes Trap Seal Depth!)
                  _buildSpecificationPickers(context, p),
                  const SizedBox(height: 14),

                  // Section 6: Sliders for Loading & Surge
                  _buildHydraulicSliders(context, p),
                  const SizedBox(height: 14),

                  // Section 7: Quick Action Buttons & Peak Data Export
                  _buildQuickActionButtons(context, p),
                  const SizedBox(height: 14),

                  // Section 8: Simulation Execution & Mode
                  _buildSimulationControls(context, p),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterLockBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.lock_rounded, size: 16, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parameters Locked · Test in Progress',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFFF59E0B)),
                ),
                SizedBox(height: 1),
                Text(
                  'Inputs locked for certified scientific accuracy',
                  style: TextStyle(fontSize: 9.5, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
              foregroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => provider.abortTest(),
            child: const Text('Abort ⏹', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- Interactive Info Notch Helper Components ---
  Widget _buildInfoNotch({
    required BuildContext context,
    required String title,
    required String what,
    required String how,
    required String impact,
  }) {
    return InkWell(
      onTap: () => _showNotchDetailDialog(
        context: context,
        title: title,
        what: what,
        how: how,
        impact: impact,
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, size: 12.5, color: AppColors.accent),
            SizedBox(width: 3),
            Text(
              'INFO',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotchDetailDialog({
    required BuildContext context,
    required String title,
    required String what,
    required String how,
    required String impact,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF131B26) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.4)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.psychology_alt_rounded, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailBlock(
                  icon: Icons.menu_book_rounded,
                  iconColor: const Color(0xFF38BDF8),
                  title: 'यह क्या है? (What is it?)',
                  text: what,
                  bg: const Color(0xFF0284C7).withValues(alpha: 0.1),
                ),
                const SizedBox(height: 10),
                _detailBlock(
                  icon: Icons.touch_app_rounded,
                  iconColor: const Color(0xFF34D399),
                  title: 'इसे कैसे यूज़ करें? (How to use it?)',
                  text: how,
                  bg: const Color(0xFF10B981).withValues(alpha: 0.1),
                ),
                const SizedBox(height: 10),
                _detailBlock(
                  icon: Icons.bolt_rounded,
                  iconColor: const Color(0xFFFBBF24),
                  title: 'सिस्टम पर क्या इम्पैक्ट आता है? (Hydraulic Impact)',
                  text: impact,
                  bg: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('समझ गया (Got It)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _detailBlock({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String text,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              height: 1.45,
              color: isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  // --- Controls Sections ---
  Widget _buildSimulationModeCard(BuildContext context, SimulatorProvider prov) {
    final FlowLabReportType currentMode = prov.isMonteCarloMode
        ? FlowLabReportType.morningRushAudit
        : prov.activeReportType;

    Color modeBorderColor;
    if (prov.isMonteCarloMode) {
      modeBorderColor = const Color(0xFFF59E0B);
    } else if (prov.activeReportType == FlowLabReportType.scenarioLab) {
      modeBorderColor = const Color(0xFF2563EB);
    } else {
      modeBorderColor = AppColors.accent.withValues(alpha: 0.4);
    }

    return Card(
      color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: modeBorderColor,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  prov.isMonteCarloMode
                      ? Icons.casino_rounded
                      : (prov.activeReportType == FlowLabReportType.scenarioLab ? Icons.science_rounded : Icons.verified_rounded),
                  size: 18,
                  color: prov.isMonteCarloMode
                      ? const Color(0xFFF59E0B)
                      : (prov.activeReportType == FlowLabReportType.scenarioLab ? const Color(0xFF2563EB) : AppColors.accent),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Simulation Testing Mode',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (prov.isMonteCarloMode
                            ? const Color(0xFFF59E0B)
                            : (prov.activeReportType == FlowLabReportType.scenarioLab ? const Color(0xFF2563EB) : AppColors.accent))
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    prov.isMonteCarloMode
                        ? 'Monte Carlo'
                        : (prov.activeReportType == FlowLabReportType.scenarioLab ? 'Scenario Lab' : 'EN 12056 Std'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: prov.isMonteCarloMode
                          ? const Color(0xFFF59E0B)
                          : (prov.activeReportType == FlowLabReportType.scenarioLab ? const Color(0xFF2563EB) : AppColors.accent),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 3-Mode Selector Tabs: Standard vs Scenario Lab vs Morning Rush
            Row(
              children: [
                // 1. Standard Test
                Expanded(
                  child: InkWell(
                    onTap: prov.isTestRunning || prov.isMonteCarloRunning
                        ? null
                        : () => prov.setTestingMode(FlowLabReportType.standardCompliance),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: currentMode == FlowLabReportType.standardCompliance
                            ? (isDarkMode ? AppColors.accent.withValues(alpha: 0.25) : AppColors.accent.withValues(alpha: 0.15))
                            : (isDarkMode ? AppColors.darkCard : AppColors.lightCard),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: currentMode == FlowLabReportType.standardCompliance
                              ? AppColors.accent
                              : (isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
                          width: currentMode == FlowLabReportType.standardCompliance ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded,
                                  size: 13,
                                  color: currentMode == FlowLabReportType.standardCompliance ? AppColors.accent : Colors.grey),
                              const SizedBox(width: 4),
                              Text('Standard',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: currentMode == FlowLabReportType.standardCompliance ? AppColors.accent : null)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('EN 12056 Std',
                              style: TextStyle(fontSize: 9, color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // 2. Scenario Lab (Custom Diversity Study: 0s vs 15s)
                Expanded(
                  child: InkWell(
                    onTap: prov.isTestRunning || prov.isMonteCarloRunning
                        ? null
                        : () => prov.setTestingMode(FlowLabReportType.scenarioLab),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: currentMode == FlowLabReportType.scenarioLab
                            ? (isDarkMode ? const Color(0xFF2563EB).withValues(alpha: 0.25) : const Color(0xFF2563EB).withValues(alpha: 0.15))
                            : (isDarkMode ? AppColors.darkCard : AppColors.lightCard),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: currentMode == FlowLabReportType.scenarioLab
                              ? const Color(0xFF2563EB)
                              : (isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
                          width: currentMode == FlowLabReportType.scenarioLab ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.science_rounded, size: 13, color: Color(0xFF2563EB)),
                              const SizedBox(width: 4),
                              Text('Scenario Lab',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: currentMode == FlowLabReportType.scenarioLab ? const Color(0xFF2563EB) : null)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('0s vs 15s Gap',
                              style: TextStyle(fontSize: 9, color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // 3. Morning Rush
                Expanded(
                  child: InkWell(
                    onTap: prov.isTestRunning || prov.isMonteCarloRunning
                        ? null
                        : () => prov.setTestingMode(FlowLabReportType.morningRushAudit),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: currentMode == FlowLabReportType.morningRushAudit
                            ? (isDarkMode ? const Color(0xFFF59E0B).withValues(alpha: 0.25) : const Color(0xFFF59E0B).withValues(alpha: 0.15))
                            : (isDarkMode ? AppColors.darkCard : AppColors.lightCard),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: currentMode == FlowLabReportType.morningRushAudit
                              ? const Color(0xFFF59E0B)
                              : (isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
                          width: currentMode == FlowLabReportType.morningRushAudit ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('🎲 ', style: TextStyle(fontSize: 11)),
                              Text('Rush',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: currentMode == FlowLabReportType.morningRushAudit ? const Color(0xFFF59E0B) : null)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('1-Hr Morning',
                              style: TextStyle(fontSize: 9, color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Dynamic Immediate Action Card for the Active Mode
            if (prov.isTestRunning) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            prov.activeReportType == FlowLabReportType.scenarioLab
                                ? 'SCENARIO LAB STUDY IN PROGRESS'
                                : 'EN 12056 COMPLIANCE TEST IN PROGRESS',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppColors.accent),
                          ),
                        ),
                        Text(
                          '${(prov.testProgress * 100).toInt()}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: prov.testProgress,
                        minHeight: 5,
                        backgroundColor: isDarkMode ? Colors.white12 : Colors.black12,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            prov.testPhaseText,
                            style: TextStyle(fontSize: 10.5, color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: AppColors.danger,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          ),
                          onPressed: () => prov.resetTestState(),
                          child: const Text('Cancel Test', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (prov.isTestCompleted) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, size: 18, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prov.activeReportType == FlowLabReportType.scenarioLab
                                    ? 'Scenario Diversity Study Completed (${prov.scenarioTargetFloors} Floors)'
                                    : 'Compliance Test Completed (${prov.params.floors} Floors)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.success),
                              ),
                              Text(
                                'Simulation auto-paused at steady state · Data certified',
                                style: TextStyle(fontSize: 10, color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 15),
                            label: Text(
                              prov.activeReportType == FlowLabReportType.scenarioLab
                                  ? 'Download Scenario Report 📄'
                                  : 'Download Official PDF 📄',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              prov.downloadPdfReport();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Downloaded Certified Report (${prov.params.floors}F)!')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            side: BorderSide(color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 16),
                          label: const Text('Resume Play', style: TextStyle(fontSize: 11)),
                          onPressed: () => prov.resumeContinuousPlay(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (prov.isMonteCarloMode) ...[
              // Morning Rush Mode Card
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.black38 : Colors.white70,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_filled_rounded, size: 14, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 5),
                            Text(
                              prov.isMonteCarloRunning
                                  ? 'Simulated Clock: ${prov.simulatedClockTime}'
                                  : 'Rush Window: 07:30 AM - 08:30 AM',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFFF59E0B)),
                            ),
                          ],
                        ),
                        Text(
                          '${prov.activeFloors.length} / ${prov.params.floors} Flushing',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (prov.isMonteCarloRunning) ...[
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: prov.monteCarloProgress,
                        color: const Color(0xFFF59E0B),
                        backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      ),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: prov.isMonteCarloRunning ? const Color(0xFFEF4444) : const Color(0xFFD97706),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () {
                          if (prov.isMonteCarloRunning) {
                            prov.pauseMonteCarloRush();
                          } else {
                            prov.startMonteCarloRush();
                          }
                        },
                        icon: Icon(prov.isMonteCarloRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 16),
                        label: Text(
                          prov.isMonteCarloRunning ? 'Pause Morning Rush' : 'Start 1-Hour Morning Rush Sim (45s)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (prov.activeReportType == FlowLabReportType.scenarioLab) ...[
              // Scenario Lab Execution Card: 0s Simultaneous Shock vs 15s Staggered Diversity
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.science_rounded, size: 16, color: Color(0xFF2563EB)),
                            SizedBox(width: 6),
                            Text(
                              'Scenario Lab: Custom Diversity Study',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF2563EB)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${prov.scenarioTargetFloors} Floors Target',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Floor Selector Row with Quick 11F Preset
                    Row(
                      children: [
                        Text(
                          'Test Floors: ',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white70 : Colors.black87),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            ),
                            child: Slider(
                              value: prov.scenarioTargetFloors.toDouble(),
                              min: 1,
                              max: prov.params.floors.toDouble(),
                              divisions: max(1, prov.params.floors - 1),
                              activeColor: const Color(0xFF2563EB),
                              onChanged: prov.isTestRunning
                                  ? null
                                  : (val) => prov.setScenarioTargetFloors(val.round()),
                            ),
                          ),
                        ),
                        Container(
                          width: 32,
                          alignment: Alignment.center,
                          child: Text(
                            '${prov.scenarioTargetFloors}F',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF2563EB)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Quick 11 Floors Button (User's benchmark)
                        InkWell(
                          onTap: prov.isTestRunning
                              ? null
                              : () => prov.setScenarioTargetFloors(min(11, prov.params.floors)),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: prov.scenarioTargetFloors == 11
                                  ? const Color(0xFF2563EB)
                                  : (isDarkMode ? Colors.white12 : Colors.black12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '11F Std',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: prov.scenarioTargetFloors == 11 ? Colors.white : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Strategy Selector: 0s Shock vs 15s Staggered vs Dual
                    Row(
                      children: [
                        // Case A: 0s Shock
                        Expanded(
                          child: InkWell(
                            onTap: prov.isTestRunning ? null : () => prov.setScenarioExecutionType('simultaneous'),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                              decoration: BoxDecoration(
                                color: prov.scenarioExecutionType == 'simultaneous'
                                    ? (isDarkMode ? const Color(0xFFEF4444).withValues(alpha: 0.25) : const Color(0xFFEF4444).withValues(alpha: 0.15))
                                    : (isDarkMode ? AppColors.darkCard : AppColors.lightCard),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: prov.scenarioExecutionType == 'simultaneous'
                                      ? const Color(0xFFEF4444)
                                      : (isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
                                  width: prov.scenarioExecutionType == 'simultaneous' ? 1.5 : 1.0,
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('🔴 0s Shock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFFEF4444))),
                                  Text('All at Once (Fail)', style: TextStyle(fontSize: 8.5, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Case B: 15s Staggered
                        Expanded(
                          child: InkWell(
                            onTap: prov.isTestRunning ? null : () => prov.setScenarioExecutionType('staggered'),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                              decoration: BoxDecoration(
                                color: prov.scenarioExecutionType == 'staggered'
                                    ? (isDarkMode ? const Color(0xFF10B981).withValues(alpha: 0.25) : const Color(0xFF10B981).withValues(alpha: 0.15))
                                    : (isDarkMode ? AppColors.darkCard : AppColors.lightCard),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: prov.scenarioExecutionType == 'staggered'
                                      ? const Color(0xFF10B981)
                                      : (isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
                                  width: prov.scenarioExecutionType == 'staggered' ? 1.5 : 1.0,
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('🟢 15s Gap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF10B981))),
                                  Text('Staggered (Pass)', style: TextStyle(fontSize: 8.5, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Case C: Dual Comparative
                        Expanded(
                          child: InkWell(
                            onTap: prov.isTestRunning ? null : () => prov.setScenarioExecutionType('dual'),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                              decoration: BoxDecoration(
                                color: prov.scenarioExecutionType == 'dual'
                                    ? (isDarkMode ? const Color(0xFF6366F1).withValues(alpha: 0.25) : const Color(0xFF6366F1).withValues(alpha: 0.15))
                                    : (isDarkMode ? AppColors.darkCard : AppColors.lightCard),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: prov.scenarioExecutionType == 'dual'
                                      ? const Color(0xFF6366F1)
                                      : (isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
                                  width: prov.scenarioExecutionType == 'dual' ? 1.5 : 1.0,
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('⚖️ Dual Study', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF6366F1))),
                                  Text('Side-by-Side', style: TextStyle(fontSize: 8.5, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Dynamic Description explaining physics
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black26 : Colors.white60,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        prov.scenarioExecutionType == 'simultaneous'
                            ? '🔴 0s Shock: All ${prov.scenarioTargetFloors} floors flush simultaneously (${(prov.scenarioTargetFloors * 2.0).toStringAsFixed(1)} L/s). Exceeds ${prov.activeTableReference} limit (${prov.activeStackCapacity.toStringAsFixed(1)} L/s), causing pipe choke & trap blowouts.'
                            : (prov.scenarioExecutionType == 'staggered'
                                ? '🟢 15s Gap: Each floor flushes with 15s interval. Instant load stays at 2.0 L/s, preserving continuous central air core and 100% trap water seal.'
                                : '⚖️ Dual Study: Computes both 0s Shock and 15s Staggered regimes side-by-side to generate an undeniable engineering proof report for clients.'),
                        style: TextStyle(
                          fontSize: 10,
                          color: prov.scenarioExecutionType == 'simultaneous'
                              ? const Color(0xFFEF4444)
                              : (prov.scenarioExecutionType == 'staggered' ? const Color(0xFF10B981) : const Color(0xFF6366F1)),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Run Test Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: prov.scenarioExecutionType == 'simultaneous'
                              ? const Color(0xFFDC2626)
                              : (prov.scenarioExecutionType == 'staggered' ? const Color(0xFF059669) : const Color(0xFF4F46E5)),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () => prov.runScenarioStudy(),
                        icon: const Icon(Icons.science_rounded, size: 16),
                        label: Text(
                          prov.scenarioExecutionType == 'dual'
                              ? 'Run Dual Comparative Study (${prov.scenarioTargetFloors}F)'
                              : (prov.scenarioExecutionType == 'staggered'
                                  ? 'Run 15s Staggered Study (${prov.scenarioTargetFloors}F)'
                                  : 'Run 0s Shock Study (${prov.scenarioTargetFloors}F)'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Standard EN 12056 Test Execution Card
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0C1929) : const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.science_rounded, size: 15, color: AppColors.accent),
                            SizedBox(width: 5),
                            Text(
                              'EN 12056 Certified Discharge Cycle',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.accent),
                            ),
                          ],
                        ),
                        Text(
                          '${min(prov.params.nActive, prov.params.floors)} / ${prov.params.floors} Floors',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tests steady-state fall, air core suction, and base backpressure for 10s. Auto-pauses at steady state.',
                      style: TextStyle(fontSize: 10, color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () => prov.startOfficialTest(),
                        icon: const Icon(Icons.play_circle_fill_rounded, size: 17),
                        label: Text(
                          '▶ Run Official Compliance Test (${min(prov.params.nActive, prov.params.floors)} Floors)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloorsStepper(BuildContext context, SimulationParams p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.apartment_rounded, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                const Flexible(
                  child: Text(
                    'Building Height (Floors)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                _buildInfoNotch(
                  context: context,
                  title: 'Building Height (Floors)',
                  what: 'बिल्डिंग के कुल फ्लोरों की संख्या और वर्टिकल ड्रेनेज स्टैक की कुल लम्बाई (मीटर में)। 1 फ्लोर = ${p.floorHeight.toStringAsFixed(1)} मीटर।',
                  how: 'माइनस (-) या प्लस (+) दबाकर 1-1 फ्लोर बदलें, या क्विक बटन (5F, 10F, 20F, 50F आदि) पर क्लिक करें। जब तक आप इसे नहीं बदलेंगे, यह हमेशा फिक्स रहेगा।',
                  impact: 'फ्लोर बढ़ने से पानी का ड्रॉप डिस्टेंस बढ़ता है जिससे टर्मिनल वेलोसिटी (लगभग 10-12 m/s) और एयर एनट्रेनमेंट बहुत बढ़ जाता है, जिससे नीचे के फ्लोरों पर बैकप्रेशर बढ़ता है।',
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 11, color: AppColors.success),
                      SizedBox(width: 3),
                      Text(
                        'Locked',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${(p.floors * p.floorHeight).toStringAsFixed(1)} m total stack height · Stays fixed until you change it',
              style: TextStyle(fontSize: 11, color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Stepper Buttons
                IconButton.filledTonal(
                  tooltip: 'Decrease 1 floor',
                  onPressed: p.floors > 2 ? () => provider.updateParams(p.copyWith(floors: p.floors - 1)) : null,
                  icon: const Icon(Icons.remove, size: 18),
                  style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
                Container(
                  width: 70,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: Text(
                    '${p.floors} F',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Increase 1 floor',
                  onPressed: p.floors < 100 ? () => provider.updateParams(p.copyWith(floors: p.floors + 1)) : null,
                  icon: const Icon(Icons.add, size: 18),
                  style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(width: 8),
                // Quick Floor Selection Chips
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [5, 10, 15, 20, 35, 50, 75, 100].map((count) {
                        final bool isSel = p.floors == count;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text('$count F'),
                            selected: isSel,
                            onSelected: (_) => provider.updateParams(p.copyWith(floors: count)),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? Colors.white : (isDarkMode ? AppColors.darkText : AppColors.lightText),
                            ),
                            selectedColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // Floor Height Slider (from original HTML)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.height_rounded, size: 15, color: AppColors.accent),
                    const SizedBox(width: 6),
                    const Text(
                      'Floor height (m)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    _buildInfoNotch(
                      context: context,
                      title: 'Floor-to-Floor Height (m)',
                      what: 'एक मंजिल से दूसरी मंजिल के बीच की ऊँचाई (Floor-to-Floor Height)। कुल स्टैक हाइट = Floors × Floor Height।',
                      how: 'स्लाइडर से 2.5m से 4.5m तक सेट करें। मानक आवासीय 3.0m होता है, कमर्शियल/हॉस्पिटल 3.5m से 4.2m।',
                      impact: 'ऊँचाई बढ़ने से वर्टिकल ड्रॉप लम्बा होता है, जिससे पानी की टर्मिनल वेलोसिटी और हवा खींचने की सक्शन क्षमता बढ़ जाती है।',
                    ),
                  ],
                ),
                Text(
                  '${p.floorHeight.toStringAsFixed(1)} m',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.accent),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 3.5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: isDarkMode ? Colors.white12 : Colors.black12,
                thumbColor: AppColors.accent,
              ),
              child: Slider(
                value: p.floorHeight.clamp(2.4, 4.5),
                min: 2.4,
                max: 4.5,
                divisions: 21,
                onChanged: (v) => provider.updateParams(p.copyWith(floorHeight: (v * 10).round() / 10.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkloadCard(BuildContext context, SimulationParams p) {
    final double flowLs = provider.totalDischargeFlow;
    final double flowLpm = provider.totalDischargeFlowLpm;
    final double loadPercent = provider.capacityUtilization;
    final double heightM = provider.buildingHeightM;
    final int activeFloors = min(p.nActive, p.floors);
    final double concurrency = (activeFloors / p.floors) * 100.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: loadPercent > 80 ? AppColors.danger.withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed_rounded, size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              const Flexible(
                child: Text(
                  'Hydraulic Workload Diagnostics',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              _buildInfoNotch(
                context: context,
                title: 'Hydraulic Workload Diagnostics',
                what: 'EN 12056 डिस्चार्ज वर्कलोड कैलकुलेटर जो एक साथ फ्लश होने वाले फ्लोरों की कुल डिस्चार्ज क्षमता और स्टैक यूटिलाइजेशन दर्शाता है।',
                how: 'चेक करें कि क्या हाइड्रोलिक लोड >80% (Heavy Load) में जा रहा है। अगर लाल रंग में 100% लोड है तो स्टैक डायमीटर या PRL की आवश्यकता होती है।',
                impact: '80% से अधिक लोड होने पर पाइप में एयर कोर ब्लॉक हो जाता है जिससे नेगेटिव वैक्यूम ट्रैप के पानी को खींच लेता है और सीवर गैस घर में घुस जाती है।',
              ),
              const Spacer(),
              Text(
                '$activeFloors/${p.floors} Active (${concurrency.toStringAsFixed(0)}%)',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _metricPill(
                label: 'Total Flow Rate',
                value: '${flowLs.toStringAsFixed(1)} L/s',
                sub: '${flowLpm.toStringAsFixed(0)} L/min',
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              _metricPill(
                label: 'Stack Height',
                value: '${heightM.toStringAsFixed(0)} m',
                sub: '${p.floors} Storeys',
                color: AppColors.info,
              ),
              const SizedBox(width: 8),
              _metricPill(
                label: 'Hydraulic Load',
                value: '${loadPercent.toStringAsFixed(0)}%',
                sub: loadPercent > 80 ? 'Heavy Load' : 'Normal',
                color: loadPercent > 80 ? AppColors.danger : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _metricPill(
                label: 'Terminal Velocity (Vt)',
                value: '${provider.terminalVelocity.toStringAsFixed(1)} m/s',
                sub: 'Wyly-Eaton Vt law',
                color: const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 8),
              _metricPill(
                label: 'Terminal Length (Lt)',
                value: '${provider.terminalLength.toStringAsFixed(1)} m',
                sub: 'Steady within ~${(provider.terminalLength / p.floorHeight).toStringAsFixed(1)} floors',
                color: const Color(0xFF34D399),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _metricPill(
                label: 'Annular Film (tw)',
                value: '${provider.filmThicknessMm.toStringAsFixed(1)} mm',
                sub: 'Water ring thickness',
                color: const Color(0xFF60A5FA),
              ),
              const SizedBox(width: 8),
              _metricPill(
                label: 'Air Core (\u2205)',
                value: '${provider.airCoreDiameterMm.toStringAsFixed(0)} mm',
                sub: '${(provider.airCoreAreaFraction * 100).toStringAsFixed(0)}% free air passage',
                color: provider.waterAreaFraction > 0.33 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricPill({
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9.5, color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            Text(sub, style: TextStyle(fontSize: 9, color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsRow(BuildContext context, SimulationParams p) {
    final Map<String, SimulationParams> presets = SimulationParams.getPresetsFor(p);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Flexible(
              child: Text(
                'Engineering Scenarios',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Floor Count Kept',
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.accent),
              ),
            ),
            const SizedBox(width: 6),
            _buildInfoNotch(
              context: context,
              title: 'Engineering Scenarios',
              what: 'रेडीमेड इंजीनियरिंग तुलनात्मक प्रीसेट्स (Baseline, Well Designed 160mm, Standard Tee, Blocked Vent, AAV Only, Sewer Surcharge, Heavy Peak) जो आपके सेट किए हुए फ्लोर काउंट को बिना बदले पाइपिंग स्पेसिफिकेशन लोड करते हैं।',
              how: 'किसी भी चिप पर क्लिक करें ताकि तुरंत टेस्ट हो सके कि स्टैंडर्ड पाइपिंग और Huliot फिटिंग्स में क्या अंतर आता है।',
              impact: 'अलग-अलग सिनेरियो में ट्रैप सील डिफ्लेक्शन और प्रेशर स्पाइक्स तुरंत अपडेट होते हैं।',
            ),
            const Spacer(),
            Text('Quick Load', style: TextStyle(fontSize: 10.5, color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.keys.map((name) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  label: Text(name),
                  onPressed: () => provider.selectPreset(name),
                  backgroundColor: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
                  side: BorderSide(color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  avatar: const Icon(Icons.tune_rounded, size: 14, color: AppColors.accent),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemCards(BuildContext context, SimulationParams p) {
    final isSingleStack = p.plumbingSystemType != 'one_pipe';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Option 1 vs Option 2 Plumbing System Toggle
        Row(
          children: [
            const Text('Plumbing System Compliance Standard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            const SizedBox(width: 8),
            _buildInfoNotch(
              context: context,
              title: 'Plumbing System Architecture',
              what: 'Option 1: Single Stack System (Table 11: 5.2 L/s) - Huliot primary single stack.\nOption 2: One Pipe System (Table 12: 7.3 L/s to 8.4 L/s) - Secondary ventilated with full vent pipe.',
              how: 'क्लिक करके Single Stack System या One Pipe System सिलेक्ट करें।',
              impact: 'Single Stack System डिफ़ॉल्ट है जो 95% रियल प्रोजेक्ट्स में काम आता है।',
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => provider.setPlumbingSystemType('single_stack'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSingleStack ? AppColors.accent.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSingleStack ? AppColors.accent : (isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
                      width: isSingleStack ? 1.6 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isSingleStack ? Icons.radio_button_checked : Icons.radio_button_off,
                            size: 15,
                            color: isSingleStack ? AppColors.accent : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Single Stack System',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'EN 12056 Table 11 • Primary Vent • 5.2 L/s (Default)',
                        style: TextStyle(fontSize: 9.5, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => provider.setPlumbingSystemType('one_pipe'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: !isSingleStack ? AppColors.accent.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: !isSingleStack ? AppColors.accent : (isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
                      width: !isSingleStack ? 1.6 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            !isSingleStack ? Icons.radio_button_checked : Icons.radio_button_off,
                            size: 15,
                            color: !isSingleStack ? AppColors.accent : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'One Pipe System',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'EN 12056 Table 12 • Secondary Vent • 7.3 - 8.4 L/s',
                        style: TextStyle(fontSize: 9.5, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            const Text('PRL Arrangement Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            const SizedBox(width: 8),
            _buildInfoNotch(
              context: context,
              title: 'Positive Relief Line (PRL) Systems',
              what: 'PRL एक विशेष बाईपास वेंट लाइन है जो स्टैक के बेस (नीचे के फ्लोर) पर बनने वाले खतरनाक पॉजिटिव एयर प्रेशर को बाईपास करके ऊपर रिलीज करती है।',
              how: 'PRL Loop A (स्टैक के बगल में 45° बेंड्स), PRL Loop B (ऑफसेट लूप), या PRL System (स्ट्रेट स्टैक री-ज्वाइन) पर क्लिक करके एक्टिव करें।',
              impact: 'Huliot PRL System 85-90% पॉजिटिव प्रेशर रिलीज करता है, जिससे ग्राउंड व फर्स्ट फ्लोर के टॉयलेट्स में पानी का फव्वारा (Blowout) 100% रुक जाता है।',
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _sysCard(
              option: 1,
              name: 'PRL Loop A',
              desc: 'PRL beside stack, 45° bends',
              eff: 'Standard Relief',
              isSel: p.prlOption == 1,
            ),
            const SizedBox(width: 8),
            _sysCard(
              option: 2,
              name: 'PRL Loop B',
              desc: 'Stack offset loop with PRL',
              eff: 'Moderate Relief',
              isSel: p.prlOption == 2,
            ),
            const SizedBox(width: 8),
            _sysCard(
              option: 3,
              name: 'PRL System',
              desc: 'Straight stack, base rejoin',
              eff: 'Max Relief (Best)',
              isSel: p.prlOption == 3,
            ),
          ],
        ),
      ],
    );
  }

  Widget _sysCard({
    required int option,
    required String name,
    required String desc,
    required String eff,
    required bool isSel,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => provider.setPrlOption(option),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSel
                ? AppColors.primary.withValues(alpha: 0.15)
                : (isDarkMode ? AppColors.darkCard : AppColors.lightCard),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel ? AppColors.primary : (isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSel ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: isSel ? AppColors.accent : (isDarkMode ? AppColors.darkText : AppColors.lightText),
                    ),
                  ),
                  if (isSel)
                    const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.accent),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primary.withValues(alpha: 0.3) : Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  eff,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: isSel ? AppColors.accent : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecificationPickers(BuildContext context, SimulationParams p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Piping & Fitting Specifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 8),
                _buildInfoNotch(
                  context: context,
                  title: 'Piping & Fitting Specifications',
                  what: 'मुख्य वर्टिकल ड्रेनेज स्टैक डायामीटर, ब्रांच टी-जंक्शन ज्योमेट्री, PRL वेंट पाइप, रूफ वेंटिलेशन और ट्रैप सील डेप्थ की इंजीनियरिंग सेटिंग्स।',
                  how: 'ड्रॉपडाउन से अपने प्रोजेक्ट की पाइप साइज और फिटिंग्स चुनें।',
                  impact: 'Huliot Swept Tee और सही डायामीटर लगाने से सक्शन व बैकप्रेशर 50-70% तक कम हो जाता है।',
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Row 1: Stack Diameter & Branch Connection
            Row(
              children: [
                Expanded(
                  child: _buildDropdown<int>(
                    context: context,
                    label: 'Stack diameter',
                    value: p.stackDiameter,
                    tooltipWhat: 'मुख्य वर्टिकल ड्रेनेज स्टैक पाइप का आंतरिक/बाहरी डायामीटर (75mm, 110mm, 125mm, 160mm, 200mm)।',
                    tooltipHow: 'लो-राइज/किचन के लिए 75mm/110mm, मध्यम के लिए 125mm, और 20-50 मंजिला हाई-राइज बिल्डिंग के लिए 160mm या 200mm चुनें।',
                    tooltipImpact: 'बड़ा स्टैक डायमीटर (160/200mm) एयर कोर को खुला रखता है, जिससे डिस्चार्ज कैपेसिटी कई गुना बढ़ जाती है और वैक्यूम सक्शन रुक जाता है।',
                    items: const [
                      DropdownMenuItem(value: 75, child: Text('75 mm')),
                      DropdownMenuItem(value: 110, child: Text('110 mm (Std)')),
                      DropdownMenuItem(value: 125, child: Text('125 mm')),
                      DropdownMenuItem(value: 160, child: Text('160 mm')),
                      DropdownMenuItem(value: 200, child: Text('200 mm')),
                    ],
                    onChanged: (v) => provider.updateParams(p.copyWith(stackDiameter: v!)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdown<String>(
                    context: context,
                    label: 'Branch connection',
                    value: p.teeType,
                    tooltipWhat: 'हर फ्लोर से आने वाली ड्रेन पाइप का मुख्य स्टैक में प्रवेश कराने वाली फिटिंग।',
                    tooltipHow: 'Huliot Swept Tee (कर्व्ड इनलेट) या Standard 87.5° Tee को सेलेक्ट करके अंतर देखें।',
                    tooltipImpact: 'Swept Tee आने वाले पानी को सीधे नीचे की ओर घुमा देता है, जिससे क्रॉस-फ्लो चोकिंग रुकती है और डायनेमिक सर्ज 15% घटता है।',
                    items: const [
                      DropdownMenuItem(value: 'swept', child: Text('Swept tee (Huliot)')),
                      DropdownMenuItem(value: 'std', child: Text('Standard 87.5° Tee')),
                    ],
                    onChanged: (v) => provider.updateParams(p.copyWith(teeType: v!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Row 2: PRL Relief Line & Top of Stack
            Row(
              children: [
                Expanded(
                  child: _buildDropdown<int>(
                    context: context,
                    label: 'Pressure relief line (PRL)',
                    value: p.prlFitted ? p.prlDiameter : 0,
                    tooltipWhat: 'स्टैक के निचले हिस्से से पॉजिटिव प्रेशर बाहर निकालने वाली समानांतर वेंट पाइप।',
                    tooltipHow: '200mm, 160mm, 125mm, 110mm, 75mm या बिना PRL (None) चुनें।',
                    tooltipImpact: 'हाई-राइज में बिना PRL (None) रखने पर ग्राउंड फ्लोर पर +40 mm WG से अधिक ब्लोआउट प्रेशर बनता है, जिससे ट्रैप सील टूट जाती है।',
                    items: const [
                      DropdownMenuItem(value: 200, child: Text('Fitted 200 mm')),
                      DropdownMenuItem(value: 160, child: Text('Fitted 160 mm')),
                      DropdownMenuItem(value: 125, child: Text('Fitted 125 mm')),
                      DropdownMenuItem(value: 110, child: Text('Fitted 110 mm')),
                      DropdownMenuItem(value: 75, child: Text('Fitted 75 mm')),
                      DropdownMenuItem(value: 0, child: Text('None (No PRL)')),
                    ],
                    onChanged: (v) {
                      if (v == 0) {
                        provider.updateParams(p.copyWith(prlFitted: false));
                      } else {
                        provider.updateParams(p.copyWith(prlFitted: true, prlDiameter: v!));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdown<String>(
                    context: context,
                    label: 'Top of stack',
                    value: p.ventType,
                    tooltipWhat: 'बिल्डिंग की छत (Roof) पर वेंट पाइप का टर्मिनेशन।',
                    tooltipHow: 'Open Atmosphere (खुली छत), AAV Valve (एयर एडमिटेंस वॉल्व), या Blocked (चोक्ड वेंट) चुनें।',
                    tooltipImpact: 'अगर वेंट Blocked हो जाए तो स्टैक में -40 mm WG से अधिक वैक्यूम बनता है जिससे सभी ऊपरी टॉयलेट्स के ट्रैप सूख जाते हैं (Induced Siphonage)।',
                    items: const [
                      DropdownMenuItem(value: 'open', child: Text('Open to atmosphere')),
                      DropdownMenuItem(value: 'aav', child: Text('AAV only')),
                      DropdownMenuItem(value: 'blocked', child: Text('Blocked vent')),
                    ],
                    onChanged: (v) => provider.updateParams(p.copyWith(ventType: v!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Row 3: Trap Seal Depth & PRL Diameter Selection (EXACT MATCH TO HTML!)
            Row(
              children: [
                Expanded(
                  child: _buildDropdown<int>(
                    context: context,
                    label: 'Trap seal depth',
                    value: p.trapSealDepth,
                    tooltipWhat: 'U-Trap या P-Trap में पानी की सील की गहराई (Water Seal Depth)। यह सीवर की बदबू और खतरनाक गैसों (H₂S, मीथेन) को बाथरूम में आने से रोकने वाली मुख्य जल-सुरक्षा परत है।',
                    tooltipHow: 'मानक आवासीय के लिए 50 mm (EN 12056) और हाई-राइज या हाई-लोड ड्रेनेज के लिए 75 mm (Deep Seal Anti-Siphon) चुनें।',
                    tooltipImpact: '75 mm सील होने पर जब तेज सक्शन या बैकप्रेशर का झटका (-35 से +35 mm WG) लगता है, तब भी 25 mm से अधिक की सील सुरक्षित बची रहती है और गैस लीक का खतरा टल जाता है।',
                    items: const [
                      DropdownMenuItem(value: 50, child: Text('50 mm')),
                      DropdownMenuItem(value: 70, child: Text('70 mm')),
                      DropdownMenuItem(value: 75, child: Text('75 mm (Deep Seal)')),
                      DropdownMenuItem(value: 100, child: Text('100 mm (High Sec)')),
                    ],
                    onChanged: (v) => provider.updateParams(p.copyWith(trapSealDepth: v!)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdown<int>(
                    context: context,
                    label: 'PRL diameter',
                    value: p.prlDiameter,
                    tooltipWhat: 'Positive Relief Line (PRL) का स्वतंत्र डायामीटर आकार।',
                    tooltipHow: '200 mm, 160 mm, 125 mm, 110 mm, 75 mm में से चुनें। बड़ा डायामीटर अधिकतम एयर बाईपास देता है।',
                    tooltipImpact: 'PRL डायामीटर 160/200 mm होने पर 95% से अधिक प्रेशर रिलीफ मिलता है, जिससे बेस फ्लोर्स पर स्पाइक बिल्कुल 0 हो जाता है।',
                    items: const [
                      DropdownMenuItem(value: 200, child: Text('200 mm')),
                      DropdownMenuItem(value: 160, child: Text('160 mm')),
                      DropdownMenuItem(value: 125, child: Text('125 mm')),
                      DropdownMenuItem(value: 110, child: Text('110 mm')),
                      DropdownMenuItem(value: 75, child: Text('75 mm')),
                    ],
                    onChanged: (v) => provider.updateParams(p.copyWith(prlDiameter: v!, prlFitted: true)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required BuildContext context,
    required String label,
    required T value,
    required String tooltipWhat,
    required String tooltipHow,
    required String tooltipImpact,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ),
            _buildInfoNotch(
              context: context,
              title: label,
              what: tooltipWhat,
              how: tooltipHow,
              impact: tooltipImpact,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? AppColors.darkText : AppColors.lightText,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHydraulicSliders(BuildContext context, SimulationParams p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Discharge Loading & Dynamic Surges', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    _buildInfoNotch(
                      context: context,
                      title: 'Discharge Loading & Dynamic Surges',
                      what: 'एक साथ फ्लश होने वाले बाथरूम, प्रति बाथरूम फ्लो रेट, डिस्चार्ज पैटर्न, सर्ज मल्टीप्लायर और सीवर बैकप्रेशर के लाइव हाइड्रोलिक स्लाइडर्स।',
                      how: 'स्लाइडर्स को ड्रैग करके अलग-अलग वर्स्ट-केस लोडिंग कंडीशन टेस्ट करें।',
                      impact: 'सर्ज और फ्लो बढ़ने से ट्रैप सील का पानी वाइब्रेट होता है और सीवर गैस लीक होने का रिस्क बढ़ता है।',
                    ),
                  ],
                ),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => provider.triggerFlushAll(),
                  icon: const Icon(Icons.waves_rounded, size: 13),
                  label: Text('Flush All ${p.floors} Floors', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Simultaneous Floors Slider
            _sliderRow(
              context: context,
              label: 'Floors discharging together',
              valueText: '${min(p.nActive, p.floors)}',
              value: min(p.nActive, p.floors).toDouble(),
              min: 1,
              max: p.floors.toDouble(),
              divisions: p.floors - 1 > 0 ? p.floors - 1 : 1,
              tooltipWhat: 'बिल्डिंग में एक ही समय पर एक साथ फ्लश होने वाले बाथरूमों की संख्या।',
              tooltipHow: '1 से लेकर सभी फ्लोरों तक स्लाइड करें या ऊपर \'Flush All Floors\' बटन दबाएं।',
              tooltipImpact: 'जितने अधिक फ्लोर एक साथ फ्लश करेंगे, वर्टिकल स्टैक में उतना ही अधिक पानी गिरेगा और हवा को ब्लॉक करेगा, जिससे बेस प्रेशर स्पाइक होगा।',
              onChanged: (v) => provider.updateParams(p.copyWith(nActive: v.round())),
            ),
            // Flow per floor
            _sliderRow(
              context: context,
              label: 'Flow per floor (L/s)',
              valueText: '${p.flowPerFloor.toStringAsFixed(1)} L/s',
              value: p.flowPerFloor,
              min: 0.3,
              max: 3.0,
              divisions: 27,
              tooltipWhat: 'प्रति बाथरूम डिस्चार्ज फ्लो रेट (Litres per second)।',
              tooltipHow: 'स्टैंडर्ड फ्लश (1.0 - 1.5 L/s) या हाई-फ्लो बाथ/शावर ओवरलोड (2.0 - 3.0 L/s) सेट करें।',
              tooltipImpact: 'फ्लो रेट बढ़ने से वॉटर फिल्म की मोटाई बढ़ती है, जिससे पाइप में हवा का रास्ता संकरा हो जाता है और सक्शन बढ़ जाता है।',
              onChanged: (v) => provider.updateParams(p.copyWith(flowPerFloor: v)),
            ),
            // Discharge pattern selector (Which floors flush)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Which floors flush',
                      style: TextStyle(fontSize: 11, color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                    _buildInfoNotch(
                      context: context,
                      title: 'Which floors flush',
                      what: 'यह निर्धारित करता है कि बिल्डिंग में कौन से विशिष्ट फ्लोर्स का पानी एक साथ छोड़ा जा रहा है।',
                      how: '\'Top, bottom and spread\', \'Top Floors\', \'Bottom Floors\', या \'All 100% Bathrooms\' पर क्लिक करें।',
                      impact: '\'Top Floors\' फ्लश होने पर पूरे स्टैक में हाई सक्शन वैक्यूम बनता है। \'All Bathrooms\' पर स्टैक बेस पर मैक्सिमम बैकप्रेशर बनता है।',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    _patternChip('Top, bottom and spread', 'mix', p),
                    _patternChip('All 100% Bathrooms', 'all', p),
                    _patternChip('Top Floors', 'top', p),
                    _patternChip('Bottom Floors', 'bottom', p),
                    _patternChip('Evenly Spread', 'spread', p),
                    _patternChip('Random', 'random', p),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Dynamic Surge Factor
            _sliderRow(
              context: context,
              label: 'Dynamic surge factor',
              valueText: '${p.surgeFactor.toStringAsFixed(1)}×',
              value: p.surgeFactor,
              min: 1.0,
              max: 4.0,
              divisions: 30,
              tooltipWhat: 'टॉयलेट फ्लश के पहले 0.8 सेकंड में बनने वाला पीक वाटर वेव और एयर कम्प्रेशन इम्पैक्ट गुणांक।',
              tooltipHow: '1.0× (शांत लैमिनर फ्लो) से 4.0× (वायलेंट अनस्टेडी फ्लश वेव) तक एडजस्ट करें।',
              tooltipImpact: 'सर्ज मल्टीप्लायर बढ़ने से वाटर ट्रैप में तेज ऑसिलेशन (पानी का हिलना) और सील लॉस का खतरा बढ़ जाता है।',
              onChanged: (v) => provider.updateParams(p.copyWith(surgeFactor: v)),
            ),
            // Sewer backpressure
            _sliderRow(
              context: context,
              label: 'Sewer back pressure (mm WG)',
              valueText: '${p.sewerBackpressure.toStringAsFixed(0)} mm WG',
              value: p.sewerBackpressure,
              min: 0.0,
              max: 40.0,
              divisions: 40,
              tooltipWhat: 'म्युनिसिपल सीवर लाइन या मैनहोल में पानी भरने से आने वाला बाहरी बैकप्रेशर।',
              tooltipHow: '0 mm WG (सामान्य) से 40 mm WG (बाढ़ या भारी बारिश में सीवर चोकिंग) तक बढ़ाएं।',
              tooltipImpact: 'बाहरी बैकप्रेशर ग्राउंड फ्लोर के ट्रैप को तुरंत पुश करके सीवर की बदबूदार गैस अंदर धकेल सकता है।',
              onChanged: (v) => provider.updateParams(p.copyWith(sewerBackpressure: v)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _patternChip(String label, String patternKey, SimulationParams p) {
    final bool isSel = p.dischargePattern == patternKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      onSelected: (_) => provider.updateParams(p.copyWith(dischargePattern: patternKey)),
      labelStyle: TextStyle(
        fontSize: 10.5,
        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
        color: isSel ? Colors.white : (isDarkMode ? AppColors.darkText : AppColors.lightText),
      ),
      selectedColor: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }

  Widget _sliderRow({
    required BuildContext context,
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String tooltipWhat,
    required String tooltipHow,
    required String tooltipImpact,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(label, style: TextStyle(fontSize: 11.5, color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                const SizedBox(width: 6),
                _buildInfoNotch(
                  context: context,
                  title: label,
                  what: tooltipWhat,
                  how: tooltipHow,
                  impact: tooltipImpact,
                ),
              ],
            ),
            Text(valueText, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accent)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: isDarkMode ? Colors.white12 : Colors.black12,
            thumbColor: AppColors.accent,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // --- Quick Action Buttons (Matching original HTML!) ---
  Widget _buildQuickActionButtons(BuildContext context, SimulationParams p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on_rounded, size: 15, color: AppColors.accent),
                const SizedBox(width: 6),
                const Text(
                  'Quick Actions & Data Export',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  'Original HTML Parity',
                  style: TextStyle(fontSize: 10, color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      side: BorderSide(color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.file_download_rounded, size: 15, color: AppColors.accent),
                    label: const Text('Peak data CSV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _showExportCsvDialog(context, provider),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      side: BorderSide(color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.cleaning_services_rounded, size: 15, color: AppColors.warning),
                    label: const Text('Clear peaks', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      provider.clearPeaks();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All recorded peak pressures cleared!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      side: BorderSide(color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.water_drop_rounded, size: 15, color: AppColors.info),
                    label: const Text('Refill Traps', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      provider.resetTraps();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('All trap water seals refilled to full ${p.trapSealDepth} mm!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExportCsvDialog(BuildContext context, SimulatorProvider provider) {
    final String csvData = provider.generateCsv();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF131B26) : Colors.white,
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
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationControls(BuildContext context, SimulationParams p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Simulation Execution & Playback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 8),
                _buildInfoNotch(
                  context: context,
                  title: 'Simulation Execution & Playback',
                  what: 'सिम्युलेशन के चलने का मोड (चक्रवात साइकल, सिंगल फ्लश, या पीक होल्ड) और प्लेबैक स्पीड।',
                  how: 'स्लो-मोशन (0.5×) में पानी की बूंदें और ट्रैप का ऑसिलेशन ध्यान से देखने के लिए स्पीड एडजस्ट करें।',
                  impact: 'होल्ड मोड में लगातार फ्लश चालू रहता है ताकि वर्स्ट-केस स्टेडी-स्टेट हाइड्रोलिक दबाव मापा जा सके।',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown<String>(
                    context: context,
                    label: 'Discharge Execution',
                    value: p.flushMode,
                    tooltipWhat: 'पानी डिस्चार्ज करने का तरीका (Repeating Cycles, Single Manual, Continuous Hold)।',
                    tooltipHow: 'स्वाभाविक रियल-वर्ल्ड फ्लशिंग के लिए \'Repeating Flush Cycles\' रखें।',
                    tooltipImpact: '\'Continuous Peak Load (Hold)\' में सक्शन और बैकप्रेशर अपनी उच्चतम सीमा पर लगातार बने रहते हैं।',
                    items: const [
                      DropdownMenuItem(value: 'cycle', child: Text('Repeating Flush Cycles')),
                      DropdownMenuItem(value: 'single', child: Text('Single Manual Flush')),
                      DropdownMenuItem(value: 'hold', child: Text('Continuous Peak Load (Hold)')),
                    ],
                    onChanged: (v) => provider.updateParams(p.copyWith(flushMode: v!)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdown<double>(
                    context: context,
                    label: 'Simulation Speed',
                    value: p.simulationSpeed,
                    tooltipWhat: 'सिम्युलेटर की गति (Time Dilation Factor)।',
                    tooltipHow: 'पानी के पार्टिकल्स और यू-ट्रैप वेव को बारीकी से देखने के लिए 0.5× Slow Motion चुनें।',
                    tooltipImpact: 'सिर्फ विज़ुअल एनीमेशन की स्पीड बदलती है, फिजिक्स के वास्तविक गणितीय नतीजे समान रहते हैं।',
                    items: const [
                      DropdownMenuItem(value: 0.5, child: Text('0.5× Slow Motion')),
                      DropdownMenuItem(value: 1.0, child: Text('1.0× Real-Time')),
                      DropdownMenuItem(value: 1.5, child: Text('1.5× Fast')),
                      DropdownMenuItem(value: 2.5, child: Text('2.5× High Speed')),
                    ],
                    onChanged: (v) => provider.updateParams(p.copyWith(simulationSpeed: v!)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccupancyAndStandardsCard(BuildContext context, SimulatorProvider prov) {
    final p = prov.params;
    final (sqCap, swCap) = prov.table12Capacities;
    final headroom = prov.sweptCapacityHeadroomPercent;

    final List<({String type, String label, double k})> occupancies = [
      (type: 'residential', label: '🏠 Residential / Dwellings / Offices (K = 0.5)', k: 0.5),
      (type: 'hotel', label: '🏨 Hotels / Hospitals / Schools (K = 0.7)', k: 0.7),
      (type: 'public', label: '🏢 Malls / Public Toilets (K = 1.0)', k: 1.0),
      (type: 'lab', label: '🔬 Laboratories / Special (K = 1.2)', k: 1.2),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.apartment_rounded, size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              const Flexible(
                child: Text(
                  'Building Occupancy & Usage (EN 12056)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'K = ${p.kFactor}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Occupancy Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black26 : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDarkMode ? Colors.white12 : Colors.black12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: p.occupancyType,
                dropdownColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                items: occupancies.map((occ) {
                  return DropdownMenuItem<String>(
                    value: occ.type,
                    child: Text(occ.label, style: const TextStyle(fontSize: 11.5)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    final matched = occupancies.firstWhere((o) => o.type == val);
                    prov.setOccupancyType(matched.type, matched.k);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Statutory Swept Capacity Headroom Banner (Dynamic Table 11 vs Table 12)
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'EN 12056 ${provider.activeTableReference}: Stack Capacity Limit',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                    Text(
                      '+${headroom.toStringAsFixed(1)}% Headroom',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Square Entry: ${sqCap.toStringAsFixed(1)} L/s', style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.white70 : Colors.black87)),
                    Text('Huliot Swept: ${swCap.toStringAsFixed(1)} L/s', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                    Text('Stack: DN ${p.stackDiameter}', style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.white60 : Colors.black54)),
                  ],
                ),
              ],
            ),
          ),

          // AAV Rule Validation (Clause 6.5.3)
          if (p.ventType == 'aav') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.air_rounded, size: 14, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'EN 12056 Clause 6.5.3: Min AAV Airflow Qa >= 8 * Qww (${prov.aavRequiredAirFlow.toStringAsFixed(1)} L/s required)',
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
