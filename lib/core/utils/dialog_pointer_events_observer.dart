import 'dart:math';
import 'package:flutter/material.dart';
import '../../widgets/visualizer/web_cad_view.dart';

class DialogPointerEventsObserver extends NavigatorObserver {
  int _modalCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PopupRoute || route is DialogRoute || route is ModalBottomSheetRoute) {
      _modalCount++;
      setIframePointerEvents(false);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is PopupRoute || route is DialogRoute || route is ModalBottomSheetRoute) {
      _modalCount = max(0, _modalCount - 1);
      if (_modalCount == 0) {
        setIframePointerEvents(true);
      }
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (route is PopupRoute || route is DialogRoute || route is ModalBottomSheetRoute) {
      _modalCount = max(0, _modalCount - 1);
      if (_modalCount == 0) {
        setIframePointerEvents(true);
      }
    }
  }
}
