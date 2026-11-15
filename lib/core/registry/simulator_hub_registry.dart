import '../../models/simulator_meta.dart';
import '../contracts/simulator_module.dart';
import '../../simulators/flowlab_drainage/flowlab_drainage_module.dart';
import '../../simulators/airnet/airnet_module.dart';
import '../../simulators/siphonic_roof/siphonic_roof_module.dart';
import '../../simulators/acoustic_noise/acoustic_noise_module.dart';
import '../../simulators/water_supply/water_supply_module.dart';

/// Central Plug-and-Play Hub Registry for all engineering simulators.
///
/// Any new simulator created in `lib/simulators/<new_sim>/` simply registers
/// here. No other existing simulator code ever needs to be modified.
class SimulatorHubRegistry {
  static final Map<String, SimulatorModule> _registeredModules = {
    'sunken-swept-tee': FlowLabDrainageModule(),
    'airnet': AirnetModule(),
    'siphonic-roof-drainage': SiphonicRoofModule(),
    'acoustic-noise-lab': AcousticNoiseModule(),
    'water-supply-booster': WaterSupplyBoosterModule(),
  };

  /// Returns the active module or falls back to FlowLab Single Stack
  static SimulatorModule getModule(String id) {
    return _registeredModules[id] ?? _registeredModules['sunken-swept-tee']!;
  }

  /// Finds a registered module if present
  static SimulatorModule? findModule(String id) {
    return _registeredModules[id];
  }

  /// Lists all registered simulator modules
  static List<SimulatorModule> get allModules => _registeredModules.values.toList();

  /// Gets list of modules by category
  static List<SimulatorModule> getByCategory(SimulatorCategory category) {
    return _registeredModules.values
        .where((m) => m.meta.category == category)
        .toList();
  }
}
