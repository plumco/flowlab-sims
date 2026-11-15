import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/url_navigation.dart';

class AirnetScreen extends StatelessWidget {
  const AirnetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.air_rounded, size: 64, color: AppColors.accent),
              ),
              const SizedBox(height: 24),
              const Text(
                'AIRNET — Transient Airflow & Pressure Simulator',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Prof. J.A. Swaffield (Heriot-Watt University) 1D Method of Characteristics (MoC) Solver',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Simulation Scope & Scientific Capabilities:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    _bullet(context, 'Annular water downflow film terminal velocity & boundary shear stress calculation.'),
                    _bullet(context, 'Transient 1D pressure wave propagation via Method of Characteristics (St. Venant).'),
                    _bullet(context, 'Active transient protection with Positive Air Pressure Attenuator (P.A.P.A.™) & AAV.'),
                    _bullet(context, 'Forensic diagnostic of Amoy Gardens SARS aerosol cross-contamination & trap depletion.'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => openSimulatorUrl('sims/airnet/index.html'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.launch_rounded, size: 20),
                label: const Text(
                  'Launch Interactive AIRNET Lab (Full Screen)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.4))),
        ],
      ),
    );
  }
}
