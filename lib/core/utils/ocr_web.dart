// ignore_for_file: deprecated_member_use
import 'dart:html' as html;
import 'dart:js_util' as js_util;

class OcrService {
  Future<String> extractText(String path) async {
    try {
      final tesseract = js_util.getProperty(html.window, 'Tesseract');
      if (tesseract == null) return '';

      final promise = js_util.callMethod(tesseract, 'recognize', [path, 'eng']);
      final result = await js_util.promiseToFuture(promise);
      final data = js_util.getProperty(result, 'data');
      final text = js_util.getProperty(data, 'text') as String? ?? '';
      return text;
    } catch (_) {}
    return '';
  }

  void dispose() {}
}
