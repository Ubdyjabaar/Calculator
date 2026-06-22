import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/ai_config.dart';
import 'gemini_service.dart';

class AIService {
  static Future<String> solveMathProblem(String query) async {
    await AIConfig.getKeywords('help');

    final trimmed = query.trim();
    if (trimmed.isEmpty) return await AIConfig.getMessage('empty');

    final lower = trimmed.toLowerCase();

    if (_matchesSimple(lower, ['help', 'what can you do', 'commands', 'suggestions'])) {
      return await AIConfig.getMessage('help');
    }

    return await GeminiService.ask(trimmed);
  }

  static bool _matchesSimple(String lower, List<String> keywords) {
    return keywords.any((k) => lower.contains(k));
  }

  static String _cleanExpr(String s) {
    return s
        .replaceAll(RegExp(r'^[,\s.:;!?]+'), '')
        .replaceAll(RegExp(r'[,\s.:;!?]+$'), '')
        .trim();
  }
}
