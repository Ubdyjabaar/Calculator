import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _r = TextRecognizer();

  Future<String> extractText(String path) async {
    final img = InputImage.fromFilePath(path);
    final result = await _r.processImage(img);
    return result.text;
  }

  void dispose() => _r.close();
}
