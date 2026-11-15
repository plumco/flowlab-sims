import 'dart:math' as math;
import '../models/acoustic_models.dart';

class NoiseIsolationService {
  /// Evaluates ambient noise level quality for on-site testing.
  static String evaluateAmbientQuality(double avgDb) {
    if (avgDb < 30.0) {
      return 'Excellent (Studio Quiet)';
    } else if (avgDb <= 40.0) {
      return 'Acceptable (Standard Indoor Floor)';
    } else if (avgDb <= 50.0) {
      return 'High Noise (May Impair Low dB Accuracy)';
    } else {
      return 'Excessive Background Noise (Site Active)';
    }
  }

  /// Calculates ISO 16032 background noise correction:
  /// L_corrected = 10 * log10(10^(L_total / 10) - 10^(L_background / 10))
  static NoiseIsolationResult isolatePipeNoise({
    required double lTotal,
    required double lBackground,
  }) {
    if (lTotal <= 0.0 || lBackground <= 0.0) {
      return NoiseIsolationResult.empty();
    }

    final double deltaL = lTotal - lBackground;

    // Case 1: Total noise is less than or nearly equal to background (ΔL < 3 dB)
    if (deltaL < 3.0) {
      return NoiseIsolationResult(
        lTotal: double.parse(lTotal.toStringAsFixed(1)),
        lBackground: double.parse(lBackground.toStringAsFixed(1)),
        deltaL: double.parse(deltaL.toStringAsFixed(1)),
        lCorrected: double.parse(lTotal.toStringAsFixed(1)),
        confidence: NoiseConfidence.unreliable,
        kCorrection: 0.0,
        isReliable: false,
        explanation:
            'Background noise is too high (ΔL = ${deltaL.toStringAsFixed(1)} dB < 3 dB). Per ISO 16032, pipe noise cannot be accurately separated from ambient site noise. Re-test during quieter hours or close duct doors.',
      );
    }

    // Energy subtraction
    final double powerTotal = math.pow(10.0, lTotal / 10.0).toDouble();
    final double powerBg = math.pow(10.0, lBackground / 10.0).toDouble();
    final double diffPower = powerTotal - powerBg;

    if (diffPower <= 0.0) {
      return NoiseIsolationResult(
        lTotal: lTotal,
        lBackground: lBackground,
        deltaL: deltaL,
        lCorrected: lTotal,
        confidence: NoiseConfidence.unreliable,
        kCorrection: 0.0,
        isReliable: false,
        explanation: 'Invalid acoustic measurement: Total energy below ambient baseline.',
      );
    }

    final double rawCorrected = 10.0 * (math.log(diffPower) / math.ln10);
    final double lCorrected = double.parse(rawCorrected.toStringAsFixed(1));
    final double kCorrection = double.parse((lTotal - lCorrected).toStringAsFixed(1));

    if (deltaL >= 10.0) {
      return NoiseIsolationResult(
        lTotal: double.parse(lTotal.toStringAsFixed(1)),
        lBackground: double.parse(lBackground.toStringAsFixed(1)),
        deltaL: double.parse(deltaL.toStringAsFixed(1)),
        lCorrected: lCorrected,
        confidence: NoiseConfidence.high,
        kCorrection: kCorrection,
        isReliable: true,
        explanation:
            'High acoustic confidence (ΔL = ${deltaL.toStringAsFixed(1)} dB ≥ 10 dB). Background contribution is negligible (< 0.5 dB error per ISO 16032).',
      );
    } else if (deltaL >= 6.0) {
      return NoiseIsolationResult(
        lTotal: double.parse(lTotal.toStringAsFixed(1)),
        lBackground: double.parse(lBackground.toStringAsFixed(1)),
        deltaL: double.parse(deltaL.toStringAsFixed(1)),
        lCorrected: lCorrected,
        confidence: NoiseConfidence.medium,
        kCorrection: kCorrection,
        isReliable: true,
        explanation:
            'Good acoustic confidence (6 dB ≤ ΔL < 10 dB). ISO 16032 correction formula applied successfully (subtracted $kCorrection dB background influence).',
      );
    } else {
      // 3.0 <= deltaL < 6.0
      return NoiseIsolationResult(
        lTotal: double.parse(lTotal.toStringAsFixed(1)),
        lBackground: double.parse(lBackground.toStringAsFixed(1)),
        deltaL: double.parse(deltaL.toStringAsFixed(1)),
        lCorrected: lCorrected,
        confidence: NoiseConfidence.low,
        kCorrection: kCorrection,
        isReliable: true,
        explanation:
            'Moderate acoustic confidence (3 dB ≤ ΔL < 6 dB). Significant background presence; result reported with ±1.5 dB tolerance.',
      );
    }
  }

  /// Evaluates compliance against DIN 4109 (<=30 dB) and VDI 4100 SSt III (<=24 dB)
  static bool passesDin4109(double db) => db <= 30.0;
  static bool passesVdi4100Luxury(double db) => db <= 24.0;
}
