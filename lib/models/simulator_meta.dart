import 'package:flutter/material.dart';

enum SimulatorCategory {
  drainage,
  waterSupply,
  acoustics,
  siphonicRainwater,
}

enum SimulatorStatus {
  live,
  beta,
  comingSoon,
}

class SimulatorMeta {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final SimulatorCategory category;
  final SimulatorStatus status;
  final IconData icon;
  final List<String> tags;
  final bool isFeatured;

  const SimulatorMeta({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.status,
    required this.icon,
    required this.tags,
    this.isFeatured = false,
  });
}

class SimulatorRegistry {
  static const List<SimulatorMeta> simulators = [
    SimulatorMeta(
      id: 'sunken-swept-tee',
      title: 'Sunken Floor + Swept Tee & PRL System',
      subtitle: 'Dynamic stack pressure & trap seal retention screening',
      description: 'Interactive CAD-grade drainage simulation with 2 to 100 floors, 3 PRL arrangements (A, B, C), live positive backpressure, negative suction, and Huliot Swept Tee fittings.',
      category: SimulatorCategory.drainage,
      status: SimulatorStatus.live,
      icon: Icons.waves_rounded,
      tags: ['Drainage', 'PRL Relief', 'Swept Tee', 'High-Rise', 'EN 12056'],
      isFeatured: true,
    ),
    SimulatorMeta(
      id: 'prl-options',
      title: 'PRL Arrangements Comparison',
      subtitle: 'Side-by-side comparative analysis of PRL A, B & C loops',
      description: 'Direct comparison of pressure relief lines under identical discharge surge loads with animated bypass airflow.',
      category: SimulatorCategory.drainage,
      status: SimulatorStatus.comingSoon,
      icon: Icons.compare_arrows_rounded,
      tags: ['Drainage', 'PRL Loop', 'Multi-System'],
    ),
    SimulatorMeta(
      id: 'stack-sizing-vent',
      title: 'Single Stack Sizing & Vent Sizing Lab',
      subtitle: 'Air entrainment, hydraulic capacity & AAV validation',
      description: 'Calculates air entrainment velocities, stack capacity limits, and verifies air admittance valve (AAV) performance.',
      category: SimulatorCategory.drainage,
      status: SimulatorStatus.comingSoon,
      icon: Icons.vertical_align_bottom_rounded,
      tags: ['Drainage', 'Vent Sizing', 'AAV Valve'],
    ),
    SimulatorMeta(
      id: 'water-supply-booster',
      title: 'Water Supply Booster & Peak Demand',
      subtitle: 'Hunter’s Curve probabilistic fixture demand & booster sizing',
      description: 'Compute instantaneous peak flow demand (WSFU), pressure drops, booster pump head, and variable frequency drive sizing.',
      category: SimulatorCategory.waterSupply,
      status: SimulatorStatus.comingSoon,
      icon: Icons.water_drop_rounded,
      tags: ['Water Supply', 'Booster Pump', 'Hunter Curve', 'Pressure Head'],
    ),
    SimulatorMeta(
      id: 'acoustic-noise-lab',
      title: 'Huliot Ultra Silent Acoustic Attenuation',
      subtitle: 'Structure-borne & airborne noise dB(A) simulator',
      description: 'Simulate wastewater flow noise levels across building floors comparing standard PVC, cast iron, and Huliot Ultra Silent triple-layer PP pipes.',
      category: SimulatorCategory.acoustics,
      status: SimulatorStatus.comingSoon,
      icon: Icons.graphic_eq_rounded,
      tags: ['Acoustic', 'dB(A) Noise', 'Ultra Silent', 'EN 14366'],
    ),
    SimulatorMeta(
      id: 'siphonic-roof-drainage',
      title: 'Siphonic Roof Rainwater Drainage',
      subtitle: 'Full bore negative pressure siphonic flow calculations',
      description: 'Design roof rainwater gutters, baffles, priming time, and calculate full-bore negative pressure siphonic velocity.',
      category: SimulatorCategory.siphonicRainwater,
      status: SimulatorStatus.comingSoon,
      icon: Icons.cloudy_snowing,
      tags: ['Rainwater', 'Siphonic', 'Roof Drainage'],
    ),
  ];

  static SimulatorMeta get activeDefault => simulators.first;

  static List<SimulatorMeta> getByCategory(SimulatorCategory category) {
    return simulators.where((s) => s.category == category).toList();
  }
}
