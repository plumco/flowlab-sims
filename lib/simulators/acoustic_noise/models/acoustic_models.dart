import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/acoustic_mic_service.dart';

enum PipeTechnologyType {
  pvc,
  castIron,
  hdpe,
  huliotUltraSilent,
  astralSilencio,
  supremeSkyrise,
  princeSilentfit,
  customPipe,
}

enum BracketType {
  huliotAcoustic,
  rigidMetal,
}

enum WallType {
  solidMasonry, // 220 kg/m²
  lightweightPartition, // 115 kg/m²
}

enum AcousticMode {
  simulation,
  liveSiteSoundTest,
}

enum MeasurementPosition {
  installationShaft, // Inside plumbing chase/duct - Airborne dominated
  receivingRoom, // Behind installation wall - Structure-borne dominated
  adjacentPipe, // 1m from pipe in room - Composite airborne radiation
}

enum TestingPhase {
  setup,
  ambientCalibration,
  flushRecording,
  analysis,
}

enum NoiseConfidence {
  high, // ΔL >= 10 dB
  medium, // 6 <= ΔL < 10 dB
  low, // 3 <= ΔL < 6 dB
  unreliable, // ΔL < 3 dB
}

class AmbientCalibrationResult {
  final double avgDb;
  final double minDb;
  final double maxDb;
  final int durationSec;
  final int sampleCount;
  final String quality; // Excellent (<30), Acceptable (30-40), High (40-50), Excessive (>50)

  const AmbientCalibrationResult({
    required this.avgDb,
    required this.minDb,
    required this.maxDb,
    required this.durationSec,
    required this.sampleCount,
    required this.quality,
  });

  static AmbientCalibrationResult empty() => const AmbientCalibrationResult(
        avgDb: 0.0,
        minDb: 0.0,
        maxDb: 0.0,
        durationSec: 0,
        sampleCount: 0,
        quality: 'Not Calibrated',
      );
}

enum AcousticReportAuditType {
  singlePipeAudit,
  dualPipeComparison,
}

enum AuditScope {
  singlePipe,
  dualPipeComparison,
}

class PipeAuditRecord {
  final PipeAcousticProfile pipe;
  final BracketType bracket;
  final WallType wall;
  final MeasurementPosition position;
  final AcousticMicReading reading;
  final NoiseIsolationResult isolation;
  final double flowRate;

  const PipeAuditRecord({
    required this.pipe,
    required this.bracket,
    required this.wall,
    required this.position,
    required this.reading,
    required this.isolation,
    required this.flowRate,
  });
}

class NoiseIsolationResult {
  final double lTotal;
  final double lBackground;
  final double deltaL;
  final double lCorrected;
  final NoiseConfidence confidence;
  final double kCorrection;
  final bool isReliable;
  final String explanation;

  const NoiseIsolationResult({
    required this.lTotal,
    required this.lBackground,
    required this.deltaL,
    required this.lCorrected,
    required this.confidence,
    required this.kCorrection,
    required this.isReliable,
    required this.explanation,
  });

  static NoiseIsolationResult empty() => const NoiseIsolationResult(
        lTotal: 0.0,
        lBackground: 0.0,
        deltaL: 0.0,
        lCorrected: 0.0,
        confidence: NoiseConfidence.unreliable,
        kCorrection: 0.0,
        isReliable: false,
        explanation: 'No test performed yet',
      );
}

class PipeAcousticProfile {
  final PipeTechnologyType type;
  final String name;
  final String shortName;
  final String materialName;
  final String resonanceDescription;
  final String typicalRangeStr;
  final Color themeColor;
  final double baseStructureBorneDb; // at 0.5 L/s baseline with acoustic clamp on solid masonry
  final double flowFactorScale;
  final double clampSensitivity; // dB added if rigid clamp is used
  final double wallSensitivity; // dB added if lightweight wall is used
  final List<String> keyFeatures;
  final double claimedStructureBorneDb2L; // Claimed or certified dB at 2.0 L/s
  final double claimedAirborneDb2L; // Claimed or certified airborne dB at 2.0 L/s
  final bool hasFraunhoferCert;
  final String certReportNo;

  const PipeAcousticProfile({
    required this.type,
    required this.name,
    required this.shortName,
    required this.materialName,
    required this.resonanceDescription,
    required this.typicalRangeStr,
    required this.themeColor,
    required this.baseStructureBorneDb,
    required this.flowFactorScale,
    required this.clampSensitivity,
    required this.wallSensitivity,
    required this.keyFeatures,
    required this.claimedStructureBorneDb2L,
    required this.claimedAirborneDb2L,
    required this.hasFraunhoferCert,
    required this.certReportNo,
  });

  /// Calculates structure-borne sound pressure level L_sc,A in dB(A)
  /// per EN 14366 & Fraunhofer test regression equations.
  double calculateNoise({
    required double flowRate, // L/s (0.5 to 6.0)
    required BracketType bracket,
    required WallType wall,
  }) {
    // Flow exponent acoustic scaling: 10 * log10(Q / 0.5)
    final double safeFlow = flowRate < 0.5 ? 0.5 : flowRate;
    final double flowFactor = 10 * (math.log(safeFlow / 0.5) / math.ln10);

    // Clamp penalty: Huliot acoustic clamp has elastomer damping
    final double clampDelta = (bracket == BracketType.rigidMetal) ? clampSensitivity : 0.0;

    // Wall penalty: Lightweight wall transmits more vibration to the receiver room
    final double wallDelta = (wall == WallType.lightweightPartition) ? wallSensitivity : 0.0;

    final double rawDb = baseStructureBorneDb + (flowFactor * flowFactorScale) + clampDelta + wallDelta;
    return double.parse(rawDb.clamp(7.0, 52.0).toStringAsFixed(1));
  }

  /// Calculates airborne noise L_a,A in dB(A) in the installation room / shaft
  double calculateAirborneNoise(double flowRate) {
    final double safeFlow = flowRate < 0.5 ? 0.5 : flowRate;
    final double flowFactor = 10 * (math.log(safeFlow / 0.5) / math.ln10);
    switch (type) {
      case PipeTechnologyType.pvc:
        return double.parse((48.0 + flowFactor * 1.1).clamp(45.0, 62.0).toStringAsFixed(1));
      case PipeTechnologyType.hdpe:
        return double.parse((46.0 + flowFactor * 1.05).clamp(43.0, 60.0).toStringAsFixed(1));
      case PipeTechnologyType.castIron:
        return double.parse((44.0 + flowFactor * 0.95).clamp(41.0, 58.0).toStringAsFixed(1));
      case PipeTechnologyType.huliotUltraSilent:
        // Fraunhofer test: 43 dB at 0.5 L/s, 49 dB at 1.0 L/s, 52 dB at 2.0 L/s, 54 dB at 4.0 L/s
        return double.parse((43.0 + flowFactor * 0.98).clamp(40.0, 57.0).toStringAsFixed(1));
      case PipeTechnologyType.astralSilencio:
        return double.parse((44.5 + flowFactor * 1.0).clamp(41.0, 58.0).toStringAsFixed(1));
      case PipeTechnologyType.supremeSkyrise:
        return double.parse((45.0 + flowFactor * 1.02).clamp(42.0, 59.0).toStringAsFixed(1));
      case PipeTechnologyType.princeSilentfit:
        return double.parse((46.0 + flowFactor * 1.04).clamp(43.0, 60.0).toStringAsFixed(1));
      case PipeTechnologyType.customPipe:
        return double.parse((47.0 + flowFactor * 1.05).clamp(40.0, 65.0).toStringAsFixed(1));
    }
  }

  static const List<PipeAcousticProfile> allPipes = [
    PipeAcousticProfile(
      type: PipeTechnologyType.huliotUltraSilent,
      name: 'Huliot Ultra Silent PP-MD',
      shortName: 'Huliot Ultra Silent',
      materialName: 'PP-MD 3-Layer Mineral-Reinforced System',
      resonanceDescription: 'Patented acoustic mass damping (Whisper Quiet)',
      typicalRangeStr: '9 - 15 dB',
      themeColor: Color(0xFF10B981),
      baseStructureBorneDb: 9.2, // Fraunhofer: < 10 dB at 0.5 L/s, 11 dB at 1.0 L/s, 15 dB at 2.0 L/s
      flowFactorScale: 0.72,
      clampSensitivity: 4.5,
      wallSensitivity: 3.8,
      claimedStructureBorneDb2L: 15.0,
      claimedAirborneDb2L: 52.0,
      hasFraunhoferCert: true,
      certReportNo: 'Fraunhofer IBP P-BA 20/2019e & P-BA 155/2023e',
      keyFeatures: [
        'Patented 3-layer co-extrusion technology',
        'Mineral-reinforced PP-MD core dampens sound waves',
        'Ultra-smooth inner PP bore (k = 0.007 mm)',
        'Fraunhofer IBP certified: 15 dB(A) at 2.0 L/s (P-BA 20/2019e)',
      ],
    ),
    PipeAcousticProfile(
      type: PipeTechnologyType.astralSilencio,
      name: 'Astral Silencio PP-MD',
      shortName: 'Astral Silencio',
      materialName: '3-Layer Mineral Reinforced PP',
      resonanceDescription: 'Acoustic PP-MD core (Market Competitor)',
      typicalRangeStr: '16 - 22 dB',
      themeColor: Color(0xFF06B6D4),
      baseStructureBorneDb: 10.5,
      flowFactorScale: 0.78,
      clampSensitivity: 4.8,
      wallSensitivity: 4.0,
      claimedStructureBorneDb2L: 17.0, // Commercial claim claims <10 dB, real-world ~17 dB
      claimedAirborneDb2L: 53.0,
      hasFraunhoferCert: false,
      certReportNo: 'EN 14366 Standard Reference (No Public IBP #)',
      keyFeatures: [
        '3-layer mineral-reinforced polypropylene',
        'Commercial competitor in Indian drainage market',
        'Requires specialized acoustic brackets for low dB',
        'VDI 4100 SSt II standard compliance',
      ],
    ),
    PipeAcousticProfile(
      type: PipeTechnologyType.supremeSkyrise,
      name: 'Supreme Skyrise Hi-Tech',
      shortName: 'Supreme Skyrise',
      materialName: 'Mineral-Reinforced PVC / Hi-Tech SWR',
      resonanceDescription: 'Thickened PVC walls with ribbed fittings',
      typicalRangeStr: '17 - 24 dB',
      themeColor: Color(0xFF8B5CF6),
      baseStructureBorneDb: 11.2,
      flowFactorScale: 0.82,
      clampSensitivity: 5.0,
      wallSensitivity: 4.2,
      claimedStructureBorneDb2L: 17.0,
      claimedAirborneDb2L: 54.0,
      hasFraunhoferCert: false,
      certReportNo: 'Manufacturer Laboratory Test (EN 1329)',
      keyFeatures: [
        'Mineral-modified PVC with increased molecular weight',
        'Ribbed fittings designed to disrupt water swirl noise',
        'Acoustic rubber lined clamps recommended',
        'Claimed 17 dB at 2 L/s, 20 dB at 4 L/s',
      ],
    ),
    PipeAcousticProfile(
      type: PipeTechnologyType.princeSilentfit,
      name: 'Prince Silentfit 3-Layer',
      shortName: 'Prince Silentfit',
      materialName: '3-Layer Acoustic Modified uPVC',
      resonanceDescription: 'uPVC composite with mineral foam core',
      typicalRangeStr: '18 - 25 dB',
      themeColor: Color(0xFFEC4899),
      baseStructureBorneDb: 11.8,
      flowFactorScale: 0.85,
      clampSensitivity: 5.2,
      wallSensitivity: 4.4,
      claimedStructureBorneDb2L: 18.0,
      claimedAirborneDb2L: 55.0,
      hasFraunhoferCert: false,
      certReportNo: 'IS 13592 / EN 14366 (Adequa Tech Collaboration)',
      keyFeatures: [
        '3-layer uPVC system with acoustic modified core',
        'Technology collaboration with Adequa Spain',
        'Solvent-cement and rubber-ring joint variants',
        'Complies with basic DIN 4109 requirement',
      ],
    ),
    PipeAcousticProfile(
      type: PipeTechnologyType.castIron,
      name: 'Traditional Cast Iron SML',
      shortName: 'Cast Iron',
      materialName: 'Cast Iron (Heavy Density Metal)',
      resonanceDescription: 'Heavy mass damping, rigid joint transmission',
      typicalRangeStr: '17 - 21 dB',
      themeColor: Color(0xFF3B82F6),
      baseStructureBorneDb: 15.8,
      flowFactorScale: 0.88,
      clampSensitivity: 4.8,
      wallSensitivity: 4.2,
      claimedStructureBorneDb2L: 21.1,
      claimedAirborneDb2L: 48.0,
      hasFraunhoferCert: false,
      certReportNo: 'Generic Reference Heavy Metal SWR',
      keyFeatures: [
        'High mass density dampens airborne noise',
        'Requires rubber collar couplings to decouple',
        'Vulnerable to long-term corrosion & scale build-up',
        'Heavy labor-intensive handling on site',
      ],
    ),
    PipeAcousticProfile(
      type: PipeTechnologyType.hdpe,
      name: 'Standard HDPE',
      shortName: 'HDPE Mono',
      materialName: 'High-Density Polyethylene (Monolayer)',
      resonanceDescription: 'Standard flexible plastic, moderate vibration',
      typicalRangeStr: '24 - 29 dB',
      themeColor: Color(0xFFF59E0B),
      baseStructureBorneDb: 23.0,
      flowFactorScale: 1.05,
      clampSensitivity: 4.0,
      wallSensitivity: 5.0,
      claimedStructureBorneDb2L: 27.0,
      claimedAirborneDb2L: 50.0,
      hasFraunhoferCert: false,
      certReportNo: 'Standard Single Layer Polyethylene',
      keyFeatures: [
        'Good chemical resistance',
        'Monolayer structure lacks internal damping mass',
        'Moderate acoustic resonance at junction fittings',
        'Borderline DIN 4109 compliance under heavy flush',
      ],
    ),
    PipeAcousticProfile(
      type: PipeTechnologyType.pvc,
      name: 'Standard Thin-Wall PVC',
      shortName: 'PVC-U',
      materialName: 'Unplasticized Polyvinyl Chloride (Single Layer)',
      resonanceDescription: 'High vibration resonance & structural ringing',
      typicalRangeStr: '28 - 34 dB',
      themeColor: Color(0xFFEF4444),
      baseStructureBorneDb: 27.5,
      flowFactorScale: 1.15,
      clampSensitivity: 4.5,
      wallSensitivity: 6.0,
      claimedStructureBorneDb2L: 34.4,
      claimedAirborneDb2L: 54.0,
      hasFraunhoferCert: false,
      certReportNo: 'Standard Single-Layer PVC-U SWR',
      keyFeatures: [
        'Single thin wall (2.2 - 2.8 mm)',
        'Low material density (~1.4 g/cm³)',
        'Prone to acoustic resonance & sound radiation',
        'Fails VDI 4100 luxury threshold at all flow rates',
      ],
    ),
    PipeAcousticProfile(
      type: PipeTechnologyType.customPipe,
      name: 'Custom / Unspecified Pipe',
      shortName: 'Custom Pipe',
      materialName: 'Unverified On-Site Drainage System',
      resonanceDescription: 'Field sample for benchmark testing against Huliot',
      typicalRangeStr: '20 - 32 dB',
      themeColor: Color(0xFF94A3B8),
      baseStructureBorneDb: 22.0,
      flowFactorScale: 1.0,
      clampSensitivity: 4.5,
      wallSensitivity: 5.0,
      claimedStructureBorneDb2L: 25.0,
      claimedAirborneDb2L: 52.0,
      hasFraunhoferCert: false,
      certReportNo: 'Field Sample / Unverified',
      keyFeatures: [
        'Used for client live field testing against Huliot claims',
        'Allows direct comparison under identical site conditions',
        'Evaluated with ISO 16032 ambient isolation',
      ],
    ),
  ];

  static PipeAcousticProfile get huliot =>
      allPipes.firstWhere((p) => p.type == PipeTechnologyType.huliotUltraSilent);
}

/// Official Fraunhofer IBP Test Data Points (Reports P-BA 20/2019e & P-BA 155/2023e)
class FraunhoferTestPoint {
  final double flowRate;
  final double structureBorneDb;
  final String structureBorneDisplay;
  final double airborneDb;
  final double standardClampStructureBorneDb;
  final bool passesDin4109; // <= 30 dB(A)
  final bool passesVdi4100Sst3; // <= 24 dB(A)
  final String acousticComfortRating;

  const FraunhoferTestPoint({
    required this.flowRate,
    required this.structureBorneDb,
    required this.structureBorneDisplay,
    required this.airborneDb,
    required this.standardClampStructureBorneDb,
    required this.passesDin4109,
    required this.passesVdi4100Sst3,
    required this.acousticComfortRating,
  });

  static const List<FraunhoferTestPoint> officialData = [
    FraunhoferTestPoint(
      flowRate: 0.5,
      structureBorneDb: 9.0,
      structureBorneDisplay: '< 10',
      airborneDb: 43.0,
      standardClampStructureBorneDb: 13.0,
      passesDin4109: true,
      passesVdi4100Sst3: true,
      acousticComfortRating: 'Whisper Quiet / Imperceptible',
    ),
    FraunhoferTestPoint(
      flowRate: 1.0,
      structureBorneDb: 11.0,
      structureBorneDisplay: '11',
      airborneDb: 49.0,
      standardClampStructureBorneDb: 16.0,
      passesDin4109: true,
      passesVdi4100Sst3: true,
      acousticComfortRating: 'Luxury Hotel Suite Class',
    ),
    FraunhoferTestPoint(
      flowRate: 2.0,
      structureBorneDb: 15.0,
      structureBorneDisplay: '15',
      airborneDb: 52.0,
      standardClampStructureBorneDb: 19.5,
      passesDin4109: true,
      passesVdi4100Sst3: true,
      acousticComfortRating: 'VDI 4100 SSt III Luxury Compliant',
    ),
    FraunhoferTestPoint(
      flowRate: 4.0,
      structureBorneDb: 20.0,
      structureBorneDisplay: '20',
      airborneDb: 54.0,
      standardClampStructureBorneDb: 25.0,
      passesDin4109: true,
      passesVdi4100Sst3: true,
      acousticComfortRating: 'High Comfort / Far Below 30 dB Limit',
    ),
  ];
}

extension BracketTypeExt on BracketType {
  String get label {
    switch (this) {
      case BracketType.huliotAcoustic:
        return 'Huliot Acoustic Damped Clamp';
      case BracketType.rigidMetal:
        return 'Standard Rigid Metal Clamp';
    }
  }
}

extension WallTypeExt on WallType {
  String get label {
    switch (this) {
      case WallType.solidMasonry:
        return 'Solid Masonry Wall (220 kg/m²)';
      case WallType.lightweightPartition:
        return 'Lightweight Drywall Partition (115 kg/m²)';
    }
  }
}

extension MeasurementPositionExt on MeasurementPosition {
  String get label {
    switch (this) {
      case MeasurementPosition.installationShaft:
        return 'Inside Plumbing Shaft / Duct (Airborne Dominated L_a,A)';
      case MeasurementPosition.receivingRoom:
        return 'Receiver Room Behind Wall (Structure-Borne L_sc,A)';
      case MeasurementPosition.adjacentPipe:
        return 'Room Adjacent to Pipe (1.0m Direct Radiation)';
    }
  }

  String get shortLabel {
    switch (this) {
      case MeasurementPosition.installationShaft:
        return 'Plumbing Shaft (Airborne)';
      case MeasurementPosition.receivingRoom:
        return 'Receiver Room (Structure-Borne)';
      case MeasurementPosition.adjacentPipe:
        return '1m Adjacent (Composite)';
    }
  }

  String get targetMetric {
    switch (this) {
      case MeasurementPosition.installationShaft:
        return 'L_a,A (Airborne)';
      case MeasurementPosition.receivingRoom:
        return 'L_sc,A (Structure-Borne)';
      case MeasurementPosition.adjacentPipe:
        return 'L_Aeq (Direct Radiation)';
    }
  }
}

extension TestingPhaseExt on TestingPhase {
  String get title {
    switch (this) {
      case TestingPhase.setup:
        return 'Step 1: Test Setup';
      case TestingPhase.ambientCalibration:
        return 'Step 2: Ambient Floor Calibration';
      case TestingPhase.flushRecording:
        return 'Step 3: Flush & Sound Capture';
      case TestingPhase.analysis:
        return 'Step 4: ISO 16032 Isolation & Report';
    }
  }
}

extension NoiseConfidenceExt on NoiseConfidence {
  String get label {
    switch (this) {
      case NoiseConfidence.high:
        return 'HIGH CONFIDENCE (ΔL ≥ 10 dB)';
      case NoiseConfidence.medium:
        return 'MEDIUM CONFIDENCE (6 ≤ ΔL < 10 dB)';
      case NoiseConfidence.low:
        return 'LOW CONFIDENCE (3 ≤ ΔL < 6 dB)';
      case NoiseConfidence.unreliable:
        return 'UNRELIABLE / RE-TEST NEEDED (ΔL < 3 dB)';
    }
  }

  Color get color {
    switch (this) {
      case NoiseConfidence.high:
        return const Color(0xFF10B981);
      case NoiseConfidence.medium:
        return const Color(0xFF3B82F6);
      case NoiseConfidence.low:
        return const Color(0xFFF59E0B);
      case NoiseConfidence.unreliable:
        return const Color(0xFFEF4444);
    }
  }
}
