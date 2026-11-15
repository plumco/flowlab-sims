import 'package:flutter/material.dart';
import '../contracts/simulator_module.dart';
import '../registry/simulator_hub_registry.dart';

/// Provider for global application-level state (Active Simulator, Dark Mode, Shell Navigation).
///
/// This decouples high-level app shell logic from specific physics simulators,
/// ensuring that individual simulators only care about their own domain.
class AppHubProvider extends ChangeNotifier {
  String _activeSimulatorId = 'sunken-swept-tee';
  bool _isDarkMode = true;

  String get activeSimulatorId => _activeSimulatorId;
  bool get isDarkMode => _isDarkMode;

  SimulatorModule get activeModule {
    return SimulatorHubRegistry.getModule(_activeSimulatorId);
  }

  void selectSimulator(String id) {
    if (_activeSimulatorId == id) return;

    final oldModule = SimulatorHubRegistry.findModule(_activeSimulatorId);
    oldModule?.onDeactivate();

    final newModule = SimulatorHubRegistry.findModule(id);
    if (newModule != null) {
      _activeSimulatorId = id;
      newModule.onActivate();
      notifyListeners();
    }
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
