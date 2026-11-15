import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/report_download.dart';
import '../models/acoustic_models.dart';
import '../services/acoustic_mic_service.dart';
import '../services/acoustic_site_report_service.dart';

class AcousticSiteReportDialog extends StatefulWidget {
  final AcousticMicReading reading;
  final PipeAcousticProfile testedPipe;
  final BracketType bracket;
  final WallType wall;
  final MeasurementPosition measurementPosition;
  final NoiseIsolationResult? isolationResult;
  final double flowRate;
  final PipeAuditRecord? recordA;
  final PipeAuditRecord? recordB;

  const AcousticSiteReportDialog({
    super.key,
    required this.reading,
    required this.testedPipe,
    required this.bracket,
    required this.wall,
    this.measurementPosition = MeasurementPosition.installationShaft,
    this.isolationResult,
    this.flowRate = 2.0,
    this.recordA,
    this.recordB,
  });

  static Future<void> show(
    BuildContext context, {
    required AcousticMicReading reading,
    required PipeAcousticProfile testedPipe,
    required BracketType bracket,
    required WallType wall,
    MeasurementPosition measurementPosition = MeasurementPosition.installationShaft,
    NoiseIsolationResult? isolationResult,
    double flowRate = 2.0,
    PipeAuditRecord? recordA,
    PipeAuditRecord? recordB,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AcousticSiteReportDialog(
        reading: reading,
        testedPipe: testedPipe,
        bracket: bracket,
        wall: wall,
        measurementPosition: measurementPosition,
        isolationResult: isolationResult,
        flowRate: flowRate,
        recordA: recordA,
        recordB: recordB,
      ),
    );
  }

  @override
  State<AcousticSiteReportDialog> createState() => _AcousticSiteReportDialogState();
}

class _AcousticSiteReportDialogState extends State<AcousticSiteReportDialog> {
  late final TextEditingController _projectController;
  late final TextEditingController _locationController;
  late final TextEditingController _inspectorController;
  late MeasurementPosition _position;
  final double _distanceMeters = 1.0;

  // Audit Type: Single Pipe Audit vs Dual Pipe A/B Comparison
  late AcousticReportAuditType _auditType;

  @override
  void initState() {
    super.initState();
    _projectController = TextEditingController(
      text: 'High-Rise Commercial & Residential Tower',
    );
    _locationController = TextEditingController(
      text: 'Floor -1 Shaft / Drainage Soil Stack #2',
    );
    _inspectorController = TextEditingController(
      text: 'Huliot Technical Field Engineer',
    );
    _position = widget.measurementPosition;

    // Default to dual if both records exist, otherwise single pipe
    _auditType = (widget.recordB != null)
        ? AcousticReportAuditType.dualPipeComparison
        : AcousticReportAuditType.singlePipeAudit;
  }

  @override
  void dispose() {
    _projectController.dispose();
    _locationController.dispose();
    _inspectorController.dispose();
    super.dispose();
  }

  void _generateAndOpenReport() {
    final bool isDual = _auditType == AcousticReportAuditType.dualPipeComparison && widget.recordB != null;

    final html = AcousticSiteReportService.generateSiteReportHtml(
      reading: widget.reading,
      testedPipe: widget.testedPipe,
      bracket: widget.bracket,
      wall: widget.wall,
      measurementPosition: _position,
      measurementDistanceMeters: _distanceMeters,
      isolationResult: widget.isolationResult,
      flowRate: widget.flowRate,
      auditType: isDual ? AcousticReportAuditType.dualPipeComparison : AcousticReportAuditType.singlePipeAudit,
      competitorRecord: isDual ? widget.recordB : null,
      projectName: _projectController.text.trim().isEmpty
          ? 'High-Rise Project Site Audit'
          : _projectController.text.trim(),
      siteLocation: _locationController.text.trim().isEmpty
          ? 'Drainage Stack Shaft'
          : _locationController.text.trim(),
      inspectorName: _inspectorController.text.trim().isEmpty
          ? 'Huliot Technical Specialist'
          : _inspectorController.text.trim(),
    );

    openPrintableHtmlReport(html);
  }

  void _downloadReport() {
    final bool isDual = _auditType == AcousticReportAuditType.dualPipeComparison && widget.recordB != null;

    final html = AcousticSiteReportService.generateSiteReportHtml(
      reading: widget.reading,
      testedPipe: widget.testedPipe,
      bracket: widget.bracket,
      wall: widget.wall,
      measurementPosition: _position,
      measurementDistanceMeters: _distanceMeters,
      isolationResult: widget.isolationResult,
      flowRate: widget.flowRate,
      auditType: isDual ? AcousticReportAuditType.dualPipeComparison : AcousticReportAuditType.singlePipeAudit,
      competitorRecord: isDual ? widget.recordB : null,
      projectName: _projectController.text.trim().isEmpty
          ? 'High-Rise Project Site Audit'
          : _projectController.text.trim(),
      siteLocation: _locationController.text.trim().isEmpty
          ? 'Drainage Stack Shaft'
          : _locationController.text.trim(),
      inspectorName: _inspectorController.text.trim().isEmpty
          ? 'Huliot Technical Specialist'
          : _inspectorController.text.trim(),
    );

    final String filename = isDual
        ? 'Acoustic_Comparative_Report_${widget.testedPipe.name}_vs_${widget.recordB?.pipe.name}.html'
        : 'Huliot_Acoustic_Site_Report_${widget.testedPipe.name.replaceAll(' ', '_')}.html';
    downloadReportHtmlFile(html, filename);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double effectiveDb = (widget.isolationResult != null && widget.isolationResult!.lCorrected > 0)
        ? widget.isolationResult!.lCorrected
        : widget.reading.avgDb;

    final bool passDin = effectiveDb <= 30.0;
    final bool passVdi = effectiveDb <= 24.0;
    final Color statusColor = passVdi
        ? AppColors.success
        : (passDin ? AppColors.warning : AppColors.danger);

    final bool hasTestedRecordB = widget.recordB != null;
    final bool isDualSelected = _auditType == AcousticReportAuditType.dualPipeComparison;
    final bool canExport = !isDualSelected || hasTestedRecordB;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF131D2D) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.2,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assessment_rounded,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ON-SITE ACOUSTIC TEST REPORT',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'ISO 16032, NBC 2016 & EN 14366 On-Site Sound Certification Audit',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Report Scope Selector: Single Pipe vs Dual Pipe A/B Comparison
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Scope (प्रमाणित रिपोर्ट प्रकार):',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _auditType = AcousticReportAuditType.singlePipeAudit),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _auditType == AcousticReportAuditType.singlePipeAudit
                                    ? AppColors.primary.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _auditType == AcousticReportAuditType.singlePipeAudit
                                      ? AppColors.primary
                                      : Colors.grey.withValues(alpha: 0.3),
                                  width: _auditType == AcousticReportAuditType.singlePipeAudit ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 16,
                                    color: _auditType == AcousticReportAuditType.singlePipeAudit
                                        ? AppColors.primary
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  const Flexible(
                                    child: Text(
                                      'Single Pipe Audit (मेरा पाइप / Standalone)',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _auditType = AcousticReportAuditType.dualPipeComparison),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _auditType == AcousticReportAuditType.dualPipeComparison
                                    ? (hasTestedRecordB
                                        ? AppColors.accent.withValues(alpha: 0.2)
                                        : AppColors.warning.withValues(alpha: 0.15))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _auditType == AcousticReportAuditType.dualPipeComparison
                                      ? (hasTestedRecordB ? AppColors.accent : AppColors.warning)
                                      : Colors.grey.withValues(alpha: 0.3),
                                  width: _auditType == AcousticReportAuditType.dualPipeComparison ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    hasTestedRecordB ? Icons.compare_arrows_rounded : Icons.lock_outline_rounded,
                                    size: 16,
                                    color: _auditType == AcousticReportAuditType.dualPipeComparison
                                        ? (hasTestedRecordB ? AppColors.accent : AppColors.warning)
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      hasTestedRecordB
                                          ? 'A/B Dual Pipe Audit (Both Tested)'
                                          : 'A/B Dual Pipe Audit (Requires Test B)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: !hasTestedRecordB && isDualSelected ? AppColors.warning : null,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Warning if Dual Pipe selected but System B not tested!
                    if (isDualSelected && !hasTestedRecordB) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'सिस्टम B (कॉम्पिटिटर) का ऑन-साइट टेस्ट अभी तक नहीं हुआ है!',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'इंजीनियरिंग नियमों के तहत, बिना टेस्ट किए किसी भी पाइप की फर्जी रिपोर्ट नहीं बनाई जा सकती। आपने सिर्फ "${widget.testedPipe.name}" का टेस्ट किया है। कृपया सिंगल पाइप रिपोर्ट निकालें, या साइट पर दूसरे पाइप का भी लाइव टेस्ट करें।',
                                    style: TextStyle(fontSize: 10.5, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // If both tested, show verified comparison badge
                    if (isDualSelected && hasTestedRecordB) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_rounded, size: 18, color: AppColors.success),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'दोनों पाइप्स का वास्तविक ऑन-साइट टेस्ट रिकॉर्ड उपलब्ध है: ${widget.testedPipe.name} vs ${widget.recordB?.pipe.name}.',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // KPI Summary Cards
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _kpiItem(
                        label: 'ISOLATED L_pipe',
                        val: '${effectiveDb.toStringAsFixed(1)} dB(A)',
                        color: statusColor,
                        sub: passDin ? 'DIN 4109 PASS' : 'EXCEEDED',
                      ),
                    ),
                    Container(width: 1, height: 38, color: Colors.grey.withValues(alpha: 0.3)),
                    Expanded(
                      child: _kpiItem(
                        label: 'TOTAL L_total',
                        val: '${widget.reading.avgDb.toStringAsFixed(1)} dB(A)',
                        color: AppColors.accent,
                        sub: 'Peak: ${widget.reading.maxDb.toStringAsFixed(1)} dB',
                      ),
                    ),
                    Container(width: 1, height: 38, color: Colors.grey.withValues(alpha: 0.3)),
                    Expanded(
                      child: _kpiItem(
                        label: 'AMBIENT L_bg',
                        val: widget.isolationResult != null && widget.isolationResult!.lBackground > 0
                            ? '${widget.isolationResult!.lBackground.toStringAsFixed(1)} dB(A)'
                            : '${widget.reading.minDb.toStringAsFixed(1)} dB(A)',
                        color: Colors.grey,
                        sub: widget.isolationResult != null
                            ? widget.isolationResult!.confidence.name.toUpperCase()
                            : 'Noise Floor',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Position & Distance Controls
              const Text(
                'Sensor Location & Positioning Details',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: MeasurementPosition.values.map((pos) {
                  final bool isSelected = _position == pos;
                  return ChoiceChip(
                    label: Text(pos.shortLabel),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.25),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.accent : null,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _position = pos);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // Form fields
              const Text(
                'Report Project & Site Metadata',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              _buildTextField(
                controller: _projectController,
                label: 'Project Name',
                icon: Icons.business_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 8),

              _buildTextField(
                controller: _locationController,
                label: 'Site Location / Pipe Shaft ID',
                icon: Icons.location_on_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 8),

              _buildTextField(
                controller: _inspectorController,
                label: 'Field Auditor / Testing Engineer',
                icon: Icons.person_rounded,
                isDark: isDark,
              ),

              const SizedBox(height: 14),

              // Tested Pipe & Specs Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isDualSelected && hasTestedRecordB
                            ? 'Comparative Mode: System A (${widget.testedPipe.name}) vs System B (${widget.recordB?.pipe.name})'
                            : 'Single Target: ${widget.testedPipe.name} | ${widget.bracket.label} | ${widget.wall.label}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Action Buttons
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 10,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: canExport
                        ? () {
                            _downloadReport();
                            Navigator.of(context).pop();
                          }
                        : null,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text(
                      canExport ? 'Download HTML' : 'Select Single Pipe Audit',
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canExport ? AppColors.primary : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: canExport
                        ? () {
                            _generateAndOpenReport();
                            Navigator.of(context).pop();
                          }
                        : null,
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: Text(
                      canExport ? 'Print / Save PDF Report' : 'Test B Required for A/B',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiItem({
    required String label,
    required String val,
    required Color color,
    required String sub,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          sub,
          style: const TextStyle(fontSize: 9, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 12.5),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 11.5,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
        prefixIcon: Icon(icon, size: 16, color: AppColors.accent),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
