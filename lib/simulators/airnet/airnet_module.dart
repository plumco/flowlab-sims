import 'package:flutter/material.dart';
import '../../core/contracts/simulator_module.dart';
import '../../models/simulator_meta.dart';
import 'screens/airnet_screen.dart';

class AirnetModule implements SimulatorModule {
  @override
  SimulatorMeta get meta => const SimulatorMeta(
        id: 'airnet',
        title: 'AIRNET - Transient Airflow & Pressure Simulator',
        subtitle: 'Prof. Swaffield MoC 1D transient airflow & Kelly trap diagnostic',
        description:
            'St. Venant 1D Method of Characteristics solver. Simulates annular water film downflow, negative suction peak, stack base hydraulic surcharge, AAV & P.A.P.A.™ active transient attenuator, trap seal blowout/siphonage & Amoy Gardens SARS virus outbreak forensics.',
        category: SimulatorCategory.drainage,
        status: SimulatorStatus.live,
        icon: Icons.air_rounded,
        tags: ['Drainage', 'AIRNET', 'Transient', 'MoC', 'P.A.P.A.', 'AAV', 'Trap Seal'],
        isFeatured: true,
        url: 'sims/airnet/index.html',
        isExternalUrl: true,
      );

  @override
  Widget buildView(BuildContext context) {
    return const AirnetScreen();
  }

  @override
  List<Widget> buildHeaderActions(BuildContext context) => const [];

  @override
  void onActivate() {}

  @override
  void onDeactivate() {}
}
