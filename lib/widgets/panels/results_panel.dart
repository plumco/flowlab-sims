import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/simulation_state.dart';
import '../../providers/simulator_provider.dart';

class ResultsPanel extends StatelessWidget {
  final SimulatorProvider provider;
  final bool isDarkMode;

  const ResultsPanel({
    super.key,
    required this.provider,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final StaticPhysicsResult stat = provider.currentResult;
    final SystemDynamicState dyn = provider.currentDynamicState;
    final StandardVerdict verdict = provider.verdict;

    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Verdict Banner + Key KPIs
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isNarrow = constraints.maxWidth < 750;
                  return isNarrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildVerdictBanner(verdict, stat),
                            const SizedBox(height: 10),
                            _buildKpiMetrics(stat, dyn),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(flex: 35, child: _buildVerdictBanner(verdict, stat)),
                            const SizedBox(width: 12),
                            Expanded(flex: 65, child: _buildKpiMetrics(stat, dyn)),
                          ],
                        );
                },
              ),
              const SizedBox(height: 14),

              // Floor-by-Floor Trap Health Grid
              _buildFloorStatusGrid(context, dyn),
              const SizedBox(height: 12),

              // Engineering Diagnostics & Huliot Recommendations
              _buildEngineeringRecommendations(stat),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerdictBanner(StandardVerdict verdict, StaticPhysicsResult stat) {
    final (String title, String desc, Color color, IconData icon) = switch (verdict) {
      StandardVerdict.pass => (
          'PASS • COMPLIANT',
          'Trap seal retained within ±25 mm WG limit (EN 12056). Sewer gas barrier fully intact.',
          AppColors.success,
          Icons.verified_rounded,
        ),
      StandardVerdict.marginal => (
          'MARGINAL WARNING',
          'Pressure transients reach 25–40 mm WG. Risk of trap oscillation, gurgling, and odor.',
          AppColors.warning,
          Icons.warning_amber_rounded,
        ),
      StandardVerdict.fail => (
          'FAIL • SEAL LOSS HAZARD',
          'Pressure exceeds 40 mm WG or trap seal lost. Sewer gases escape into living areas.',
          AppColors.danger,
          Icons.cancel_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: TextStyle(
              fontSize: 11,
              color: isDarkMode ? AppColors.darkText : AppColors.lightText,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetrics(StaticPhysicsResult stat, SystemDynamicState dyn) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = constraints.maxWidth > 550
            ? (constraints.maxWidth - 32) / 5
            : (constraints.maxWidth > 300 ? (constraints.maxWidth - 10) / 2 : constraints.maxWidth);
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: itemWidth,
              child: _kpiItem(
                label: 'Peak Positive',
                value: '+${dyn.peakAllPositive.toStringAsFixed(1)}',
                unit: 'mm WG',
                color: dyn.peakAllPositive > 40
                    ? AppColors.danger
                    : (dyn.peakAllPositive > 25 ? AppColors.warning : AppColors.success),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _kpiItem(
                label: 'Peak Suction',
                value: '-${dyn.peakAllNegative.toStringAsFixed(1)}',
                unit: 'mm WG',
                color: dyn.peakAllNegative > 40
                    ? AppColors.danger
                    : (dyn.peakAllNegative > 25 ? AppColors.warning : AppColors.success),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _kpiItem(
                label: 'Water Velocity',
                value: stat.terminalVelocity.toStringAsFixed(1),
                unit: 'm/s terminal',
                color: AppColors.accent,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _kpiItem(
                label: 'Air Velocity',
                value: stat.airVelocity.toStringAsFixed(1),
                unit: 'm/s entrained',
                color: AppColors.info,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _kpiItem(
                label: 'Stack Load',
                value: '${(stat.capacityUtilization * 100).toStringAsFixed(0)}%',
                unit: 'of ${stat.stackCapacity.toStringAsFixed(1)} L/s',
                color: stat.capacityUtilization > 0.8 ? AppColors.danger : AppColors.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _kpiItem({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              unit,
              style: TextStyle(fontSize: 9, color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ),
          ],
        ),
      );
  }

  Widget _buildFloorStatusGrid(BuildContext context, SystemDynamicState dyn) {
    final int n = provider.params.floors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.grid_view_rounded, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  'Building Floor Status Matrix ($n Floors)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => provider.triggerFlushAll(),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.accent, width: 0.9),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.waves_rounded, size: 12, color: AppColors.accent),
                        SizedBox(width: 3),
                        Text('Select All', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => provider.triggerFlush(),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: provider.isFlushing ? AppColors.success : AppColors.success.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.success, width: 1.2),
                      boxShadow: provider.isFlushing
                          ? [
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flash_on_rounded,
                          size: 12,
                          color: provider.isFlushing ? Colors.white : AppColors.success,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          provider.isFlushing ? '⚡ Flushing (${provider.activeFloors.length}F)...' : 'Flush Active (${provider.activeFloors.length}F)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: provider.isFlushing ? Colors.white : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active: ${provider.activeFloors.map((f) => "F$f").join(", ")} (${provider.activeFloors.length} of $n floors)',
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.accent),
            ),
            Text(
              'Click: Toggle Floor  •  Double-Click: Solo Flush',
              style: TextStyle(fontSize: 10, color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(n, (index) {
            final int floorNum = n - index; // Top floor first
            final int idx = floorNum - 1;
            final double displ = idx < dyn.trapDisplacement.length ? dyn.trapDisplacement[idx].abs() : 0.0;
            final double seal = idx < dyn.trapSealRetention.length ? dyn.trapSealRetention[idx] : 50.0;
            final bool isFlushing = provider.activeFloors.contains(floorNum);
            final bool lost = seal < 25.0;

            final Color chipColor = lost || displ > 40
                ? AppColors.danger
                : (displ > 25 ? AppColors.warning : AppColors.success);

            return Tooltip(
              message: 'Floor $floorNum: ${isFlushing ? "Flushing Active" : "Standby"}\nClick to toggle, Double-click for solo flush',
              child: InkWell(
                onTap: () => provider.toggleFloor(floorNum),
                onDoubleTap: () => provider.setSingleFloorActive(floorNum),
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 38,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: isFlushing ? 0.95 : 0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isFlushing ? Colors.white : chipColor,
                      width: isFlushing ? 2 : 1,
                    ),
                    boxShadow: isFlushing
                        ? [
                            BoxShadow(
                              color: chipColor.withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'F$floorNum',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isFlushing ? Colors.white : chipColor,
                      decoration: lost ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEngineeringRecommendations(StaticPhysicsResult stat) {
    final bool sweptFitted = provider.params.teeType == 'swept';
    final bool prlFitted = provider.params.prlFitted;
    final int floors = provider.params.floors;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                'Engineering Diagnostics for $floors-Storey Stack',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            floors >= 35
                ? '• High-Rise Height Alert: At $floors floors (${provider.buildingHeightM.toStringAsFixed(0)} m), entrained air velocity reaches ${stat.airVelocity.toStringAsFixed(1)} m/s. A Pressure Relief Line (PRL) is strictly required to protect ground floor trap seals.'
                : '• Mid-Rise Stack: At $floors floors (${provider.buildingHeightM.toStringAsFixed(0)} m), standard single stack loads are manageable, but simultaneous flushes generate pressure spikes near stack base.',
            style: TextStyle(fontSize: 11, color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          ),
          const SizedBox(height: 3),
          Text(
            sweptFitted
                ? '• Huliot Swept Tee fitted: Curved branch inlet directs incoming water smoothly down the pipe wall, preventing cross-flow blockage and reducing dynamic surge by ~15%.'
                : '• Standard 87.5° Tee warning: High risk of hydraulic jump and horizontal branch backflow. Recommend upgrading to Huliot Swept Tee.',
            style: TextStyle(fontSize: 11, color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          ),
          const SizedBox(height: 3),
          Text(
            prlFitted
                ? '• PRL System ${provider.params.prlOption == 3 ? "C (Maximum Efficiency)" : (provider.params.prlOption == 2 ? "B" : "A")} Active: Positive air backpressure is safely vented away from the bottom floors.'
                : '• Hazard: Without PRL, bottom floors F1–F3 experience positive backpressure blow-out under heavy simultaneous flushes.',
            style: TextStyle(fontSize: 11, color: isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          ),
          const SizedBox(height: 10),
          // Action Buttons for Report
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: () => provider.downloadPdfReport(),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 15),
                  label: const Text('Download PDF Report', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: () => provider.openPrintableReport(),
                  icon: const Icon(Icons.print_rounded, size: 15),
                  label: const Text('Print / View Report', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
