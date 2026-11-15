import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/acoustic_models.dart';

class PipeComparisonBench extends StatelessWidget {
  final double flowRate;
  final BracketType bracket;
  final WallType wall;
  final PipeTechnologyType selectedPipeType;
  final ValueChanged<PipeTechnologyType> onSelectPipe;

  const PipeComparisonBench({
    super.key,
    required this.flowRate,
    required this.bracket,
    required this.wall,
    required this.selectedPipeType,
    required this.onSelectPipe,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Precalculate Huliot noise for delta comparison
    final double huliotDb = PipeAcousticProfile.huliot.calculateNoise(
      flowRate: flowRate,
      bracket: bracket,
      wall: wall,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MULTI-PIPE ACOUSTIC BENCHMARK COMPARISON',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                Text(
                  'Engineering Acoustic Matrix @ Q = ${flowRate.toStringAsFixed(1)} L/s (Continuous Vertical Stack Discharge)',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.table_chart_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('${PipeAcousticProfile.allPipes.length} Pipe Systems Matrix',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Sleek, High-Density Engineering Comparison Matrix Table
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 840),
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 56,
                horizontalMargin: 16,
                columnSpacing: 18,
                headingRowColor: WidgetStateProperty.all(
                  isDark ? const Color(0xFF131D2D) : const Color(0xFFF1F5F9),
                ),
                columns: const [
                  DataColumn(
                    label: Text(
                      'PIPE SYSTEM & TECHNOLOGY',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'STRUCTURE L_sc,A',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'AIRBORNE L_a,A',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'VS HULIOT Δ',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'CERTIFICATION SOURCE',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'COMPLIANCE RATING',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'ACTION',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                    ),
                  ),
                ],
                rows: PipeAcousticProfile.allPipes.map((pipe) {
                  final double pipeDb = pipe.calculateNoise(
                    flowRate: flowRate,
                    bracket: bracket,
                    wall: wall,
                  );
                  final double airborneDb = pipe.calculateAirborneNoise(flowRate);
                  final bool isSelected = pipe.type == selectedPipeType;
                  final bool isHuliot = pipe.type == PipeTechnologyType.huliotUltraSilent;
                  final double deltaDb = pipeDb - huliotDb;

                  return _buildDataRow(
                    context: context,
                    pipe: pipe,
                    pipeDb: pipeDb,
                    airborneDb: airborneDb,
                    deltaDb: deltaDb,
                    isSelected: isSelected,
                    isHuliot: isHuliot,
                    isDark: isDark,
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Huliot Ultra Silent 3-Layer Technology Highlight Card
        _threeLayerTechnologyCard(isDark: isDark),
      ],
    );
  }

  DataRow _buildDataRow({
    required BuildContext context,
    required PipeAcousticProfile pipe,
    required double pipeDb,
    required double airborneDb,
    required double deltaDb,
    required bool isSelected,
    required bool isHuliot,
    required bool isDark,
  }) {
    Color statusColor;
    String statusText;
    if (pipeDb <= 24.0) {
      statusColor = AppColors.success;
      statusText = 'VDI 4100 SSt III Luxury';
    } else if (pipeDb <= 30.0) {
      statusColor = AppColors.warning;
      statusText = 'DIN 4109 Pass';
    } else {
      statusColor = AppColors.danger;
      statusText = 'Fails DIN 4109';
    }

    return DataRow(
      selected: isSelected,
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (isSelected) {
          return pipe.themeColor.withValues(alpha: isDark ? 0.2 : 0.1);
        }
        if (isHuliot) {
          return AppColors.success.withValues(alpha: isDark ? 0.08 : 0.05);
        }
        return null;
      }),
      onSelectChanged: (_) => onSelectPipe(pipe.type),
      cells: [
        // 1. Pipe System & Technology
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: pipe.themeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pipe.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isHuliot ? FontWeight.w900 : FontWeight.bold,
                          color: isHuliot ? AppColors.success : null,
                        ),
                      ),
                      if (isHuliot) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'WHISPER QUIET',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    pipe.resonanceDescription,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Structure L_sc,A
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${pipeDb.toStringAsFixed(1)} dB',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: pipe.themeColor,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 4),
              const Text('(A)', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
            ],
          ),
        ),

        // 3. Airborne L_a,A
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${airborneDb.toStringAsFixed(1)} dB',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.cyan,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 4),
              const Text('(A)', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
            ],
          ),
        ),

        // 4. Vs Huliot Δ
        DataCell(
          isHuliot
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'BENCHMARK REF',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AppColors.success),
                  ),
                )
              : Text(
                  '+${deltaDb.toStringAsFixed(1)} dB (${_perceivedLoudness(deltaDb)})',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                  ),
                ),
        ),

        // 5. Certification Source
        DataCell(
          pipe.hasFraunhoferCert
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    '✓ Fraunhofer IBP (P-BA 20/2019e)',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                )
              : Text(
                  pipe.certReportNo,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
        ),

        // 6. Compliance Rating
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              statusText,
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
        ),

        // 7. Action
        DataCell(
          isSelected
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: pipe.themeColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: pipe.themeColor),
                  ),
                )
              : OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: () => onSelectPipe(pipe.type),
                  child: const Text('Select', style: TextStyle(fontSize: 10)),
                ),
        ),
      ],
    );
  }

  String _perceivedLoudness(double deltaDb) {
    if (deltaDb >= 15) return '~3.5x louder';
    if (deltaDb >= 10) return '~2x louder';
    if (deltaDb >= 6) return '+50% louder';
    if (deltaDb >= 3) return 'noticeably louder';
    return 'comparable';
  }

  Widget _threeLayerTechnologyCard({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1B2A) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.layers_rounded, color: AppColors.success, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HULIOT ULTRA SILENT: 3-LAYER CO-EXTRUSION ACOUSTIC TECHNOLOGY',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      'Patented composite pipe wall engineered to attenuate both fluid flow turbulence & structure vibration',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 layer visual breakdown
          Row(
            children: [
              Expanded(
                child: _layerPill(
                  number: '1',
                  name: 'Ultra-Smooth PP Bore',
                  desc: 'Hydraulic friction k = 0.007 mm. Prevents turbulence noise.',
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _layerPill(
                  number: '2',
                  name: 'Mineral-Reinforced PP-MD',
                  desc: 'High mass damping core. Absorbs acoustic vibration energy.',
                  color: const Color(0xFF06B6D4),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _layerPill(
                  number: '3',
                  name: 'Impact Casing Shield',
                  desc: 'Tough outer PP layer. Resists mechanical damage and site weathering.',
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _layerPill({
    required String number,
    required String name,
    required String desc,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
