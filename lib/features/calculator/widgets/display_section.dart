import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/glass_container.dart';

class DisplaySection extends StatefulWidget {
  final String expression;
  final String result;
  final String previousExpression;
  final bool hasResult;
  final int cursorIndex;

  const DisplaySection({
    super.key,
    required this.expression,
    required this.result,
    required this.previousExpression,
    required this.hasResult,
    required this.cursorIndex,
  });

  @override
  State<DisplaySection> createState() => _DisplaySectionState();
}

class _DisplaySectionState extends State<DisplaySection>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;
  late AnimationController _handleController;
  late AnimationController _bannerController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _handleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(DisplaySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expression != widget.expression) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCursor();
      });
    }
    if (oldWidget.cursorIndex != widget.cursorIndex && widget.cursorIndex >= 0) {
      _onCursorMoved();
    }
  }

  void _onCursorMoved() {
    _bannerController.forward(from: 0.0);
    _handleController.forward(from: 0.0);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _handleController.reverse();
    });
  }

  void _scrollToCursor() {
    if (_scrollController.hasClients && !widget.hasResult) {
      final fontSize = 30;
      final approxCharWidth = fontSize * 0.55;
      final cursorOffset = widget.cursorIndex * approxCharWidth;
      final viewportWidth = _scrollController.position.viewportDimension;
      final target = cursorOffset - viewportWidth + 40;
      if (target > 0) {
        _scrollController.animateTo(
          target.clamp(0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _cursorController.dispose();
    _handleController.dispose();
    _bannerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availH = constraints.maxHeight;
          final tight = availH < 130;
          final vPad = tight ? 8.0 : 12.0;

          return GlassContainer(
            borderRadius: AppConstants.borderRadiusLarge,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: vPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  flex: tight ? 1 : 1,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        widget.hasResult ? widget.previousExpression : '',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.textTheme.headlineMedium?.color
                              ?.withValues(alpha: 0.45),
                          fontSize: tight ? 16 : 22,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: tight ? 2 : 6),
                Flexible(
                  flex: tight ? 1 : 2,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      if (!widget.hasResult) {
                        _handleTap(context, details, tight);
                      }
                    },
                    onHorizontalDragUpdate: (details) {
                      if (!widget.hasResult) {
                        _handleDrag(context, details, tight);
                      }
                    },
                    onHorizontalDragEnd: (_) {
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) _handleController.reverse();
                      });
                    },
                    child: widget.hasResult
                        ? Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              widget.result,
                              style: theme.textTheme.displayMedium?.copyWith(
                                fontSize: _resultFontSize(
                                    widget.result, tight),
                                fontWeight: FontWeight.w300,
                                color: theme.colorScheme.primary,
                              ),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                            ),
                          )
                        : SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            child: _buildExpressionWithCursor(theme, tight),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleTap(BuildContext context, TapUpDetails details, bool tight) {
    final calc = context.read<CalculatorProvider>();
    final text = widget.expression;
    if (text.isEmpty) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localX = box.globalToLocal(details.globalPosition).dx;
    final displayWidth = box.size.width - 40;
    final tapRatio = (displayWidth - localX + 20) / displayWidth;
    final index = (text.length * tapRatio.clamp(0.0, 1.0)).round().clamp(0, text.length);
    calc.setCursorPosition(index);
  }

  void _handleDrag(BuildContext context, DragUpdateDetails details, bool tight) {
    final calc = context.read<CalculatorProvider>();
    if (widget.expression.isEmpty) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localX = box.globalToLocal(details.globalPosition).dx;
    final displayWidth = box.size.width - 40;
    final tapRatio = (displayWidth - localX + 20) / displayWidth;
    final index = (widget.expression.length * tapRatio.clamp(0.0, 1.0)).round().clamp(0, widget.expression.length);
    calc.setCursorPosition(index);
  }

  Widget _buildExpressionWithCursor(ThemeData theme, bool tight) {
    final before = widget.expression.substring(0, widget.cursorIndex);
    final after = widget.expression.substring(widget.cursorIndex);
    final fontSize = _resultFontSize(widget.expression, tight);
    final cursorH = fontSize * 0.65;
    final handleSize = 10.0;

    return Stack(
      children: [
        RichText(
          textAlign: TextAlign.right,
          text: TextSpan(
            children: [
              TextSpan(
                text: before,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w300,
                  color: theme.textTheme.displayMedium?.color,
                ),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.aboveBaseline,
                baseline: TextBaseline.alphabetic,
                child: _CursorPainter(
                  cursorController: _cursorController,
                  handleController: _handleController,
                  bannerController: _bannerController,
                  cursorHeight: cursorH,
                  fontSize: fontSize,
                  handleSize: handleSize,
                  primaryColor: theme.colorScheme.primary,
                ),
              ),
              TextSpan(
                text: after,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w300,
                  color: theme.textTheme.displayMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _resultFontSize(String text, bool tight) {
    if (tight) {
      if (text.length <= 6) return 36;
      if (text.length <= 10) return 28;
      return 22;
    }
    if (text.length <= 6) return AppConstants.fontSizeResult;
    if (text.length <= 10) return 40;
    if (text.length <= 14) return 32;
    return 26;
  }
}

class _CursorPainter extends AnimatedWidget {
  final AnimationController cursorController;
  final AnimationController handleController;
  final AnimationController bannerController;
  final double cursorHeight;
  final double fontSize;
  final double handleSize;
  final Color primaryColor;

  _CursorPainter({
    required this.cursorController,
    required this.handleController,
    required this.bannerController,
    required this.cursorHeight,
    required this.fontSize,
    required this.handleSize,
    required this.primaryColor,
  }) : super(listenable: Listenable.merge([cursorController, handleController, bannerController]));

  @override
  Widget build(BuildContext context) {
    final cursorOpacity = cursorController.value;
    final handleOpacity = handleController.value;
    final bannerProgress = bannerController.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 2.5,
              height: cursorHeight,
              margin: EdgeInsets.only(top: fontSize * 0.25),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: cursorOpacity),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            if (bannerProgress > 0.01)
              Positioned(
                left: -8,
                right: -8,
                top: fontSize * 0.15,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: (1 - bannerProgress) * 0.5,
                    child: Container(
                      height: cursorHeight + 6,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: (1 - bannerProgress) * 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (handleOpacity > 0.01)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: IgnorePointer(
              child: Opacity(
                opacity: handleOpacity,
                child: Container(
                  width: handleSize,
                  height: handleSize,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
