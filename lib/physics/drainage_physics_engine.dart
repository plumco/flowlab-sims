import 'dart:math';
import '../models/simulation_params.dart';
import '../models/simulation_state.dart';

class DrainagePhysicsEngine {
  static const double g = 9.81;
  static const double rho = 1.2; // Air density kg/m3
  static const double nu = 1e-6; // Kinematic viscosity m2/s
  static const double fi = 0.05; // Interfacial friction factor
  static const double fw = 0.02; // Pipe wall friction factor

  /// Calculates the quasi-steady air-entrainment and pressure screening along the stack.
  static StaticPhysicsResult calculateStaticProfile(
    SimulationParams p, {
    int? overridePrlOption,
    bool? overridePrlFitted,
  }) {
    final int opt = overridePrlOption ?? p.prlOption;
    final bool prl = overridePrlFitted ?? p.prlFitted;

    final double totalHeight = p.floors * p.floorHeight;
    final double pipeDiameterM = (p.stackDiameter - 6) / 1000.0; // Internal diameter
    final int actualActiveFloors = min(p.nActive, p.floors);
    final double totalDischargeFlowM3s = (actualActiveFloors * p.flowPerFloor) / 1000.0;
    final double totalDischargeFlowLps = actualActiveFloors * p.flowPerFloor;

    // Wyly & Eaton (NBS Monograph 31 / BMS 132) Terminal Velocity Formula:
    // Vt = 10.1 * (Q / D)^(2/5) = 10.1 * (Q / D)^0.4
    // where Q is in LPS (L/s) and D is stack diameter in mm
    final double vt = totalDischargeFlowLps > 0
        ? (10.1 * pow(totalDischargeFlowLps / p.stackDiameter, 0.4)).toDouble()
        : 0.0;

    // Wyly & Eaton Terminal Length: Lt = 0.17 * Vt^2 (vertical fall in meters to achieve Vt)
    final double lt = 0.17 * vt * vt;

    // Wyly & Eaton Annular Flow Continuity & Air Core Metrics:
    final double pipeAreaM2 = pi * pipeDiameterM * pipeDiameterM / 4.0;
    final double waterAreaM2 = vt > 0 ? (totalDischargeFlowM3s / vt) : 0.0;
    final double waterAreaFraction = (waterAreaM2 / pipeAreaM2).clamp(0.0, 1.0);
    final double airCoreAreaFraction = 1.0 - waterAreaFraction;
    final double airCoreDiameterM = pipeDiameterM * sqrt(airCoreAreaFraction);
    final double filmThicknessM = (pipeDiameterM - airCoreDiameterM) / 2.0;
    final double filmThicknessMm = filmThicknessM * 1000.0;
    final double airCoreDiameterMm = airCoreDiameterM * 1000.0;
    final String chokeRiskLevel = waterAreaFraction > 0.33
        ? 'choked'
        : (waterAreaFraction > 0.25 ? 'transition' : 'optimal');

    // Core air diameter inside annular film for friction calculations
    final double coreDiameter = max(0.01, airCoreDiameterM);

    // Hydraulic stack capacity Qcap (L/s)
    final double qCap = 4.0 * pow(p.stackDiameter / 110.0, 8.0 / 3.0);
    final double capacityUtilization = (totalDischargeFlowM3s * 1000.0) / max(0.1, qCap);

    // Inlet loss coefficient at stack top
    final double kin = switch (p.ventType) {
      'aav' => 4.0,
      'blocked' => 25.0,
      _ => 0.8, // 'open'
    };

    // Base geometry and PRL system factor
    final (double kb, double prlEff) = switch (opt) {
      2 => (1.5, 0.85), // System B: offset with PRL loop
      3 => (0.2, 0.95), // System C: straight stack, base rejoin
      _ => (0.6, 1.00), // System A: PRL beside stack, 45° bends
    };

    // Fitting loss multiplier (Huliot Swept Tee vs Standard 87.5° tee)
    final double kjFitted = p.teeType == 'swept' ? 0.85 : 1.00;
    final double surgeMultiplier = p.teeType == 'swept' ? 0.93 : 1.12;

    final double totalFlowLs = totalDischargeFlowM3s * 1000.0;
    final double branchLossKj = 10.0 * min(2.0, max(0.3, totalFlowLs / 3.0)) * kjFitted;
    final double dynamicSurge = p.surgeFactor * surgeMultiplier;

    double kBase = kb + branchLossKj;
    if (prl) {
      final double areaRatio = pow(p.prlDiameter / p.stackDiameter, 2.0) * prlEff;
      kBase = (kBase / pow(1.0 + 1.5 * areaRatio, 2.0)) * (1.0 + 0.02 * 2.0);
    }

    final double totalK = kin + kBase;
    final double dynamicPressureCoeff = 0.5 * rho;

    // Bisection search for entrained air velocity Va (m/s)
    double lo = 0.0;
    double hi = vt;
    for (int i = 0; i < 60; i++) {
      final double mid = (lo + hi) / 2.0;
      final double frictionDriving = fi * (totalHeight / coreDiameter) * dynamicPressureCoeff * pow(vt - mid, 2);
      final double frictionWallLoss = fw * (totalHeight / pipeDiameterM) * dynamicPressureCoeff * pow(mid, 2);
      final double entranceAndBaseLoss = totalK * dynamicPressureCoeff * pow(mid, 2);
      final double netForce = frictionDriving - frictionWallLoss - entranceAndBaseLoss;

      if (netForce > 0) {
        lo = mid;
      } else {
        hi = mid;
      }
    }

    final double va = (lo + hi) / 2.0;
    final double dynamicHead = dynamicPressureCoeff * va * va;

    // Pressures in mm Water Gauge (mm WG): P / (rho_water * g) * 1000 ≈ P / 9.81
    final double maxAllowableCapacity = getMaxCapacity(p.stackDiameter, p.teeType);
    final double capacityRatio = totalDischargeFlowLps / max(0.1, maxAllowableCapacity);

    // Choking overload surge modeling:
    // When flow exceeds certified capacity (capacityRatio > 1.0), annular flow breaks down,
    // forming piston slugs that compress air ahead of them and create deep vacuum behind them.
    double chokeSurgePositiveMm = 0.0;
    double chokeSuctionNegativeMm = 0.0;

    if (capacityRatio > 1.0) {
      final double excess = capacityRatio - 1.0;
      // Exponential rise in piston slug compression surge at stack base (exceeds +25 mm limit)
      chokeSurgePositiveMm = 28.0 * excess + 42.0 * pow(excess, 1.6).toDouble();
      // Vacuum siphon pull upstream (exceeds -25 mm limit)
      chokeSuctionNegativeMm = -22.0 * excess - 35.0 * pow(excess, 1.6).toDouble();
    }

    final double pTopMm = ((-kin * dynamicHead * dynamicSurge) / g) + chokeSuctionNegativeMm;
    final double pBaseMm = ((kBase * dynamicHead * dynamicSurge) / g) + chokeSurgePositiveMm;

    final List<double> pr = [];
    final List<double> prDyn = [];
    final List<double> sw = [];

    for (int floor = 1; floor <= p.floors; floor++) {
      final double s = (p.floors - floor) / max(1.0, (p.floors - 1).toDouble());
      final double weight = pow(s, 1.6).toDouble();
      final double dynamicComponent = pTopMm + (pBaseMm - pTopMm) * weight;
      final double sewerComponent = p.sewerBackpressure * weight;

      prDyn.add(dynamicComponent);
      sw.add(sewerComponent);
      pr.add(dynamicComponent + sewerComponent);
    }

    double mx = pr.first;
    double mn = pr.first;
    for (final val in pr) {
      if (val > mx) mx = val;
      if (val < mn) mn = val;
    }

    return StaticPhysicsResult(
      pr: pr,
      prDyn: prDyn,
      sw: sw,
      terminalVelocity: vt,
      terminalLength: lt,
      airVelocity: va,
      capacityUtilization: capacityUtilization,
      stackCapacity: qCap,
      maxPositivePressure: mx,
      maxNegativePressure: mn,
      worstPressureMagnitude: max(mx.abs(), mn.abs()),
      filmThicknessMm: filmThicknessMm,
      airCoreDiameterMm: airCoreDiameterMm,
      waterAreaFraction: waterAreaFraction,
      airCoreAreaFraction: airCoreAreaFraction,
      chokeRiskLevel: chokeRiskLevel,
    );
  }

  /// Transient pulse envelope for hydraulic flushes
  static double pulseEnvelope(double phase, String mode) {
    const double riseTime = 0.8;
    const double holdTime = 3.0;
    const double decayTau = 1.2;

    if (phase <= 0) return 0.0;
    if (phase < riseTime) {
      final double s = phase / riseTime;
      return s * s * (3.0 - 2.0 * s);
    }
    if (mode == 'hold' || phase < riseTime + holdTime) {
      return 1.0;
    }
    return exp(-(phase - riseTime - holdTime) / decayTau);
  }

  /// EN 12056-2:2000 & Huliot Engineering Specification Table 12: Hydraulic capacity (Qmax in L/s)
  /// Returns (squareEntryCapacity, sweptEntryCapacity)
  static (double squareCap, double sweptCap) getTable12Capacity(int stackDiameter) {
    if (stackDiameter >= 200) return (16.0, 21.0);
    if (stackDiameter >= 160 || stackDiameter >= 150) return (10.0, 12.4);
    if (stackDiameter >= 125) return (5.8, 7.6);
    if (stackDiameter >= 110 || stackDiameter >= 100) return (4.0, 5.2);
    if (stackDiameter >= 90) return (2.7, 3.5);
    if (stackDiameter >= 80) return (2.0, 2.6);
    if (stackDiameter >= 75) return (1.5, 2.0);
    return (0.7, 0.9); // DN 60
  }

  /// Returns the maximum certified capacity (Qmax in L/s) for a given stack diameter and tee type
  static double getMaxCapacity(int stackDiameter, String teeType) {
    final (sq, sw) = getTable12Capacity(stackDiameter);
    return teeType == 'swept' ? sw : sq;
  }

  /// EN 12056-2:2000 Clause 6.5.3: AAV Air Intake Requirement: Qa >= 8 * Qww
  static double calculateAavRequiredAirFlow(double qWwLps) {
    return 8.0 * qWwLps;
  }
}
