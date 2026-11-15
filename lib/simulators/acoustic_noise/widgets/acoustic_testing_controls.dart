import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/acoustic_models.dart';

class AcousticTestingControls extends StatelessWidget {
  final double flowRate;
  final BracketType bracket;
  final WallType wall;
  final PipeTechnologyType selectedPipe;
  final ValueChanged<double> onFlowRateChanged;
  final ValueChanged<BracketType> onBracketChanged;
  final ValueChanged<WallType> onWallChanged;
  final ValueChanged<PipeTechnologyType> onPipeChanged;

  const AcousticTestingControls({
    super.key,
    required this.flowRate,
    required this.bracket,
    required this.wall,
    required this.selectedPipe,
    required this.onFlowRateChanged,
    required this.onBracketChanged,
    required this.onWallChanged,
    required this.onPipeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune_rounded, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACOUSTIC TEST INSTALLATION CONTROLS',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                  Text(
                    'EN 14366 Boundary Conditions & Hydraulic Load',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),

          // 1. Flow Rate Control
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.water_drop_outlined, size: 16, color: AppColors.accent),
                  SizedBox(width: 6),
                  Text(
                    'Discharge Flow Rate (Q):',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${flowRate.toStringAsFixed(1)} L/s',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accent,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
              thumbColor: AppColors.accent,
              overlayColor: AppColors.accent.withValues(alpha: 0.2),
              trackHeight: 6,
            ),
            child: Slider(
              value: flowRate,
              min: 0.5,
              max: 6.0,
              divisions: 55, // 0.1 L/s step from 0.5 to 6.0
              onChanged: onFlowRateChanged,
            ),
          ),

          // Quick Preset Flow Rate Buttons
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _presetFlowChip(0.5, '0.5 L/s (Basin)'),
              _presetFlowChip(1.0, '1.0 L/s (Shower)'),
              _presetFlowChip(2.0, '2.0 L/s (Std WC Flush)'),
              _presetFlowChip(4.0, '4.0 L/s (Peak Flush)'),
              _presetFlowChip(6.0, '6.0 L/s (Commercial)'),
            ],
          ),

          const SizedBox(height: 20),

          // 2. Pipe Bracket Selection (Huliot Acoustic Isolating vs Rigid Metal)
          const Row(
            children: [
              Icon(Icons.hardware_rounded, size: 16, color: AppColors.accent),
              SizedBox(width: 6),
              Text(
                'Pipe Clamping & Bracket Dampening:',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _bracketChoiceCard(
                  title: 'Huliot Acoustic Clamp',
                  subtitle: 'Elastomer rubber decoupling damper (-5 to -6 dB)',
                  type: BracketType.huliotAcoustic,
                  selected: bracket == BracketType.huliotAcoustic,
                  isDark: isDark,
                  badgeText: 'RECOMMENDED',
                  badgeColor: AppColors.success,
                  onTap: () => onBracketChanged(BracketType.huliotAcoustic),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _bracketChoiceCard(
                  title: 'Rigid Metal Clamp',
                  subtitle: 'Direct metal contact, transmits structural vibrations',
                  type: BracketType.rigidMetal,
                  selected: bracket == BracketType.rigidMetal,
                  isDark: isDark,
                  badgeText: '+5 dB NOISE',
                  badgeColor: AppColors.danger,
                  onTap: () => onBracketChanged(BracketType.rigidMetal),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 3. Wall Construction Mass (220 kg/m² Solid Masonry vs 115 kg/m² Lightweight Partition)
          const Row(
            children: [
              Icon(Icons.foundation_rounded, size: 16, color: AppColors.accent),
              SizedBox(width: 6),
              Text(
                'Mounting Wall Construction & Mass:',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _wallChoiceCard(
                  title: 'Solid Masonry (220 kg/m²)',
                  subtitle: 'Standard EN 14366 test wall with sand-lime blocks',
                  type: WallType.solidMasonry,
                  selected: wall == WallType.solidMasonry,
                  isDark: isDark,
                  badgeText: 'EN 14366 REF',
                  onTap: () => onWallChanged(WallType.solidMasonry),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _wallChoiceCard(
                  title: 'Lightweight Wall (115 kg/m²)',
                  subtitle: 'Drywall metal stud partition (+4 to +6 dB penalty)',
                  type: WallType.lightweightPartition,
                  selected: wall == WallType.lightweightPartition,
                  isDark: isDark,
                  badgeText: 'LIGHTWEIGHT',
                  badgeColor: AppColors.warning,
                  onTap: () => onWallChanged(WallType.lightweightPartition),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 4. Active Pipe Selector (for Decibel Meter needle)
          const Row(
            children: [
              Icon(Icons.radio_button_checked_rounded, size: 16, color: AppColors.accent),
              SizedBox(width: 6),
              Text(
                'Meter Target Pipe Focus:',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: PipeAcousticProfile.allPipes.map((p) {
              final bool isSelected = p.type == selectedPipe;
              return ChoiceChip(
                label: Text(p.name),
                selected: isSelected,
                selectedColor: p.themeColor.withValues(alpha: 0.25),
                side: BorderSide(
                  color: isSelected ? p.themeColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isSelected ? 1.5 : 1.0,
                ),
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? p.themeColor : null,
                ),
                onSelected: (val) {
                  if (val) onPipeChanged(p.type);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _presetFlowChip(double targetFlow, String label) {
    final bool isCurrent = (flowRate - targetFlow).abs() < 0.05;
    return InkWell(
      onTap: () => onFlowRateChanged(targetFlow),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.accent.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isCurrent ? AppColors.accent : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? AppColors.accent : null,
          ),
        ),
      ),
    );
  }

  Widget _bracketChoiceCard({
    required String title,
    required String subtitle,
    required BracketType type,
    required bool selected,
    required bool isDark,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08)
              : (isDark ? const Color(0xFF131D2D) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: selected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _wallChoiceCard({
    required String title,
    required String subtitle,
    required WallType type,
    required bool selected,
    required bool isDark,
    required String badgeText,
    Color badgeColor = AppColors.info,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08)
              : (isDark ? const Color(0xFF131D2D) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: selected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
