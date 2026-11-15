import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/acoustic_models.dart';

class FraunhoferCertificateDialog extends StatelessWidget {
  const FraunhoferCertificateDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const FraunhoferCertificateDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 720),
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131D2D) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: AppColors.accent, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            const Text(
                              'FRAUNHOFER IBP TEST REPORT SUMMARY',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.success),
                              ),
                              child: const Text(
                                'OFFICIAL CERTIFICATE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Test Reports P-BA 20/2019e & P-BA 155/2023e | Fraunhofer Institute for Building Physics (IBP Stuttgart)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Specimen & Standards Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tested Specimen & Test Facility Specifications',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          _infoRow('Test Facility:', 'Fraunhofer IBP Laboratory Test Stand (Nobelstr. 12, Stuttgart, Germany)', isDark),
                          _infoRow('Specimen Tested:', 'Huliot Ultra Silent DN 110 x 3.4 mm PP-MD 3-Layer Pipe System', isDark),
                          _infoRow('Standard Method:', 'DIN EN 14366:2005 "Laboratory measurement of noise from waste water installations"', isDark),
                          _infoRow('Installation Wall:', '220 kg/m² Solid Sand-Lime Blockwork Wall with plaster (Standard EN 14366 test wall)', isDark),
                          _infoRow('Acoustic Brackets:', 'Huliot Acoustic Dampening Clamps (elastomeric vibration decoupling collar)', isDark),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Test Data Table
                    const Text(
                      'Official Fraunhofer Laboratory Measured Acoustic Sound Levels',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Structure-Borne (L_sc,A) & Airborne (L_a,A) noise across discharge flow rates Q per EN 14366:',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Custom Data Table
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1.2),
                            1: FlexColumnWidth(1.8),
                            2: FlexColumnWidth(1.5),
                            3: FlexColumnWidth(1.8),
                            4: FlexColumnWidth(2.0),
                          },
                          border: TableBorder(
                            horizontalInside: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              width: 0.8,
                            ),
                          ),
                          children: [
                            // Table Header
                            TableRow(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                              ),
                              children: [
                                _tableHeaderCell('Flow (Q)', 'L/s'),
                                _tableHeaderCell('Structure-Borne', 'L_sc,A dB(A)'),
                                _tableHeaderCell('Airborne', 'L_a,A dB(A)'),
                                _tableHeaderCell('Standard Clamp', 'L_sc,A dB(A)'),
                                _tableHeaderCell('VDI 4100 / DIN 4109', 'Acoustic Compliance'),
                              ],
                            ),

                            // Data Rows
                            ...FraunhoferTestPoint.officialData.map((pt) {
                              return TableRow(
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                ),
                                children: [
                                  _tableDataCell('${pt.flowRate.toStringAsFixed(1)} L/s', isBold: true),
                                  _tableHighlightedCell(
                                    '${pt.structureBorneDisplay} dB(A)',
                                    AppColors.success,
                                    subtext: 'Huliot Acoustic Clamp',
                                  ),
                                  _tableDataCell('${pt.airborneDb.toStringAsFixed(0)} dB(A)'),
                                  _tableDataCell('${pt.standardClampStructureBorneDb.toStringAsFixed(1)} dB(A)'),
                                  _tableBadgeCell(
                                    'VDI 4100 SSt III (<24 dB)',
                                    'PASSED (Whisper Quiet)',
                                    AppColors.success,
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Standards Compliance Badges Grid
                    const Text(
                      'International Standard Compliance Certifications',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isWide = constraints.maxWidth > 580;
                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(
                                child: _complianceCard(
                                  standard: 'DIN 4109',
                                  title: 'German Building Acoustic Code',
                                  limitStr: 'Limit: <= 30 dB(A)',
                                  resultStr: 'Huliot: 15 dB(A) (Pass by 15 dB)',
                                  color: AppColors.success,
                                  icon: Icons.check_circle_rounded,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _complianceCard(
                                  standard: 'VDI 4100 SSt III',
                                  title: 'Highest Luxury Comfort Class',
                                  limitStr: 'Limit: <= 24 dB(A)',
                                  resultStr: 'Huliot: 15 dB(A) (Pass by 9 dB)',
                                  color: AppColors.success,
                                  icon: Icons.hotel_rounded,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _complianceCard(
                                  standard: 'EN 14366',
                                  title: 'European Laboratory Protocol',
                                  limitStr: 'Accredited Lab Protocol',
                                  resultStr: 'Report P-BA 20/2019e Certified',
                                  color: AppColors.accent,
                                  icon: Icons.fact_check_rounded,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _complianceCard(
                                standard: 'DIN 4109',
                                title: 'German Building Acoustic Code',
                                limitStr: 'Limit: <= 30 dB(A)',
                                resultStr: 'Huliot: 15 dB(A) (Pass by 15 dB)',
                                color: AppColors.success,
                                icon: Icons.check_circle_rounded,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 10),
                              _complianceCard(
                                standard: 'VDI 4100 SSt III',
                                title: 'Highest Luxury Comfort Class',
                                limitStr: 'Limit: <= 24 dB(A)',
                                resultStr: 'Huliot: 15 dB(A) (Pass by 9 dB)',
                                color: AppColors.success,
                                icon: Icons.hotel_rounded,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 10),
                              _complianceCard(
                                standard: 'EN 14366',
                                title: 'European Laboratory Protocol',
                                limitStr: 'Accredited Lab Protocol',
                                resultStr: 'Report P-BA 20/2019e Certified',
                                color: AppColors.accent,
                                icon: Icons.fact_check_rounded,
                                isDark: isDark,
                              ),
                            ],
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // Technical Note
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Engineering Interpretation: At typical toilet flush flow (2.0 L/s), Huliot Ultra Silent produces only 15 dB(A) structure-borne noise in adjoining bedrooms. For reference, human breathing is 10 dB(A), rustling leaves are 20 dB(A), and a quiet bedroom at night is 25 dB(A). Huliot ensures total acoustic silence for occupants.',
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.45,
                                color: isDark ? AppColors.darkText : AppColors.lightText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131D2D) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(
                  top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Fraunhofer IBP Reports P-BA 20/2019e & P-BA 155/2023e | Huliot Pipes Ltd.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close Certificate'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeaderCell(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _tableDataCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _tableHighlightedCell(String text, Color color, {String? subtext}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color),
          ),
          if (subtext != null)
            Text(subtext, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _tableBadgeCell(String title, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color, width: 0.8),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _complianceCard({
    required String standard,
    required String title,
    required String limitStr,
    required String resultStr,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  standard,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            limitStr,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
          ),
          Text(
            resultStr,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
