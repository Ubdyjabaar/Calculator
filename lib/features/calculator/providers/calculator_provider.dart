import 'package:flutter/material.dart';
import '../../../core/utils/expression_parser.dart';
import '../../history/providers/history_provider.dart';

enum CalculatorMode { standard, scientific, graphing }

class CalculatorProvider extends ChangeNotifier {
  CalculatorMode _mode = CalculatorMode.standard;
  String _expression = '';
  String _result = '0';
  String _previousExpression = '';
  bool _degreesMode = false;
  bool _hasResult = false;
  String _graphFunction = 'sin(x)';
  int _precision = 10;
  HistoryProvider? _historyProvider;

  CalculatorMode get mode => _mode;
  String get expression => _expression;
  String get result => _result;
  String get previousExpression => _previousExpression;
  bool get degreesMode => _degreesMode;
  bool get hasResult => _hasResult;
  String get graphFunction => _graphFunction;

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

  void inputNumber(String number) {
    if (_hasResult) {
      _expression = '';
      _result = '0';
      _hasResult = false;
    }
    if (_expression.replaceAll(RegExp(r'[^0-9]'), '').length >= 15) return;
    _expression += number;
    notifyListeners();
  }

  void inputOperator(String op) {
    _hasResult = false;
    if (_expression.isEmpty && op == '-') {
      _expression = '-';
    } else if (_expression.isNotEmpty) {
      final last = _expression[_expression.length - 1];
      if ('+-×÷^'.contains(last)) {
        _expression = _expression.substring(0, _expression.length - 1);
      }
      _expression += op;
    }
    notifyListeners();
  }

  void inputFunction(String func) {
    if (_hasResult) {
      _expression = '';
      _result = '0';
      _hasResult = false;
    }
    if (func == 'π') {
      _expression += 'π';
    } else if (func == 'e') {
      _expression += 'e';
    } else {
      _expression += '$func(';
    }
    notifyListeners();
  }

  void inputDecimal() {
    if (_hasResult) {
      _expression = '0.';
      _result = '0';
      _hasResult = false;
      notifyListeners();
      return;
    }
    if (_expression.isEmpty) {
      _expression = '0.';
    } else {
      final parts = _expression.split(RegExp(r'[+\-×÷^()]'));
      if (parts.isNotEmpty && !parts.last.contains('.')) {
        _expression += '.';
      }
    }
    notifyListeners();
  }

  void inputLeftParen() {
    if (_hasResult) {
      _expression = '';
      _result = '0';
      _hasResult = false;
    }
    _expression += '(';
    notifyListeners();
  }

  void inputRightParen() {
    _expression += ')';
    notifyListeners();
  }

  void clear() {
    _expression = '';
    _result = '0';
    _previousExpression = '';
    _hasResult = false;
    notifyListeners();
  }

  void backspace() {
    if (_hasResult) {
      _expression = '';
      _result = '0';
      _hasResult = false;
      notifyListeners();
      return;
    }
    if (_expression.isNotEmpty) {
      _expression = _expression.substring(0, _expression.length - 1);
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
    } else {
      final lastNum = RegExp(r'-?\d+(\.\d+)?$');
      final match = lastNum.stringMatch(_expression);
      if (match != null) {
        final before = _expression.substring(0, _expression.length - match.length);
        final toggled = match.startsWith('-') ? match.substring(1) : '-$match';
        _expression = before + toggled;
      } else {
        _expression = '-$_expression';
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
    notifyListeners();
    setMode(CalculatorMode.standard);
  }
}
