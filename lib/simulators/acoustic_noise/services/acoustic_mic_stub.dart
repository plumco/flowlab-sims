import 'acoustic_mic_service.dart';

AcousticMicService createAcousticMicService() => AcousticMicServiceStub();

class AcousticMicServiceStub implements AcousticMicService {
  bool _isActive = false;

  @override
  Future<bool> start() async {
    _isActive = true;
    return true;
  }

  @override
  void stop() {
    _isActive = false;
  }

  @override
  AcousticMicReading getReading() {
    return AcousticMicReading(
      isActive: _isActive,
      permissionState: 'granted',
      errorMsg: '',
      currentDb: _isActive ? 18.5 : 0.0,
      minDb: _isActive ? 12.0 : 0.0,
      maxDb: _isActive ? 22.0 : 0.0,
      avgDb: _isActive ? 16.5 : 0.0,
      durationSec: _isActive ? 10 : 0,
      sampleCount: _isActive ? 50 : 0,
    );
  }
}
