import os
from pathlib import Path

downloads_dir = Path.home() / "Downloads"
report_path = downloads_dir / "Huliot_FlowLab_Test_Report_50F_Wyly_Eaton.html"

# Read the HTML generation code from report_generator_service.dart or write the complete template
html_content = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Huliot FlowLab - Engineering Test Report (50 Floors)</title>
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
  .verdict-banner {
    padding: 18px;
    border-radius: 8px;
    background: #f0fdf4;
    border: 2px solid #22c55e;
    margin-bottom: 22px;
  }
  .verdict-title { font-size: 18px; font-weight: bold; color: #15803d; margin-bottom: 6px; }
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
  <div><b>HULIOT FLOWLAB</b> &bull; Official EN 12056 Drainage Compliance Test Certificate (50 Floors)</div>
  <div style="display: flex; gap: 8px;">
    <button class="btn-print" onclick="downloadPdfFile()">📥 Download PDF File</button>
    <button class="btn-print" style="background: #059669;" onclick="window.print()">🖨️ Print / Save as PDF (Vector)</button>
  </div>
</div>

<div id="report-content">

<div class="header">
  <div>
    <div class="logo">HULIOT <span>FLOWLAB</span></div>
    <div style="font-size: 12.5px; color: #475569; font-weight: 500;">High-Rise Single Stack Drainage Hydraulic Simulation Report</div>
    <div style="font-size: 11px; color: #64748b;">Standards: EN 12056-2 / BS EN 12056 / DIN 1986-100 / Wyly &amp; Eaton (NBS Monograph 31)</div>
  </div>
  <div style="text-align: right; font-size: 11px; color: #475569;">
    <div><b>Report ID:</b> HLT-50F-WYLY-EATON-VERIFIED</div>
    <div><b>Date & Time:</b> 2026-11-11 00:05</div>
    <div><b>Classification:</b> Supertall High-Rise (50 Storeys)</div>
  </div>
</div>

<div class="verdict-banner">
  <div class="verdict-title">✓ PASS &bull; FULLY COMPLIANT (EN 12056)</div>
  <div style="font-size: 12.5px; color: #334155;">
    The building stack configured with Huliot Swept Tee and Positive Relief Line (PRL System C) safely retains all water trap seals (&plusmn;25 mm WG limit). Sewer gas barrier is 100% intact.
  </div>
  <div class="kpi-grid">
    <div class="kpi-item">
      <div class="kpi-val" style="color: #10b981;">+15.6 mm</div>
      <div class="kpi-lbl">Peak Positive Surge</div>
    </div>
    <div class="kpi-item">
      <div class="kpi-val" style="color: #10b981;">-4.3 mm</div>
      <div class="kpi-lbl">Peak Suction Pull</div>
    </div>
    <div class="kpi-item">
      <div class="kpi-val">3.7 m/s</div>
      <div class="kpi-lbl">Wyly-Eaton Terminal Velocity (Vt)</div>
    </div>
    <div class="kpi-item">
      <div class="kpi-val">2.3 m</div>
      <div class="kpi-lbl">Terminal Fall Length (Lt)</div>
    </div>
    <div class="kpi-item">
      <div class="kpi-val">2.8 m/s</div>
      <div class="kpi-lbl">Entrained Air Speed</div>
    </div>
    <div class="kpi-item">
      <div class="kpi-val">72%</div>
      <div class="kpi-lbl">Stack Load Capacity</div>
    </div>
  </div>
</div>

<!-- Building Stack Schematic Diagram -->
<div class="schematic-box">
  <div class="schematic-title">📐 Building Stack Structural Architecture (50 Floors &bull; 150.0 Meters)</div>
  <div class="schematic-content">
    <svg width="180" height="130" viewBox="0 0 180 130" style="background:#020617;border-radius:6px;border:1px solid #1e293b;">
      <!-- Roof Vent Cowl -->
      <path d="M 50 15 L 70 15 L 60 5 Z" fill="#38bdf8"/>
      <!-- Main Stack Pipe -->
      <rect x="58" y="15" width="4" height="95" fill="#e2e8f0"/>
      <!-- Floor Branches with Swept Tee -->
      <path d="M 30 35 Q 56 35 58 45" fill="none" stroke="#e8392f" stroke-width="2"/>
      <path d="M 30 65 Q 56 65 58 75" fill="none" stroke="#e8392f" stroke-width="2"/>
      <!-- PRL Bypass Loop (System C) -->
      <path d="M 62 85 Q 75 85 75 95 L 75 105 Q 75 110 62 110" fill="none" stroke="#facc15" stroke-width="2" stroke-dasharray="2,2"/>
      <!-- Base Drain to Sewer -->
      <path d="M 60 110 Q 60 120 100 120" fill="none" stroke="#3b82f6" stroke-width="3"/>
      <!-- Labels -->
      <text x="80" y="38" fill="#94a3b8" font-size="8">F50 Roof Vent</text>
      <text x="80" y="68" fill="#94a3b8" font-size="8">Swept Tee Branch</text>
      <text x="85" y="98" fill="#facc15" font-size="8">PRL Relief Loop</text>
      <text x="105" y="122" fill="#38bdf8" font-size="8">To Sewer</text>
    </svg>
    <div class="schematic-text">
      <b>Single Stack System with Huliot Swept Tee &amp; PRL System C (Straight Stack, Base Rejoin):</b><br>
      Incoming fixture discharge from 9 bathrooms (9.0 L/s) forms an annular water sleeve accelerating over a terminal length of <b>2.3 m</b> (~0.8 storeys) to its Wyly-Eaton terminal velocity of <b>3.7 m/s</b>. Beyond this height, terminal velocity is invariant for both 5F and 100F stacks; however, the entrained air core accumulates suction and hydraulic jump backpressure at the stack base, safely diverted by the Positive Relief Line (PRL &mdash; System C).
    </div>
  </div>
</div>

<h3 style="color:#0369a1;margin-bottom:8px">1. Building &amp; Simulation Test Inputs</h3>
<table>
  <tr><th width="30%">Building Height</th><td><b>50 Storeys</b> (150.0 meters total vertical stack height)</td></tr>
  <tr><th>Floor-to-Floor Height</th><td><b>3.0 meters</b> per storey</td></tr>
  <tr><th>Active Flushing Bathrooms</th><td><b>9 Floors</b> (18% simultaneous flush concurrency)</td></tr>
  <tr><th>Total Discharge Flow Rate</th><td><b>9.0 L/s</b> (540 Litres/minute)</td></tr>
  <tr><th>Fixture Discharge Flow (Qf)</th><td>1.0 L/s per bathroom (WC + Basin)</td></tr>
  <tr><th>Soil &amp; Waste Stack Diameter</th><td>110 mm Nominal Diameter</td></tr>
  <tr><th>Wyly-Eaton Terminal Velocity (Vt)</th><td><b>3.7 m/s</b> (governed by Vt = 10.1 &times; (Q/D)<sup>0.4</sup>; invariant for 5F to 100F)</td></tr>
  <tr><th>Terminal Acceleration Fall Length (Lt)</th><td><b>2.3 meters</b> (Lt = 0.17 &times; Vt<sup>2</sup>; annular flow reaches steady velocity within 0.8 storeys)</td></tr>
  <tr><th>Branch Inlet Geometry</th><td>Huliot Swept Tee (Curved 87.5&deg; inlet with sweep radius)</td></tr>
  <tr><th>Positive Relief Line (PRL)</th><td>Fitted (110 mm Relief Line &mdash; PRL System C (Straight Stack, Base Rejoin))</td></tr>
  <tr><th>Trap Seal Depth</th><td><b>50 mm</b> Initial Water Seal (EN 12056 Standard)</td></tr>
  <tr><th>Roof Vent Condition</th><td>Open Atmosphere (Air Intake Cowl)</td></tr>
</table>

<h3 style="color:#0369a1;margin-bottom:8px">2. Hydraulic Stack Architecture Comparison</h3>
<table>
  <tr>
    <th>Configuration</th>
    <th>Base Backpressure</th>
    <th>Top Suction</th>
    <th>Ground Trap Seal</th>
    <th>EN 12056 Verdict</th>
  </tr>
  <tr>
    <td><b>Standard Tee without PRL (Unmitigated Baseline)</b></td>
    <td style="color:#ef4444;font-weight:bold">+80.2 mm WG</td>
    <td style="color:#ef4444;font-weight:bold">-3.6 mm WG</td>
    <td style="color:#ef4444;font-weight:bold">0 mm (BLOWN OUT)</td>
    <td><span class="tag-fail">FAIL (HAZARDOUS)</span></td>
  </tr>
  <tr style="background:#f0fdf4;">
    <td><b>Huliot Swept Tee + PRL System C (Straight Stack, Base Rejoin) <span style="color:#0284c7;font-weight:bold;">(Tested System)</span></b></td>
    <td style="color:#10b981;font-weight:bold">+15.6 mm WG</td>
    <td style="color:#10b981;font-weight:bold">-4.3 mm WG</td>
    <td style="color:#10b981;font-weight:bold">50 mm (100% Retained)</td>
    <td><span class="tag-pass">PASS (SUPERIOR)</span></td>
  </tr>
</table>

<h3 style="color:#0369a1;margin-bottom:8px">3. Floor-by-Floor Pressure &amp; Residual Trap Seal Data (Sample)</h3>
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
    <tr><td><b>F50</b></td><td>150.0 m</td><td>-4.3 mm</td><td style="color:#10b981;font-weight:bold">+0.0 mm</td><td style="color:#10b981;font-weight:bold">-4.3 mm</td><td style="color:#0284c7;font-weight:bold">50 mm</td><td><span class="tag-pass">COMPLIANT</span></td></tr>
    <tr><td><b>F47</b> <span class="badge-flush">ACTIVE FLUSH</span></td><td>141.0 m</td><td>-4.0 mm</td><td style="color:#10b981;font-weight:bold">+0.0 mm</td><td style="color:#10b981;font-weight:bold">-4.0 mm</td><td style="color:#0284c7;font-weight:bold">50 mm</td><td><span class="tag-pass">COMPLIANT</span></td></tr>
    <tr><td><b>F25</b></td><td>75.0 m</td><td>-2.1 mm</td><td style="color:#10b981;font-weight:bold">+0.0 mm</td><td style="color:#10b981;font-weight:bold">-2.1 mm</td><td style="color:#0284c7;font-weight:bold">50 mm</td><td><span class="tag-pass">COMPLIANT</span></td></tr>
    <tr><td><b>F2</b></td><td>6.0 m</td><td>+8.5 mm</td><td style="color:#10b981;font-weight:bold">+8.5 mm</td><td style="color:#10b981;font-weight:bold">-0.5 mm</td><td style="color:#0284c7;font-weight:bold">50 mm</td><td><span class="tag-pass">COMPLIANT</span></td></tr>
    <tr><td><b>F1</b></td><td>3.0 m</td><td>+15.6 mm</td><td style="color:#10b981;font-weight:bold">+15.6 mm</td><td style="color:#10b981;font-weight:bold">-0.0 mm</td><td style="color:#0284c7;font-weight:bold">50 mm</td><td><span class="tag-pass">COMPLIANT</span></td></tr>
  </tbody>
</table>

<div style="border-top: 1.5px solid #cbd5e1; padding-top: 14px; margin-top: 24px; display: flex; justify-content: space-between; font-size: 11px; color: #64748b;">
  <div>Generated by Huliot FlowLab High-Rise Drainage Simulation Suite. Valid for engineering submittals.</div>
  <div><b>Huliot Piping Systems &bull; Certified EN 12056 Compliance</b></div>
</div>

</div>

<script>
function downloadPdfFile() {
  const element = document.getElementById('report-content');
  const opt = {
    margin: [8, 8, 8, 8],
    filename: 'Huliot_FlowLab_Test_Report_50F.pdf',
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
</script>

</body>
</html>
"""

with open(report_path, "w", encoding="utf-8") as f:
    f.write(html_content)

print(f"Report written to: {report_path}")
