import 'package:flutter/material.dart';
import '../../core/contracts/simulator_module.dart';
import '../../models/simulator_meta.dart';
import 'screens/acoustic_noise_screen.dart';

class AcousticNoiseModule implements SimulatorModule {
  @override
  SimulatorMeta get meta => const SimulatorMeta(
        id: 'acoustic-noise-lab',
        title: 'Huliot Ultra Silent Acoustic Attenuation',
        subtitle: 'Structure-borne & airborne noise dB(A) simulator',
        description:
            'Simulate wastewater flow noise levels across building floors comparing standard PVC, cast iron, and Huliot Ultra Silent triple-layer PP pipes per EN 14366, DIN 4109, and VDI 4100.',
        category: SimulatorCategory.acoustics,
        status: SimulatorStatus.live,
        icon: Icons.graphic_eq_rounded,
        tags: ['Acoustic', 'dB(A) Noise', 'Ultra Silent', 'EN 14366', 'DIN 4109'],
        isFeatured: true,
      );

  @override
  Widget buildView(BuildContext context) {
    return const AcousticNoiseScreen();
  }

  @override
  List<Widget> buildHeaderActions(BuildContext context) => const [];

  @override
  void onActivate() {}

  @override
  void onDeactivate() {}
}
