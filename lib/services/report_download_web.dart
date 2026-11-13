import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

void downloadPdfFile(Uint8List bytes, String filename) {
  final jsArray = bytes.map((b) => b.toJS).toList().toJS;
  final blob = web.Blob([jsArray].toJS, web.BlobPropertyBag(type: 'application/pdf'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  Future.delayed(const Duration(seconds: 45), () {
    web.URL.revokeObjectURL(url);
  });
}

void openPrintableHtmlReport(String htmlContent) {
  try {
    final newTab = web.window.open('', '_blank');
    if (newTab != null) {
      newTab.document.open();
      newTab.document.write(htmlContent.toJS);
      newTab.document.close();
    } else {
      // Fallback: download directly if window.open was blocked by browser
      downloadReportHtmlFile(htmlContent, 'Huliot_FlowLab_Engineering_Report.html');
    }
  } catch (_) {
    downloadReportHtmlFile(htmlContent, 'Huliot_FlowLab_Engineering_Report.html');
  }
}

void downloadReportHtmlFile(String htmlContent, String filename) {
  try {
    final blob = web.Blob([htmlContent.toJS].toJS, web.BlobPropertyBag(type: 'text/html;charset=utf-8'));
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = filename;
    anchor.setAttribute('download', filename);
    anchor.style.position = 'fixed';
    anchor.style.left = '-9999px';
    anchor.style.top = '-9999px';
    web.document.body?.appendChild(anchor);
    anchor.click();
    Future.delayed(const Duration(milliseconds: 2500), () {
      anchor.remove();
      web.URL.revokeObjectURL(url);
    });
  } catch (e) {
    // Secondary fallback using data URI
    try {
      final encodedUri = 'data:text/html;charset=utf-8,${Uri.encodeComponent(htmlContent)}';
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
      anchor.href = encodedUri;
      anchor.download = filename;
      anchor.setAttribute('download', filename);
      web.document.body?.appendChild(anchor);
      anchor.click();
      Future.delayed(const Duration(milliseconds: 1000), () {
        anchor.remove();
      });
    } catch (_) {}
  }
}
