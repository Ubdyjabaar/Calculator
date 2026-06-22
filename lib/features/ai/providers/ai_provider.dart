import 'package:flutter/material.dart';
import '../../../services/ai_service.dart';
import '../../../core/config/ai_config.dart';

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

    try {
      final reply = await AIService.solveMathProblem(text.trim());
      _loading = false;
      addMessage(AIMessage(role: 'model', text: reply));
    } catch (e) {
      _loading = false;
      notifyListeners();
      final errMsg = await AIConfig.getMessage('connection_error');
      addMessage(AIMessage(role: 'model', text: errMsg.isNotEmpty ? errMsg : 'Connection error. Please check your internet and try again.'));
    }
  }

  Future<void> sendMessageWithImage(String text, String imagePath) async {
    final msg = text.trim();
    final displayText = msg.isNotEmpty ? '$msg\n[Image scanned]' : '[Image scanned]';
    addMessage(AIMessage(role: 'user', text: displayText));
    _loading = true;
    notifyListeners();

    try {
      final reply = await AIService.solveMathProblem(msg);
      _loading = false;
      addMessage(AIMessage(role: 'model', text: reply));
    } catch (e) {
      _loading = false;
      notifyListeners();
      final errMsg = await AIConfig.getMessage('connection_error');
      addMessage(AIMessage(role: 'model', text: errMsg.isNotEmpty ? errMsg : 'Connection error. Please check your internet and try again.'));
    }
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}
