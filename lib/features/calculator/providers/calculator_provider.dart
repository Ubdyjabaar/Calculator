import 'package:flutter/material.dart';
import '../../../core/utils/expression_parser.dart';
import '../../history/providers/history_provider.dart';

enum CalculatorMode { standard, scientific, graphing, converter }

class CalculatorProvider extends ChangeNotifier {
  CalculatorMode _mode = CalculatorMode.standard;
  String _expression = '';
  String _result = '0';
  String _previousExpression = '';
  bool _degreesMode = false;
  bool _hasResult = false;
  String _graphFunction = 'sin(x)';
  int _precision = 10;
  int _cursorIndex = 0;
  HistoryProvider? _historyProvider;

  CalculatorMode get mode => _mode;
  String get expression => _expression;
  String get result => _result;
  String get previousExpression => _previousExpression;
  bool get degreesMode => _degreesMode;
  bool get hasResult => _hasResult;
  String get graphFunction => _graphFunction;
  int get cursorIndex => _cursorIndex;

  void setHistoryProvider(HistoryProvider provider) {
    _historyProvider = provider;
  }

  void setPrecision(int precision) {
    _precision = precision;
  }

  void setMode(CalculatorMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void toggleDegrees() {
    _degreesMode = !_degreesMode;
    notifyListeners();
  }

  void setGraphFunction(String function) {
    _graphFunction = function;
    notifyListeners();
  }

  void setCursorPosition(int index) {
    if (index >= 0 && index <= _expression.length) {
      _cursorIndex = index;
      notifyListeners();
    }
  }

  void moveCursorLeft() {
    if (_cursorIndex > 0) {
      _cursorIndex--;
      notifyListeners();
    }
  }

  void moveCursorRight() {
    if (_cursorIndex < _expression.length) {
      _cursorIndex++;
      notifyListeners();
    }
  }

  void inputNumber(String number) {
    if (_hasResult) {
      _expression = '';
      _result = '0';
      _hasResult = false;
      _cursorIndex = 0;
    }
    if (_expression.replaceAll(RegExp(r'[^0-9]'), '').length >= 15) return;
    _expression = _expression.substring(0, _cursorIndex) +
        number +
        _expression.substring(_cursorIndex);
    _cursorIndex++;
    notifyListeners();
  }

  void inputOperator(String op) {
    if (_hasResult && _expression.isEmpty) {
      _hasResult = false;
    }
    if (_expression.isEmpty && op == '-') {
      _expression = '-';
      _cursorIndex = 1;
    } else {
      final before = _expression.substring(0, _cursorIndex);
      final after = _expression.substring(_cursorIndex);
      if (before.isNotEmpty && '+-×÷^'.contains(before[before.length - 1])) {
        _expression = before.substring(0, before.length - 1) + op + after;
      } else {
        _expression = before + op + after;
        _cursorIndex++;
      }
    }
    notifyListeners();
  }

  void inputFunction(String func) {
    if (_hasResult) {
      _expression = '';
      _result = '0';
      _hasResult = false;
      _cursorIndex = 0;
    }
    final before = _expression.substring(0, _cursorIndex);
    final after = _expression.substring(_cursorIndex);
    if (func == 'π') {
      _expression = before + 'π' + after;
      _cursorIndex++;
    } else if (func == 'e') {
      _expression = before + 'e' + after;
      _cursorIndex++;
    } else {
      _expression = before + '$func(' + after;
      _cursorIndex += func.length + 1;
    }
    notifyListeners();
  }

  void inputDecimal() {
    if (_hasResult) {
      _expression = '0.';
      _result = '0';
      _hasResult = false;
      _cursorIndex = 2;
      notifyListeners();
      return;
    }
    final before = _expression.substring(0, _cursorIndex);
    final parts = before.split(RegExp(r'[+\-×÷^()]'));
    if (parts.isNotEmpty && !parts.last.contains('.')) {
      _expression =
          before + '.' + _expression.substring(_cursorIndex);
      _cursorIndex++;
      notifyListeners();
    }
  }

  void inputLeftParen() {
    if (_hasResult) {
      _expression = '';
      _result = '0';
      _hasResult = false;
      _cursorIndex = 0;
    }
    final before = _expression.substring(0, _cursorIndex);
    final after = _expression.substring(_cursorIndex);
    _expression = before + '(' + after;
    _cursorIndex++;
    notifyListeners();
  }

  void inputRightParen() {
    final before = _expression.substring(0, _cursorIndex);
    final after = _expression.substring(_cursorIndex);
    _expression = before + ')' + after;
    _cursorIndex++;
    notifyListeners();
  }

  void clear() {
    _expression = '';
    _result = '0';
    _previousExpression = '';
    _hasResult = false;
    _cursorIndex = 0;
    notifyListeners();
  }

  void backspace() {
    if (_hasResult) {
      _expression = '';
      _result = '0';
      _hasResult = false;
      _cursorIndex = 0;
      notifyListeners();
      return;
    }
    if (_cursorIndex > 0) {
      _expression = _expression.substring(0, _cursorIndex - 1) +
          _expression.substring(_cursorIndex);
      _cursorIndex--;
      notifyListeners();
    }
  }

  void toggleSign() {
    if (_hasResult) {
      final current = _result;
      _result = current.startsWith('-') ? current.substring(1) : '-$current';
      notifyListeners();
      return;
    }
    if (_expression.isEmpty) {
      _expression = '-';
      _cursorIndex = 1;
    } else {
      final lastNum = RegExp(r'-?\d+(\.\d+)?$');
      final match = lastNum.stringMatch(_expression);
      if (match != null) {
        final before = _expression.substring(0, _expression.length - match.length);
        final toggled = match.startsWith('-') ? match.substring(1) : '-$match';
        _expression = before + toggled;
        _cursorIndex = _expression.length;
      } else {
        _expression = '-$_expression';
        _cursorIndex = _expression.length;
      }
    }
    notifyListeners();
  }

  void percent() {
    try {
      final value =
          ExpressionParser.evaluate(_expression, degrees: _degreesMode);
      final result = value / 100;
      _previousExpression = _expression;
      _expression = '';
      _result = _formatResult(result);
      _hasResult = true;
      _cursorIndex = 0;
      _historyProvider?.addEntry('$_previousExpression%', _result);
      notifyListeners();
    } catch (e) {
      _result = 'Error';
      _hasResult = true;
      notifyListeners();
    }
  }

  void calculate() {
    if (_expression.isEmpty) return;
    try {
      _previousExpression = _expression;
      final hasEq = _expression.contains('=');
      if (hasEq) {
        final eqParts = _expression.split('=');
        if (eqParts.length == 2) {
          String? varName;
          for (final ch in _expression.split('')) {
            if (RegExp(r'[a-zA-Z]').hasMatch(ch) && ch != 'e') {
              varName = ch;
              break;
            }
          }
          final value = ExpressionParser.evaluate(_expression, degrees: _degreesMode);
          if (value.isNaN || value.isInfinite) {
            _result = 'Error';
          } else {
            final formatted = _formatResult(value);
            _result = varName != null ? '$varName = $formatted' : formatted;
          }
          _expression = '';
          _hasResult = true;
          _cursorIndex = 0;
          _historyProvider?.addEntry(_previousExpression, _result);
          notifyListeners();
          return;
        }
      }
      final value =
          ExpressionParser.evaluate(_expression, degrees: _degreesMode);
      _result = _formatResult(value);
      _expression = '';
      _hasResult = true;
      _cursorIndex = 0;
      _historyProvider?.addEntry(_previousExpression, _result);
      notifyListeners();
    } catch (e) {
      _result = 'Error';
      _hasResult = true;
      notifyListeners();
    }
  }

  String _formatResult(double value) {
    if (!value.isFinite) return 'Error';
    if (value == 0) return '0';
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    final formatted = value.toStringAsFixed(_precision);
    String trimmed = formatted.replaceAll(RegExp(r'0+$'), '');
    if (trimmed.endsWith('.')) trimmed = trimmed.substring(0, trimmed.length - 1);
    return trimmed;
  }

  double? evaluateGraphFunction(double x) {
    try {
      return ExpressionParser.evaluate(
        _graphFunction,
        degrees: false,
        variables: {'x': x},
      );
    } catch (e) {
      return null;
    }
  }

  String evaluateExpression(String expr) {
    try {
      final value = ExpressionParser.evaluate(expr, degrees: _degreesMode);
      return _formatResult(value);
    } catch (e) {
      return 'Error';
    }
  }

  void loadFromHistory(String expression, String result) {
    _expression = '';
    _previousExpression = expression;
    _result = result;
    _hasResult = true;
    _cursorIndex = 0;
    notifyListeners();
    setMode(CalculatorMode.standard);
  }
}
