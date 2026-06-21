import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static Future<String> solveMathProblem(String query, String apiKey) async {
    if (apiKey.isEmpty) return 'Please set your API key in settings first.';

    final prompt = '''
You are a math tutor. Solve the user's math problem step-by-step.
Explain each step clearly with proper mathematical notation.
If the user types an equation, solve it and show the solution steps.
If the user asks a conceptual question, explain it thoroughly.
Keep responses concise but complete.

User's problem: $query
''';

    try {
      final uri = Uri.parse('$_baseUrl?key=$apiKey');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.4,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']['parts'] as List;
          if (parts.isNotEmpty) {
            return parts[0]['text'] as String;
          }
        }
        return 'No response from AI.';
      } else if (response.statusCode == 403 || response.statusCode == 400) {
        final data = jsonDecode(response.body);
        final msg = data['error']?['message'] ?? 'Invalid API key or request.';
        return 'Error: $msg';
      } else {
        return 'Error: HTTP ${response.statusCode}';
      }
    } catch (e) {
      return 'Network error: ${e.toString()}';
    }
  }
}
