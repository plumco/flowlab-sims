import 'package:flutter/material.dart';
import '../../core/contracts/simulator_module.dart';
import '../../models/simulator_meta.dart';
import 'screens/siphonic_roof_screen.dart';

class SiphonicRoofModule implements SimulatorModule {
  @override
  SimulatorMeta get meta => const SimulatorMeta(
        id: 'siphonic-roof-drainage',
        title: 'Siphonic Roof Rainwater Drainage',
        subtitle: 'Full bore negative pressure siphonic flow calculations',
        description:
            'Design roof rainwater gutters, baffles, priming time, and calculate full-bore negative pressure siphonic velocity according to EN 12056-3 and BS 8490.',
        category: SimulatorCategory.siphonicRainwater,
        status: SimulatorStatus.live,
        icon: Icons.cloudy_snowing,
        tags: ['Rainwater', 'Siphonic', 'Roof Drainage', 'BS 8490', 'EN 12056-3'],
        isFeatured: true,
      );

  @override
  Widget buildView(BuildContext context) {
    return const SiphonicRoofScreen();
  }

  @override
  List<Widget> buildHeaderActions(BuildContext context) => const [];

  @override
  void onActivate() {}

  @override
  void onDeactivate() {}
}
