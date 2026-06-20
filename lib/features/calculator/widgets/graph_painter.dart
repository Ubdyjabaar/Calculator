import 'dart:math';
import 'package:flutter/material.dart';

class GraphPainter extends CustomPainter {
  final double? Function(double x) evaluate;
  final double centerX;
  final double centerY;
  final double scale;

  GraphPainter({
    required this.evaluate,
    required this.centerX,
    required this.centerY,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawAxes(canvas, size);
    _drawLabels(canvas, size);
    _drawFunction(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;

    // Calculate visible range
    final minGraphX = (0 - size.width / 2) / scale + centerX;
    final maxGraphX = (size.width - size.width / 2) / scale + centerX;
    final minGraphY = (size.height - size.height / 2) / scale + centerY;
    final maxGraphY = (0 - size.height / 2) / scale + centerY;

    // Calculate step size based on scale
    double step = _calculateStep();

    // Vertical grid lines
    double x = (minGraphX / step).ceil() * step;
    while (x <= maxGraphX) {
      if (x.abs() > 0.001) {
        final px = (x - centerX) * scale + size.width / 2;
        canvas.drawLine(Offset(px, 0), Offset(px, size.height), gridPaint);
      }
      x += step;
    }

    // Horizontal grid lines
    double y = (minGraphY / step).ceil() * step;
    while (y <= maxGraphY) {
      if (y.abs() > 0.001) {
        final py = -(y - centerY) * scale + size.height / 2;
        canvas.drawLine(Offset(0, py), Offset(size.width, py), gridPaint);
      }
      y += step;
    }
  }

  void _drawAxes(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.5;

    // Y-axis
    final yPx = (0 - centerX) * scale + size.width / 2;
    if (yPx >= 0 && yPx <= size.width) {
      canvas.drawLine(Offset(yPx, 0), Offset(yPx, size.height), axisPaint);
    }

    // X-axis
    final xPx = -(0 - centerY) * scale + size.height / 2;
    if (xPx >= 0 && xPx <= size.height) {
      canvas.drawLine(Offset(0, xPx), Offset(size.width, xPx), axisPaint);
    }
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final minGraphX = (0 - size.width / 2) / scale + centerX;
    final maxGraphX = (size.width - size.width / 2) / scale + centerX;
    final minGraphY = (size.height - size.height / 2) / scale + centerY;
    final maxGraphY = (0 - size.height / 2) / scale + centerY;

    double step = _calculateStep();

    // X-axis labels
    double x = (minGraphX / step).ceil() * step;
    final xAxisY = -(0 - centerY) * scale + size.height / 2;

    while (x <= maxGraphX) {
      if (x.abs() > 0.001) {
        final px = (x - centerX) * scale + size.width / 2;
        textPainter.text = TextSpan(
          text: _formatLabel(x),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            px - textPainter.width / 2,
            min(xAxisY + 8, size.height - textPainter.height - 4),
          ),
        );
      }
      x += step;
    }

    // Y-axis labels
    double y = (minGraphY / step).ceil() * step;
    final yAxisX = (0 - centerX) * scale + size.width / 2;

    while (y <= maxGraphY) {
      if (y.abs() > 0.001) {
        final py = -(y - centerY) * scale + size.height / 2;
        textPainter.text = TextSpan(
          text: _formatLabel(y),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            min(yAxisX - textPainter.width - 8, size.width - textPainter.width - 4),
            py - textPainter.height / 2,
          ),
        );
      }
      y += step;
    }
  }

  void _drawFunction(Canvas canvas, Size size) {
    final funcPaint = Paint()
      ..color = const Color(0xFF7C4DFF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF7C4DFF),
          const Color(0xFF448AFF),
          const Color(0xFF00BCD4),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final glowPaint = Paint()
      ..color = const Color(0xFF7C4DFF).withValues(alpha: 0.2)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    bool hasLastPoint = false;
    double lastPx = 0;

    final graphLeft = (0 - size.width / 2) / scale + centerX;
    final graphRight = (size.width - size.width / 2) / scale + centerX;
    final step = 1.0 / scale;

    for (double gx = graphLeft; gx <= graphRight; gx += step) {
      final gy = evaluate(gx);
      if (gy != null && gy.isFinite && gy.abs() < 1e10) {
        final px = (gx - centerX) * scale + size.width / 2;
        final py = -(gy - centerY) * scale + size.height / 2;

        if (!hasLastPoint) {
          path.moveTo(px, py);
          hasLastPoint = true;
        } else {
          if ((px - lastPx).abs() > 3 * step * scale) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        lastPx = px;
      } else {
        hasLastPoint = false;
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, funcPaint);
  }

  double _calculateStep() {
    if (scale > 100) return 1;
    if (scale > 50) return 2;
    if (scale > 20) return 5;
    if (scale > 10) return 10;
    return 20;
  }

  String _formatLabel(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(GraphPainter oldDelegate) =>
      oldDelegate.centerX != centerX ||
      oldDelegate.centerY != centerY ||
      oldDelegate.scale != scale;
}
