import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AcousticTestingGuideDialog extends StatelessWidget {
  const AcousticTestingGuideDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AcousticTestingGuideDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F2620) : const Color(0xFFECFDF5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: AppColors.success.withValues(alpha: 0.3))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: AppColors.success, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ON-SITE ACOUSTIC TESTING SOP & GUIDELINES',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          'ISO 16032 & EN 14366 Standardized Drainage Pipe Acoustic Field Protocol',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
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

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 1: Physical Placement
                    _buildSectionHeader(
                      icon: Icons.my_location_rounded,
                      title: '1. Device & Microphone Placement (Distance & Location)',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBullet(
                            title: 'Shaft / Duct Testing (Airborne Sound L_a,A):',
                            description:
                                'Hold the device exactly 1.0 meter away from the vertical drainage stack. Maintain sensor height between 1.2 m to 1.5 m above finished floor level. Do not place device directly in contact with pipe vibrations.',
                          ),
                          const SizedBox(height: 8),
                          _buildBullet(
                            title: 'Receiver Room Testing (Structure-Borne Sound L_sc,A):',
                            description:
                                'Stand in the habitable room adjacent to the pipe shaft (behind the wall). Keep the room door closed, windows sealed. Maintain at least 1.0 m clearance from walls and windows to eliminate corner reflection buildup.',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Step 2: 3-Phase ISO 16032 Protocol
                    _buildSectionHeader(
                      icon: Icons.filter_drama_rounded,
                      title: '2. 3-Phase Acoustic Testing Protocol (Background Noise Isolation)',
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPhaseItem(
                            step: 'Phase A',
                            title: 'Ambient Noise Floor Calibration (10-15s)',
                            desc:
                                'Record the resting room sound before flushing. Site background noise (traffic, fans, generators) is measured as L_bg. Ensure ambient floor is ideally < 35 dB(A).',
                          ),
                          const Divider(height: 16),
                          _buildPhaseItem(
                            step: 'Phase B',
                            title: 'Water Discharge & Flush Capture (15-30s)',
                            desc:
                                'Initiate steady toilet flush or water discharge (2.0 L/s). The app records combined sound (pipe sound + background) as L_total.',
                          ),
                          const Divider(height: 16),
                          _buildPhaseItem(
                            step: 'Phase C',
                            title: 'ISO 16032 Mathematical Energetic Isolation',
                            desc:
                                'App applies logarithmic subtraction: L_pipe = 10·log₁₀(10^(L_total/10) − 10^(L_bg/10)). This strips out room noise to reveal true pipe noise!',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Step 3: ISO 16032 Reliability & ΔL Rules
                    _buildSectionHeader(
                      icon: Icons.analytics_outlined,
                      title: '3. ISO 16032 Measurement Validity Rules (ΔL = L_total − L_bg)',
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 10),
                    Table(
                      border: TableBorder.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(1.2),
                        1: FlexColumnWidth(1.0),
                        2: FlexColumnWidth(2.0),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.grey.shade100,
                          ),
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Difference (ΔL)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Confidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Scientific Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                        _buildTableRow('ΔL ≥ 10 dB', 'HIGH', 'Negligible background interference (<0.5 dB error). Direct pass.', isDark),
                        _buildTableRow('6 ≤ ΔL < 10 dB', 'MEDIUM', 'Apply formula; subtracts 0.6 to 1.3 dB background energy.', isDark),
                        _buildTableRow('3 ≤ ΔL < 6 dB', 'LOW', 'Formula applies with ±1.5 dB uncertainty warning.', isDark),
                        _buildTableRow('ΔL < 3 dB', 'UNRELIABLE', 'Cannot isolate pipe noise. Wait for site silence & re-test.', isDark, isError: true),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Step 4: Engineering Disclaimer
                    _buildSectionHeader(
                      icon: Icons.verified_user_rounded,
                      title: '4. Legal & Regulatory Compliance Note',
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'This in-app acoustic meter uses device Web Audio hardware and ISO 16032 mathematical correction to benchmark pipe noise on construction sites. Huliot Ultra Silent official certified ratings (< 10 dB at 0.5 L/s, 15 dB at 2.0 L/s) are formally validated by Fraunhofer Institute for Building Physics (IBP Report P-BA 20/2019e & P-BA 155/2023e) under EN 14366 laboratory conditions.',
                        style: TextStyle(fontSize: 11, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Understood / Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title, required Color color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: child,
    );
  }

  Widget _buildBullet({required String title, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 11.5, height: 1.4, color: Colors.grey),
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseItem({required String step, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            step,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildTableRow(String delta, String conf, String action, bool isDark, {bool isError = false}) {
    final Color textColor = isError
        ? AppColors.danger
        : (conf == 'HIGH' ? AppColors.success : (conf == 'MEDIUM' ? AppColors.accent : AppColors.warning));
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(delta, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(conf, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: textColor)),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(action, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ),
      ],
    );
  }
}
