import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

class AIConfig {
  static Map<String, dynamic>? _config;
  static int _lastFetchMs = 0;
  static const int _cacheDurationMs = 3600000;

  static Future<Map<String, dynamic>> _load() async {
    if (_config != null && DateTime.now().millisecondsSinceEpoch - _lastFetchMs < _cacheDurationMs) {
      return _config!;
    }

    try {
      final response = await http
          .get(Uri.parse('https://ubdyjabaar.github.io/Calculator/ai/ai_rules.json'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        _config = jsonDecode(response.body) as Map<String, dynamic>;
        _lastFetchMs = DateTime.now().millisecondsSinceEpoch;
        return _config!;
      }
    } catch (_) {}

    final local = await rootBundle.loadString('assets/config/ai_rules.json');
    _config = jsonDecode(local) as Map<String, dynamic>;
    _lastFetchMs = DateTime.now().millisecondsSinceEpoch;
    return _config!;
  }

  static Future<List<String>> getKeywords(String key) async {
    final cfg = await _load();
    final list = (cfg['keywords']?[key] as List<dynamic>?)?.cast<String>();
    return list ?? [];
  }

  static Future<String> getMessage(String key) async {
    final cfg = await _load();
    return (cfg['messages']?[key] as String?) ?? '';
  }

  static Future<String> getApiUrl() async {
    final cfg = await _load();
    return (cfg['api']?['mathjs_url'] as String?) ?? 'http://api.mathjs.org/v4/';
  }

  static Future<String> getGeminiApiKey() async {
    final cfg = await _load();
    final key = cfg['gemini_api_key'] as String?;
    if (key != null && key.isNotEmpty && key != 'YOUR_GEMINI_API_KEY_HERE') {
      return key;
    }
    return '';
  }
}
