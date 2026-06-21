import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _mathjsUrl = 'http://api.mathjs.org/v4/';

  static Future<String> solveMathProblem(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return 'Please enter a problem.';

    // Detect operation type from natural language
    final lower = trimmed.toLowerCase();

    // --- Derivative ---
    if (_matches(lower, ['derivative of', 'derive', 'differentiate',
                          'd/dx', 'ddx', 'find the derivative'])) {
      final expr = _extractAfter(trimmed, ['derivative of', 'derive',
          'differentiate', 'd/dx', 'ddx', 'find the derivative']);
      if (expr.isNotEmpty) {
        final cleaned = _cleanExpr(expr);
        final result = await _mathjs('simplify(derivative(\'$cleaned\',\'x\'))');
        if (result != null) {
          return 'Derivative of $expr:\n  d/dx($expr) = $result';
        }
      }
    }

    // --- Integral ---
    if (_matches(lower, ['integral of', 'integrate', 'antiderivative',
                          'find the integral', 'indefinite integral',
                          '∫'])) {
      final expr = _extractAfter(trimmed, ['integral of', 'integrate',
          'antiderivative', 'find the integral', 'indefinite integral', '∫']);
      if (expr.isNotEmpty) {
        final cleaned = _cleanExpr(expr);
        final result = await _mathjs('integrate($cleaned,x)');
        if (result != null) {
          return 'Integral of $expr:\n  ∫ $expr dx = $result + C';
        }
      }
    }

    // --- Solve equation (with = sign) ---
    if (lower.contains('solve') || trimmed.contains('=')) {
      if (trimmed.contains('=')) {
        // Extract left side of equation
        final parts = trimmed.split('=');
        if (parts.length >= 2) {
          final lhs = _cleanExpr(parts[0].replaceAll(RegExp(r'solve', caseSensitive: false), '').trim());
          final rhs = _cleanExpr(parts[1].trim());
          // Move everything to LHS: lhs - rhs = 0
          final combined = lhs.isEmpty ? rhs : '($lhs)-($rhs)';
          // Try to factor or solve
          final result = await _mathjs('factor($combined)');
          if (result != null && !result.contains('Error')) {
            return 'Expression:\n  $trimmed\nFactored:\n  $result';
          }
          // Try numeric solve for quadratic
          final roots = await _mathjs('solve($combined,x)');
          if (roots != null && !roots.contains('Error')) {
            return 'Solve $trimmed:\n  x = $roots';
          }
        }
      } else {
        final expr = _extractAfter(trimmed, ['solve']);
        if (expr.isNotEmpty) {
          final cleaned = _cleanExpr(expr);
          final result = await _mathjs('solve($cleaned,x)');
          if (result != null) {
            return 'Solve $expr:\n  x = $result';
          }
        }
      }
    }

    // --- Simplify ---
    if (_matches(lower, ['simplify', 'expand'])) {
      final expr = _extractAfter(trimmed, ['simplify', 'expand']);
      if (expr.isNotEmpty) {
        final cleaned = _cleanExpr(expr);
        final result = await _mathjs('simplify($cleaned)');
        if (result != null) {
          return 'Simplify $expr:\n  = $result';
        }
      }
    }

    // --- Factor ---
    if (_matches(lower, ['factor', 'factorise', 'factorize'])) {
      final expr = _extractAfter(trimmed, ['factor', 'factorise', 'factorize']);
      if (expr.isNotEmpty) {
        final cleaned = _cleanExpr(expr);
        final result = await _mathjs('factor($cleaned)');
        if (result != null) {
          return 'Factor $expr:\n  = $result';
        }
      }
    }

    // --- Evaluate as expression ---
    final expr = _cleanExpr(trimmed);
    if (expr.isNotEmpty) {
      final result = await _mathjs(expr);
      if (result != null) {
        return '$trimmed\n  = $result';
      }
    }

    return '''
I can help with math problems! Try:

• "derivative of x^2 + 2x"
• "integrate x^2"
• "solve x^2 - 5x + 6 = 0"
• "simplify (x+1)(x-1)"
• "factor x^2 - 4"
• Or just type any expression like "cos(45)^2 + sin(45)^2"
''';
  }

  static Future<String?> _mathjs(String expr) async {
    try {
      final uri = Uri.parse('$_mathjsUrl?expr=${Uri.encodeComponent(expr)}');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final text = response.body.trim();
        if (text.isNotEmpty && !text.startsWith('Error')) {
          return text;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static bool _matches(String lower, List<String> keywords) {
    return keywords.any((k) => lower.startsWith(k) || lower.contains(' $k '));
  }

  static String _extractAfter(String text, List<String> prefixes) {
    final lower = text.toLowerCase();
    for (final p in prefixes) {
      final idx = lower.indexOf(p);
      if (idx >= 0) {
        final after = text.substring(idx + p.length).trim();
        if (after.isNotEmpty) return after;
      }
    }
    return text;
  }

  static String _cleanExpr(String s) {
    // Remove leading punctuation/whitespace
    return s
        .replaceAll(RegExp(r'^[,\s.:;!?]+'), '')
        .replaceAll(RegExp(r'[,\s.:;!?]+$'), '')
        .replaceAll('^', '^') // keep exponent
        .trim();
  }
}
