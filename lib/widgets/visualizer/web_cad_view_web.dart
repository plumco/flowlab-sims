import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredViews = {};
String? _lastJsonParams;

Widget buildCadPlatformView({required String src, required String viewId}) {
  if (!_registeredViews.contains(viewId)) {
    _registeredViews.add(viewId);
    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int id) {
        final iframe = web.HTMLIFrameElement();
        iframe.src = src;
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';

        iframe.onload = (web.Event e) {
          if (_lastJsonParams != null) {
            try {
              iframe.contentWindow?.postMessage(_lastJsonParams!.toJS, '*'.toJS);
            } catch (_) {}
          }
        }.toJS;

        // Listen for messages from iframe (e.g. onFlushAll, toggleMorningRush, onFlush)
        web.window.addEventListener('message', (web.MessageEvent event) {
          try {
            // Let the global bus notify listeners if needed
          } catch (_) {}
        }.toJS);

        return iframe;
      },
    );
  }

  return HtmlElementView(viewType: viewId);
}

void setIframePointerEvents(bool enabled) {
  try {
    final value = enabled ? 'auto' : 'none';
    final iframes = web.document.querySelectorAll('iframe');
    for (int i = 0; i < iframes.length; i++) {
      final iframe = iframes.item(i) as web.HTMLElement?;
      iframe?.style.pointerEvents = value;
    }
    final platformViews = web.document.querySelectorAll('flt-platform-view');
    for (int i = 0; i < platformViews.length; i++) {
      final pv = platformViews.item(i) as web.HTMLElement?;
      pv?.style.pointerEvents = value;
    }
  } catch (_) {}
}

void postMessageToCadView(Map<String, dynamic> data) {
  try {
    final String jsonStr = jsonEncode(data);
    _lastJsonParams = jsonStr;

    // 1. Safe JS Interop: only set __HULIOT_PARAMS__ when syncing actual parameters, not transient actions
    if (data['action'] == 'syncParams') {
      try {
        web.window.setProperty('__HULIOT_PARAMS__'.toJS, jsonStr.toJS);
        if (web.window.has('__huliotDispatchParams')) {
          web.window.callMethod('__huliotDispatchParams'.toJS, jsonStr.toJS);
        }
      } catch (_) {}
    }

    // 2. Query all iframes and post message directly as fallback
    final iframes = web.document.querySelectorAll('iframe');
    for (int i = 0; i < iframes.length; i++) {
      final iframe = iframes.item(i) as web.HTMLIFrameElement?;
      if (iframe != null && iframe.contentWindow != null) {
        try {
          iframe.contentWindow!.postMessage(jsonStr.toJS, '*'.toJS);
        } catch (_) {}
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('postMessageToCadView error: $e');
    }
  }
}
