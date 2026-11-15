import 'package:flutter/material.dart';
import '../../core/contracts/simulator_module.dart';
import '../../models/simulator_meta.dart';
import 'screens/water_supply_screen.dart';

class WaterSupplyBoosterModule implements SimulatorModule {
  @override
  SimulatorMeta get meta => const SimulatorMeta(
        id: 'water-supply-booster',
        title: 'Water Supply Booster & Peak Demand',
        subtitle: 'Hunter’s Curve probabilistic fixture demand & booster sizing',
        description:
            'Compute instantaneous peak flow demand (WSFU), pressure drops, booster pump head, and variable frequency drive sizing per IPC, UPC, and BS EN 806.',
        category: SimulatorCategory.waterSupply,
        status: SimulatorStatus.live,
        icon: Icons.water_drop_rounded,
        tags: ['Water Supply', 'Booster Pump', 'Hunter Curve', 'Pressure Head'],
        isFeatured: true,
      );

  @override
  Widget buildView(BuildContext context) {
    return const WaterSupplyScreen();
  }

  @override
  List<Widget> buildHeaderActions(BuildContext context) => const [];

  @override
  void onActivate() {}

  @override
  void onDeactivate() {}
}
