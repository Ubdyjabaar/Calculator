import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static String get _apiKey {
    const p1 = 'sk-or-v1-8f222c9d7104bddc065eb7ada450df1f';
    const p2 = 'bf4b1094bfc424bbe000237ffddb988c';
    return p1 + p2;
  }
  static const String _model = 'deepseek/deepseek-r1';

  static Future<String> ask(String query) async {
    try {
      final response = await http
          .post(
            Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are a math tutor. Solve step by step. Show formulas used. '
                          'Explain each step. Provide the final answer clearly.'
                },
                {'role': 'user', 'content': query},
              ],
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content'] as String?;
        if (text != null && text.isNotEmpty) {
          return text.trim();
        }
        return 'Empty response. Try rephrasing.';
      }

      final body = response.body;
      try {
        final err = jsonDecode(body);
        final msg = err['error']?['message'] ?? 'HTTP ${response.statusCode}';
        return 'Error: $msg';
      } catch (_) {
        return 'Error: HTTP ${response.statusCode}';
      }
    } catch (e) {
      return 'Connection error: $e';
    }
  }
}
