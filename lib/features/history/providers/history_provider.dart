import 'package:flutter/material.dart';
import '../../../core/database/history_database.dart';

class HistoryProvider extends ChangeNotifier {
  List<HistoryEntry> _entries = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<HistoryEntry> get entries =>
      _searchQuery.isEmpty ? _entries : _filteredEntries;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  bool get isEmpty => _entries.isEmpty;

  List<HistoryEntry> get _filteredEntries => _entries
      .where((e) =>
          e.expression.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.result.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      _entries = await HistoryDatabase.getAll();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEntry(String expression, String result) async {
    final entry = HistoryEntry(
      expression: expression,
      result: result,
      timestamp: DateTime.now(),
    );
    try {
      await HistoryDatabase.insert(entry);
      _entries.insert(0, entry);
      if (_entries.length > 500) _entries.removeLast();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> deleteEntry(int id, int index) async {
    try {
      await HistoryDatabase.delete(id);
      _entries.removeAt(index);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      await HistoryDatabase.clearAll();
      _entries.clear();
      notifyListeners();
    } catch (_) {}
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
