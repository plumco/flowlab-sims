import 'dart:math';

class StaticPhysicsResult {
  final List<double> pr; // Total static+dynamic pressure profile mm WG
  final List<double> prDyn; // Dynamic component
  final List<double> sw; // Sewer component
  final double terminalVelocity; // Vt in m/s (Wyly-Eaton: 10.1 * (Q/D)^0.4)
  final double terminalLength; // Lt in meters (Wyly-Eaton: 0.17 * Vt^2)
  final double airVelocity; // Va in m/s
  final double capacityUtilization; // fill %
  final double stackCapacity; // Qcap L/s
  final double maxPositivePressure;
  final double maxNegativePressure;
  final double worstPressureMagnitude;

  // Wyly-Eaton Annular Water Film & Air Core Metrics
  final double filmThicknessMm; // tw in mm (annular water ring thickness)
  final double airCoreDiameterMm; // Dair in mm (central air core diameter)
  final double waterAreaFraction; // rw = Aw / Apipe
  final double airCoreAreaFraction; // 1 - rw
  final String chokeRiskLevel; // 'optimal' (rw <= 0.25), 'transition' (0.25-0.33), 'choked' (> 0.33)

  StaticPhysicsResult({
    required this.pr,
    required this.prDyn,
    required this.sw,
    required this.terminalVelocity,
    required this.terminalLength,
    required this.airVelocity,
    required this.capacityUtilization,
    required this.stackCapacity,
    required this.maxPositivePressure,
    required this.maxNegativePressure,
    required this.worstPressureMagnitude,
    required this.filmThicknessMm,
    required this.airCoreDiameterMm,
    required this.waterAreaFraction,
    required this.airCoreAreaFraction,
    required this.chokeRiskLevel,
  });
}

class SystemDynamicState {
  final List<double> trapDisplacement; // y (mm)
  final List<double> trapVelocity; // v (mm/s)
  final List<double> targetPressure; // tgt (mm WG)
  final List<double> trapSealRetention; // seal level (mm)
  final List<double> peakPositive;
  final List<double> peakNegative;
  final List<Point<double>> pressureHistory; // max/min over time
  double peakAllPositive = 0.0;
  double peakAllNegative = 0.0;

  SystemDynamicState({
    required int floors,
    required double initialSeal,
  })  : trapDisplacement = List<double>.filled(floors, 0.0),
        trapVelocity = List<double>.filled(floors, 0.0),
        targetPressure = List<double>.filled(floors, 0.0),
        trapSealRetention = List<double>.filled(floors, initialSeal),
        peakPositive = List<double>.filled(floors, 0.0),
        peakNegative = List<double>.filled(floors, 0.0),
        pressureHistory = [];

  void resetTraps(double initialSeal) {
    trapDisplacement.fillRange(0, trapDisplacement.length, 0.0);
    trapVelocity.fillRange(0, trapVelocity.length, 0.0);
    trapSealRetention.fillRange(0, trapSealRetention.length, initialSeal);
  }

  void clearPeaks() {
    peakPositive.fillRange(0, peakPositive.length, 0.0);
    peakNegative.fillRange(0, peakNegative.length, 0.0);
    peakAllPositive = 0.0;
    peakAllNegative = 0.0;
    pressureHistory.clear();
  }
}

enum StandardVerdict {
  pass,
  marginal,
  fail,
}

enum FlowLabReportType {
  standardCompliance, // EN 12056 standard test on user-selected floors
  overloadStress,     // Full building simultaneous all-bathroom overload test
  morningRushAudit,   // 1-Hour dynamic behavioral Monte Carlo rush audit
}
