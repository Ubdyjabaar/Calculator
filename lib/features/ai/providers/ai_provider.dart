import 'package:flutter/material.dart';
import '../../../services/ai_service.dart';

class AIMessage {
  final String role;
  final String text;
  final DateTime timestamp;

  AIMessage({required this.role, required this.text, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
  bool get isAi => role == 'model';
}

class AIProvider extends ChangeNotifier {
  List<AIMessage> _messages = [];
  bool _loading = false;

  List<AIMessage> get messages => _messages;
  bool get loading => _loading;

  void addMessage(AIMessage msg) {
    _messages.add(msg);
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    addMessage(AIMessage(role: 'user', text: text.trim()));
    _loading = true;
    notifyListeners();

    final reply = await AIService.solveMathProblem(text.trim());

    _loading = false;
    addMessage(AIMessage(role: 'model', text: reply));
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}
