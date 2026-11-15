import 'dart:math';

class SimulationParams {
  final int floors;
  final double floorHeight;
  final int stackDiameter; // mm (75, 110, 125, 160, 200)
  final int nActive; // Simultaneous discharging floors
  final double flowPerFloor; // L/s
  final int trapSealDepth; // mm (50 or 75)
  final String ventType; // 'open', 'aav', 'blocked'
  final String teeType; // 'swept', 'std'
  final bool prlFitted;
  final int prlDiameter; // mm (75, 110, 125, 160, 200)
  final int prlOption; // 1: System A, 2: System B, 3: System C
  final double surgeFactor;
  final double sewerBackpressure; // mm WG
  final String dischargePattern; // 'mix', 'top', 'bottom', 'spread', 'random'
  final String flushMode; // 'cycle', 'single', 'hold'
  final double simulationSpeed;
  final double kFactor; // EN 12056-2 Table 3 (0.5, 0.7, 1.0, 1.2)
  final String occupancyType; // 'residential', 'hotel', 'public', 'lab'
  final String plumbingSystemType; // 'single_stack' (Table 11: 5.2 L/s default), 'one_pipe' (Table 12: 7.3-8.4 L/s)

  const SimulationParams({
    this.floors = 10,
    this.floorHeight = 3.0,
    this.stackDiameter = 110,
    this.nActive = 4,
    this.flowPerFloor = 1.0,
    this.trapSealDepth = 50,
    this.ventType = 'open',
    this.teeType = 'swept',
    this.prlFitted = true,
    this.prlDiameter = 110,
    this.prlOption = 1,
    this.surgeFactor = 2.5,
    this.sewerBackpressure = 0.0,
    this.dischargePattern = 'mix',
    this.flushMode = 'cycle',
    this.simulationSpeed = 1.0,
    this.kFactor = 0.5,
    this.occupancyType = 'residential',
    this.plumbingSystemType = 'single_stack',
  });

  SimulationParams copyWith({
    int? floors,
    double? floorHeight,
    int? stackDiameter,
    int? nActive,
    double? flowPerFloor,
    int? trapSealDepth,
    String? ventType,
    String? teeType,
    bool? prlFitted,
    int? prlDiameter,
    int? prlOption,
    double? surgeFactor,
    double? sewerBackpressure,
    String? dischargePattern,
    String? flushMode,
    double? simulationSpeed,
    double? kFactor,
    String? occupancyType,
    String? plumbingSystemType,
  }) {
    final int resolvedFloors = floors ?? this.floors;
    // Ensure nActive never exceeds current floors
    final int resolvedActive = min(nActive ?? this.nActive, resolvedFloors);

    return SimulationParams(
      floors: resolvedFloors,
      floorHeight: floorHeight ?? this.floorHeight,
      stackDiameter: stackDiameter ?? this.stackDiameter,
      nActive: max(1, resolvedActive),
      flowPerFloor: flowPerFloor ?? this.flowPerFloor,
      trapSealDepth: trapSealDepth ?? this.trapSealDepth,
      ventType: ventType ?? this.ventType,
      teeType: teeType ?? this.teeType,
      prlFitted: prlFitted ?? this.prlFitted,
      prlDiameter: prlDiameter ?? this.prlDiameter,
      prlOption: prlOption ?? this.prlOption,
      surgeFactor: surgeFactor ?? this.surgeFactor,
      sewerBackpressure: sewerBackpressure ?? this.sewerBackpressure,
      dischargePattern: dischargePattern ?? this.dischargePattern,
      flushMode: flushMode ?? this.flushMode,
      simulationSpeed: simulationSpeed ?? this.simulationSpeed,
      kFactor: kFactor ?? this.kFactor,
      occupancyType: occupancyType ?? this.occupancyType,
      plumbingSystemType: plumbingSystemType ?? this.plumbingSystemType,
    );
  }

  static const SimulationParams baseline = SimulationParams();

  /// Generates presets dynamically so the user's chosen building floors are NEVER overwritten!
  static Map<String, SimulationParams> getPresetsFor(SimulationParams current) {
    return {
      'Current Baseline': current.copyWith(
        stackDiameter: 110,
        trapSealDepth: 50,
        teeType: 'swept',
        prlFitted: true,
        prlDiameter: 110,
        ventType: 'open',
        surgeFactor: 2.5,
        sewerBackpressure: 0,
      ),
      'Well Designed (160mm)': current.copyWith(
        stackDiameter: 160,
        trapSealDepth: 75,
        teeType: 'swept',
        prlFitted: true,
        prlDiameter: 160,
      ),
      'Standard Tee (No Swept)': current.copyWith(
        teeType: 'std',
      ),
      'No PRL (Critical Blowout)': current.copyWith(
        prlFitted: false,
      ),
      'Max Relief PRL (200 mm)': current.copyWith(
        prlDiameter: 200,
        prlFitted: true,
      ),
      'Blocked Vent Failure': current.copyWith(
        ventType: 'blocked',
      ),
      'AAV Only, No PRL': current.copyWith(
        ventType: 'aav',
        prlFitted: false,
      ),
      'Sewer Surcharge (30mm)': current.copyWith(
        sewerBackpressure: 30,
      ),
      'Heavy Peak Discharge': current.copyWith(
        nActive: min(current.floors, max(6, (current.floors * 0.35).round())),
        flowPerFloor: 1.5,
        dischargePattern: 'top',
      ),
    };
  }
}
