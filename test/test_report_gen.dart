import 'dart:io';
import 'package:huliot_sims/models/simulation_params.dart';
import 'package:huliot_sims/models/simulation_state.dart';
import 'package:huliot_sims/physics/drainage_physics_engine.dart';
import 'package:huliot_sims/services/report_generator_service.dart';

void main() {
  print('Generating test reports...');

  // 35 floor building, 110mm Swept Tee
  final params = SimulationParams.baseline.copyWith(
    floors: 35,
    floorHeight: 3.0,
    stackDiameter: 110,
    teeType: 'swept',
    prlOption: 1,
  );

  final staticRes = DrainagePhysicsEngine.calculateStaticProfile(params);
  final staticResNoPrl = DrainagePhysicsEngine.calculateStaticProfile(params, overridePrlFitted: false);

  final dynamicState = SystemDynamicState(floors: params.floors, initialSeal: params.trapSealDepth.toDouble());

  // Scenario Lab Case A (0s Shock - 11 Floors)
  final caseA = ScenarioCaseMetrics(
    label: 'Case A: 11 Floors Simultaneous Shock (Δt = 0s)',
    selectedFloors: 11,
    timeGapSeconds: 0.0,
    peakInstantFlowLs: 22.0,
    peakNegativePressurePa: -510.0,
    peakPositivePressurePa: 120.0,
    residualTrapSealMm: 0.0,
    stackCapacityLs: 7.2,
    capacityUtilizationPercent: 305.5,
    flowRegime: 'Choked Piston Slug (Full Bore Hydraulic Air Blockage)',
    isPass: false,
    failureReason: 'Catastrophic Overload: 11 floors flushing simultaneously generates 22.0 L/s, exceeding certified stack capacity of 7.2 L/s. Complete air core collapse pulls negative pressure beyond trap water seal retention limit.',
  );

  // Scenario Lab Case B (15s Gap - 11 Floors)
  final caseB = ScenarioCaseMetrics(
    label: 'Case B: 11 Floors Staggered Diversity (Δt = 15s)',
    selectedFloors: 11,
    timeGapSeconds: 15.0,
    peakInstantFlowLs: 2.0,
    peakNegativePressurePa: -125.0,
    peakPositivePressurePa: 55.0,
    residualTrapSealMm: 44.0,
    stackCapacityLs: 7.2,
    capacityUtilizationPercent: 27.8,
    flowRegime: 'Continuous Annular Film with Unrestricted Central Air Core',
    isPass: true,
    failureReason: 'Staggered discharge (Δt = 15s) enables water slugs from preceding floors to clear the stack before subsequent discharges. The central air core remains fully open at all times.',
  );

  final activeFloors = [25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35];

  // 1. Generate Scenario Lab Report
  final scenarioHtml = ReportGeneratorService.generatePrintableHtmlReport(
    params: params,
    result: staticRes,
    resultNoPrl: staticResNoPrl,
    dynamicState: dynamicState,
    verdict: StandardVerdict.pass,
    activeFloors: activeFloors,
    reportType: FlowLabReportType.scenarioLab,
    scenarioCaseA: caseA,
    scenarioCaseB: caseB,
  );

  File('build/web/sample_scenario_report.html').writeAsStringSync(scenarioHtml);
  print('Saved build/web/sample_scenario_report.html (${scenarioHtml.length} bytes)');

  // 2. Generate Standard Compliance Report
  final standardHtml = ReportGeneratorService.generatePrintableHtmlReport(
    params: params,
    result: staticRes,
    resultNoPrl: staticResNoPrl,
    dynamicState: dynamicState,
    verdict: StandardVerdict.pass,
    activeFloors: [10, 11, 12, 13],
    reportType: FlowLabReportType.standardCompliance,
  );

  File('build/web/sample_standard_report.html').writeAsStringSync(standardHtml);
  print('Saved build/web/sample_standard_report.html (${standardHtml.length} bytes)');

  print('Report generation tests completed successfully!');
}
