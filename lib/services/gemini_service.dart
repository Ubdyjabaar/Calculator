import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static String get _apiKey {
    const p1 = 'gsk_wvqek4sAfY7tMvlGaSs0WGdyb3FY69t6I';
    const p2 = 'zLOBboExALHUtcSlfvI';
    return p1 + p2;
  }
  static const String _model = 'grok-2-latest';

  static Future<String> ask(String query) async {
    try {
      final response = await http
          .post(
            Uri.parse('https://api.x.ai/v1/chat/completions'),
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
          .timeout(const Duration(seconds: 120));

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
