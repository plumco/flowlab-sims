import 'package:flutter/material.dart';
import '../../core/contracts/simulator_module.dart';
import '../../core/theme/app_colors.dart';
import '../../models/simulator_meta.dart';
import 'screens/acoustic_noise_screen.dart';
import 'widgets/fraunhofer_certificate_dialog.dart';

class AcousticNoiseModule implements SimulatorModule {
  @override
  SimulatorMeta get meta => const SimulatorMeta(
        id: 'acoustic-noise-lab',
        title: 'Huliot Ultra Silent Acoustic Attenuation',
        subtitle: 'Structure-borne & airborne noise dB(A) simulator',
        description:
            'Simulate wastewater flow noise levels across building floors comparing standard PVC, cast iron, HDPE, and Huliot Ultra Silent triple-layer PP pipes per EN 14366, DIN 4109, and VDI 4100.',
        category: SimulatorCategory.acoustics,
        status: SimulatorStatus.live,
        icon: Icons.graphic_eq_rounded,
        tags: ['Acoustic', 'dB(A) Noise', 'Ultra Silent', 'EN 14366', 'DIN 4109', 'Fraunhofer IBP'],
        isFeatured: true,
      );

  @override
  Widget buildView(BuildContext context) {
    return const AcousticNoiseScreen();
  }

  @override
  List<Widget> buildHeaderActions(BuildContext context) => [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.accent, width: 1.2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          onPressed: () => FraunhoferCertificateDialog.show(context),
          icon: const Icon(Icons.verified_user_rounded, size: 16),
          label: const Text('Fraunhofer Certificate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ];

  @override
  void onActivate() {}

  @override
  void onDeactivate() {}
}
