import 'dart:math';

enum _TokenType {
  number,
  operator_,
  function,
  functionPower,
  constant,
  variable,
  leftParen,
  rightParen,
}

class _Token {
  final String value;
  final _TokenType type;
  const _Token(this.value, this.type);
}

class ExpressionParser {
  ExpressionParser._();

  static const Map<String, int> _precedence = {
    '+': 2,
    '-': 2,
    '×': 3,
    '÷': 3,
    '^': 4,
  };

  static const Set<String> _rightAssociative = {'^'};
  static const Set<String> _functions = {
    'sin', 'cos', 'tan', 'log', 'ln', 'sqrt', 'asin', 'acos', 'atan',
  };
  static const Map<String, double> _constants = {
    'π': pi,
    'e': e,
  };

  static double evaluate(
    String expression, {
    bool degrees = false,
    Map<String, double> variables = const {},
  }) {
    if (expression.trim().isEmpty) return 0;

    if (expression.contains('=')) {
      return _solveEquation(expression, degrees: degrees);
    }

    String expr = expression
        .replaceAll('²', '^2')
        .replaceAll('³', '^3');
    expr = _insertImplicitMultiplication(expr);
    final tokens = _tokenize(expr);
    final postfix = _toPostfix(tokens);
    return _evaluatePostfix(postfix, degrees: degrees, variables: variables);
  }

  static double _solveEquation(
    String equation, {
    bool degrees = false,
  }) {
    final parts = equation.split('=');
    if (parts.length != 2) throw FormatException('Invalid equation');

    String clean(String s) => _insertImplicitMultiplication(s.replaceAll('²', '^2').replaceAll('³', '^3'));
    final leftExpr = clean(parts[0].trim());
    final rightExpr = clean(parts[1].trim());

    if (leftExpr.isEmpty || rightExpr.isEmpty) {
      throw FormatException('Invalid equation');
    }

    final leftTokens = _tokenize(leftExpr);
    final rightTokens = _tokenize(rightExpr);

    String? variable;
    for (final t in [...leftTokens, ...rightTokens]) {
      if (t.type == _TokenType.variable) {
        variable = t.value;
        break;
      }
    }

    if (variable == null) {
      final leftVal = _evaluatePostfix(
        _toPostfix(leftTokens),
        degrees: degrees,
      );
      final rightVal = _evaluatePostfix(
        _toPostfix(rightTokens),
        degrees: degrees,
      );
      final val = leftVal - rightVal;
      if (val == 0) return double.infinity;
      throw FormatException('Contradiction: $leftVal ≠ $rightVal');
    }

    final leftPostfix = _toPostfix(leftTokens);
    final rightPostfix = _toPostfix(rightTokens);

    double f(double x) {
      final vars = {variable!: x};
      final l = _evaluatePostfix(leftPostfix, degrees: degrees, variables: vars);
      final r = _evaluatePostfix(rightPostfix, degrees: degrees, variables: vars);
      return l - r;
    }

    double low = -1e6;
    double high = 1e6;
    double fLow = f(low);
    double fHigh = f(high);

    if (fLow == 0) return low;
    if (fHigh == 0) return high;

    if (fLow.sign == fHigh.sign) {
      for (int i = 0; i < 20; i++) {
        low *= 2;
        high *= 2;
        fLow = f(low);
        fHigh = f(high);
        if (fLow.sign != fHigh.sign) break;
      }
      if (fLow.sign == fHigh.sign) {
        if (fLow.abs() < fHigh.abs()) return low;
        return high;
      }
    }

    for (int i = 0; i < 200; i++) {
      final mid = (low + high) / 2;
      final fMid = f(mid);
      if (fMid == 0) return mid;
      if (fLow.sign != fMid.sign) {
        high = mid;
        fHigh = fMid;
      } else {
        low = mid;
        fLow = fMid;
      }
    }

    final result = (low + high) / 2;
    if (result.isNaN || result.isInfinite) {
      throw FormatException('Could not solve equation');
    }
    return result;
  }

  static String _insertImplicitMultiplication(String expr) {
    String result = expr;
    result = result.replaceAllMapped(
      RegExp(r'(\d|π|e|\))\s*\('),
      (m) => '${m[1]}×(',
    );
    result = result.replaceAllMapped(
      RegExp(r'(\d|\))\s*(π|e|[a-zA-Z])'),
      (m) => '${m[1]}×${m[2]}',
    );
    result = result.replaceAllMapped(
      RegExp(r'(π|e)\s*(\d|π|e|[a-zA-Z])'),
      (m) => '${m[1]}×${m[2]}',
    );
    return result;
  }

  static List<_Token> _tokenize(String expr) {
    List<_Token> tokens = [];
    int i = 0;
    bool expectOperand = true;

    while (i < expr.length) {
      final ch = expr[i];

      if (ch == ' ' || ch == '\t') {
        i++;
        continue;
      }

      if (_isDigit(ch) || (ch == '.' && i + 1 < expr.length && _isDigit(expr[i + 1]))) {
        int start = i;
        bool hasDot = false;
        while (i < expr.length && (_isDigit(expr[i]) || (expr[i] == '.' && !hasDot))) {
          if (expr[i] == '.') hasDot = true;
          i++;
        }
        tokens.add(_Token(expr.substring(start, i), _TokenType.number));
        expectOperand = false;
        continue;
      }

      if (ch == 'π') {
        tokens.add(_Token('π', _TokenType.constant));
        i++;
        expectOperand = false;
        continue;
      }

      if (_isLetter(ch)) {
        int start = i;
        while (i < expr.length && (_isLetter(expr[i]) || _isDigit(expr[i]))) {
          i++;
        }
        final word = expr.substring(start, i);
        if (_functions.contains(word)) {
          int la = i;
          while (la < expr.length && expr[la] == ' ') la++;
          if (la < expr.length && expr[la] == '^') {
            int expStart = la + 1;
            int expEnd = expStart;
            while (expEnd < expr.length && (_isDigit(expr[expEnd]) || '²³' .contains(expr[expEnd]))) {
              expEnd++;
            }
            if (expStart < expEnd) {
              int afterExp = expEnd;
              while (afterExp < expr.length && expr[afterExp] == ' ') afterExp++;
              if (afterExp < expr.length && (expr[afterExp] == '(' || _isLetter(expr[afterExp]))) {
                String exp = expr.substring(expStart, expEnd)
                    .replaceAll('²', '2')
                    .replaceAll('³', '3');
                tokens.add(_Token('$word^$exp', _TokenType.functionPower));
                i = afterExp;
                expectOperand = true;
                continue;
              }
            }
          }
          tokens.add(_Token(word, _TokenType.function));
          expectOperand = true;
        } else if (word == 'e') {
          tokens.add(_Token('e', _TokenType.constant));
          expectOperand = false;
        } else if (word == 'x' || word == 'X') {
          tokens.add(_Token('x', _TokenType.variable));
          expectOperand = false;
        } else {
          tokens.add(_Token(word, _TokenType.variable));
          expectOperand = false;
        }
        continue;
      }

      if (ch == '(') {
        tokens.add(_Token('(', _TokenType.leftParen));
        i++;
        expectOperand = true;
        continue;
      }
      if (ch == ')') {
        tokens.add(_Token(')', _TokenType.rightParen));
        i++;
        expectOperand = false;
        continue;
      }

      if ('+-×÷^'.contains(ch)) {
        if (ch == '-' && expectOperand) {
          tokens.add(_Token('0', _TokenType.number));
        }
        tokens.add(_Token(ch, _TokenType.operator_));
        i++;
        expectOperand = true;
        continue;
      }

      i++;
    }

    return tokens;
  }

  static bool _isDigit(String ch) =>
      ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;

  static bool _isLetter(String ch) {
    final c = ch.codeUnitAt(0);
    return (c >= 65 && c <= 90) || (c >= 97 && c <= 122);
  }

  static List<_Token> _toPostfix(List<_Token> tokens) {
    List<_Token> output = [];
    List<_Token> opStack = [];

    for (final token in tokens) {
      switch (token.type) {
        case _TokenType.number:
        case _TokenType.constant:
        case _TokenType.variable:
          output.add(token);
          break;

        case _TokenType.function:
        case _TokenType.functionPower:
          opStack.add(token);
          break;

        case _TokenType.operator_:
          while (opStack.isNotEmpty) {
            final top = opStack.last;
            if (top.type != _TokenType.operator_) break;
            final topPrec = _precedence[top.value]!;
            final currPrec = _precedence[token.value]!;
            if (topPrec > currPrec ||
                (topPrec == currPrec && !_rightAssociative.contains(token.value))) {
              output.add(opStack.removeLast());
            } else {
              break;
            }
          }
          opStack.add(token);
          break;

        case _TokenType.leftParen:
          opStack.add(token);
          break;

        case _TokenType.rightParen:
          while (opStack.isNotEmpty && opStack.last.type != _TokenType.leftParen) {
            output.add(opStack.removeLast());
          }
          if (opStack.isNotEmpty && opStack.last.type == _TokenType.leftParen) {
            opStack.removeLast();
          }
          if (opStack.isNotEmpty &&
              (opStack.last.type == _TokenType.function ||
               opStack.last.type == _TokenType.functionPower)) {
            output.add(opStack.removeLast());
          }
          break;
      }
    }

    while (opStack.isNotEmpty) {
      output.add(opStack.removeLast());
    }

    return output;
  }

  static double _evaluatePostfix(
    List<_Token> postfix, {
    bool degrees = false,
    Map<String, double> variables = const {},
  }) {
    List<double> stack = [];

    for (final token in postfix) {
      switch (token.type) {
        case _TokenType.number:
          stack.add(double.parse(token.value));
          break;
        case _TokenType.constant:
          stack.add(_constants[token.value]!);
          break;
        case _TokenType.variable:
          if (variables.containsKey(token.value)) {
            stack.add(variables[token.value]!);
          } else {
            throw FormatException('Unknown variable: ${token.value}');
          }
          break;
        case _TokenType.operator_:
          if (stack.length < 2) throw FormatException('Insufficient operands');
          final b = stack.removeLast();
          final a = stack.removeLast();
          switch (token.value) {
            case '+':
              stack.add(a + b);
              break;
            case '-':
              stack.add(a - b);
              break;
            case '×':
              stack.add(a * b);
              break;
            case '÷':
              if (b == 0) throw FormatException('Division by zero');
              stack.add(a / b);
              break;
            case '^':
              stack.add(pow(a, b).toDouble());
              break;
          }
          break;
        case _TokenType.function:
        case _TokenType.functionPower:
          if (stack.isEmpty) throw FormatException('Insufficient operands');
          final arg = stack.removeLast();
          double processedArg = arg;
          final parts = token.value.split('^');
          final func = parts[0];
          final exponent = parts.length > 1 ? int.parse(parts[1]) : 1;
          if (degrees && ['sin', 'cos', 'tan'].contains(func)) {
            processedArg = arg * pi / 180.0;
          }
          double result;
          switch (func) {
            case 'sin':
              result = sin(processedArg);
              break;
            case 'cos':
              result = cos(processedArg);
              break;
            case 'tan':
              result = tan(processedArg);
              break;
            case 'log':
              result = log(processedArg) / ln10;
              break;
            case 'ln':
              result = log(processedArg);
              break;
            case 'sqrt':
              if (processedArg < 0) {
                throw FormatException('Square root of negative number');
              }
              result = sqrt(processedArg);
              break;
            case 'asin':
              if (processedArg < -1 || processedArg > 1) {
                throw FormatException('asin domain error');
              }
              final r = asin(processedArg);
              result = degrees ? r * 180.0 / pi : r;
              break;
            case 'acos':
              if (processedArg < -1 || processedArg > 1) {
                throw FormatException('acos domain error');
              }
              final r = acos(processedArg);
              result = degrees ? r * 180.0 / pi : r;
              break;
            case 'atan':
              final r = atan(processedArg);
              result = degrees ? r * 180.0 / pi : r;
              break;
            default:
              result = 0;
          }
          if (exponent > 1) result = pow(result, exponent).toDouble();
          stack.add(result);
          break;
        case _TokenType.leftParen:
        case _TokenType.rightParen:
          break;
      }
    }

    if (stack.isEmpty) return 0;
    return stack.last;
  }
}
