import 'acoustic_mic_stub.dart'
    if (dart.library.js_interop) 'acoustic_mic_web.dart';

class AcousticMicReading {
  final bool isActive;
  final String permissionState; // 'prompt' | 'granted' | 'denied'
  final String errorMsg;
  final double currentDb;
  final double minDb;
  final double maxDb;
  final double avgDb;
  final int durationSec;
  final int sampleCount;

  const AcousticMicReading({
    required this.isActive,
    required this.permissionState,
    required this.errorMsg,
    required this.currentDb,
    required this.minDb,
    required this.maxDb,
    required this.avgDb,
    required this.durationSec,
    required this.sampleCount,
  });

  factory AcousticMicReading.empty() {
    return const AcousticMicReading(
      isActive: false,
      permissionState: 'prompt',
      errorMsg: '',
      currentDb: 0.0,
      minDb: 0.0,
      maxDb: 0.0,
      avgDb: 0.0,
      durationSec: 0,
      sampleCount: 0,
    );
  }
}

abstract class AcousticMicService {
  static AcousticMicService create() => createAcousticMicService();

  Future<bool> start();
  void stop();
  AcousticMicReading getReading();
}
