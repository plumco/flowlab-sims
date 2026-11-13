import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/simulation_state.dart';
import '../../providers/simulator_provider.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final SimulatorProvider provider;
  final VoidCallback onOpenDrawer;
  final VoidCallback onExportCsv;
  final VoidCallback onExportPdf;

  const AppHeader({
    super.key,
    required this.provider,
    required this.onOpenDrawer,
    required this.onExportCsv,
    required this.onExportPdf,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final bool isDark = provider.isDarkMode;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        tooltip: 'Browse All Simulators',
        onPressed: onOpenDrawer,
      ),
      titleSpacing: 0,
      title: InkWell(
        onTap: onOpenDrawer,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.water_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'HULIOT FLOWLAB',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'v2.0',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Mode Selector: Standard EN 12056 Test vs Overload vs 🎲 Morning Rush
        Container(
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Standard Test
              InkWell(
                onTap: provider.isTestRunning || provider.isMonteCarloRunning
                    ? null
                    : () => provider.setTestingMode(FlowLabReportType.standardCompliance),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: (!provider.isMonteCarloMode && provider.activeReportType == FlowLabReportType.standardCompliance)
                        ? (isDark ? AppColors.accent.withValues(alpha: 0.25) : AppColors.accent.withValues(alpha: 0.15))
                        : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                  ),
                  child: Text(
                    'Standard Test',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: (!provider.isMonteCarloMode && provider.activeReportType == FlowLabReportType.standardCompliance)
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: (!provider.isMonteCarloMode && provider.activeReportType == FlowLabReportType.standardCompliance)
                          ? AppColors.accent
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              ),
              // 2. Overload Test
              InkWell(
                onTap: provider.isTestRunning || provider.isMonteCarloRunning
                    ? null
                    : () => provider.setTestingMode(FlowLabReportType.overloadStress),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: (!provider.isMonteCarloMode && provider.activeReportType == FlowLabReportType.overloadStress)
                        ? (isDark ? const Color(0xFFEA580C).withValues(alpha: 0.25) : const Color(0xFFEA580C).withValues(alpha: 0.15))
                        : Colors.transparent,
                  ),
                  child: Text(
                    '⚡ Overload',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: (!provider.isMonteCarloMode && provider.activeReportType == FlowLabReportType.overloadStress)
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: (!provider.isMonteCarloMode && provider.activeReportType == FlowLabReportType.overloadStress)
                          ? const Color(0xFFEA580C)
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              ),
              // 3. Morning Rush
              InkWell(
                onTap: provider.isTestRunning || provider.isMonteCarloRunning
                    ? null
                    : () => provider.setTestingMode(FlowLabReportType.morningRushAudit),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: provider.isMonteCarloMode
                        ? (isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.25) : const Color(0xFFF59E0B).withValues(alpha: 0.15))
                        : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎲 ', style: TextStyle(fontSize: 10)),
                      Text(
                        'Morning Rush',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: provider.isMonteCarloMode ? FontWeight.bold : FontWeight.normal,
                          color: provider.isMonteCarloMode ? const Color(0xFFF59E0B) : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Primary Action: Monte Carlo Mode Controllers vs Overload vs Standard Test Controllers
        if (provider.isMonteCarloMode) ...[
          if (provider.isMonteCarloRunning) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      value: provider.monteCarloProgress,
                      strokeWidth: 2.2,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '⏰ ${provider.simulatedClockTime} (${provider.activeFloors.length}F)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Pause Morning Rush',
              onPressed: () => provider.pauseMonteCarloRush(),
              icon: const Icon(Icons.pause_circle_filled_rounded, color: Color(0xFFF59E0B), size: 22),
            ),
          ] else if (provider.isMonteCarloCompleted) ...[
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onExportPdf,
              icon: const Icon(Icons.assessment_rounded, size: 14, color: Colors.white),
              label: const Text('Rush Report 📄', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Restart Morning Rush',
              onPressed: () => provider.startMonteCarloRush(),
              icon: const Icon(Icons.replay_rounded, color: Color(0xFFF59E0B), size: 21),
            ),
          ] else ...[
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => provider.startMonteCarloRush(),
              icon: const Icon(Icons.play_arrow_rounded, size: 15, color: Colors.white),
              label: const Text('Start Rush Sim', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(width: 4),
          ],
        ] else ...[
          // Standard / Overload Formal Compliance Test Controller
          if (provider.isTestRunning) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      value: provider.testProgress,
                      strokeWidth: 2.2,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Testing ${(provider.testProgress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                ],
              ),
            ),
          ] else if (provider.isTestCompleted) ...[
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: provider.verdict == StandardVerdict.pass ? const Color(0xFF059669) : const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onExportPdf,
              icon: Icon(provider.verdict == StandardVerdict.pass ? Icons.check_circle_rounded : Icons.warning_rounded, size: 14, color: Colors.white),
              label: Text(
                provider.activeReportType == FlowLabReportType.overloadStress
                    ? 'Overload Report 📄'
                    : (provider.verdict == StandardVerdict.pass ? 'Report Ready 📄' : 'Test Failed ⚠️'),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Resume Continuous Play',
              onPressed: () => provider.resumeContinuousPlay(),
              icon: const Icon(Icons.play_arrow_rounded, color: AppColors.accent, size: 21),
            ),
          ] else if (provider.activeReportType == FlowLabReportType.overloadStress) ...[
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC2410C),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => provider.triggerFlushAll(),
              icon: const Icon(Icons.bolt_rounded, size: 15, color: Colors.white),
              label: const Text('Overload Test', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(width: 4),
          ] else ...[
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => provider.startOfficialTest(),
              icon: const Icon(Icons.play_circle_fill_rounded, size: 14, color: Colors.white),
              label: const Text('Run Test', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(width: 4),
          ],
        ],

        // Export PDF Report (Locks during test run to prevent partial uncertified reports)
        IconButton(
          onPressed: provider.isTestRunning ? null : onExportPdf,
          tooltip: provider.isTestRunning
              ? 'Test running (${(provider.testProgress * 100).toInt()}%)... Report unlocks when complete'
              : 'Download Certified PDF Report',
          icon: Icon(
            Icons.picture_as_pdf_rounded,
            size: 19,
            color: provider.isTestRunning
                ? Colors.grey
                : (provider.isTestCompleted ? const Color(0xFF34D399) : AppColors.accent),
          ),
          visualDensity: VisualDensity.compact,
        ),

        // Export CSV
        IconButton(
          onPressed: onExportCsv,
          tooltip: 'Export CSV',
          icon: const Icon(Icons.table_chart_rounded, size: 19),
          visualDensity: VisualDensity.compact,
        ),

        // Theme Toggle
        IconButton(
          onPressed: () => provider.toggleTheme(),
          tooltip: isDark ? 'Light Mode' : 'Dark Mode',
          icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 19),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}
