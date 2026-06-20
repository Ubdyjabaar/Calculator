import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';

class HistoryEntry {
  final int? id;
  final String expression;
  final String result;
  final DateTime timestamp;

  HistoryEntry({
    this.id,
    required this.expression,
    required this.result,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'expression': expression,
        'result': result,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HistoryEntry.fromMap(Map<String, dynamic> map) => HistoryEntry(
        id: map['id'] as int?,
        expression: map['expression'] as String,
        result: map['result'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
      );
}

class HistoryDatabase {
  static Database? _database;
  static const _prefsKey = 'calculator_history';

  static Future<Database> get _nativeDb async {
    if (_database != null) return _database!;
    final path = join(await getDatabasesPath(), AppConstants.dbName);
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${AppConstants.historyTable}(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            expression TEXT NOT NULL,
            result TEXT NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_history_timestamp
          ON ${AppConstants.historyTable}(timestamp DESC)
        ''');
      },
    );
    return _database!;
  }

  static Future<List<HistoryEntry>> getAll({String? searchQuery}) async {
    if (kIsWeb) {
      return _webGetAll(searchQuery: searchQuery);
    }
    final db = await _nativeDb;
    final maps = searchQuery != null && searchQuery.isNotEmpty
        ? await db.query(
            AppConstants.historyTable,
            where: 'expression LIKE ? OR result LIKE ?',
            whereArgs: ['%$searchQuery%', '%$searchQuery%'],
            orderBy: 'timestamp DESC',
          )
        : await db.query(
            AppConstants.historyTable,
            orderBy: 'timestamp DESC',
          );
    return maps.map((m) => HistoryEntry.fromMap(m)).toList();
  }

  static Future<void> insert(HistoryEntry entry) async {
    if (kIsWeb) {
      return _webInsert(entry);
    }
    final db = await _nativeDb;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
          'SELECT COUNT(*) FROM ${AppConstants.historyTable}'),
    );
    if (count != null && count >= AppConstants.maxHistoryItems) {
      await db.delete(
        AppConstants.historyTable,
        where:
            'id = (SELECT id FROM ${AppConstants.historyTable} ORDER BY timestamp ASC LIMIT 1)',
      );
    }
    await db.insert(AppConstants.historyTable, entry.toMap());
  }

  static Future<void> delete(int id) async {
    if (kIsWeb) {
      return _webDelete(id);
    }
    final db = await _nativeDb;
    await db.delete(AppConstants.historyTable,
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearAll() async {
    if (kIsWeb) {
      return _webClearAll();
    }
    final db = await _nativeDb;
    await db.delete(AppConstants.historyTable);
  }

  static Future<List<HistoryEntry>> _webGetAll(
      {String? searchQuery}) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefsKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List<dynamic>;
    var entries = list
        .map((e) => HistoryEntry.fromMap(e as Map<String, dynamic>))
        .toList();
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      entries = entries
          .where((e) =>
              e.expression.toLowerCase().contains(q) ||
              e.result.toLowerCase().contains(q))
          .toList();
    }
    return entries;
  }

  static Future<void> _webInsert(HistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefsKey);
    final list = data != null
        ? (jsonDecode(data) as List<dynamic>).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    final maxId = list.fold<int>(0, (p, e) => (e['id'] as int? ?? 0) > p ? (e['id'] as int) : p);
    final newEntry = entry.toMap();
    newEntry['id'] = maxId + 1;
    list.insert(0, newEntry);
    if (list.length > AppConstants.maxHistoryItems) {
      list.removeLast();
    }
    await prefs.setString(_prefsKey, jsonEncode(list));
  }

  static Future<void> _webDelete(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefsKey);
    if (data == null) return;
    final list = (jsonDecode(data) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((e) => (e['id'] as int) != id)
        .toList();
    await prefs.setString(_prefsKey, jsonEncode(list));
  }

  static Future<void> _webClearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
