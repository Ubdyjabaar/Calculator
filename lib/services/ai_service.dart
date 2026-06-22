import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../core/config/ai_config.dart';

class AIService {
  static String? _cachedUrl;

  static Future<String> solveMathProblem(String query) async {
    // Ensure config is loaded
    await AIConfig.getKeywords('help');

    final trimmed = query.trim();
    if (trimmed.isEmpty) return await AIConfig.getMessage('empty');

    final lower = trimmed.toLowerCase();

    if (await _matchesConfig(lower, 'help')) {
      return await AIConfig.getMessage('help');
    }

    if (await _matchesConfig(lower, 'derivative')) {
      final expr = _extractAfter(trimmed, await AIConfig.getKeywords('derivative'));
      if (expr.isNotEmpty) return await _handleDerivative(expr);
    }

    if (await _matchesConfig(lower, 'integral')) {
      final expr = _extractAfter(trimmed, await AIConfig.getKeywords('integral'));
      if (expr.isNotEmpty) return await _handleIntegral(expr);
    }

    if (lower.contains('solve') || trimmed.contains('=')) {
      if (trimmed.contains('=')) {
        final parts = trimmed.split('=');
        if (parts.length >= 2) {
          return await _handleSolve(trimmed, parts[0].trim(), parts[1].trim());
        }
      } else {
        final expr = _extractAfter(trimmed, ['solve']);
        if (expr.isNotEmpty) return await _handleSolve(expr, null, null);
      }
    }

    if (await _matchesConfig(lower, 'simplify')) {
      final expr = _extractAfter(trimmed, await AIConfig.getKeywords('simplify'));
      if (expr.isNotEmpty) return await _handleSimplify(expr);
    }

    if (await _matchesConfig(lower, 'factor')) {
      final expr = _extractAfter(trimmed, await AIConfig.getKeywords('factor'));
      if (expr.isNotEmpty) return await _handleFactor(expr);
    }

    return await _handleEvaluate(trimmed);
  }

  static Future<String> _getMathjsUrl() async {
    if (_cachedUrl != null) return _cachedUrl!;
    _cachedUrl = await AIConfig.getApiUrl();
    return _cachedUrl!;
  }

  static Future<String> _handleDerivative(String expr) async {
    final cleaned = _cleanExpr(expr);
    final result = await _mathjs('simplify(derivative(\'$cleaned\',\'x\'))');
    if (result == null || result.startsWith('Error')) {
      final err = await _mathjsRaw('simplify(derivative(\'$cleaned\',\'x\'))');
      final template = await AIConfig.getMessage('math_error');
      return template.replaceAll('{error}', err ?? 'Could not compute derivative.');
    }

    final buf = StringBuffer()
      ..writeln('Step-by-Step Derivative')
      ..writeln()
      ..writeln('Function: f(x) = $cleaned')
      ..writeln()
      ..writeln('Step 1: Apply differentiation rules');
    if (_isPoly(cleaned)) {
      buf.writeln('  Power rule: d/dx(x^n) = n·x^(n-1)');
    }
    buf.writeln();

    final terms = _splitTerms(cleaned);
    if (terms.length > 1) {
      buf.writeln('Step 2: Differentiate each term:');
      for (final term in terms) {
        final tResult = await _mathjs('derivative(\'$term\',\'x\')');
        if (tResult != null && !tResult.startsWith('Error')) {
          buf.writeln('  d/dx($term) = $tResult');
        }
      }
      buf.writeln();
      buf.writeln('Step 3: Combine:');
    }

    buf.writeln('  f\'(x) = $result');
    return buf.toString();
  }

  static Future<String> _handleIntegral(String expr) async {
    final cleaned = _cleanExpr(expr);
    final result = await _mathjs('integrate($cleaned,x)');
    if (result == null || result.startsWith('Error')) {
      final err = await _mathjsRaw('integrate($cleaned,x)');
      final template = await AIConfig.getMessage('math_error');
      return template.replaceAll('{error}', err ?? 'Could not compute integral.');
    }

    final buf = StringBuffer()
      ..writeln('Step-by-Step Integral')
      ..writeln()
      ..writeln('Function: f(x) = $cleaned')
      ..writeln()
      ..writeln('Step 1: Apply integration rules')
      ..writeln('  Power rule: ∫ x^n dx = x^(n+1)/(n+1) + C')
      ..writeln();

    final terms = _splitTerms(cleaned);
    if (terms.length > 1) {
      buf.writeln('Step 2: Integrate each term:');
      for (final term in terms) {
        final tResult = await _mathjs('integrate($term,x)');
        if (tResult != null && !tResult.startsWith('Error')) {
          buf.writeln('  ∫ $term dx = $tResult');
        }
      }
      buf.writeln();
      buf.writeln('Step 3: Combine:');
    }

    buf.writeln('  F(x) = $result + C');
    return buf.toString();
  }

  static Future<String> _handleSolve(String fullExpr, String? lhs, String? rhs) async {
    String combined;
    if (lhs != null && rhs != null) {
      final l = _cleanExpr(lhs.replaceAll(RegExp(r'solve', caseSensitive: false), ''));
      final r = _cleanExpr(rhs);
      combined = l.isEmpty ? r : '($l)-($r)';
    } else {
      combined = _cleanExpr(fullExpr.replaceAll(RegExp(r'solve', caseSensitive: false), ''));
    }

    final buf = StringBuffer()
      ..writeln('Step-by-Step Solution')
      ..writeln()
      ..writeln('Equation: ${lhs != null ? "$lhs = $rhs" : "$combined = 0"}')
      ..writeln();

    final factored = await _mathjs('factor($combined)');
    if (factored != null && !factored.startsWith('Error') && factored != _cleanExpr(combined)) {
      buf.writeln('Step 1: Factor the expression');
      buf.writeln('  $combined = $factored');
      buf.writeln();
    }

    final isQuad = await _isQuadratic(combined);
    if (isQuad) {
      final coeffs = await _extractQuadraticCoeffs(combined);
      if (coeffs != null) {
        final a = coeffs['a']!;
        final b = coeffs['b']!;
        final c = coeffs['c']!;
        final disc = b * b - 4 * a * c;

        buf.writeln('Step ${factored != null && !factored.startsWith('Error') && factored != _cleanExpr(combined) ? 2 : 1}: Identify coefficients');
        buf.writeln('  a = $a, b = $b, c = $c');
        buf.writeln();
        buf.writeln('  Quadratic formula: x = (-b ± √(b² - 4ac)) / 2a');
        buf.writeln();
        buf.writeln('  Discriminant: Δ = b² - 4ac');
        buf.writeln('  Δ = (${b})² - 4($a)($c) = $disc');
        buf.writeln();

        if (disc >= 0) {
          final sqrtDisc = await _mathjs('sqrt($disc)');
          final root1 = await _mathjs('(($b * -1) + sqrt($disc)) / (2 * $a)');
          final root2 = await _mathjs('(($b * -1) - sqrt($disc)) / (2 * $a)');
          buf.writeln('  x = (${b * -1} ± √$disc) / ${2 * a}');
          if (sqrtDisc != null && !sqrtDisc.startsWith('Error')) {
            buf.writeln('  x = (${b * -1} ± $sqrtDisc) / ${2 * a}');
          }
          buf.writeln();
          if (root1 != null && root2 != null) {
            buf.writeln('Solution:');
            if (root1 == root2) {
              buf.writeln('  x = $root1 (repeated root)');
            } else {
              buf.writeln('  x₁ = $root1');
              buf.writeln('  x₂ = $root2');
            }
          }
        } else {
          final real = await _mathjs('($b * -1) / (2 * $a)');
          final imag = await _mathjs('sqrt($disc * -1) / (2 * $a)');
          buf.writeln('  Δ < 0 → Two complex roots');
          buf.writeln();
          if (real != null && imag != null) {
            buf.writeln('Solution:');
            buf.writeln('  x₁ = $real + ${imag}i');
            buf.writeln('  x₂ = $real - ${imag}i');
          }
        }
        return buf.toString();
      }
    }

    // Polynomial root finding for degree >= 3
    final degree = _detectDegree(combined);
    if (degree >= 3) {
      final coeffs = await _extractPolyCoeffs(combined, degree);
      if (coeffs != null && coeffs.length == degree + 1) {
        final rootsResult = await _mathjs('roots([${coeffs.join(',')}])');
        if (rootsResult != null && !rootsResult.startsWith('Error')) {
          buf.writeln('Step: Find all roots numerically');
          buf.writeln('  Polynomial degree: $degree');
          buf.writeln('  Roots: $rootsResult');
          return buf.toString();
        }
      }
    }

    final roots = await _mathjs('solve($combined,x)');
    if (roots != null && !roots.startsWith('Error')) {
      buf.writeln('Solution:');
      buf.writeln('  x = $roots');
      return buf.toString();
    }

    final err = await _mathjsRaw('solve($combined,x)');
    final template = await AIConfig.getMessage('math_error');
    return template.replaceAll('{error}', err ?? 'Could not solve equation.');
  }

  static Future<String> _handleSimplify(String expr) async {
    final cleaned = _cleanExpr(expr);
    final result = await _mathjs('simplify($cleaned)');
    if (result == null || result.startsWith('Error')) {
      final err = await _mathjsRaw('simplify($cleaned)');
      final template = await AIConfig.getMessage('math_error');
      return template.replaceAll('{error}', err ?? 'Could not simplify.');
    }

    final buf = StringBuffer()
      ..writeln('Step-by-Step Simplification')
      ..writeln()
      ..writeln('Expression: $cleaned')
      ..writeln();

    if (cleaned.contains('(')) {
      buf.writeln('Step 1: Expand brackets');
      final expanded = await _mathjs('expand($cleaned)');
      if (expanded != null && !expanded.startsWith('Error') && expanded != result) {
        buf.writeln('  = $expanded');
        buf.writeln();
        buf.writeln('Step 2: Combine like terms');
      }
    }

    buf.writeln('  Simplified: $result');
    return buf.toString();
  }

  static Future<String> _handleFactor(String expr) async {
    final cleaned = _cleanExpr(expr);
    final result = await _mathjs('factor($cleaned)');
    if (result == null || result.startsWith('Error')) {
      final err = await _mathjsRaw('factor($cleaned)');
      final template = await AIConfig.getMessage('math_error');
      return template.replaceAll('{error}', err ?? 'Could not factor.');
    }

    final buf = StringBuffer()
      ..writeln('Step-by-Step Factoring')
      ..writeln()
      ..writeln('Expression: $cleaned')
      ..writeln();

    if (cleaned.contains('^2') && !cleaned.contains('+') && !cleaned.contains('(')) {
      final parts = cleaned.split(RegExp(r'\s*-\s*'));
      if (parts.length == 2) {
        buf.writeln('Step 1: Recognize difference of squares');
        buf.writeln('  $cleaned = ${parts[0]} - ${parts[1]}');
        buf.writeln('  Formula: a² - b² = (a - b)(a + b)');
        buf.writeln();
      }
    }

    buf.writeln('  Factored: $result');
    return buf.toString();
  }

  static Future<String> _handleEvaluate(String expr) async {
    final cleaned = _cleanExpr(expr);
    if (cleaned.isEmpty) return await AIConfig.getMessage('help');

    final result = await _mathjs(cleaned);
    if (result != null) return '$cleaned\n  = $result';

    final fixed = _fixExpression(expr);
    if (fixed != cleaned) {
      final retry = await _mathjs(fixed);
      if (retry != null) return '$expr\n  = $retry';
    }

    final err = await _mathjsRaw(cleaned);
    if (err != null) {
      final template = await AIConfig.getMessage('math_error');
      return template.replaceAll('{error}', err);
    }
    return await AIConfig.getMessage('help');
  }

  static Future<bool> _matchesConfig(String lower, String configKey) async {
    final keywords = await AIConfig.getKeywords(configKey);
    return keywords.any((k) => lower.contains(k));
  }

  static List<String> _splitTerms(String expr) {
    List<String> terms = [];
    int depth = 0;
    int start = 0;
    for (int i = 0; i < expr.length; i++) {
      if (expr[i] == '(') depth++;
      if (expr[i] == ')') depth--;
      if (depth == 0 && (expr[i] == '+' || (expr[i] == '-' && i > 0))) {
        final term = expr.substring(start, i).trim();
        if (term.isNotEmpty) terms.add(term);
        start = i;
      }
    }
    final last = expr.substring(start).trim();
    if (last.isNotEmpty) terms.add(last);
    return terms;
  }

  static bool _isPoly(String expr) {
    if (expr.contains(RegExp(r'sin|cos|tan|log|ln|sqrt|exp|pi|e\^', caseSensitive: false))) return false;
    return true;
  }

  static Future<bool> _isQuadratic(String expr) async {
    if (!expr.contains('^2')) return false;
    final result = await _mathjs('derivative(\'$expr\',\'x\')');
    if (result == null || result.startsWith('Error')) return false;
    final second = await _mathjs('derivative(\'$result\',\'x\')');
    return second != null && !second.startsWith('Error');
  }

  static Future<Map<String, double>?> _extractQuadraticCoeffs(String expr) async {
    try {
      final c = double.tryParse(await _evaluateAt(expr, 0) ?? '') ?? 0;
      final f1 = double.tryParse(await _evaluateAt(expr, 1) ?? '') ?? 0;
      final fNeg1 = double.tryParse(await _evaluateAt(expr, -1) ?? '') ?? 0;
      final a = (f1 + fNeg1 - 2 * c) / 2;
      final b = (f1 - fNeg1) / 2;
      return {'a': a, 'b': b, 'c': c};
    } catch (_) {
      return null;
    }
  }

  static int _detectDegree(String expr) {
    int maxDeg = 0;
    for (final m in RegExp(r'x\^(\d+)').allMatches(expr)) {
      final deg = int.tryParse(m.group(1)!) ?? 0;
      if (deg > maxDeg) maxDeg = deg;
    }
    if (maxDeg == 0 && expr.contains('x')) maxDeg = 1;
    return maxDeg;
  }

  static Future<List<double>?> _extractPolyCoeffs(String expr, int degree) async {
    final n = degree + 1;
    final points = <int>[];
    points.add(0);
    for (int i = 1; points.length < n; i++) {
      points.add(i);
      if (points.length < n) points.add(-i);
    }

    final rows = <String>[];
    final values = <String>[];
    for (final p in points) {
      final row = <String>[];
      for (int j = 0; j <= degree; j++) {
        if (p == 0 && j == 0) {
          row.add('1');
        } else if (p == 0) {
          row.add('0');
        } else {
          row.add('${math.pow(p, j).toInt()}');
        }
      }
      rows.add('[${row.join(',')}]');
      final v = await _evaluateAt(expr, p.toDouble());
      if (v == null) return null;
      values.add(v);
    }

    final result = await _mathjs('linsolve([${rows.join(',')}], [${values.join(',')}])');
    if (result == null || result.startsWith('Error')) return null;

    final coeffs = result
        .replaceAll('[', '').replaceAll(']', '')
        .split(',')
        .map((s) => double.tryParse(s.trim()) ?? 0)
        .toList();

    return coeffs.reversed.toList();
  }

  static Future<String?> _evaluateAt(String expr, double x) async {
    return await _mathjs('evaluate(\'$expr\', {x: $x})');
  }

  static String _fixExpression(String s) {
    return s
        .replaceAll(RegExp(r'(\w+)\^2\s*([a-zA-Z])'), r'($1($2))^2')
        .replaceAll(RegExp(r'(\w+)²\s*([a-zA-Z])'), r'($1($2))^2')
        .replaceAll(RegExp(r'(\w+)\^3\s*([a-zA-Z])'), r'($1($2))^3');
  }

  static Future<String?> _mathjs(String expr) async {
    try {
      final url = await _getMathjsUrl();
      final uri = Uri.parse('$url?expr=${Uri.encodeComponent(expr)}');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final text = response.body.trim();
        if (text.isNotEmpty && !text.startsWith('Error')) return text;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _mathjsRaw(String expr) async {
    try {
      final url = await _getMathjsUrl();
      final uri = Uri.parse('$url?expr=${Uri.encodeComponent(expr)}');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return response.body.trim();
      final body = response.body.trim();
      if (body.isNotEmpty) return body;
      return 'HTTP ${response.statusCode}';
    } catch (e) {
      return '$e';
    }
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
    return s
        .replaceAll(RegExp(r'^[,\s.:;!?]+'), '')
        .replaceAll(RegExp(r'[,\s.:;!?]+$'), '')
        .trim();
  }
}
