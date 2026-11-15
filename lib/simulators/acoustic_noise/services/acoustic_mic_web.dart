import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'acoustic_mic_service.dart';

AcousticMicService createAcousticMicService() => AcousticMicServiceWeb();

@JS('window')
external JSObject get _window;

class AcousticMicServiceWeb implements AcousticMicService {
  JSObject? get _micObj {
    try {
      final prop = _window.getProperty('__huliotAcousticMic'.toJS);
      if (prop != null && !prop.isUndefined && !prop.isNull) {
        return prop as JSObject;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<bool> start() async {
    try {
      final obj = _micObj;
      if (obj == null) return false;
      final JSPromise? promise = obj.callMethod('start'.toJS);
      if (promise != null) {
        final res = await promise.toDart;
        return (res as JSBoolean).toDart;
      }
    } catch (e) {
      // Error handling
    }
    return false;
  }

  @override
  void stop() {
    try {
      final obj = _micObj;
      obj?.callMethod('stop'.toJS);
    } catch (_) {}
  }

  @override
  AcousticMicReading getReading() {
    try {
      final obj = _micObj;
      if (obj != null) {
        final JSString? jsonStr = obj.callMethod('getReading'.toJS);
        if (jsonStr != null) {
          final Map<String, dynamic> data = jsonDecode(jsonStr.toDart) as Map<String, dynamic>;
          return AcousticMicReading(
            isActive: data['isActive'] == true,
            permissionState: data['permissionState']?.toString() ?? 'prompt',
            errorMsg: data['errorMsg']?.toString() ?? '',
            currentDb: (data['currentDb'] as num?)?.toDouble() ?? 0.0,
            minDb: (data['minDb'] as num?)?.toDouble() ?? 0.0,
            maxDb: (data['maxDb'] as num?)?.toDouble() ?? 0.0,
            avgDb: (data['avgDb'] as num?)?.toDouble() ?? 0.0,
            durationSec: (data['durationSec'] as num?)?.toInt() ?? 0,
            sampleCount: (data['sampleCount'] as num?)?.toInt() ?? 0,
          );
        }
      }
    } catch (_) {}
    return AcousticMicReading.empty();
  }
}
