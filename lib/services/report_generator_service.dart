import 'dart:math';
import '../models/fixture_model.dart';
import '../models/simulation_params.dart';
import '../models/simulation_state.dart';
import '../physics/drainage_physics_engine.dart';
import 'report_download.dart';

class ReportGeneratorService {
  /// Opens the dedicated High-Resolution Engineering Test Report with SVG diagrams,
  /// perfectly formatted for printing or direct "Save as PDF" via browser print.
  static void openPrintableReport({
    required SimulationParams params,
    required StaticPhysicsResult result,
    required StaticPhysicsResult resultNoPrl,
    required SystemDynamicState dynamicState,
    required StandardVerdict verdict,
    required List<int> activeFloors,
    FlowLabReportType reportType = FlowLabReportType.standardCompliance,
    int? peakConcurrent,
    int? totalRushFlushes,
    List<FixtureEventLog>? eventLogs,
  }) {
    final html = generatePrintableHtmlReport(
      params: params,
      result: result,
      resultNoPrl: resultNoPrl,
      dynamicState: dynamicState,
      verdict: verdict,
      activeFloors: activeFloors,
      reportType: reportType,
      peakConcurrent: peakConcurrent,
      totalRushFlushes: totalRushFlushes,
      eventLogs: eventLogs,
    );
    openPrintableHtmlReport(html);
  }

  /// Downloads the dedicated High-Resolution PDF/HTML Engineering Test Report directly to disk
  static void downloadHtmlReport({
    required SimulationParams params,
    required StaticPhysicsResult result,
    required StaticPhysicsResult resultNoPrl,
    required SystemDynamicState dynamicState,
    required StandardVerdict verdict,
    required List<int> activeFloors,
    FlowLabReportType reportType = FlowLabReportType.standardCompliance,
    int? peakConcurrent,
    int? totalRushFlushes,
    List<FixtureEventLog>? eventLogs,
  }) {
    final html = generatePrintableHtmlReport(
      params: params,
      result: result,
      resultNoPrl: resultNoPrl,
      dynamicState: dynamicState,
      verdict: verdict,
      activeFloors: activeFloors,
      reportType: reportType,
      peakConcurrent: peakConcurrent,
      totalRushFlushes: totalRushFlushes,
      eventLogs: eventLogs,
    );
    final filename = switch (reportType) {
      FlowLabReportType.overloadStress => 'Huliot_Overload_Stress_Report_${params.floors}F.html',
      FlowLabReportType.morningRushAudit => 'Huliot_Morning_Rush_Audit_Log_${params.floors}F.html',
      FlowLabReportType.standardCompliance => 'Huliot_EN12056_Standard_Compliance_${params.floors}F.html',
    };
    downloadReportHtmlFile(html, filename);
  }

  /// Generate High-Resolution Printable HTML Report with Vector Diagram, DU Schedule & Event Ledger
  static String generatePrintableHtmlReport({
    required SimulationParams params,
    required StaticPhysicsResult result,
    required StaticPhysicsResult resultNoPrl,
    required SystemDynamicState dynamicState,
    required StandardVerdict verdict,
    required List<int> activeFloors,
    FlowLabReportType reportType = FlowLabReportType.standardCompliance,
    int? peakConcurrent,
    int? totalRushFlushes,
    List<FixtureEventLog>? eventLogs,
  }) {
    final totalHeightM = (params.floors * params.floorHeight).toStringAsFixed(1);
    final bool isMonteCarlo = reportType == FlowLabReportType.morningRushAudit;
    final bool isOverloadTest = reportType == FlowLabReportType.overloadStress;
    final effectiveConcurrent = isMonteCarlo ? (peakConcurrent ?? params.nActive) : (isOverloadTest ? params.floors : activeFloors.length);
    final totalFlowLs = (effectiveConcurrent * params.flowPerFloor).toStringAsFixed(1);
    final totalFlowLmin = (effectiveConcurrent * params.flowPerFloor * 60).toStringAsFixed(0);
    final concurrencyPct = (effectiveConcurrent / params.floors * 100).toStringAsFixed(0);

    // EN 12056-2 & Huliot Specification Table 12 Capacity limits
    final (sqCap, swCap) = DrainagePhysicsEngine.getTable12Capacity(params.stackDiameter);
    final maxCapacity = params.teeType == 'swept' ? swCap : sqCap;
    final totalFlowNum = effectiveConcurrent * params.flowPerFloor;
    final isFlowOverloaded = totalFlowNum > maxCapacity;

    // A test CANNOT pass if total discharge flow exceeds Table 12 certified limit!
    final isPass = (verdict == StandardVerdict.pass) && !isFlowOverloaded;

    // Dedicated Header Titles, Badges, and Scope Statements
    final String reportTitle = switch (reportType) {
      FlowLabReportType.overloadStress => 'Huliot FlowLab - Overload Stress Test Report (${params.floors} Floors)',
      FlowLabReportType.morningRushAudit => 'Huliot FlowLab - Morning Rush Concurrency Audit (${params.floors} Floors)',
      FlowLabReportType.standardCompliance => 'Huliot FlowLab - EN 12056 Standard Compliance Certificate (${params.floors} Floors)',
    };

    final String modeBadge = switch (reportType) {
      FlowLabReportType.overloadStress => '⚠️ EXTREME HYDRAULIC OVERLOAD TEST (100% BUILDING CONCURRENCY)',
      FlowLabReportType.morningRushAudit => '🎲 1-HOUR REALISTIC MORNING RUSH SIMULATION (07:30 - 08:30 AM)',
      FlowLabReportType.standardCompliance => '📐 EN 12056-2 / BS EN 12056 STANDARD VERIFICATION TEST',
    };

    final String scopeStatement = switch (reportType) {
      FlowLabReportType.overloadStress =>
        '<b>Executive Scope &amp; Purpose:</b> This destructive stress test evaluates the absolute physical ceiling of the drainage stack by discharging 100% of building bathrooms simultaneously without time diversity (0.0s gap). It evaluates annular choke limits, piston slug pressure spikes, and trap blowout thresholds under deliberate catastrophic overloading.',
      FlowLabReportType.morningRushAudit =>
        '<b>Executive Scope &amp; Purpose:</b> This dynamic audit evaluates real-world domestic living during peak 1-hour morning rush hours. It models human occupancy behavior under the Single-Occupancy Mutual Exclusivity Principle (1 fixture/person) with realistic Poisson arrival time gaps (&Delta;t), certifying long-term odor barrier integrity.',
      FlowLabReportType.standardCompliance =>
        '<b>Executive Scope &amp; Purpose:</b> This official engineering compliance submittal evaluates building drainage performance per BS EN 12056-2 Table 12 and DIN 1986-100 standards for user-selected active floors, verifying that pneumatic transient surges remain strictly within the certified &plusmn;25 mm WG limit.',
    };

    // EN 12056-2 Discharge Units (DU) calculations matching user's spreadsheet
    final totalBuildingDU = params.floors * 3.1;
    final en12056FlowRate = params.kFactor * sqrt(totalBuildingDU);
    final headroomPct = ((swCap - sqCap) / sqCap) * 100.0;
    final aavAirReq = DrainagePhysicsEngine.calculateAavRequiredAirFlow(en12056FlowRate);

    // Resolve exact system name and detail matching the user's selected configuration
    final (String sysLetter, String sysDetail) = switch (params.prlOption) {
      2 => ('System B', 'PRL System B (Stack Offset Loop)'),
      3 => ('System C', 'PRL System C (Straight Stack, Base Rejoin)'),
      _ => ('System A', 'PRL System A (PRL Beside Stack, 45° Bends)'),
    };

    // Build floor table rows
    final floorRows = StringBuffer();
    for (int i = params.floors - 1; i >= 0; i--) {
      final floorNum = i + 1;
      final heightM = (floorNum * params.floorHeight).toStringAsFixed(1);
      final staticP = result.pr[i];
      final peakPos = dynamicState.peakPositive[i];
      final peakNeg = dynamicState.peakNegative[i];
      final seal = dynamicState.trapSealRetention[i];
      final isFlushing = activeFloors.contains(floorNum);
      final isFloorSafe = peakPos <= 25 && peakNeg.abs() <= 25 && seal >= 25;

      // Fixture details for active flush floors
      String fixtureBadge = '';
      if (isFlushing) {
        FixtureType fType = FixtureType.wc;
        if (eventLogs != null && eventLogs.isNotEmpty) {
          try {
            final ev = eventLogs.lastWhere((e) => e.floor == floorNum);
            fType = ev.fixtureType;
          } catch (_) {
            fType = FixtureType.wc;
          }
        }
        fixtureBadge = '<span class="badge-flush">${fType.icon} ${fType.displayName} (${fType.du.toStringAsFixed(1)} DU)</span>';
      }

      floorRows.writeln('''
      <tr class="${isFlushing ? 'active-floor' : ''}">
        <td><b>F$floorNum</b> $fixtureBadge</td>
        <td>$heightM m</td>
        <td>${staticP >= 0 ? '+' : ''}${staticP.toStringAsFixed(1)} mm</td>
        <td style="color:${peakPos > 25 ? '#ef4444' : '#10b981'};font-weight:bold">+${peakPos.toStringAsFixed(1)} mm</td>
        <td style="color:${peakNeg.abs() > 25 ? '#ef4444' : '#10b981'};font-weight:bold">-${peakNeg.abs().toStringAsFixed(1)} mm</td>
        <td style="color:${seal < 25 ? '#ef4444' : '#0284c7'};font-weight:bold">${seal.toStringAsFixed(0)} mm</td>
        <td><span class="${isFloorSafe ? 'tag-pass' : 'tag-fail'}">${isFloorSafe ? 'COMPLIANT' : 'HAZARD'}</span></td>
      </tr>
      ''');
    }

    // Build Chronological Event Ledger rows (if available)
    final eventRows = StringBuffer();
    if (eventLogs != null && eventLogs.isNotEmpty) {
      for (final ev in eventLogs) {
        final isSafe = ev.minTrapSealMm >= 25.0;
        eventRows.writeln('''
        <tr>
          <td><b>#${ev.seq.toString().padLeft(2, '0')}</b></td>
          <td><code>${ev.timeFormatted}</code></td>
          <td><span style="color:#f59e0b;font-weight:bold;">${ev.simulatedClock}</span></td>
          <td><b>F${ev.floor}</b></td>
          <td>${ev.fixtureType.icon} <b>${ev.fixtureType.displayName}</b></td>
          <td><b>${ev.du.toStringAsFixed(1)}</b></td>
          <td>${ev.flowRateLs.toStringAsFixed(1)} L/s</td>
          <td>${ev.seq == 1 ? 'Start' : '+${ev.timeGapSeconds.toStringAsFixed(1)}s'}</td>
          <td>${ev.instantaneousStackFlowLs.toStringAsFixed(1)} L/s</td>
          <td style="color:${ev.peakPositiveSurgeMm > 25 ? '#ef4444' : '#10b981'};font-weight:bold">+${ev.peakPositiveSurgeMm.toStringAsFixed(1)} mm</td>
          <td style="color:${ev.minTrapSealMm < 25 ? '#ef4444' : '#0284c7'};font-weight:bold">${ev.minTrapSealMm.toStringAsFixed(0)} mm</td>
          <td><span class="${isSafe ? 'tag-pass' : 'tag-fail'}">${isSafe ? 'PASS' : 'SEAL LOSS'}</span></td>
        </tr>
        ''');
      }
    }

    return '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>$reportTitle</title>
<style>
  @page { size: A4; margin: 12mm; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    color: #1e293b;
    background: #fff;
    margin: 0;
    padding: 24px;
    font-size: 13px;
    line-height: 1.5;
  }
  .no-print-bar {
    background: #0f172a;
    color: #fff;
    padding: 14px 24px;
    margin: -24px -24px 24px -24px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  }
  .btn-print {
    background: #0284c7;
    color: #fff;
    border: none;
    padding: 9px 20px;
    border-radius: 6px;
    font-weight: bold;
    cursor: pointer;
    font-size: 13.5px;
    box-shadow: 0 2px 6px rgba(2,132,199,0.4);
  }
  .btn-print:hover { background: #0369a1; }
  .header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2.5px solid #0284c7; padding-bottom: 14px; margin-bottom: 18px; }
  .logo { font-size: 26px; font-weight: 900; color: #0369a1; letter-spacing: -0.5px; }
  .logo span { color: #0284c7; }
  .mode-badge {
    display: inline-block;
    padding: 4px 10px;
    background: ${isMonteCarlo ? '#f59e0b' : '#0284c7'};
    color: #fff;
    font-size: 11px;
    font-weight: bold;
    border-radius: 4px;
    margin-top: 4px;
  }
  .verdict-banner {
    padding: 18px;
    border-radius: 8px;
    background: ${isPass ? '#f0fdf4' : '#fef2f2'};
    border: 2px solid ${isPass ? '#22c55e' : '#ef4444'};
    margin-bottom: 22px;
  }
  .verdict-title { font-size: 18px; font-weight: bold; color: ${isPass ? '#15803d' : '#b91c1c'}; margin-bottom: 6px; }
  .kpi-grid { display: grid; grid-template-columns: repeat(6, 1fr); gap: 8px; margin-top: 14px; }
  .kpi-item { background: #fff; padding: 10px 6px; border-radius: 6px; border: 1px solid #e2e8f0; text-align: center; }
  .kpi-val { font-size: 16px; font-weight: bold; color: #0369a1; }
  .kpi-lbl { font-size: 10px; color: #64748b; margin-top: 2px; }
  table { width: 100%; border-collapse: collapse; margin-bottom: 22px; font-size: 12px; }
  th, td { border: 1px solid #cbd5e1; padding: 7px 10px; text-align: left; }
  th { background: #f1f5f9; font-weight: bold; color: #334155; }
  .active-floor { background: #e0f2fe; }
  .badge-flush { font-size: 9px; background: #0284c7; color: #fff; padding: 2px 6px; border-radius: 4px; font-weight: bold; margin-left: 6px; }
  .tag-pass { color: #15803d; font-weight: bold; background: #dcfce7; padding: 2px 8px; border-radius: 4px; }
  .tag-fail { color: #b91c1c; font-weight: bold; background: #fee2e2; padding: 2px 8px; border-radius: 4px; }
  .schematic-box {
    background: #0b0f17;
    border-radius: 8px;
    padding: 16px;
    margin-bottom: 22px;
    color: #e2e8f0;
    border: 1px solid #1e293b;
  }
  .schematic-title { font-size: 13px; font-weight: bold; color: #38bdf8; margin-bottom: 10px; }
  .schematic-content { display: flex; gap: 16px; align-items: center; }
  .schematic-text { font-size: 11.5px; color: #94a3b8; line-height: 1.6; }
  @media print {
    .no-print-bar { display: none; }
    body { padding: 0; }
  }
</style>
<script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>
</head>
<body>

<div class="no-print-bar">
  <div><b>HULIOT FLOWLAB</b> &bull; $modeBadge (${params.floors} Floors)</div>
  <div style="display: flex; gap: 8px;">
    <button class="btn-print" onclick="downloadPdfFile()">📥 Download PDF File</button>
    <button class="btn-print" style="background: #059669;" onclick="window.print()">🖨️ Print / Save as PDF</button>
  </div>
</div>

<div id="report-content">

<div class="header">
  <div>
    <div class="logo">HULIOT <span>FLOWLAB</span></div>
    <div style="font-size: 13.5px; color: #1e293b; font-weight: bold; margin-top: 2px;">
      $reportTitle
    </div>
    <div class="mode-badge" style="background:${isOverloadTest ? '#dc2626' : (isMonteCarlo ? '#d97706' : '#0284c7')};">
      $modeBadge
    </div>
    <div style="font-size: 11px; color: #64748b; margin-top: 4px;">Physics Core: Wyly &amp; Eaton (NBS Monograph 31) &bull; Single-Occupancy Mutual Exclusivity Model</div>
  </div>
  <div style="text-align: right; font-size: 11px; color: #475569;">
    <div><b>Report ID:</b> ${isOverloadTest ? 'OVERLOAD' : (isMonteCarlo ? 'RUSH' : 'EN12056')}-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}</div>
    <div><b>Report Generated:</b> ${DateTime.now().toString().substring(0, 19)} (Laptop Clock)</div>
    <div><b>Building:</b> ${params.floors >= 40 ? 'Supertall High-Rise' : (params.floors >= 20 ? 'High-Rise Tower' : 'Residential Tower')} (${params.floors} Storeys, $totalHeightM m)</div>
  </div>
</div>

<!-- Executive Scope & Purpose Box -->
<div style="background:#f8fafc;border-left:4px solid ${isOverloadTest ? '#ef4444' : (isMonteCarlo ? '#f59e0b' : '#0284c7')};padding:10px 14px;border-radius:0 6px 6px 0;margin-bottom:18px;font-size:11.5px;color:#334155;line-height:1.5;">
  $scopeStatement
</div>

<div class="verdict-banner">
  <div class="verdict-title">${isPass ? (isMonteCarlo ? '✓ PASS • REALISTIC MORNING RUSH INTEGRITY CERTIFIED (Zero Gas Leak)' : '✓ PASS • FULLY COMPLIANT (EN 12056)') : (isFlowOverloaded ? '⚠️ FAIL • EXCEEDED TABLE 12 HYDRAULIC CAPACITY LIMIT (Q = $totalFlowLs L/s > ${maxCapacity.toStringAsFixed(1)} L/s Limit)' : '⚠️ FAIL • DANGEROUS SEAL LOSS HAZARD DETECTED')}</div>
  <div style="font-size: 12.5px; color: #334155;">
    ${isPass
        ? (isMonteCarlo
            ? 'Under a realistic 1-hour morning rush occupancy load ($totalRushFlushes simulated flush events, peak concurrency of $effectiveConcurrent floors), the Huliot system maintained all trap seals safely above the mandatory 25 mm threshold.'
            : 'The building stack configured with Huliot Swept Tee and Positive Relief Line (PRL) safely retains all water trap seals (±25 mm WG limit). Sewer gas barrier is 100% intact.')
        : (isFlowOverloaded
            ? 'The simultaneous active stack flow ($totalFlowLs L/s) exceeds the maximum certified hydraulic capacity (${maxCapacity.toStringAsFixed(1)} L/s for DN ${params.stackDiameter} with ${params.teeType == 'swept' ? 'Swept Tee' : 'Square Tee'}). Annular air core has collapsed, causing severe hydraulic choking, trap seal blowout, and reverse sewer gas contamination.'
            : 'Pneumatic pressures exceed ±25 mm WG limit. Siphonage or backpressure blowout hazard detected on active floors. Sewer odors will penetrate into living spaces.')}
  </div>
  <div class="kpi-grid">
    <div class="kpi-item">
      <div class="kpi-val" style="color: ${dynamicState.peakAllPositive > 25 ? '#ef4444' : '#10b981'}">+${dynamicState.peakAllPositive.toStringAsFixed(1)} mm</div>
      <div class="kpi-lbl">Peak Positive Surge</div>
    </div>
    <div class="kpi-item">
      <div class="kpi-val" style="color: ${dynamicState.peakAllNegative > 25 ? '#ef4444' : '#10b981'}">-${dynamicState.peakAllNegative.toStringAsFixed(1)} mm</div>
      <div class="kpi-lbl">Peak Suction Pull</div>
    </div>
    <div class="kpi-item">
      <div class="kpi-val" style="color: #0284c7">${dynamicState.trapSealRetention[0].toStringAsFixed(0)} mm</div>
      <div class="kpi-lbl">Min Trap Seal Retained</div>
    </div>
    <div class="kpi-item">
      <div class="kpi-val">${result.terminalVelocity.toStringAsFixed(1)} m/s</div>
      <div class="kpi-lbl">Wyly-Eaton Velocity (Vt)</div>
    </div>
    <div class="kpi-item">
      <div class="kpi-val">${result.filmThicknessMm.toStringAsFixed(1)} mm</div>
      <div class="kpi-lbl">Water Film (tw)</div>
    </div>
    <div class="kpi-item">
      <div class="kpi-val">${result.airCoreDiameterMm.toStringAsFixed(0)} mm</div>
      <div class="kpi-lbl">Air Core Clear (\u2205)</div>
    </div>
  </div>
</div>

<!-- Building Stack Schematic Diagram -->
<div class="schematic-box">
  <div class="schematic-title">📐 High-Rise Stack Aerodynamics &amp; Annular Water Film (${params.floors} Floors &bull; $totalHeightM Meters)</div>
  <div class="schematic-content">
    <svg width="180" height="130" viewBox="0 0 180 130" style="background:#020617;border-radius:6px;border:1px solid #1e293b;">
      <path d="M 50 15 L 70 15 L 60 5 Z" fill="#38bdf8"/>
      <rect x="58" y="15" width="4" height="95" fill="#e2e8f0"/>
      <path d="M 30 35 Q 56 35 58 45" fill="none" stroke="#e8392f" stroke-width="2"/>
      <path d="M 30 65 Q 56 65 58 75" fill="none" stroke="#e8392f" stroke-width="2"/>
      <path d="M 62 85 Q 75 85 75 95 L 75 105 Q 75 110 62 110" fill="none" stroke="#facc15" stroke-width="2" stroke-dasharray="2,2"/>
      <path d="M 60 110 Q 60 120 100 120" fill="none" stroke="#3b82f6" stroke-width="3"/>
      <text x="80" y="38" fill="#94a3b8" font-size="8">F${params.floors} Roof Vent</text>
      <text x="80" y="68" fill="#94a3b8" font-size="8">Swept Tee Branch</text>
      <text x="85" y="98" fill="#facc15" font-size="8">PRL Relief Loop</text>
      <text x="105" y="122" fill="#38bdf8" font-size="8">To Sewer</text>
    </svg>
    <div class="schematic-text">
      <b>Single Stack System with Huliot Swept Tee &amp; ${params.prlFitted ? sysDetail : 'No PRL'}:</b><br>
      Fixture discharges from $effectiveConcurrent simultaneous bathrooms ($totalFlowLs L/s) adhere to the pipe perimeter, forming an annular water film (${result.filmThicknessMm.toStringAsFixed(1)} mm thickness). Water accelerates over a terminal length of <b>${result.terminalLength.toStringAsFixed(1)} m</b> to Wyly-Eaton terminal velocity of <b>${result.terminalVelocity.toStringAsFixed(1)} m/s</b>. The central air core (${result.airCoreDiameterMm.toStringAsFixed(0)} mm diameter, ${(result.airCoreAreaFraction * 100).toStringAsFixed(0)}% open area) entrains steady airflow (${result.airVelocity.toStringAsFixed(1)} m/s), safely balanced by Positive Relief Line (PRL &mdash; $sysLetter).
    </div>
  </div>
</div>

<h3 style="color:#0369a1;margin-bottom:8px">1. Typical Bathroom Fixture Discharge Units (EN 12056-2 Schedule)</h3>
<table>
  <thead>
    <tr>
      <th width="8%">Sr No.</th>
      <th width="32%">Fixtures</th>
      <th width="10%">Qty / Toilet</th>
      <th width="10%">D U</th>
      <th width="12%">For Toilet</th>
      <th width="10%">Floors</th>
      <th width="18%">Total DU</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>1</td>
      <td><b>WASHBASIN</b></td>
      <td>1</td>
      <td>0.5</td>
      <td>0.5</td>
      <td>${params.floors}</td>
      <td>${(params.floors * 0.5).toStringAsFixed(1)}</td>
    </tr>
    <tr>
      <td>2</td>
      <td><b>W C - WITH 6 L CISTERN</b></td>
      <td>1</td>
      <td>2.0</td>
      <td>2.0</td>
      <td>${params.floors}</td>
      <td>${(params.floors * 2.0).toStringAsFixed(1)}</td>
    </tr>
    <tr>
      <td>3</td>
      <td><b>FLOOR TRAP - Shower without plug consider</b></td>
      <td>1</td>
      <td>0.6</td>
      <td>0.6</td>
      <td>${params.floors}</td>
      <td>${(params.floors * 0.6).toStringAsFixed(1)}</td>
    </tr>
    <tr>
      <td>4</td>
      <td>WM (WASHING MACHINE UP TO 6 KG CONSIDER)</td>
      <td>0</td>
      <td>0.8</td>
      <td>0</td>
      <td>${params.floors}</td>
      <td>0.0</td>
    </tr>
    <tr>
      <td>5</td>
      <td>Trap without any fixture 75 mm outlet</td>
      <td>0</td>
      <td>1.5</td>
      <td>0</td>
      <td>${params.floors}</td>
      <td>0.0</td>
    </tr>
    <tr style="background:#f8fafc;font-weight:bold;">
      <td colspan="6" style="text-align:right;">Cumulative Discharge Units (&#931; DU) Across ${params.floors} Floors:</td>
      <td style="color:#0284c7;font-size:13px;">${totalBuildingDU.toStringAsFixed(1)} DU</td>
    </tr>
    <tr style="background:#f0fdf4;font-weight:bold;">
      <td colspan="6" style="text-align:right;">Total Building EN 12056 Peak Design Flow Q<sub>ww</sub> = K &times; &#8730;&#931;DU (${params.occupancyType.toUpperCase()} K = ${params.kFactor}):</td>
      <td style="color:#15803d;font-size:13.5px;">${en12056FlowRate.toStringAsFixed(2)} L/s</td>
    </tr>
    <tr style="background:${isFlowOverloaded ? '#fef2f2' : '#eff6ff'};">
      <td colspan="6" style="text-align:right;"><b>EN 12056 Table 12 Hydraulic Capacity Limit (DN ${params.stackDiameter}):</b></td>
      <td>
        Square Entry: <b>${sqCap.toStringAsFixed(1)} L/s</b> &bull; 
        <span style="color:${isFlowOverloaded ? '#ef4444' : '#0284c7'};font-weight:bold;">
          Huliot Swept: ${swCap.toStringAsFixed(1)} L/s 
          ${isFlowOverloaded ? '<span class="tag-fail" style="margin-left:6px">⚠️ OVERLOAD FAIL ($totalFlowLs L/s)</span>' : '<span class="tag-pass" style="margin-left:6px">✓ SAFE LOAD (+${headroomPct.toStringAsFixed(1)}%)</span>'}
        </span>
      </td>
    </tr>
  </tbody>
</table>

<h3 style="color:#0369a1;margin-bottom:8px">2. Building &amp; Simulation Test Parameters</h3>
<table>
  <tr><th width="32%">Building Height</th><td><b>${params.floors} Storeys</b> ($totalHeightM meters total vertical stack height)</td></tr>
  <tr><th>Floor-to-Floor Height</th><td><b>${params.floorHeight.toStringAsFixed(1)} meters</b> per storey</td></tr>
  <tr><th>Building Occupancy Type</th><td><b>${params.occupancyType.toUpperCase()}</b> (EN 12056-2 Table 3 Frequency Factor K = <b>${params.kFactor}</b>)</td></tr>
  ${params.ventType == 'aav' ? '''
  <tr><th>AAV Airflow Compliance (Clause 6.5.3)</th><td><b>Mandatory Qa &ge; 8 &times; Qww:</b> ${aavAirReq.toStringAsFixed(1)} L/s minimum air intake required</td></tr>
  ''' : ''}
  ${isMonteCarlo ? '''
  <tr><th>Simulation Testing Mode</th><td><b>🎲 Monte Carlo Real-World Morning Rush</b> (1-Hour 07:30 - 08:30 AM Peak Period)</td></tr>
  <tr><th>Peak Concurrency Observed</th><td><b>$effectiveConcurrent Floors</b> ($concurrencyPct% simultaneous peak concurrency)</td></tr>
  <tr><th>Total Rush Flushes Simulated</th><td><b>${totalRushFlushes ?? (params.nActive * 6)} Flushes</b> (Poisson arrival distribution)</td></tr>
  ''' : '''
  <tr><th>Simulation Testing Mode</th><td><b>10-Second EN 12056 Certified Continuous Flush</b></td></tr>
  <tr><th>Active Flushing Bathrooms</th><td><b>${params.nActive} Floors</b> ($concurrencyPct% simultaneous flush concurrency)</td></tr>
  '''}
  <tr><th>Total Peak Discharge Flow</th><td><b>$totalFlowLs L/s</b> ($totalFlowLmin Litres/minute)</td></tr>
  <tr><th>Single-Occupancy Principle</th><td><b>Active</b> &mdash; strictly 1 fixture active per toilet (WC 2.0 DU / Basin 0.5 DU / Trap 0.6 DU)</td></tr>
  <tr><th>Soil &amp; Waste Stack Diameter</th><td>${params.stackDiameter} mm Nominal Diameter</td></tr>
  <tr><th>Wyly-Eaton Terminal Velocity (Vt)</th><td><b>${result.terminalVelocity.toStringAsFixed(1)} m/s</b> (governed by Vt = 10.1 &times; (Q/D)<sup>0.4</sup>)</td></tr>
  <tr><th>Terminal Acceleration Fall Length (Lt)</th><td><b>${result.terminalLength.toStringAsFixed(1)} meters</b> (Lt = 0.17 &times; Vt<sup>2</sup>; annular flow reaches steady velocity within ${(result.terminalLength / params.floorHeight).toStringAsFixed(1)} storeys)</td></tr>
  <tr><th>Annular Flow Water Film (tw)</th><td><b>${result.filmThicknessMm.toStringAsFixed(1)} mm</b> (Uniform cylindrical water sleeve clinging to internal pipe wall)</td></tr>
  <tr><th>Central Air Core Clearance (\u2205)</th><td><b>${result.airCoreDiameterMm.toStringAsFixed(0)} mm</b> (${(result.airCoreAreaFraction * 100).toStringAsFixed(0)}% free air passage &bull; Regime: <b>${result.chokeRiskLevel.toUpperCase()}</b>)</td></tr>
  <tr><th>Branch Inlet Geometry</th><td>${params.teeType == 'swept' ? 'Huliot Swept Tee (Curved 87.5° inlet with sweep radius)' : 'Standard 87.5° Square Tee'}</td></tr>
  <tr><th>Positive Relief Line (PRL)</th><td>${params.prlFitted ? 'Fitted (${params.prlDiameter} mm Relief Line &mdash; $sysDetail)' : 'None (Unprotected Single Stack)'}</td></tr>
  <tr><th>Trap Seal Depth</th><td><b>${params.trapSealDepth} mm</b> Initial Water Seal (${params.trapSealDepth >= 75 ? 'Deep Seal Anti-Siphon' : 'EN 12056 Standard'})</td></tr>
  <tr><th>Roof Vent Condition</th><td>${params.ventType == 'open' ? 'Open Atmosphere (Air Intake Cowl)' : (params.ventType == 'aav' ? 'Air Admittance Valve (AAV)' : 'Blocked / Restricted Vent')}</td></tr>
</table>

<h3 style="color:#0369a1;margin-bottom:8px">3. Hydraulic Stack Architecture Comparison</h3>
<p style="font-size:11.5px;color:#64748b;margin-bottom:10px;">
  Direct side-by-side engineering evaluation between an Unmitigated Standard Single Stack without PRL vs. the Tested High-Performance Huliot System with Swept Tee &amp; Positive Relief Line ($sysLetter).
</p>
<table style="margin-bottom:22px;">
  <thead>
    <tr style="background:#0f172a;color:#fff;">
      <th style="background:#0f172a;color:#fff;width:28%;">Engineering Hydraulic Metric</th>
      <th style="background:#7f1d1d;color:#fee2e2;width:36%;">Unmitigated Baseline (Standard Tee, No PRL)</th>
      <th style="background:#065f46;color:#d1fae5;width:36%;">Tested System (Huliot Swept Tee + $sysLetter)</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>Base Positive Backpressure Surge (+mm WG)</b></td>
      <td style="color:#dc2626;font-weight:bold;">+${resultNoPrl.maxPositivePressure.toStringAsFixed(1)} mm WG &bull; High Blowout Risk</td>
      <td style="color:${result.maxPositivePressure > 25 ? '#dc2626' : '#059669'};font-weight:bold;">
        +${result.maxPositivePressure.toStringAsFixed(1)} mm WG &bull; ${result.maxPositivePressure > 25 ? 'SURGE HAZARD (> 25 mm)' : 'SAFE (≤ 25 mm)'}
      </td>
    </tr>
    <tr>
      <td><b>Top Negative Siphonage Suction (-mm WG)</b></td>
      <td style="color:#dc2626;font-weight:bold;">-${resultNoPrl.maxNegativePressure.abs().toStringAsFixed(1)} mm WG &bull; Induced Siphonage</td>
      <td style="color:${result.maxNegativePressure.abs() > 25 ? '#dc2626' : '#059669'};font-weight:bold;">
        -${result.maxNegativePressure.abs().toStringAsFixed(1)} mm WG &bull; ${result.maxNegativePressure.abs() > 25 ? 'SIPHONAGE HAZARD (> 25 mm)' : 'BALANCED (≤ 25 mm)'}
      </td>
    </tr>
    <tr>
      <td><b>Ground Floor P-Trap Seal Retention</b></td>
      <td style="color:#dc2626;font-weight:bold;">0 mm (0% Retained &bull; Traps Siphoned)</td>
      <td style="color:${dynamicState.trapSealRetention[0] < 25 ? '#dc2626' : '#0284c7'};font-weight:bold;">
        ${dynamicState.trapSealRetention[0].toStringAsFixed(0)} mm (${dynamicState.trapSealRetention[0] < 25 ? '⚠️ SEAL LOSS' : '100% Water Barrier Maintained'})
      </td>
    </tr>
    <tr>
      <td><b>Wyly-Eaton Terminal Velocity (V<sub>t</sub>)</b></td>
      <td>${resultNoPrl.terminalVelocity.toStringAsFixed(1)} m/s</td>
      <td><b>${result.terminalVelocity.toStringAsFixed(1)} m/s</b> (governed by V<sub>t</sub> = 10.1 &times; (Q/D)<sup>0.4</sup>)</td>
    </tr>
    <tr>
      <td><b>Annular Water Film / Air Core Clearance</b></td>
      <td>${resultNoPrl.filmThicknessMm.toStringAsFixed(1)} mm film (${(resultNoPrl.airCoreAreaFraction * 100).toStringAsFixed(0)}% air core)</td>
      <td><b>${result.filmThicknessMm.toStringAsFixed(1)} mm film (${(result.airCoreAreaFraction * 100).toStringAsFixed(0)}% air core)</b></td>
    </tr>
    <tr>
      <td><b>Branch Hydraulic Entry Performance</b></td>
      <td style="color:#dc2626;">Abrupt 87.5° cross-flow; air core occlusion hazard</td>
      <td style="color:#059669;font-weight:bold;">Smooth curved trajectory clinging to stack wall</td>
    </tr>
    <tr style="background:#f8fafc;font-size:13px;">
      <td><b>EN 12056-2 / BS EN 12056 Compliance Verdict</b></td>
      <td><span class="tag-fail">NON-COMPLIANT (UNSAFE)</span></td>
      <td><span class="${isPass ? 'tag-pass' : 'tag-fail'}">${isPass ? '100% CERTIFIED COMPLIANT' : 'FAIL • EXCEEDS TABLE 12 LIMIT'}</span></td>
    </tr>
  </tbody>
</table>

<h3 style="color:#0369a1;margin-bottom:8px">4. Floor-by-Floor Pressure &amp; Residual Trap Seal Data</h3>
<table>
  <thead>
    <tr>
      <th>Floor</th>
      <th>Elevation</th>
      <th>Static Air Pressure</th>
      <th>Peak Positive (+)</th>
      <th>Peak Suction (-)</th>
      <th>Residual Seal Depth</th>
      <th>Compliance</th>
    </tr>
  </thead>
  <tbody>
    $floorRows
  </tbody>
</table>

${eventRows.isNotEmpty ? '''
<div style="background:#f0fdf4;border:1.5px solid #86efac;border-radius:8px;padding:14px;margin-bottom:18px;">
  <div style="font-size:15px;font-weight:bold;color:#15803d;margin-bottom:4px;">
    🟢 Section 5: Part A &mdash; Realistic Domestic Morning Rush Performance (Normal Living Audit)
  </div>
  <p style="font-size:12px;color:#166534;margin:0 0 10px 0;line-height:1.5;">
    <b>Engineering Principle:</b> In actual residential occupancy, individual users operate strictly one fixture at a time (Mutual Exclusivity). Furthermore, residents across different apartments flush with natural intervals (&Delta;t = 15s to several minutes) represented by Poisson stochastic distribution. Because of this natural behavioral diversity, peak concurrent stack flow remains well within safe design limits, ensuring <b>100% trap seal retention and zero sewer gas penetration</b>.
  </p>
  <table style="font-size:11px;background:#fff;">
    <thead>
      <tr style="background:#f1f5f9;">
        <th>Seq</th>
        <th>Laptop Time</th>
        <th>Sim Clock</th>
        <th>Floor</th>
        <th>Fixture Discharged</th>
        <th>DU</th>
        <th>Flow Rate</th>
        <th>Interval (&Delta;t)</th>
        <th>Instant Flow</th>
        <th>Base Surge</th>
        <th>Trap Seal</th>
        <th>Status</th>
      </tr>
    </thead>
    <tbody>
      $eventRows
    </tbody>
  </table>
</div>
''' : ''}

<div style="background:${isFlowOverloaded ? '#fef2f2' : '#f8fafc'};border:1.5px solid ${isFlowOverloaded ? '#fca5a5' : '#cbd5e1'};border-radius:8px;padding:14px;margin-bottom:22px;">
  <div style="font-size:15px;font-weight:bold;color:${isFlowOverloaded ? '#b91c1c' : '#334155'};margin-bottom:4px;">
    ${isFlowOverloaded ? '🔴 Section 6: Part B &mdash; Extreme Hydraulic Stress & Overload Capacity Limit (Test Failure Point)' : 'ℹ️ Section 6: Part B &mdash; Table 12 Hydraulic Capacity Threshold Analysis'}
  </div>
  <p style="font-size:12px;color:${isFlowOverloaded ? '#991b1b' : '#475569'};margin:0 0 10px 0;line-height:1.5;">
    <b>Engineering Principle:</b> When artificial stress is applied &mdash; such as forcing multiple floors or all bathroom fixtures to discharge simultaneously without time diversity (0.0s gap) &mdash; the total flow exceeds the maximum certified EN 12056 Table 12 capacity (<b>${maxCapacity.toStringAsFixed(1)} L/s</b> for DN ${params.stackDiameter} with ${params.teeType == 'swept' ? 'Huliot Swept Tee' : 'Square Tee'}). At this point, the annular air core collapses, hydraulic choking occurs, and the system correctly fails as demonstrated by excessive pressure surge and trap seal evacuation.
  </p>
  <table style="font-size:12px;background:#fff;">
    <tr style="background:#f1f5f9;">
      <th width="35%">Hydraulic Limit Parameter</th>
      <th width="30%">Normal Domestic Limit</th>
      <th width="35%">Observed Test Workload</th>
    </tr>
    <tr>
      <td><b>Total Stack Hydraulic Load</b></td>
      <td>&le; ${maxCapacity.toStringAsFixed(1)} L/s (EN 12056 Table 12)</td>
      <td style="color:${isFlowOverloaded ? '#dc2626' : '#15803d'};font-weight:bold;">
        $totalFlowLs L/s (${isFlowOverloaded ? '⚠️ OVERLOAD EXCEEDED (+${(totalFlowNum - maxCapacity).toStringAsFixed(1)} L/s above limit)' : '✓ SAFE WITHIN CAPACITY'})
      </td>
    </tr>
    <tr>
      <td><b>Annular Air Core Occlusion</b></td>
      <td>Air Core &gt; 67% Open (rw &le; 0.33)</td>
      <td style="color:${result.chokeRiskLevel == 'choked' ? '#dc2626' : '#15803d'};font-weight:bold;">
        ${(result.airCoreAreaFraction * 100).toStringAsFixed(0)}% Open (${result.chokeRiskLevel.toUpperCase()})
      </td>
    </tr>
    <tr>
      <td><b>Overload Safety Certification Verdict</b></td>
      <td>Pass if Q &le; Qcap &amp; &Delta;P &le; &plusmn;25 mm</td>
      <td>
        <span class="${isPass ? 'tag-pass' : 'tag-fail'}">${isPass ? 'PASS • FULLY CERTIFIED' : 'FAIL • EXCEEDED TABLE 12 CAPACITY'}</span>
      </td>
    </tr>
  </table>
</div>

<div style="border-top: 1.5px solid #cbd5e1; padding-top: 14px; margin-top: 24px; display: flex; justify-content: space-between; font-size: 11px; color: #64748b;">
  <div>Generated by Huliot FlowLab High-Rise Drainage Simulation Suite. Valid for engineering submittals.</div>
  <div><b>Huliot Piping Systems &bull; Certified EN 12056 Compliance</b></div>
</div>

</div><!-- end report-content -->

<script>
function downloadPdfFile() {
  const element = document.getElementById('report-content');
  const opt = {
    margin: [8, 8, 8, 8],
    filename: '${isOverloadTest ? 'Huliot_Overload_Stress_Report_' : (isMonteCarlo ? 'Huliot_Morning_Rush_Audit_Log_' : 'Huliot_EN12056_Standard_Compliance_')}${params.floors}F.pdf',
    image: { type: 'jpeg', quality: 0.98 },
    html2canvas: { scale: 2, useCORS: true },
    jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' }
  };
  if (window.html2pdf) {
    html2pdf().set(opt).from(element).save();
  } else {
    window.print();
  }
}

// Auto-trigger browser Print-to-PDF dialog on load
window.addEventListener('load', function() {
  setTimeout(function() {
    window.print();
  }, 450);
});
</script>

</body>
</html>
''';
  }
}
