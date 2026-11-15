import 'package:flutter/material.dart';
import '../../models/simulator_meta.dart';

/// Abstract contract for any simulator module in the Huliot Engineering Hub.
///
/// Every simulator (Single Stack FlowLab, AIRNET, Siphonic Roof, Acoustic Noise,
/// Water Supply Booster, etc.) implements this contract.
///
/// Adding a new simulator to the suite requires ZERO changes to existing simulators.
abstract class SimulatorModule {
  /// Metadata identifying the simulator, its category, status, and display tags.
  SimulatorMeta get meta;

  /// Builds the main interactive view / screen for this simulator.
  Widget buildView(BuildContext context);

  /// Builds simulator-specific action buttons for the top app header
  /// (e.g. Export CSV, Generate PDF, Scenario Lab Toggle, etc.).
  List<Widget> buildHeaderActions(BuildContext context) => const [];

  /// Lifecycle callback when the user navigates TO this simulator.
  void onActivate() {}

  /// Lifecycle callback when the user navigates AWAY from this simulator.
  void onDeactivate() {}
}
