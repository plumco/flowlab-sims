import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

void openSimulatorUrl(String url) {
  if (kIsWeb) {
    try {
      web.window.location.href = url;
    } catch (_) {
      web.window.open(url, '_self');
    }
  }
}
