import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SiphonicRoofScreen extends StatefulWidget {
  const SiphonicRoofScreen({super.key});

  @override
  State<SiphonicRoofScreen> createState() => _SiphonicRoofScreenState();
}

class _SiphonicRoofScreenState extends State<SiphonicRoofScreen> {
  double _roofArea = 2500; // m²
  double _rainfallIntensity = 150; // mm/h
  double _buildingHeight = 30; // meters (driving head)
  int _outletsCount = 4;
  int _pipeDiameterMm = 75; // mm

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Siphonic Physics Calculations (EN 12056-3 / BS 8490)
    // Runoff Q = (Area * Intensity * Discharge Coeff) / 3600  (L/s)
    final double totalRunoffFlow = (_roofArea * _rainfallIntensity * 1.0) / 3600.0;
    final double flowPerOutlet = totalRunoffFlow / _outletsCount;

    // Internal pipe diameter in meters
    final double dM = (_pipeDiameterMm - 6.0) / 1000.0; // Wall thickness deduction
    final double pipeArea = math.pi * math.pow(dM / 2.0, 2);

    // Full-bore Siphonic Velocity: v = Q / A (m/s)
    final double flowM3s = (flowPerOutlet / 1000.0);
    final double velocity = pipeArea > 0 ? (flowM3s / pipeArea) : 0;

    // Velocity head: hv = v² / (2g)
    final double velocityHead = math.pow(velocity, 2) / (2 * 9.81);

    // Minimum self-cleansing velocity requirement: 2.0 m/s (BS 8490)
    final bool isVelocityAdequate = velocity >= 2.0 && velocity <= 8.0;

    // Available static driving head H = building height
    // Friction loss estimate (Darcy-Weisbach with lambda ~ 0.018 for smooth PP):
    final double frictionLoss = (0.018 * (_buildingHeight + 15) / dM) * velocityHead;
    final double residualHead = _buildingHeight - frictionLoss;

    // Peak negative suction pressure in mbar (1 m WG ≈ 98.1 mbar)
    final double peakSuctionMbar = (residualHead * 98.1).clamp(0, 850);
    final bool isCavitationSafe = peakSuctionMbar < 800; // Safe below 800 mbar suction

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cloudy_snowing, color: AppColors.accent, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HULIOT SIPHONIC ROOF DRAINAGE SIMULATOR',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Full-Bore Negative Pressure Rainwater Calculations (EN 12056-3 & BS 8490 Compliant)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isVelocityAdequate && isCavitationSafe)
                          ? AppColors.success.withValues(alpha: 0.2)
                          : AppColors.danger.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (isVelocityAdequate && isCavitationSafe) ? AppColors.success : AppColors.danger,
                      ),
                    ),
                    child: Text(
                      (isVelocityAdequate && isCavitationSafe) ? 'DESIGN COMPLIANT' : 'ADJUST SIZING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: (isVelocityAdequate && isCavitationSafe) ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Controls & Results Split
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Parameters Sliders
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Roof & Storm Design Parameters',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const Divider(height: 24),
                        _sliderRow(
                          title: 'Catchment Roof Area',
                          valText: '${_roofArea.toStringAsFixed(0)} m²',
                          min: 500,
                          max: 15000,
                          divisions: 58,
                          val: _roofArea,
                          onChanged: (v) => setState(() => _roofArea = v),
                        ),
                        const SizedBox(height: 12),
                        _sliderRow(
                          title: 'Rainfall Intensity (i)',
                          valText: '${_rainfallIntensity.toStringAsFixed(0)} mm/h',
                          min: 50,
                          max: 300,
                          divisions: 25,
                          val: _rainfallIntensity,
                          onChanged: (v) => setState(() => _rainfallIntensity = v),
                        ),
                        const SizedBox(height: 12),
                        _sliderRow(
                          title: 'Building Height (Static Head)',
                          valText: '${_buildingHeight.toStringAsFixed(1)} m',
                          min: 6,
                          max: 120,
                          divisions: 38,
                          val: _buildingHeight,
                          onChanged: (v) => setState(() => _buildingHeight = v),
                        ),
                        const SizedBox(height: 12),
                        _sliderRow(
                          title: 'Siphonic Outlets Count',
                          valText: '$_outletsCount Baffled Outlets',
                          min: 1,
                          max: 20,
                          divisions: 19,
                          val: _outletsCount.toDouble(),
                          onChanged: (v) => setState(() => _outletsCount = v.toInt()),
                        ),
                        const SizedBox(height: 12),
                        const Text('Downpipe Diameter:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [50, 75, 90, 110, 125, 160].map((d) {
                            final bool sel = _pipeDiameterMm == d;
                            return ChoiceChip(
                              label: Text('DN $d mm'),
                              selected: sel,
                              onSelected: (_) => setState(() => _pipeDiameterMm = d),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Right Column: Live Physics Metrics & Diagrams
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      // Metric Cards Grid
                      Row(
                        children: [
                          Expanded(
                            child: _metricCard(
                              title: 'Total Storm Runoff',
                              val: '${totalRunoffFlow.toStringAsFixed(1)} L/s',
                              sub: '${(totalRunoffFlow * 3.6).toStringAsFixed(0)} m³/h',
                              icon: Icons.water_drop_rounded,
                              isGood: true,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _metricCard(
                              title: 'Flow per Siphonic Outlet',
                              val: '${flowPerOutlet.toStringAsFixed(1)} L/s',
                              sub: 'Through Air Baffle',
                              icon: Icons.filter_alt_rounded,
                              isGood: true,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _metricCard(
                              title: 'Siphonic Velocity (v)',
                              val: '${velocity.toStringAsFixed(2)} m/s',
                              sub: isVelocityAdequate
                                  ? 'Self-cleansing (≥ 2.0 m/s)'
                                  : (velocity < 2.0 ? 'Low velocity (< 2.0 m/s)' : 'Excessive velocity (> 8 m/s)'),
                              icon: Icons.speed_rounded,
                              isGood: isVelocityAdequate,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _metricCard(
                              title: 'Peak Negative Suction',
                              val: '-${peakSuctionMbar.toStringAsFixed(0)} mbar',
                              sub: isCavitationSafe ? 'Safe Cavitation Margin' : 'Hazard: Cavitation Risk',
                              icon: Icons.compress_rounded,
                              isGood: isCavitationSafe,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Engineering Explanatory Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 18),
                                SizedBox(width: 8),
                                Text('Siphonic Action vs Conventional Gravity',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'In conventional gravity drainage, pipe fills to only 33% water and 67% air. In Huliot Siphonic Drainage with anti-vortex air baffles, the pipe fills 100% full-bore. The vertical water column creates immense negative suction (Bernoulli effect), pulling rainwater from the roof at high speeds ($velocity m/s). This allows 70% smaller pipe diameters and zero pipe slope in horizontal collector runs!',
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.45,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sliderRow({
    required String title,
    required String valText,
    required double min,
    required double max,
    required int divisions,
    required double val,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(valText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
          ],
        ),
        Slider(
          value: val.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String val,
    required String sub,
    required IconData icon,
    required bool isGood,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: isGood ? AppColors.success : AppColors.danger),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isGood ? null : AppColors.danger)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
        ],
      ),
    );
  }
}
