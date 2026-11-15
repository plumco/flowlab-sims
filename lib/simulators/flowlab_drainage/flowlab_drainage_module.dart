import 'package:flutter/material.dart';
import '../../core/contracts/simulator_module.dart';
import '../../models/simulator_meta.dart';
import '../../screens/dashboard_screen.dart';

/// Module adapter for Huliot FlowLab Single Stack & PRL System Simulator.
///
/// Encapsulates all drainage physics, EN 12056-2 standards, and CAD visualization
/// without exposing or entangling any logic with other simulators.
class FlowLabDrainageModule implements SimulatorModule {
  @override
  SimulatorMeta get meta => const SimulatorMeta(
        id: 'sunken-swept-tee',
        title: 'Sunken Floor + Swept Tee & PRL System',
        subtitle: 'Dynamic stack pressure & trap seal retention screening',
        description:
            'Interactive CAD-grade drainage simulation with 2 to 100 floors, 3 PRL arrangements, live positive backpressure, negative suction, and Huliot Swept Tee fittings.',
        category: SimulatorCategory.drainage,
        status: SimulatorStatus.live,
        icon: Icons.waves_rounded,
        tags: ['Drainage', 'PRL Relief', 'Swept Tee', 'High-Rise', 'EN 12056'],
        isFeatured: true,
      );

  @override
  Widget buildView(BuildContext context) {
    return const DashboardScreen();
  }

  @override
  List<Widget> buildHeaderActions(BuildContext context) {
    return const [];
  }

  @override
  void onActivate() {}

  @override
  void onDeactivate() {}
}
