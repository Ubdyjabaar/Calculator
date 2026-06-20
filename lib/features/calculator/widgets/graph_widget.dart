import 'package:flutter/material.dart';
import 'graph_painter.dart';

class GraphWidget extends StatefulWidget {
  final double? Function(double x) evaluate;

  const GraphWidget({super.key, required this.evaluate});

  @override
  State<GraphWidget> createState() => _GraphWidgetState();
}

class _GraphWidgetState extends State<GraphWidget> {
  double _centerX = 0;
  double _centerY = 0;
  double _scale = 50;
  double? _lastFocalDistance;
  Offset? _lastFocalPoint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: GraphPainter(
                evaluate: widget.evaluate,
                centerX: _centerX,
                centerY: _centerY,
                scale: _scale,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastFocalDistance = null;
    _lastFocalPoint = details.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (_lastFocalPoint != null) {
        final delta = details.focalPoint - _lastFocalPoint!;
        _centerX -= delta.dx / _scale;
        _centerY += delta.dy / _scale;
        _lastFocalPoint = details.focalPoint;
      }

      if (_lastFocalDistance == null) {
        _lastFocalDistance = details.scale;
      } else {
        final scaleDelta = details.scale / _lastFocalDistance!;
        _scale = (_scale * scaleDelta).clamp(5, 500);
        _lastFocalDistance = details.scale;
      }
    });
  }
}
