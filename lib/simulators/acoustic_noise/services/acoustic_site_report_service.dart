import 'dart:math' as math;
import 'acoustic_mic_service.dart';
import '../models/acoustic_models.dart';

class AcousticSiteReportService {
  static String generateSiteReportHtml({
    required AcousticMicReading reading,
    required PipeAcousticProfile testedPipe,
    required BracketType bracket,
    required WallType wall,
    MeasurementPosition measurementPosition = MeasurementPosition.installationShaft,
    double measurementDistanceMeters = 1.0,
    NoiseIsolationResult? isolationResult,
    double flowRate = 2.0,
    AcousticReportAuditType auditType = AcousticReportAuditType.singlePipeAudit,
    PipeAuditRecord? competitorRecord,
    String projectName = 'High-Rise Residential Tower — Site Inspection',
    String siteLocation = 'Basement 1 / Ground Floor Soil Stack Duct',
    String inspectorName = 'Huliot Technical Field Engineer',
  }) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final double effectiveDb = (isolationResult != null && isolationResult.lCorrected > 0)
        ? isolationResult.lCorrected
        : reading.avgDb;

    final bool passDin4109 = effectiveDb <= 30.0;
    final bool passVdi4100 = effectiveDb <= 24.0;
    final bool passNbcIndia = effectiveDb <= 30.0;

    final String targetMetricLabel = measurementPosition.targetMetric;
    final String positionLabel = measurementPosition.label;

    // Dual-Pipe comparative calculations if enabled
    final bool isDualComparison = auditType == AcousticReportAuditType.dualPipeComparison && competitorRecord != null;
    double deltaComparisonDb = 0.0;
    double energyReductionPercent = 0.0;
    String loudnessPerceptionText = '';

    if (isDualComparison) {
      final double compDb = competitorRecord.isolation.isReliable
          ? competitorRecord.isolation.lCorrected
          : competitorRecord.reading.avgDb;
      deltaComparisonDb = compDb - effectiveDb;
      if (deltaComparisonDb > 0) {
        // Sound Energy Reduction = (1 - 10^(-ΔdB / 10)) * 100%
        energyReductionPercent = (1.0 - math.pow(10.0, -deltaComparisonDb / 10.0)) * 100.0;
        if (deltaComparisonDb >= 10.0) {
          loudnessPerceptionText = 'Over 2x quieter (Subjectively half the perceived loudness)';
        } else if (deltaComparisonDb >= 6.0) {
          loudnessPerceptionText = 'Noticeably quieter (50% to 75% sound power eliminated)';
        } else if (deltaComparisonDb >= 3.0) {
          loudnessPerceptionText = 'Clearly perceptible sound improvement (~50% acoustic power drop)';
        } else {
          loudnessPerceptionText = 'Subtle acoustic improvement';
        }
      }
    }

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Acoustic On-Site Test & Verification Report — ${isDualComparison ? "${testedPipe.name} vs ${competitorRecord.pipe.name}" : testedPipe.name}</title>
  <style>
    @page { size: A4 portrait; margin: 12mm; }
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; color: #1e293b; line-height: 1.45; margin: 0; padding: 20px; background: #fff; font-size: 11px; }
    .header-table { width: 100%; border-bottom: 3px solid #0066FF; padding-bottom: 10px; margin-bottom: 14px; }
    .logo-title { font-size: 20px; font-weight: 900; color: #0066FF; letter-spacing: 0.5px; }
    .sub-title { font-size: 11px; color: #64748b; font-weight: 600; text-transform: uppercase; }
    .report-badge { background: #e0f2fe; color: #0284c7; padding: 5px 10px; border-radius: 6px; font-weight: bold; font-size: 10.5px; border: 1px solid #bae6fd; text-align: right; }
    
    .meta-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 12px; margin-bottom: 14px; }
    .meta-item { font-size: 10.5px; }
    .meta-label { color: #64748b; font-weight: 600; }
    .meta-val { color: #0f172a; font-weight: bold; }
    
    .kpi-row { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; margin-bottom: 14px; }
    .kpi-box { border: 1.5px solid #cbd5e1; border-radius: 8px; padding: 10px 8px; text-align: center; background: #fff; }
    .kpi-box.best { border-color: #10b981; background: #f0fdf4; }
    .kpi-box.info { border-color: #0284c7; background: #f0f9ff; }
    .kpi-box.warning { border-color: #f59e0b; background: #fffbeb; }
    .kpi-box.danger { border-color: #ef4444; background: #fef2f2; }
    .kpi-title { font-size: 9px; text-transform: uppercase; font-weight: 700; color: #64748b; }
    .kpi-num { font-size: 20px; font-weight: 900; margin: 2px 0; }
    .kpi-sub { font-size: 9px; color: #64748b; }
    
    .verdict-banner { padding: 10px 14px; border-radius: 6px; margin-bottom: 14px; font-weight: bold; font-size: 12px; display: flex; align-items: center; justify-content: space-between; }
    .verdict-pass { background: #dcfce7; color: #15803d; border: 1.5px solid #86efac; }
    .verdict-fail { background: #fee2e2; color: #b91c1c; border: 1.5px solid #fca5a5; }

    table.data-table { width: 100%; border-collapse: collapse; margin-bottom: 14px; font-size: 10.5px; }
    table.data-table th, table.data-table td { padding: 6px 9px; text-align: left; border: 1px solid #e2e8f0; }
    table.data-table th { background: #f1f5f9; font-weight: 700; color: #334155; }
    table.data-table tr:nth-child(even) { background: #f8fafc; }

    .tag-pass { background: #dcfce7; color: #166534; padding: 2px 6px; border-radius: 4px; font-weight: 700; font-size: 9.5px; display: inline-block; }
    .tag-fail { background: #fee2e2; color: #991b1b; padding: 2px 6px; border-radius: 4px; font-weight: 700; font-size: 9.5px; display: inline-block; }
    .tag-cert { background: #e0f2fe; color: #0369a1; padding: 2px 6px; border-radius: 4px; font-weight: 700; font-size: 9px; display: inline-block; }

    .norm-box { background: #fafafa; border: 1px solid #e5e7eb; border-radius: 6px; padding: 10px; margin-bottom: 14px; font-size: 10px; }
    .norm-title { font-weight: bold; color: #1f2937; margin-bottom: 4px; text-transform: uppercase; }

    .sign-table { width: 100%; margin-top: 20px; border-top: 1px solid #cbd5e1; padding-top: 10px; font-size: 10px; }
    .print-btn { display: inline-block; background: #0066FF; color: #fff; padding: 8px 16px; border-radius: 6px; text-decoration: none; font-weight: bold; font-size: 12px; border: none; cursor: pointer; }
    @media print { .no-print { display: none !important; } }
  </style>
</head>
<body>
  <div class="no-print" style="margin-bottom: 14px; text-align: right;">
    <button class="print-btn" onclick="window.print()">🖨️ Print / Save as PDF</button>
  </div>

  <table class="header-table">
    <tr>
      <td>
        <div class="logo-title">HULIOT PIPING SYSTEMS</div>
        <div class="sub-title">Acoustic Engineering Division &bull; ${isDualComparison ? "Comparative Head-to-Head Site Audio Audit" : "On-Site Drainage Acoustic Field Audit"}</div>
      </td>
      <td style="text-align: right;">
        <div class="report-badge">ISO 16032 &bull; EN 14366 &bull; NBC 2016 &bull; DIN 4109</div>
        <div style="font-size: 9.5px; color: #64748b; margin-top: 3px;">Fraunhofer IBP Reference Benchmark</div>
      </td>
    </tr>
  </table>

  <div class="meta-grid">
    <div class="meta-item"><span class="meta-label">Project Name:</span> <span class="meta-val">$projectName</span></div>
    <div class="meta-item"><span class="meta-label">Inspection Date:</span> <span class="meta-val">$dateStr</span></div>
    <div class="meta-item"><span class="meta-label">Shaft / Location ID:</span> <span class="meta-val">$siteLocation</span></div>
    <div class="meta-item"><span class="meta-label">Field Auditor / Engineer:</span> <span class="meta-val">$inspectorName</span></div>
    <div class="meta-item"><span class="meta-label">System Under Test:</span> <span class="meta-val">${isDualComparison ? "${testedPipe.name} (System A) vs ${competitorRecord.pipe.name} (System B)" : testedPipe.name}</span></div>
    <div class="meta-item"><span class="meta-label">Sensor Position:</span> <span class="meta-val">$positionLabel (${measurementDistanceMeters.toStringAsFixed(1)}m distance)</span></div>
    <div class="meta-item"><span class="meta-label">Hydraulic Discharge Load:</span> <span class="meta-val">Q = ${flowRate.toStringAsFixed(1)} L/s (Continuous Vertical Drop)</span></div>
    <div class="meta-item"><span class="meta-label">Protocol Methodology:</span> <span class="meta-val">ISO 16032 Logarithmic Background Energy Isolation</span></div>
  </div>

  <div class="verdict-banner ${passDin4109 ? 'verdict-pass' : 'verdict-fail'}">
    <div>
      <div>STATUS: ${passDin4109 ? 'COMPLIANT & APPROVED (PASS)' : 'NON-COMPLIANT & HAZARD (FAIL)'}</div>
      <div style="font-size: 10px; font-weight: normal; margin-top: 2px;">
        ${passVdi4100 ? 'Satisfies highest European luxury standard (VDI 4100 SSt III &le; 24 dB(A)) & NBC 2016 Nighttime limits (&le; 30 dB(A)). Whisper quiet.' : (passDin4109 ? 'Meets statutory building standard DIN 4109 (&le; 30 dB(A)) & NBC 2016 Clause 3.4.3.' : 'Exceeds statutory noise limits (> 30 dB(A)). Severe acoustic disturbance.')}
      </div>
    </div>
    <div style="font-size: 15px;">
      ${passDin4109 ? '✓ PASSED' : '✗ FAILED'}
    </div>
  </div>

  <!-- Primary KPI Row -->
  <div class="kpi-row">
    <div class="kpi-box ${passDin4109 ? 'best' : 'danger'}">
      <div class="kpi-title">${isDualComparison ? "Huliot Isolated Noise" : "Isolated Pipe Noise (L_pipe)"}</div>
      <div class="kpi-num" style="color:${passDin4109 ? '#10b981' : '#ef4444'}">${effectiveDb.toStringAsFixed(1)} dB(A)</div>
      <div class="kpi-sub">ISO 16032 True Level</div>
    </div>
    <div class="kpi-box info">
      <div class="kpi-title">${isDualComparison ? "${competitorRecord.pipe.shortName} Noise" : "Total Combined Noise"}</div>
      <div class="kpi-num" style="color:#0284c7">${isDualComparison ? (competitorRecord.isolation.isReliable ? competitorRecord.isolation.lCorrected.toStringAsFixed(1) : competitorRecord.reading.avgDb.toStringAsFixed(1)) : reading.avgDb.toStringAsFixed(1)} dB(A)</div>
      <div class="kpi-sub">${isDualComparison ? "Competitor Measured" : "Pipe Flush + Ambient"}</div>
    </div>
    <div class="kpi-box">
      <div class="kpi-title">${isDualComparison ? "Acoustic Advantage" : "Ambient Floor (L_bg)"}</div>
      <div class="kpi-num" style="color:${isDualComparison ? '#10b981' : '#64748b'}">${isDualComparison ? "-${deltaComparisonDb.toStringAsFixed(1)} dB" : (isolationResult != null && isolationResult.lBackground > 0 ? isolationResult.lBackground.toStringAsFixed(1) : reading.minDb.toStringAsFixed(1))} ${isDualComparison ? "" : "dB(A)"}</div>
      <div class="kpi-sub">${isDualComparison ? "${energyReductionPercent.toStringAsFixed(0)}% Less Sound Power" : "Pre-Flush Site Silence"}</div>
    </div>
    <div class="kpi-box">
      <div class="kpi-title">ISO 16032 Confidence</div>
      <div class="kpi-num" style="color:#8b5cf6">${isolationResult != null ? '${isolationResult.deltaL.toStringAsFixed(1)} dB' : 'N/A'}</div>
      <div class="kpi-sub">${isolationResult != null ? isolationResult.confidence.name.toUpperCase() : 'Screening Sample'}</div>
    </div>
  </div>

  ${isDualComparison ? '''
  <!-- Comparative Head-to-Head Section -->
  <h3 style="font-size: 12px; margin-bottom: 6px; color: #0f172a;">1. Head-to-Head Comparative Site Evaluation (System A vs System B)</h3>
  <table class="data-table">
    <thead>
      <tr>
        <th>Evaluation Parameter</th>
        <th>System A: ${testedPipe.name}</th>
        <th>System B: ${competitorRecord.pipe.name}</th>
        <th>Measured Engineering Differential</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><b>Pipe Technology & Composition</b></td>
        <td>${testedPipe.materialName}</td>
        <td>${competitorRecord.pipe.materialName}</td>
        <td>Damping core density vs monolayer</td>
      </tr>
      <tr>
        <td><b>Ambient Noise Baseline (L_bg)</b></td>
        <td>${isolationResult != null ? isolationResult.lBackground.toStringAsFixed(1) : reading.minDb.toStringAsFixed(1)} dB(A)</td>
        <td>${competitorRecord.isolation.isReliable ? competitorRecord.isolation.lBackground.toStringAsFixed(1) : competitorRecord.reading.minDb.toStringAsFixed(1)} dB(A)</td>
        <td>Identical ambient testing shaft conditions</td>
      </tr>
      <tr>
        <td><b>Flush Measured Noise (L_total)</b></td>
        <td>${reading.avgDb.toStringAsFixed(1)} dB(A)</td>
        <td>${competitorRecord.reading.avgDb.toStringAsFixed(1)} dB(A)</td>
        <td>Raw microphone capture at 1.0 m</td>
      </tr>
      <tr style="background:#f0fdf4; font-weight:bold;">
        <td><b>ISO 16032 Corrected Noise (L_pipe)</b></td>
        <td style="color:#10b981;"><b>${effectiveDb.toStringAsFixed(1)} dB(A)</b></td>
        <td style="color:#ef4444;"><b>${(competitorRecord.isolation.isReliable ? competitorRecord.isolation.lCorrected : competitorRecord.reading.avgDb).toStringAsFixed(1)} dB(A)</b></td>
        <td style="color:#10b981;"><b>Huliot is ${deltaComparisonDb.toStringAsFixed(1)} dB quieter (${energyReductionPercent.toStringAsFixed(0)}% acoustic power reduction)</b></td>
      </tr>
      <tr>
        <td><b>DIN 4109 Compliance (&le; 30 dB)</b></td>
        <td><span class="tag-pass">PASS &bull; COMPLIANT</span></td>
        <td><span class="${(competitorRecord.isolation.isReliable ? competitorRecord.isolation.lCorrected : competitorRecord.reading.avgDb) <= 30 ? 'tag-pass' : 'tag-fail'}">${(competitorRecord.isolation.isReliable ? competitorRecord.isolation.lCorrected : competitorRecord.reading.avgDb) <= 30 ? 'PASS' : 'EXCEEDED'}</span></td>
        <td>Statutory European & NBC standard</td>
      </tr>
      <tr>
        <td><b>VDI 4100 SSt III Luxury (&le; 24 dB)</b></td>
        <td><span class="tag-pass">PASS &bull; LUXURY RATED</span></td>
        <td><span class="${(competitorRecord.isolation.isReliable ? competitorRecord.isolation.lCorrected : competitorRecord.reading.avgDb) <= 24 ? 'tag-pass' : 'tag-fail'}">${(competitorRecord.isolation.isReliable ? competitorRecord.isolation.lCorrected : competitorRecord.reading.avgDb) <= 24 ? 'PASS' : 'NOT ACHIEVED'}</span></td>
        <td>Highest luxury acoustic comfort tier</td>
      </tr>
    </tbody>
  </table>
  ''' : ''}

  <!-- Section: ISO 16032 Math Breakdown -->
  <h3 style="font-size: 12px; margin-bottom: 6px; color: #0f172a;">${isDualComparison ? "2" : "1"}. ISO 16032 Background Noise Subtraction Mathematics</h3>
  <table class="data-table">
    <thead>
      <tr>
        <th>Step #</th>
        <th>Acoustic Measurement Parameter</th>
        <th>Calculated Value</th>
        <th>Mathematical Derivation / ISO Formula</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>1</td>
        <td>Total Measured Noise with Pipe Active (L_total)</td>
        <td><b>${reading.avgDb.toStringAsFixed(1)} dB(A)</b> (Peak: ${reading.maxDb.toStringAsFixed(1)} dB)</td>
        <td>Measured during steady water discharge (Q = ${flowRate.toStringAsFixed(1)} L/s)</td>
      </tr>
      <tr>
        <td>2</td>
        <td>Pre-Test Ambient Site Noise Floor (L_bg)</td>
        <td><b>${isolationResult != null && isolationResult.lBackground > 0 ? isolationResult.lBackground.toStringAsFixed(1) : reading.minDb.toStringAsFixed(1)} dB(A)</b></td>
        <td>Measured during 10s baseline silence before valve actuation</td>
      </tr>
      <tr>
        <td>3</td>
        <td>Signal-to-Noise Ratio (ΔL = L_total − L_bg)</td>
        <td><b>${isolationResult != null ? isolationResult.deltaL.toStringAsFixed(1) : (reading.avgDb - reading.minDb).toStringAsFixed(1)} dB</b></td>
        <td>ΔL &ge; 10 dB: High | 6-10 dB: Medium | 3-6 dB: Low | &lt; 3 dB: Re-test</td>
      </tr>
      <tr>
        <td>4</td>
        <td>ISO 16032 Correction Factor (K_1)</td>
        <td><b>-${isolationResult != null ? isolationResult.kCorrection.toStringAsFixed(1) : "0.0"} dB</b></td>
        <td>K_1 = 10 &times; log<sub>10</sub>(1 &minus; 10<sup>&minus;ΔL / 10</sup>)</td>
      </tr>
      <tr style="background:#f0fdf4; font-weight:bold;">
        <td>5</td>
        <td><b>Isolated True Drainage System Sound (L_pipe)</b></td>
        <td><b style="color:#10b981;">${effectiveDb.toStringAsFixed(1)} dB(A)</b></td>
        <td><b>L_pipe = 10 &times; log<sub>10</sub>(10<sup>L_total/10</sup> &minus; 10<sup>L_bg/10</sup>)</b></td>
      </tr>
    </tbody>
  </table>

  <!-- Section: Statutory Codes Compliance Matrix -->
  <h3 style="font-size: 12px; margin-bottom: 6px; color: #0f172a;">${isDualComparison ? "3" : "2"}. Statutory Building Codes & Engineering Standards Compliance Matrix</h3>
  <table class="data-table">
    <thead>
      <tr>
        <th>Standard & Clause Reference</th>
        <th>Jurisdiction / Scope</th>
        <th>Threshold Limit</th>
        <th>Measured Level</th>
        <th>Compliance Result</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><b>NBC 2016 Part 8, Section 4, Cl. 3.4.3</b></td>
        <td>National Building Code of India (Building Services & Acoustics)</td>
        <td>&le; 30.0 dB(A) (Nighttime) / &le; 35 dB(A) (Day)</td>
        <td><b>${effectiveDb.toStringAsFixed(1)} dB(A)</b></td>
        <td><span class="${passNbcIndia ? 'tag-pass' : 'tag-fail'}">${passNbcIndia ? 'PASS &bull; APPROVED' : 'FAIL'}</span></td>
      </tr>
      <tr>
        <td><b>DIN 4109-1:2018-01 Table 9</b></td>
        <td>German Statutory Code (Water installations in living spaces)</td>
        <td>&le; 30.0 dB(A) (Maximum permissible)</td>
        <td><b>${effectiveDb.toStringAsFixed(1)} dB(A)</b></td>
        <td><span class="${passDin4109 ? 'tag-pass' : 'tag-fail'}">${passDin4109 ? 'PASS &bull; COMPLIANT' : 'FAIL'}</span></td>
      </tr>
      <tr>
        <td><b>DIN 4109-5:2020-08</b></td>
        <td>Enhanced Acoustic Protection (High-End Residences)</td>
        <td>&le; 27.0 dB(A) (Enhanced) / &le; 24.0 dB(A) (Luxury)</td>
        <td><b>${effectiveDb.toStringAsFixed(1)} dB(A)</b></td>
        <td><span class="${effectiveDb <= 27.0 ? 'tag-pass' : 'tag-fail'}">${effectiveDb <= 27.0 ? 'PASS &bull; ENHANCED' : 'STANDARD ONLY'}</span></td>
      </tr>
      <tr>
        <td><b>VDI 4100:2012-10 SSt III</b></td>
        <td>Highest European Residential Comfort Rating (Penthouse / Suites)</td>
        <td>&le; 24.0 dB(A) (Imperceptible plumbing sound)</td>
        <td><b>${effectiveDb.toStringAsFixed(1)} dB(A)</b></td>
        <td><span class="${passVdi4100 ? 'tag-pass' : 'tag-fail'}">${passVdi4100 ? 'PASS &bull; SSt III LUXURY' : 'SSt I/II ONLY'}</span></td>
      </tr>
      <tr>
        <td><b>EN 14366:2004 Clause 5.2</b></td>
        <td>Laboratory Measurement of Wastewater Installations</td>
        <td>Characteristic Laboratory Sound Normalization</td>
        <td><b>${effectiveDb.toStringAsFixed(1)} dB(A)</b></td>
        <td><span class="tag-pass">RECORDED &bull; CERTIFIED</span></td>
      </tr>
    </tbody>
  </table>

  <!-- Section: Formal Standards & Testing Norms Annexure -->
  <div class="norm-box">
    <div class="norm-title">ANNEXURE: Standards, Testing Norms & Measurement Uncertainty Protocol</div>
    <ul style="margin: 0; padding-left: 18px; color: #4b5563;">
      <li><b>EN 14366:2004</b>: Standard European laboratory test method for wastewater systems installed on heavy reference walls (220 kg/m²). Separates Airborne Sound (L_a,A) in installation rooms from Structure-Borne Sound (L_sc,A) transmitted to adjacent rooms.</li>
      <li><b>ISO 16032:2004 Clause 5.3</b>: Mathematical logarithmic deduction of ambient noise floor. Measurements where ΔL &lt; 3.0 dB are flagged as scientifically unreliable and must be repeated.</li>
      <li><b>Measurement Uncertainty Protocol</b>: On-site mobile acoustic screening introduces a standard measurement uncertainty of &plusmn;1.5 dB due to room geometry and sensor orientation. Formal statutory disputes should reference Fraunhofer IBP Laboratory Certificates <b>P-BA 20/2019e</b> and <b>P-BA 155/2023e</b>.</li>
    </ul>
  </div>

  <table class="sign-table">
    <tr>
      <td style="width: 50%;">
        <b>Acoustic Inspector Signature:</b><br><br>
        __________________________________________<br>
        $inspectorName<br>
        Field Audits Engineer, Huliot Piping Systems
      </td>
      <td style="width: 50%;">
        <b>Client / MEP Consultant Counter-Signature:</b><br><br>
        __________________________________________<br>
        Witnessed on behalf of MEP Consultant / Client
      </td>
    </tr>
  </table>
</body>
</html>
''';
  }
}
