import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/fixture_model.dart';
import '../models/simulation_params.dart';
import '../models/simulation_state.dart';
import '../models/simulator_meta.dart';
import '../physics/drainage_physics_engine.dart';
import '../services/report_generator_service.dart';
import '../widgets/visualizer/web_cad_view.dart';

enum TestRunStatus { idle, running, completed }

class SimulatorProvider extends ChangeNotifier {
  SimulatorMeta _currentSimulator = SimulatorRegistry.activeDefault;
  SimulationParams _params = SimulationParams.baseline;
  bool _isDarkMode = true;
  bool _isPlaying = false; // Start in idle/ready state; only runs on explicit test or play!

  // Test Run State Machine (EN 12056 Certified Test Mode)
  TestRunStatus _testStatus = TestRunStatus.idle;
  FlowLabReportType _activeReportType = FlowLabReportType.standardCompliance;
  double _testProgress = 0.0; // 0.0 to 1.0
  double _testDuration = 10.0;
  double _testElapsed = 0.0;
  String _testPhaseText = 'Ready';

  // View mode in visualizer ('full', 'fit', 'prl')
  String _viewMode = 'full';

  // Dynamic simulation timing & state
  double _simTime = 0.0;
  double _flushStartTime = 0.0;
  int _flushCount = 0;
  List<int> _activeFloors = [];
  int _firstActiveFloor = 10;

  // Monte Carlo Morning Rush Simulation State
  bool _isMonteCarloMode = false;
  bool _isMonteCarloRunning = false;
  bool _isMonteCarloCompleted = false;
  double _monteCarloElapsed = 0.0;
  final double _monteCarloDuration = 45.0; // 45 real seconds = 60 mins morning rush
  int _peakConcurrentFlushes = 0;
  int _totalFlushesTriggered = 0;
  final List<double> _concurrencyHistory = [];
  final List<double> _trapHealthHistory = [];
  final Map<int, double> _floorFlushEndTimes = {};

  // Fixture State & Event Logging (Single-Occupancy Principle & Real-Time Audit Log)
  final Map<int, FloorOccupancyState> _floorOccupancyStates = {};
  final List<FixtureEventLog> _chronologicalEventLogs = [];
  DateTime? _lastEventRealTime;

  // Scenario Lab State (Custom Floors, Simultaneous Shock vs Staggered Diversity)
  int _scenarioTargetFloors = 11;
  double _scenarioTimeGapSeconds = 0.0; // 0s = Simultaneous, 15s = Staggered
  String _scenarioExecutionType = 'simultaneous'; // 'simultaneous', 'staggered', 'dual'
  ScenarioCaseMetrics? _scenarioCaseAResult;
  ScenarioCaseMetrics? _scenarioCaseBResult;

  // Static screening results for all 3 systems + no-PRL comparison
  late StaticPhysicsResult _resultSys1;
  late StaticPhysicsResult _resultSys2;
  late StaticPhysicsResult _resultSys3;
  late StaticPhysicsResult _resultNoPrl;

  // Dynamic oscillator states for systems 1, 2, 3
  late Map<int, SystemDynamicState> _systemStates;

  // Particle positions for visualization (0.0 to 1.0 along stack)
  List<double> _waterParticles = [];
  List<double> _airParticles = [];

  bool _isFlushing = false;
  Timer? _flushFeedbackTimer;

  Timer? _tickerTimer;

  SimulatorProvider() {
    try {
      final initialSim = Uri.base.queryParameters['sim'];
      if (initialSim != null) {
        final found = SimulatorRegistry.simulators.cast<SimulatorMeta?>().firstWhere(
              (s) => s?.id == initialSim,
              orElse: () => null,
            );
        if (found != null) {
          _currentSimulator = found;
        }
      }
    } catch (_) {}
    _initSystemStates();
    _recalculateStatic();
    _initParticles();
    _pickActiveFloors();
    _startTicker();
  }

  // Getters
  SimulatorMeta get currentSimulator => _currentSimulator;
  SimulationParams get params => _params;
  bool get isDarkMode => _isDarkMode;
  bool get isPlaying => _isPlaying;
  String get viewMode => _viewMode;
  List<int> get activeFloors => _activeFloors;
  int get flushCount => _flushCount;
  double get simTime => _simTime;
  bool get isFlushing => _isFlushing;

  // Test Run State Getters
  TestRunStatus get testStatus => _testStatus;
  FlowLabReportType get activeReportType => _activeReportType;
  double get testProgress => _testProgress;
  String get testPhaseText => _testPhaseText;
  bool get isTestRunning => _testStatus == TestRunStatus.running;
  bool get isTestCompleted => _testStatus == TestRunStatus.completed;

  StaticPhysicsResult get currentResult {
    return switch (_params.prlOption) {
      2 => _resultSys2,
      3 => _resultSys3,
      _ => _resultSys1,
    };
  }

  StaticPhysicsResult get resultSys1 => _resultSys1;
  StaticPhysicsResult get resultSys2 => _resultSys2;
  StaticPhysicsResult get resultSys3 => _resultSys3;
  StaticPhysicsResult get resultNoPrl => _resultNoPrl;

  SystemDynamicState get currentDynamicState => _systemStates[_params.prlOption]!;
  Map<int, SystemDynamicState> get systemStates => _systemStates;
  List<double> get waterParticles => _waterParticles;
  List<double> get airParticles => _airParticles;

  StandardVerdict get verdict {
    final double qTotal = totalDischargeFlow;
    final double qCap = DrainagePhysicsEngine.getMaxCapacity(
      _params.stackDiameter,
      _params.teeType,
      hasSecondaryVent: isOnePipeSystem,
    );

    // 1. Mandatory Table 12 Hydraulic Capacity Check (EN 12056-2 / Huliot Specifications):
    // If total flow rate exceeds certified stack capacity (e.g. 5.2 L/s for 110mm Swept Tee,
    // 7.2 L/s for 125mm Swept Tee), system is in severe hydraulic overload and MUST FAIL!
    if (qTotal > qCap) {
      return StandardVerdict.fail;
    }

    // 2. Water Trap Seal Integrity Check:
    // Any trap seal dropping below 25 mm violates EN 12056-2 mandatory sewer barrier.
    final double minSeal = currentDynamicState.trapSealRetention.reduce(min);
    if (minSeal < 25.0) {
      return StandardVerdict.fail;
    }

    // 3. Peak Pressure Surge & Suction Limit Check (±25 mm WG limit):
    final double worst = currentResult.worstPressureMagnitude;
    if (worst < 25.0) return StandardVerdict.pass;
    if (worst < 35.0) return StandardVerdict.marginal;
    return StandardVerdict.fail;
  }

  // Real physical hydraulic workload metrics
  double get totalDischargeFlow => min(_params.nActive, _params.floors) * _params.flowPerFloor; // L/s
  double get totalDischargeFlowLpm => totalDischargeFlow * 60.0; // Litres per minute
  double get buildingHeightM => _params.floors * _params.floorHeight; // meters
  double get capacityUtilization => currentResult.capacityUtilization * 100.0; // %
  double get estimatedAirFlowLs => currentResult.airVelocity * (pi * pow((_params.stackDiameter - 6) / 2000.0, 2) * 1000.0); // L/s
  double get terminalVelocity => currentResult.terminalVelocity; // Wyly-Eaton Vt (m/s)
  double get terminalLength => currentResult.terminalLength; // Wyly-Eaton Lt (m)

  // Wyly-Eaton Annular Water Film & Air Core Getters
  double get filmThicknessMm => currentResult.filmThicknessMm;
  double get airCoreDiameterMm => currentResult.airCoreDiameterMm;
  double get waterAreaFraction => currentResult.waterAreaFraction;
  double get airCoreAreaFraction => currentResult.airCoreAreaFraction;
  String get chokeRiskLevel => currentResult.chokeRiskLevel;

  // Monte Carlo Morning Rush Getters
  bool get isMonteCarloMode => _isMonteCarloMode;
  bool get isMonteCarloRunning => _isMonteCarloRunning;
  bool get isMonteCarloCompleted => _isMonteCarloCompleted;
  double get monteCarloProgress => (_monteCarloElapsed / _monteCarloDuration).clamp(0.0, 1.0);

  // Scenario Lab Getters
  int get scenarioTargetFloors => min(_scenarioTargetFloors, _params.floors);
  double get scenarioTimeGapSeconds => _scenarioTimeGapSeconds;
  String get scenarioExecutionType => _scenarioExecutionType;
  ScenarioCaseMetrics? get scenarioCaseAResult => _scenarioCaseAResult;
  ScenarioCaseMetrics? get scenarioCaseBResult => _scenarioCaseBResult;
  int get peakConcurrentFlushes => _peakConcurrentFlushes;
  int get totalFlushesTriggered => _totalFlushesTriggered;
  List<double> get concurrencyHistory => _concurrencyHistory;
  List<double> get trapHealthHistory => _trapHealthHistory;

  String get simulatedClockTime {
    final int totalMinutes = 7 * 60 + 30 + (monteCarloProgress * 60).round();
    final int hr = totalMinutes ~/ 60;
    final int min = totalMinutes % 60;
    final String period = hr >= 12 ? 'PM' : 'AM';
    final int displayHr = hr > 12 ? hr - 12 : hr;
    final String minStr = min < 10 ? '0$min' : '$min';
    return '${displayHr < 10 ? '0$displayHr' : displayHr}:$minStr $period';
  }

  // Fixture & Audit Log Getters
  List<FixtureEventLog> get chronologicalEventLogs => List.unmodifiable(_chronologicalEventLogs);
  Map<int, FloorOccupancyState> get floorOccupancyStates => _floorOccupancyStates;
  double get buildingTotalDU => _params.floors * 3.1;
  double get en12056DesignFlow => _params.kFactor * sqrt(buildingTotalDU);

  // Plumbing System Type: Option 1: "Single Stack System" (Table 11: 5.2 L/s default), Option 2: "One Pipe System" (Table 12: 7.3 L/s)
  bool get isOnePipeSystem => _params.plumbingSystemType == 'one_pipe';
  String get plumbingSystemName => isOnePipeSystem ? 'One Pipe System (Secondary Vent)' : 'Single Stack System (Primary Vent)';
  String get activeTableReference => isOnePipeSystem ? 'Table 12 (One Pipe System)' : 'Table 11 (Single Stack System)';
  String get activeTableClause => isOnePipeSystem ? 'Table 12 (Secondary Ventilated)' : 'Table 11 (Primary Ventilated Single Stack)';

  (double, double) get table12Capacities => DrainagePhysicsEngine.getTable12Capacity(
        _params.stackDiameter,
        hasSecondaryVent: isOnePipeSystem,
      );
  double get table12SquareCapacity => table12Capacities.$1;
  double get table12SweptCapacity => table12Capacities.$2;
  double get activeStackCapacity => _params.teeType == 'swept' ? table12SweptCapacity : table12SquareCapacity;
  double get sweptCapacityHeadroomPercent => ((table12SweptCapacity - table12SquareCapacity) / table12SquareCapacity) * 100.0;
  double get aavRequiredAirFlow => DrainagePhysicsEngine.calculateAavRequiredAirFlow(en12056DesignFlow);

  void setPlumbingSystemType(String type) {
    if (isTestRunning || isMonteCarloRunning) return;
    _params = _params.copyWith(plumbingSystemType: type);
    _recalculateStatic();
    _syncWithCadView();
    notifyListeners();
  }

  void setOccupancyType(String type, double k) {
    if (isTestRunning || isMonteCarloRunning) return;
    _params = _params.copyWith(occupancyType: type, kFactor: k);
    _recalculateStatic();
    _syncWithCadView();
    notifyListeners();
  }

  void _initSystemStates() {
    _systemStates = {
      1: SystemDynamicState(floors: _params.floors, initialSeal: _params.trapSealDepth.toDouble()),
      2: SystemDynamicState(floors: _params.floors, initialSeal: _params.trapSealDepth.toDouble()),
      3: SystemDynamicState(floors: _params.floors, initialSeal: _params.trapSealDepth.toDouble()),
    };
    _floorOccupancyStates.clear();
    for (int f = 1; f <= _params.floors; f++) {
      _floorOccupancyStates[f] = FloorOccupancyState(floor: f);
    }
  }

  void _initParticles() {
    final Random rnd = Random();
    final int waterCount = min(800, max(60, _params.floors * 15));
    _waterParticles = List.generate(waterCount, (_) => rnd.nextDouble());

    final int airCount = min(80, max(14, _params.floors * 3));
    _airParticles = List.generate(airCount, (i) => i / airCount);
  }

  void _recalculateStatic({int? customActive}) {
    final active = customActive ?? (_isMonteCarloMode ? _activeFloors.length : _params.nActive);
    final pEffective = _params.copyWith(nActive: max(1, active));
    _resultSys1 = DrainagePhysicsEngine.calculateStaticProfile(pEffective, overridePrlOption: 1);
    _resultSys2 = DrainagePhysicsEngine.calculateStaticProfile(pEffective, overridePrlOption: 2);
    _resultSys3 = DrainagePhysicsEngine.calculateStaticProfile(pEffective, overridePrlOption: 3);
    _resultNoPrl = DrainagePhysicsEngine.calculateStaticProfile(pEffective, overridePrlFitted: false);
  }

  void _pickActiveFloors() {
    final int n = _params.floors;
    if (_params.nActive >= n || _params.dischargePattern == 'all') {
      _activeFloors = List.generate(n, (i) => i + 1);
      _firstActiveFloor = n;
      _flushStartTime = _simTime;
      _flushCount++;
      _floorOccupancyStates.forEach((_, s) => s.reset());
      final now = DateTime.now();
      for (final f in _activeFloors) {
        _floorOccupancyStates[f]?.triggerFixture(FixtureType.wc, now);
      }
      _logDischargeEventsForActive();
      return;
    }

    final int k = min(_params.nActive, n);
    final Set<int> picked = {};

    switch (_params.dischargePattern) {
      case 'top':
        for (int i = 0; i < k; i++) {
          picked.add(n - i);
        }
        break;
      case 'bottom':
        for (int i = 0; i < k; i++) {
          picked.add(1 + i);
        }
        break;
      case 'spread':
        for (int i = 0; i < k; i++) {
          final int f = max(1, min(n, (1 + (i + 0.5) * (n - 1) / k).round()));
          picked.add(f);
        }
        break;
      case 'random':
        final Random rnd = Random();
        while (picked.length < k) {
          picked.add(1 + rnd.nextInt(n));
        }
        break;
      default: // 'mix'
        if (picked.length < k) picked.add(n);
        if (picked.length < k) picked.add(1);
        final int rem = k - picked.length;
        for (int j = 1; j <= rem; j++) {
          picked.add(max(1, min(n, (1 + j * (n - 1) / (rem + 1)).round())));
        }
        final Random rnd = Random();
        while (picked.length < k) {
          picked.add(1 + rnd.nextInt(n));
        }
        break;
    }

    _activeFloors = picked.toList()..sort();
    _firstActiveFloor = _activeFloors.isNotEmpty ? _activeFloors.last : n;
    _flushStartTime = _simTime;
    _flushCount++;

    // Single-occupancy activation: each active bathroom runs its WC flush
    _floorOccupancyStates.forEach((_, s) => s.reset());
    final now = DateTime.now();
    for (final f in _activeFloors) {
      _floorOccupancyStates[f]?.triggerFixture(FixtureType.wc, now);
    }
    _logDischargeEventsForActive();
  }

  /// Logs realistic fixture discharge events for active floors into chronological ledger
  void _logDischargeEventsForActive({List<int>? floorsToLog}) {
    final targets = floorsToLog ?? _activeFloors;
    if (targets.isEmpty) return;

    final DateTime now = DateTime.now();
    final Random rnd = Random();

    for (int i = 0; i < targets.length; i++) {
      final int floor = targets[i];
      final occ = _floorOccupancyStates[floor];
      if (occ == null) continue;

      // Realistic fixture distribution matching single occupancy:
      // Most flushes are WC (70%), or washbasin (18%), or shower (12%)
      final double r = rnd.nextDouble();
      final FixtureType fixture = r < 0.70
          ? FixtureType.wc
          : (r < 0.88 ? FixtureType.washbasin : FixtureType.shower);

      occ.triggerFixture(fixture, now);
      _totalFlushesTriggered++;

      final double gap = _lastEventRealTime != null
          ? (now.difference(_lastEventRealTime!).inMilliseconds / 1000.0).clamp(0.0, 60.0)
          : (i == 0 ? 0.0 : 1.2 + rnd.nextDouble() * 1.5);
      _lastEventRealTime = now;

      final double instantFlow = targets.length * _params.flowPerFloor;

      double minSeal = _params.trapSealDepth.toDouble();
      for (final s in currentDynamicState.trapSealRetention) {
        if (s < minSeal) minSeal = s;
      }

      _chronologicalEventLogs.add(FixtureEventLog(
        seq: _chronologicalEventLogs.length + 1,
        realTimestamp: now.add(Duration(milliseconds: i * 350)),
        simulatedClock: _isMonteCarloMode ? simulatedClockTime : 'Active Test',
        floor: floor,
        fixtureType: fixture,
        du: fixture.du,
        flowRateLs: fixture.flowRateLs,
        timeGapSeconds: gap,
        instantaneousStackFlowLs: instantFlow,
        peakPositiveSurgeMm: currentDynamicState.peakAllPositive,
        peakSuctionPullMm: currentDynamicState.peakAllNegative,
        minTrapSealMm: minSeal,
      ));

      if (_chronologicalEventLogs.length > 300) {
        _chronologicalEventLogs.removeAt(0);
      }
    }
  }

  void _syncWithCadView() {
    final Map<String, String> activeFixtures = {};
    for (final e in _floorOccupancyStates.entries) {
      if (e.value.isBusy) {
        activeFixtures['${e.key}'] = e.value.activeFixture.shortCode.toLowerCase();
      }
    }

    postMessageToCadView({
      'action': 'syncParams',
      'floors': _params.floors,
      'H': _params.floorHeight,
      'seal': _params.trapSealDepth,
      'nAct': _params.nActive,
      'actFloors': _activeFloors,
      'fixtures': activeFixtures,
      'allFloors': _params.nActive >= _params.floors || _params.dischargePattern == 'all',
      'qf': _params.flowPerFloor,
      'D': _params.stackDiameter,
      'prl': _params.prlFitted,
      'prlD': _params.prlDiameter,
      'tee': _params.teeType,
      'vent': _params.ventType,
      'surge': _params.surgeFactor,
      'sewer': _params.sewerBackpressure,
      'sys': _params.prlOption,
    });
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (_isPlaying) {
        stepSimulation(0.033 * _params.simulationSpeed);
      }
    });
  }

  void stepSimulation(double dt) {
    _simTime += dt;
    final double transitTime = (_params.floors * _params.floorHeight) / max(1.0, _resultSys1.terminalVelocity) * 0.3;

    for (final state in _floorOccupancyStates.values) {
      state.update(dt);
    }

    if (_isMonteCarloMode) {
      if (_isMonteCarloRunning) {
        _monteCarloElapsed += dt;
        if (_monteCarloElapsed >= _monteCarloDuration) {
          _monteCarloElapsed = _monteCarloDuration;
          _isMonteCarloRunning = false;
          _isMonteCarloCompleted = true;
          _isPlaying = false;
          postMessageToCadView({'action': 'pause'});
          notifyListeners();
          return;
        }

        // Peak rush bell-curve intensity factor
        final double rushFrac = (_monteCarloElapsed / _monteCarloDuration).clamp(0.0, 1.0);
        final double intensity = 0.5 + 1.6 * sin(rushFrac * pi);
        // Time compression: 45 real seconds = 3600 simulated seconds (scaled by occupancy K-factor)
        final double pFlushStart = (2.8 / 3600.0) * (3600.0 / _monteCarloDuration) * intensity * (_params.kFactor / 0.5) * dt;
        final Random rnd = Random();

        for (int f = 1; f <= _params.floors; f++) {
          final occ = _floorOccupancyStates[f];
          if (occ != null && !occ.isBusy) {
            if (rnd.nextDouble() < pFlushStart) {
              final double r = rnd.nextDouble();
              final FixtureType fixture = r < 0.60
                  ? FixtureType.wc
                  : (r < 0.85 ? FixtureType.washbasin : FixtureType.shower);

              final DateTime now = DateTime.now();
              occ.triggerFixture(fixture, now);
              _totalFlushesTriggered++;

              final double gap = _lastEventRealTime != null
                  ? (now.difference(_lastEventRealTime!).inMilliseconds / 1000.0)
                  : 0.0;
              _lastEventRealTime = now;

              double instantFlow = 0.0;
              for (final s in _floorOccupancyStates.values) {
                if (s.isBusy) instantFlow += s.activeFixture.flowRateLs;
              }

              double minSeal = _params.trapSealDepth.toDouble();
              for (final s in currentDynamicState.trapSealRetention) {
                if (s < minSeal) minSeal = s;
              }

              _chronologicalEventLogs.add(FixtureEventLog(
                seq: _chronologicalEventLogs.length + 1,
                realTimestamp: now,
                simulatedClock: simulatedClockTime,
                floor: f,
                fixtureType: fixture,
                du: fixture.du,
                flowRateLs: fixture.flowRateLs,
                timeGapSeconds: gap,
                instantaneousStackFlowLs: instantFlow,
                peakPositiveSurgeMm: currentDynamicState.peakAllPositive,
                peakSuctionPullMm: currentDynamicState.peakAllNegative,
                minTrapSealMm: minSeal,
              ));
              if (_chronologicalEventLogs.length > 250) {
                _chronologicalEventLogs.removeAt(0);
              }
            }
          }
        }

        final List<int> activeNow = [];
        for (final entry in _floorOccupancyStates.entries) {
          if (entry.value.isBusy) {
            activeNow.add(entry.key);
          }
        }

        if (activeNow.length != _activeFloors.length || !listEquals(activeNow, _activeFloors)) {
          _activeFloors = activeNow;
          if (_activeFloors.length > _peakConcurrentFlushes) {
            _peakConcurrentFlushes = _activeFloors.length;
          }
          _firstActiveFloor = _activeFloors.isNotEmpty ? _activeFloors.last : _params.floors;
          _recalculateStatic();
          _syncWithCadView();
        }

        if (_simTime % 0.2 < dt) {
          _concurrencyHistory.add(_activeFloors.length.toDouble());
          if (_concurrencyHistory.length > 70) _concurrencyHistory.removeAt(0);

          final avgSeal = currentDynamicState.trapSealRetention.reduce((a, b) => a + b) / _params.floors;
          _trapHealthHistory.add(avgSeal);
          if (_trapHealthHistory.length > 70) _trapHealthHistory.removeAt(0);
        }
      }
    } else {
      final double cyclePeriod = 0.8 + 3.0 + 4 * 1.2 + transitTime + 1.5;

      // Continuous cycle mode (only when NOT in formal test run)
      if (_testStatus != TestRunStatus.running) {
        if (_params.flushMode == 'cycle' && (_simTime - _flushStartTime) > cyclePeriod) {
          _pickActiveFloors();
        }
      } else {
        // Formal Compliance Test Run Mode
        _testElapsed += dt;
        _testProgress = (_testElapsed / max(0.1, _testDuration)).clamp(0.0, 1.0);

        if (_testProgress < 0.25) {
          _testPhaseText = 'Phase 1/4: Fixture Inflow Discharge';
        } else if (_testProgress < 0.60) {
          _testPhaseText = 'Phase 2/4: Annular Film Terminal Fall';
        } else if (_testProgress < 0.85) {
          _testPhaseText = 'Phase 3/4: Base Surge & PRL Relief';
        } else {
          _testPhaseText = 'Phase 4/4: Trap Damping & Stability Check';
        }

        if (_testElapsed >= _testDuration) {
          _testProgress = 1.0;
          _testStatus = TestRunStatus.completed;
          _testPhaseText = 'Test Complete • Data Certified';
          _isPlaying = false; // Auto-pause simulation
          postMessageToCadView({'action': 'pause'});
        }
      }
    }

    final int subSteps = max(1, (dt / 0.02).ceil());
    final double h = dt / subSteps;
    const double w0 = 2.0 * pi * 1.3;
    const double z = 0.22;

    for (final opt in [1, 2, 3]) {
      final SystemDynamicState state = _systemStates[opt]!;
      final StaticPhysicsResult staticRes = switch (opt) {
        2 => _resultSys2,
        3 => _resultSys3,
        _ => _resultSys1,
      };

      double maxFrame = -1e9;
      double minFrame = 1e9;

      for (int i = 0; i < _params.floors; i++) {
        final int floorNum = i + 1;
        final double distDelay = floorNum < _firstActiveFloor
            ? (_firstActiveFloor - floorNum) * _params.floorHeight / max(1.0, staticRes.terminalVelocity) * 0.3
            : 0.0;
        final double pulse = DrainagePhysicsEngine.pulseEnvelope(_simTime - _flushStartTime - distDelay, _params.flushMode);
        final double tgt = staticRes.prDyn[i] * pow(pulse, 1.5) + staticRes.sw[i];
        state.targetPressure[i] = tgt;

        double y = state.trapDisplacement[i];
        double v = state.trapVelocity[i];

        for (int s = 0; s < subSteps; s++) {
          final double acc = w0 * w0 * (tgt - y) - 2.0 * z * w0 * v;
          v += acc * h;
          y += v * h;
        }

        y = max(-120.0, min(120.0, y));
        state.trapDisplacement[i] = y;
        state.trapVelocity[i] = v;

        final double absY = y.abs();
        if (absY > 25.0) {
          state.trapSealRetention[i] = max(0.0, state.trapSealRetention[i] - (absY - 25.0) * 0.1 * dt);
        }

        if (tgt > state.peakPositive[i]) state.peakPositive[i] = tgt;
        if (tgt < state.peakNegative[i]) state.peakNegative[i] = tgt;

        if (tgt > maxFrame) maxFrame = tgt;
        if (tgt < minFrame) minFrame = tgt;
      }

      if (maxFrame > state.peakAllPositive) state.peakAllPositive = maxFrame;
      if (-minFrame > state.peakAllNegative) state.peakAllNegative = -minFrame;

      state.pressureHistory.add(Point(maxFrame, minFrame));
      if (state.pressureHistory.length > 250) {
        state.pressureHistory.removeAt(0);
      }
    }

    final double flowRate = 1.0 / max(1.5, transitTime * 0.9);
    for (int i = 0; i < _waterParticles.length; i++) {
      _waterParticles[i] = (_waterParticles[i] + dt * flowRate * (0.8 + 0.4 * ((i * 7) % 5) / 5.0)) % 1.0;
    }
    for (int i = 0; i < _airParticles.length; i++) {
      _airParticles[i] = (_airParticles[i] + dt * 0.28) % 1.0;
    }

    notifyListeners();
  }

  // Actions
  void updateParams(SimulationParams newParams) {
    if (isTestRunning || isMonteCarloRunning) return;
    final bool floorsChanged = newParams.floors != _params.floors;
    final bool sealChanged = newParams.trapSealDepth != _params.trapSealDepth;
    final bool activeChanged = newParams.nActive != _params.nActive;
    final bool stackChanged = newParams.stackDiameter != _params.stackDiameter;
    final bool prlChanged = newParams.prlFitted != _params.prlFitted ||
        newParams.prlDiameter != _params.prlDiameter ||
        newParams.prlOption != _params.prlOption;
    final bool fittingChanged = newParams.teeType != _params.teeType ||
        newParams.ventType != _params.ventType;

    SimulationParams effective = newParams;
    if (floorsChanged && _activeReportType == FlowLabReportType.standardCompliance) {
      final double qww = effective.kFactor * sqrt(effective.floors * 3.1);
      final int enActive = max(1, min(effective.floors, (qww / 1.0).round()));
      effective = effective.copyWith(nActive: enActive, flowPerFloor: 1.0, dischargePattern: 'mix');
    }

    _params = effective;

    if (floorsChanged || sealChanged || stackChanged || prlChanged || fittingChanged) {
      _initSystemStates();
      _initParticles();
      _pickActiveFloors();
    } else if (activeChanged) {
      _pickActiveFloors();
    }

    _recalculateStatic();
    _syncWithCadView();
    notifyListeners();
  }

  void selectPreset(String presetName) {
    if (isTestRunning || isMonteCarloRunning) return;
    final Map<String, SimulationParams> presets = SimulationParams.getPresetsFor(_params);
    final SimulationParams? preset = presets[presetName];
    if (preset != null) {
      updateParams(preset);
    }
  }

  void _triggerFlushFeedback() {
    _isFlushing = true;
    _flushFeedbackTimer?.cancel();
    _flushFeedbackTimer = Timer(const Duration(milliseconds: 3600), () {
      _isFlushing = false;
      notifyListeners();
    });
  }

  void triggerFlush({int? singleFloor}) {
    _activeReportType = FlowLabReportType.standardCompliance;
    if (singleFloor != null) {
      _activeFloors = [singleFloor];
      _firstActiveFloor = singleFloor;
      _params = _params.copyWith(nActive: 1, flowPerFloor: 1.8);
      _floorOccupancyStates.forEach((_, s) => s.reset());
      _floorOccupancyStates[singleFloor]?.triggerFixture(FixtureType.wc, DateTime.now());
      _logDischargeEventsForActive(floorsToLog: [singleFloor]);
    } else {
      if (_params.flowPerFloor >= 2.5 || _params.dischargePattern == 'all') {
        final double qww = _params.kFactor * sqrt(_params.floors * 3.1);
        final int enActive = max(1, min(_params.floors, (qww / 1.0).round()));
        _params = _params.copyWith(flowPerFloor: 1.0, dischargePattern: 'mix', nActive: enActive);
      }
      // If user has manually selected floors via toggleFloor, preserve their exact selection!
      if (_activeFloors.isEmpty) {
        _pickActiveFloors();
      } else {
        _params = _params.copyWith(nActive: _activeFloors.length);
        _floorOccupancyStates.forEach((_, s) => s.reset());
        final now = DateTime.now();
        for (final f in _activeFloors) {
          _floorOccupancyStates[f]?.triggerFixture(FixtureType.wc, now);
        }
        _logDischargeEventsForActive();
      }
    }
    _recalculateStatic();
    _syncWithCadView();
    _flushStartTime = _simTime;
    _flushCount++;
    _isPlaying = true;

    // Start 10-second standard compliance test cycle
    _testElapsed = 0.0;
    _testProgress = 0.0;
    _testDuration = 10.0;
    _testStatus = TestRunStatus.running;
    _testPhaseText = 'EN 12056 Standard Test Running (${_activeFloors.length} Floors)';

    _triggerFlushFeedback();

    postMessageToCadView({
      'action': 'flush',
      'singleFloor': singleFloor,
      'actFloors': _activeFloors,
      'nAct': _activeFloors.length,
      'qf': _params.flowPerFloor,
    });

    notifyListeners();
  }

  void triggerFlushAll() {
    final int n = _params.floors;
    // Full Equipment Load Test:
    // ALL fixtures in each bathroom (WC 2.0 DU + Washbasin 0.5 DU + Floor Trap 0.6 DU = 3.1 DU, flow = 2.9 L/s)
    // are flushed simultaneously across all floors to stress-test the stack against its maximum capacity limit!
    const double fullEquipmentFlowPerBathroom = 2.9; // L/s
    _activeReportType = FlowLabReportType.scenarioLab;
    _params = _params.copyWith(nActive: n, dischargePattern: 'all', flowPerFloor: fullEquipmentFlowPerBathroom);
    _activeFloors = List.generate(n, (i) => i + 1);
    _firstActiveFloor = n;
    _floorOccupancyStates.forEach((_, s) => s.reset());
    final now = DateTime.now();
    for (final f in _activeFloors) {
      _floorOccupancyStates[f]?.triggerFixture(FixtureType.wc, now);
    }
    _logDischargeEventsForActive();
    _recalculateStatic();
    _syncWithCadView();
    _flushStartTime = _simTime;
    _flushCount++;
    _isPlaying = true;

    // Start 10-second formal test cycle for Flush All so user sees clear completion
    _testElapsed = 0.0;
    _testProgress = 0.0;
    _testDuration = 10.0;
    _testStatus = TestRunStatus.running;
    _testPhaseText = 'Overload Stress Test Running (All Floors)';

    _triggerFlushFeedback();

    postMessageToCadView({
      'action': 'flushAll',
      'floors': n,
      'actFloors': _activeFloors,
      'qf': fullEquipmentFlowPerBathroom,
      'hold': true,
    });

    notifyListeners();
  }

  /// Toggles a specific floor into or out of the active flushing floor set
  void toggleFloor(int floorNum) {
    if (isTestRunning || isMonteCarloRunning) return;
    if (floorNum < 1 || floorNum > _params.floors) return;
    final List<int> updated = List<int>.from(_activeFloors);
    final bool wasActive = updated.contains(floorNum);
    if (wasActive) {
      if (updated.length > 1) {
        updated.remove(floorNum);
        _floorOccupancyStates[floorNum]?.reset();
      }
    } else {
      updated.add(floorNum);
      _floorOccupancyStates[floorNum]?.triggerFixture(FixtureType.wc, DateTime.now());
    }
    updated.sort();
    _activeFloors = updated;
    _firstActiveFloor = _activeFloors.isNotEmpty ? _activeFloors.last : _params.floors;
    _params = _params.copyWith(nActive: _activeFloors.length);

    if (!wasActive) {
      _logDischargeEventsForActive(floorsToLog: [floorNum]);
    }
    _recalculateStatic();
    _syncWithCadView();
    _flushStartTime = _simTime;
    _flushCount++;
    _isPlaying = true;
    _triggerFlushFeedback();

    postMessageToCadView({
      'action': 'flush',
      'actFloors': _activeFloors,
      'nAct': _activeFloors.length,
    });

    notifyListeners();
  }

  /// Directly isolates and flushes a single floor exclusively
  void setSingleFloorActive(int floorNum) {
    if (isTestRunning || isMonteCarloRunning) return;
    if (floorNum < 1 || floorNum > _params.floors) return;
    _activeFloors = [floorNum];
    _firstActiveFloor = floorNum;
    _params = _params.copyWith(nActive: 1);
    _floorOccupancyStates.forEach((_, s) => s.reset());
    _floorOccupancyStates[floorNum]?.triggerFixture(FixtureType.wc, DateTime.now());
    _logDischargeEventsForActive(floorsToLog: [floorNum]);
    _recalculateStatic();
    _syncWithCadView();
    _flushStartTime = _simTime;
    _flushCount++;
    _isPlaying = true;
    _triggerFlushFeedback();

    postMessageToCadView({
      'action': 'flush',
      'singleFloor': floorNum,
      'actFloors': _activeFloors,
      'nAct': 1,
    });

    notifyListeners();
  }

  void startOfficialTest() {
    // 1. Certified EN 12056 Standard Compliance Test initialization
    _activeReportType = FlowLabReportType.standardCompliance;
    _isMonteCarloMode = false;
    _isMonteCarloRunning = false;

    // 2. Compute certified simultaneous design flow: Qww = K * sqrt(floors * 3.1)
    final double qww = _params.kFactor * sqrt(_params.floors * 3.1);
    final int enActive = max(1, min(_params.floors, (qww / 1.0).round()));
    _params = _params.copyWith(
      nActive: enActive,
      flowPerFloor: 1.0,
      dischargePattern: 'mix',
    );

    // 3. Pristine baseline: reinitialize states, refill traps to initial depth & clear peaks
    _initSystemStates();
    resetTraps();
    clearPeaks();
    _recalculateStatic();

    // 4. Physical duration based on stack transit and wave damping
    final double transitTime = (_params.floors * _params.floorHeight) / max(1.0, currentResult.terminalVelocity) * 0.3;
    _testDuration = 0.8 + 3.0 + 4 * 1.2 + transitTime + 2.5;
    _testElapsed = 0.0;
    _testProgress = 0.0;
    _testPhaseText = 'Phase 1/4: Fixture Inflow Discharge';
    _testStatus = TestRunStatus.running;
    _isPlaying = true;

    // 5. Initiate flush of active floors
    _pickActiveFloors();
    _flushStartTime = _simTime;
    _flushCount++;

    postMessageToCadView({
      'action': 'flush',
      'actFloors': _activeFloors,
      'nAct': _activeFloors.length,
      'qf': _params.flowPerFloor,
    });
    _syncWithCadView();

    notifyListeners();
  }

  void resetTestState() {
    abortTest();
  }

  /// Cancels any active test run and immediately unlocks parameters
  void abortTest() {
    _testStatus = TestRunStatus.idle;
    _testProgress = 0.0;
    _testElapsed = 0.0;
    _testPhaseText = 'Ready';
    _isPlaying = false;
    _isMonteCarloRunning = false;
    _monteCarloElapsed = 0.0;
    postMessageToCadView({'action': 'pause'});
    notifyListeners();
  }

  void toggleMonteCarloMode(bool enabled) {
    _isMonteCarloMode = enabled;
    _isMonteCarloRunning = false;
    _isMonteCarloCompleted = false;
    _monteCarloElapsed = 0.0;
    _peakConcurrentFlushes = 0;
    _totalFlushesTriggered = 0;
    _concurrencyHistory.clear();
    _trapHealthHistory.clear();
    _floorFlushEndTimes.clear();
    _chronologicalEventLogs.clear();
    _lastEventRealTime = null;
    _floorOccupancyStates.forEach((_, s) => s.reset());
    if (!enabled) {
      _pickActiveFloors();
      _recalculateStatic();
      _syncWithCadView();
    }
    notifyListeners();
  }

  void setScenarioTargetFloors(int count) {
    if (isTestRunning || isMonteCarloRunning) return;
    _scenarioTargetFloors = count.clamp(1, _params.floors);
    if (_activeReportType == FlowLabReportType.scenarioLab) {
      _applyScenarioConfiguration();
    }
    notifyListeners();
  }

  void setScenarioTimeGap(double gap) {
    if (isTestRunning || isMonteCarloRunning) return;
    _scenarioTimeGapSeconds = gap;
    if (_activeReportType == FlowLabReportType.scenarioLab) {
      _applyScenarioConfiguration();
    }
    notifyListeners();
  }

  void setScenarioExecutionType(String type) {
    if (isTestRunning || isMonteCarloRunning) return;
    _scenarioExecutionType = type;
    if (type == 'simultaneous') {
      _scenarioTimeGapSeconds = 0.0;
    } else if (type == 'staggered') {
      _scenarioTimeGapSeconds = 15.0;
    }
    if (_activeReportType == FlowLabReportType.scenarioLab) {
      _applyScenarioConfiguration();
    }
    notifyListeners();
  }

  ScenarioCaseMetrics calculateScenarioMetrics({required int targetFloors, required double gapSeconds}) {
    final double qCap = DrainagePhysicsEngine.getMaxCapacity(
      _params.stackDiameter,
      _params.teeType,
      hasSecondaryVent: isOnePipeSystem,
    );
    final bool isSimultaneous = gapSeconds <= 2.0;

    if (isSimultaneous) {
      // All target floors discharging simultaneously (e.g. 11 floors * 2.0 L/s = 22.0 L/s)
      final double instantFlow = targetFloors * 2.0;
      final double utilization = (instantFlow / qCap) * 100.0;
      final bool isPass = instantFlow <= qCap;
      final double overRatio = (instantFlow / qCap).clamp(1.0, 5.0);
      final double negPa = isPass ? -120.0 : -(180.0 + overRatio * 110.0).clamp(200.0, 750.0);
      final double posPa = isPass ? 45.0 : (60.0 + overRatio * 50.0).clamp(70.0, 350.0);
      final double residualSeal = isPass
          ? max(45.0, _params.trapSealDepth - 10.0)
          : max(0.0, _params.trapSealDepth - (overRatio * 22.0)).clamp(0.0, _params.trapSealDepth.toDouble());
      final String regime = isPass
          ? 'Smooth Annular Film'
          : 'Choked Piston Slug (Full Bore Hydraulic Air Blockage)';
      final String reason = isPass
          ? 'Instant discharge flow ($instantFlow L/s) is within EN 12056 $activeTableReference certified capacity ($qCap L/s).'
          : 'Catastrophic Overload: $targetFloors floors flushing simultaneously generates $instantFlow L/s, exceeding certified $activeTableReference capacity of $qCap L/s. Complete air core collapse pulls negative pressure beyond trap water seal retention limit.';

      return ScenarioCaseMetrics(
        label: 'Case A: $targetFloors Floors Simultaneous Shock (Δt = 0s)',
        selectedFloors: targetFloors,
        timeGapSeconds: 0.0,
        peakInstantFlowLs: instantFlow,
        peakNegativePressurePa: negPa,
        peakPositivePressurePa: posPa,
        residualTrapSealMm: residualSeal,
        stackCapacityLs: qCap,
        capacityUtilizationPercent: utilization,
        flowRegime: regime,
        isPass: isPass,
        failureReason: reason,
      );
    } else {
      // Staggered sequential flush with time gap (e.g. 15s gap)
      // Since individual WC flush duration is ~5 seconds, with a 15s interval only 1 floor is flowing at any instant!
      const double singleFixtureFlow = 2.0;
      final double instantFlow = singleFixtureFlow;
      final double utilization = (instantFlow / qCap) * 100.0;
      const bool isPass = true;
      const double negPa = -125.0; // Comfortably below -250 Pa (25mm WG) limit
      const double posPa = 55.0;
      final double residualSeal = max(45.0, _params.trapSealDepth - 6.0);
      const String regime = 'Continuous Annular Film with Unrestricted Central Air Core';
      final String reason = 'Staggered discharge (Δt = ${gapSeconds.toInt()}s) enables water slugs from preceding floors to clear the stack before subsequent discharges. The central air core remains fully open at all times.';

      return ScenarioCaseMetrics(
        label: 'Case B: $targetFloors Floors Staggered Diversity (Δt = ${gapSeconds.toInt()}s)',
        selectedFloors: targetFloors,
        timeGapSeconds: gapSeconds,
        peakInstantFlowLs: instantFlow,
        peakNegativePressurePa: negPa,
        peakPositivePressurePa: posPa,
        residualTrapSealMm: residualSeal,
        stackCapacityLs: qCap,
        capacityUtilizationPercent: utilization,
        flowRegime: regime,
        isPass: isPass,
        failureReason: reason,
      );
    }
  }

  static List<int> computeDistributedFloors(int totalFloors, int count) {
    final int k = count.clamp(1, totalFloors);
    if (k >= totalFloors) {
      return List.generate(totalFloors, (i) => totalFloors - i);
    }
    final double step = (totalFloors - 1) / (k - 1 > 0 ? k - 1 : 1);
    final Set<int> picked = {};
    for (int i = 0; i < k; i++) {
      int f = (totalFloors - (i * step).round()).clamp(1, totalFloors);
      while (picked.contains(f) && f > 1) {
        f--;
      }
      while (picked.contains(f) && f < totalFloors) {
        f++;
      }
      picked.add(f);
    }
    final res = picked.toList()..sort((a, b) => b.compareTo(a));
    return res;
  }

  void _applyScenarioConfiguration() {
    final int k = min(_scenarioTargetFloors, _params.floors);
    final List<int> picked = computeDistributedFloors(_params.floors, k);
    _activeFloors = picked;
    _firstActiveFloor = picked.isNotEmpty ? picked.first : _params.floors;

    final bool isSimultaneous = _scenarioTimeGapSeconds <= 2.0;
    final double flowPerF = isSimultaneous ? 2.0 : 2.0;
    final int nAct = isSimultaneous ? k : 1;

    _params = _params.copyWith(
      nActive: nAct,
      flowPerFloor: flowPerF,
      dischargePattern: isSimultaneous ? 'all' : 'top',
    );

    _floorOccupancyStates.forEach((_, s) => s.reset());
    final now = DateTime.now();
    for (final f in _activeFloors) {
      _floorOccupancyStates[f]?.triggerFixture(FixtureType.wc, now);
    }
    _logDischargeEventsForActive();
    _recalculateStatic();
    _syncWithCadView();
  }

  void runScenarioStudy({String? overrideType}) {
    final typeToRun = overrideType ?? _scenarioExecutionType;
    _activeReportType = FlowLabReportType.scenarioLab;
    _isMonteCarloMode = false;
    _isMonteCarloRunning = false;

    // Precalculate both Case A and Case B for comparative study reporting
    _scenarioCaseAResult = calculateScenarioMetrics(targetFloors: scenarioTargetFloors, gapSeconds: 0.0);
    _scenarioCaseBResult = calculateScenarioMetrics(targetFloors: scenarioTargetFloors, gapSeconds: 15.0);

    _applyScenarioConfiguration();

    _testDuration = 8.0;
    _testElapsed = 0.0;
    _testProgress = 0.0;
    _testStatus = TestRunStatus.running;
    _testPhaseText = typeToRun == 'staggered'
        ? 'Scenario Lab: 15s Staggered Diversity Study Running'
        : (typeToRun == 'dual'
            ? 'Scenario Lab: Dual Comparative Shock vs Diversity Study Running'
            : 'Scenario Lab: 0s Simultaneous Shock Study Running');
    _isPlaying = true;
    _flushStartTime = _simTime;
    _flushCount++;

    _triggerFlushFeedback();

    postMessageToCadView({
      'action': 'flush',
      'actFloors': _activeFloors,
      'nAct': _activeFloors.length,
      'qf': _params.flowPerFloor,
    });

    notifyListeners();
  }

  void setTestingMode(FlowLabReportType type) {
    if (isTestRunning || isMonteCarloRunning) return;
    _activeReportType = type;
    if (type == FlowLabReportType.morningRushAudit) {
      _isMonteCarloMode = true;
      _syncWithCadView();
      postMessageToCadView({'action': 'toggleMorningRush', 'enabled': true});
    } else if (type == FlowLabReportType.scenarioLab) {
      _isMonteCarloMode = false;
      _applyScenarioConfiguration();
      postMessageToCadView({'action': 'toggleMorningRush', 'enabled': false});
      postMessageToCadView({'action': 'setParams', 'params': {'pattern': 'all', 'nAct': _activeFloors.length, 'qf': 2.0}});
    } else {
      _isMonteCarloMode = false;
      final n = _params.floors;
      final double qww = _params.kFactor * sqrt(n * 3.1);
      final int defaultActive = max(1, min(n, (qww / 1.0).round()));
      _params = _params.copyWith(nActive: defaultActive, dischargePattern: 'mix', flowPerFloor: 1.0);
      _initSystemStates();
      resetTraps();
      clearPeaks();
      _pickActiveFloors();
      _recalculateStatic();
      _syncWithCadView();
      postMessageToCadView({'action': 'toggleMorningRush', 'enabled': false});
      postMessageToCadView({'action': 'setParams', 'params': {'pattern': 'mix', 'nAct': defaultActive, 'qf': 1.0}});
    }
    notifyListeners();
  }

  void startMonteCarloRush() {
    _isMonteCarloMode = true;
    _isMonteCarloRunning = true;
    _isMonteCarloCompleted = false;
    _activeReportType = FlowLabReportType.morningRushAudit;
    _monteCarloElapsed = 0.0;
    _peakConcurrentFlushes = 0;
    _totalFlushesTriggered = 0;
    _concurrencyHistory.clear();
    _trapHealthHistory.clear();
    _floorFlushEndTimes.clear();
    _chronologicalEventLogs.clear();
    _lastEventRealTime = null;
    _floorOccupancyStates.forEach((_, s) => s.reset());
    _isPlaying = true;
    resetTraps();
    clearPeaks();
    postMessageToCadView({'action': 'play'});
    notifyListeners();
  }

  void pauseMonteCarloRush() {
    _isMonteCarloRunning = false;
    postMessageToCadView({'action': 'pause'});
    notifyListeners();
  }

  void resumeMonteCarloRush() {
    _isMonteCarloRunning = true;
    _isPlaying = true;
    postMessageToCadView({'action': 'play'});
    notifyListeners();
  }

  void resumeContinuousPlay() {
    _testStatus = TestRunStatus.idle;
    _testProgress = 0.0;
    _testPhaseText = 'Ready';
    _isPlaying = true;
    postMessageToCadView({'action': 'play'});
    notifyListeners();
  }

  void downloadPdfReport() {
    if (_isMonteCarloMode) {
      downloadMonteCarloReport();
    } else {
      if (_activeReportType == FlowLabReportType.scenarioLab && (_scenarioCaseAResult == null || _scenarioCaseBResult == null)) {
        _scenarioCaseAResult = calculateScenarioMetrics(targetFloors: scenarioTargetFloors, gapSeconds: 0.0);
        _scenarioCaseBResult = calculateScenarioMetrics(targetFloors: scenarioTargetFloors, gapSeconds: 15.0);
      }
      ReportGeneratorService.downloadHtmlReport(
        params: _params,
        result: currentResult,
        resultNoPrl: _resultNoPrl,
        dynamicState: currentDynamicState,
        verdict: verdict,
        activeFloors: _activeFloors,
        reportType: _activeReportType,
        eventLogs: _chronologicalEventLogs,
        scenarioCaseA: _scenarioCaseAResult,
        scenarioCaseB: _scenarioCaseBResult,
      );
    }
  }

  void downloadMonteCarloReport() {
    ReportGeneratorService.downloadHtmlReport(
      params: _params,
      result: currentResult,
      resultNoPrl: _resultNoPrl,
      dynamicState: currentDynamicState,
      verdict: verdict,
      activeFloors: _activeFloors,
      reportType: FlowLabReportType.morningRushAudit,
      peakConcurrent: _peakConcurrentFlushes > 0 ? _peakConcurrentFlushes : _params.nActive,
      totalRushFlushes: _totalFlushesTriggered > 0 ? _totalFlushesTriggered : (_params.nActive * 6),
      eventLogs: _chronologicalEventLogs,
    );
  }

  void openPrintableMonteCarloReport() {
    ReportGeneratorService.openPrintableReport(
      params: _params,
      result: currentResult,
      resultNoPrl: _resultNoPrl,
      dynamicState: currentDynamicState,
      verdict: verdict,
      activeFloors: _activeFloors,
      reportType: FlowLabReportType.morningRushAudit,
      peakConcurrent: _peakConcurrentFlushes > 0 ? _peakConcurrentFlushes : _params.nActive,
      totalRushFlushes: _totalFlushesTriggered > 0 ? _totalFlushesTriggered : (_params.nActive * 6),
      eventLogs: _chronologicalEventLogs,
    );
  }

  void openPrintableReport() {
    if (_isMonteCarloMode) {
      openPrintableMonteCarloReport();
    } else {
      if (_activeReportType == FlowLabReportType.scenarioLab && (_scenarioCaseAResult == null || _scenarioCaseBResult == null)) {
        _scenarioCaseAResult = calculateScenarioMetrics(targetFloors: scenarioTargetFloors, gapSeconds: 0.0);
        _scenarioCaseBResult = calculateScenarioMetrics(targetFloors: scenarioTargetFloors, gapSeconds: 15.0);
      }
      ReportGeneratorService.openPrintableReport(
        params: _params,
        result: currentResult,
        resultNoPrl: _resultNoPrl,
        dynamicState: currentDynamicState,
        verdict: verdict,
        activeFloors: _activeFloors,
        reportType: _activeReportType,
        eventLogs: _chronologicalEventLogs,
        scenarioCaseA: _scenarioCaseAResult,
        scenarioCaseB: _scenarioCaseBResult,
      );
    }
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void resetTraps() {
    for (final state in _systemStates.values) {
      state.resetTraps(_params.trapSealDepth.toDouble());
    }
    postMessageToCadView({'action': 'refill'});
    notifyListeners();
  }

  void clearPeaks() {
    for (final state in _systemStates.values) {
      state.clearPeaks();
    }
    postMessageToCadView({'action': 'clearPeaks'});
    notifyListeners();
  }

  void setPrlOption(int option) {
    if (isTestRunning || isMonteCarloRunning) return;
    if (option >= 1 && option <= 3) {
      _params = _params.copyWith(prlOption: option);
      _syncWithCadView();
      notifyListeners();
    }
  }

  void setViewMode(String mode) {
    _viewMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void selectSimulator(String id) {
    final SimulatorMeta? found = SimulatorRegistry.simulators.cast<SimulatorMeta?>().firstWhere(
          (s) => s?.id == id,
          orElse: () => null,
        );
    if (found != null) {
      _currentSimulator = found;
      notifyListeners();
    }
  }

  String generateCsv() {
    final SystemDynamicState state = currentDynamicState;
    final StringBuffer sb = StringBuffer();
    sb.writeln('Floor,Peak_Positive_mmWG,Peak_Negative_mmWG,Residual_Trap_Seal_mm');
    for (int i = 0; i < _params.floors; i++) {
      sb.writeln('${i + 1},${state.peakPositive[i].toStringAsFixed(2)},${state.peakNegative[i].toStringAsFixed(2)},${state.trapSealRetention[i].toStringAsFixed(2)}');
    }
    return sb.toString();
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }
}
