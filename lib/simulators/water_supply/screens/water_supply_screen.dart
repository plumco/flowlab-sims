import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class WaterSupplyScreen extends StatefulWidget {
  const WaterSupplyScreen({super.key});

  @override
  State<WaterSupplyScreen> createState() => _WaterSupplyScreenState();
}

class _WaterSupplyScreenState extends State<WaterSupplyScreen> {
  int _floors = 30;
  int _apartmentsPerFloor = 4;
  String _wcType = 'flush_tank'; // 'flush_tank' (3 WSFU) or 'flush_valve' (10 WSFU)
  double _residualPressureBar = 2.0; // Bar at top floor

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Fixture Units Calculation per Hunter Curve (IPC / BS EN 806)
    final int totalApartments = _floors * _apartmentsPerFloor;
    final double wcWSFU = _wcType == 'flush_valve' ? 10.0 : 3.0;
    // Typical 2-bath apartment: 2 WCs, 2 Basins (1.5), 2 Showers (2.0), 1 Kitchen Sink (2.0)
    final double wsfuPerApt = (2 * wcWSFU) + (2 * 1.5) + (2 * 2.0) + 2.0;
    final double totalWSFU = totalApartments * wsfuPerApt;

    // Peak Flow Conversion from Hunter Curve (approximated mathematically)
    // Q_peak (gpm) ≈ 1.5 * WSFU^0.65 for flush valves, 1.2 * WSFU^0.62 for tanks
    final double peakGpm = _wcType == 'flush_valve'
        ? 1.55 * math.pow(totalWSFU, 0.65)
        : 1.15 * math.pow(totalWSFU, 0.63);
    final double peakFlowLps = peakGpm * 0.06309; // GPM to L/s
    final double peakFlowM3h = peakFlowLps * 3.6; // m³/h

    // Total Dynamic Head (TDH)
    final double staticHeadM = _floors * 3.0; // 3m per floor
    final double frictionLossM = staticHeadM * 0.15; // ~15% friction loss in riser and valves
    final double residualHeadM = _residualPressureBar * 10.197; // 1 bar ≈ 10.2 m WG
    final double tdhM = staticHeadM + frictionLossM + residualHeadM;
    final double pumpPressureBar = tdhM / 10.197;

    // Booster Pump Power Requirement (kW): P = (rho * g * Q * H) / (1000 * efficiency)
    final double pumpEff = 0.72; // 72% pump efficiency
    final double pumpKw = (9.81 * peakFlowLps * tdhM) / (1000.0 * pumpEff);
    final double pumpHp = pumpKw * 1.341;

    // VFD Energy Savings (Variable Frequency Drive vs fixed speed throttled)
    final double vfdEnergySavingsPercent = 38.0;

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
                    child: const Icon(Icons.water_drop_rounded, color: AppColors.accent, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HULIOT WATER SUPPLY BOOSTER & PEAK DEMAND SIMULATOR',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hunter’s Curve Probabilistic Peak Demand & Booster Pump Sizing (IPC, UPC & BS EN 806)',
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
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Text(
                      'TOTAL WSFU: ${totalWSFU.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
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
                // Left Column: Parameters
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
                        const Text('Building Water Demand Parameters',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Building Storeys:',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('$_floors Floors (${(_floors * 3.0).toStringAsFixed(0)} m)',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
                          ],
                        ),
                        Slider(
                          value: _floors.toDouble(),
                          min: 5,
                          max: 80,
                          divisions: 75,
                          onChanged: (v) => setState(() => _floors = v.toInt()),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Apartments Per Floor:',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('$_apartmentsPerFloor Units ($totalApartments Total)',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
                          ],
                        ),
                        Slider(
                          value: _apartmentsPerFloor.toDouble(),
                          min: 1,
                          max: 12,
                          divisions: 11,
                          onChanged: (v) => setState(() => _apartmentsPerFloor = v.toInt()),
                        ),
                        const SizedBox(height: 12),
                        const Text('Toilet Flush Valve Type:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Flush Tank (Cistern)'),
                                selected: _wcType == 'flush_tank',
                                onSelected: (_) => setState(() => _wcType = 'flush_tank'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Flushometer Valve'),
                                selected: _wcType == 'flush_valve',
                                onSelected: (_) => setState(() => _wcType = 'flush_valve'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Residual Pressure at Top Fixture:',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('${_residualPressureBar.toStringAsFixed(1)} bar',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
                          ],
                        ),
                        Slider(
                          value: _residualPressureBar,
                          min: 1.0,
                          max: 3.5,
                          divisions: 25,
                          onChanged: (v) => setState(() => _residualPressureBar = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Right Column: Sizing Results
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _resultBox(
                              title: 'Peak Instantaneous Demand',
                              val: '${peakFlowLps.toStringAsFixed(1)} L/s',
                              sub: '${peakFlowM3h.toStringAsFixed(1)} m³/h (${peakGpm.toStringAsFixed(0)} GPM)',
                              icon: Icons.speed_rounded,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _resultBox(
                              title: 'Total Dynamic Head (TDH)',
                              val: '${tdhM.toStringAsFixed(1)} m WG',
                              sub: '${pumpPressureBar.toStringAsFixed(1)} bar pump discharge',
                              icon: Icons.compress_rounded,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _resultBox(
                              title: 'Booster Pump Motor Power',
                              val: '${pumpHp.toStringAsFixed(1)} HP',
                              sub: '${pumpKw.toStringAsFixed(1)} kW (72% efficiency)',
                              icon: Icons.electric_bolt_rounded,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _resultBox(
                              title: 'VFD Energy Saving',
                              val: '${vfdEnergySavingsPercent.toStringAsFixed(0)}%',
                              sub: 'vs fixed throttled pump',
                              icon: Icons.energy_savings_leaf_rounded,
                              isDark: isDark,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Technical summary banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Recommended Booster Skid Configuration: Multi-pump 3+1 arrangement (3 Working + 1 Standby) with individual frequency inverters (VFD) ensuring consistent pressure across all floors without water hammer.',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.4,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
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

  Widget _resultBox({
    required String title,
    required String val,
    required String sub,
    required IconData icon,
    required bool isDark,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.accent;
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
              Icon(icon, size: 16, color: effectiveColor),
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
          Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
        ],
      ),
    );
  }
}
