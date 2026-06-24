import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';

class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleAmount;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool hapticFeedback;
  final double? width;
  final double? height;
  final Gradient? gradient;
  final Gradient? tapGradient;
  final List<BoxShadow>? boxShadow;
  final List<BoxShadow>? tapBoxShadow;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleAmount = 0.95,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = AppConstants.borderRadiusSmall,
    this.padding,
    this.hapticFeedback = true,
    this.width,
    this.height,
    this.gradient,
    this.tapGradient,
    this.boxShadow,
    this.tapBoxShadow,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleAmount)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(AnimatedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scaleAmount != widget.scaleAmount) {
      _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleAmount)
          .animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.hapticFeedback) {
      HapticFeedback.selectionClick();
    }
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _controller.forward();
    if (widget.hapticFeedback) {
      HapticFeedback.heavyImpact();
    }
    widget.onLongPress?.call();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = widget.backgroundColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.06));

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPressStart:
          widget.onLongPress != null ? _onLongPressStart : null,
      onLongPressEnd:
          widget.onLongPress != null ? _onLongPressEnd : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, _) {
          final progress = _scaleAnimation.value;
          final isPressed = _controller.isAnimating && progress < 0.98;

          final useTapGradient = isPressed && widget.tapGradient != null;
          final currentShadow = isPressed && widget.tapBoxShadow != null
              ? widget.tapBoxShadow
              : widget.boxShadow;

          return Transform.scale(
            scale: progress,
            child: Container(
              width: widget.width,
              height: widget.height,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: useTapGradient || widget.gradient != null
                    ? null
                    : defaultBg,
                gradient: useTapGradient
                    ? widget.tapGradient
                    : widget.gradient,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: currentShadow,
                border: widget.gradient == null && widget.tapGradient == null
                    ? Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                        width: 1,
                      )
                    : null,
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
