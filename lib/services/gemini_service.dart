import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/ai_config.dart';

class GeminiService {
  static const String _model = 'gemini-2.0-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  static String get _hardcodedKey {
    const p1 = 'AQ.Ab8RN6LiUO088nKF6JJCsNvYJn_Vd-rYTDi0Wa0';
    const p2 = '8YrUaQMpFFQ';
    return p1 + p2;
  }

  static Future<String> ask(String query) async {
    final remoteKey = await AIConfig.getGeminiApiKey();
    final apiKey = remoteKey.isNotEmpty ? remoteKey : _hardcodedKey;

    final url = '$_baseUrl?key=$apiKey';

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {
                      'text':
                          'You are a math tutor. Solve the math problem and explain step by step. '
                              'Show each step clearly. For equations, show how to rearrange, '
                              'apply formulas, and find the answer. Be concise but thorough.\n\n'
                              'Problem: $query'
                    }
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.2,
                'maxOutputTokens': 2048,
                'topP': 0.9,
              },
              'safetySettings': [
                {
                  'category': 'HARM_CATEGORY_HARASSMENT',
                  'threshold': 'BLOCK_NONE'
                },
                {
                  'category': 'HARM_CATEGORY_HATE_SPEECH',
                  'threshold': 'BLOCK_NONE'
                },
                {
                  'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
                  'threshold': 'BLOCK_NONE'
                },
                {
                  'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
                  'threshold': 'BLOCK_NONE'
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            if (text != null && text.isNotEmpty) {
              return text.trim();
            }
          }
        }
        return 'Gemini returned an empty response. Try rephrasing.';
      }

      final body = response.body;
      try {
        final err = jsonDecode(body);
        final msg = err['error']?['message'] ?? 'HTTP ${response.statusCode}';
        return 'Gemini Error: $msg';
      } catch (_) {
        return 'Gemini Error: HTTP ${response.statusCode}';
      }
    } catch (e) {
      return 'Connection error: $e';
    }
  }
}
