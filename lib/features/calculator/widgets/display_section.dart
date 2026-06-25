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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(DisplaySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expression != widget.expression) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCursor();
      });
    }
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
    final fontSize = 30;
    final approxCharWidth = fontSize * 0.55;
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

    return RichText(
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
            child: AnimatedBuilder(
              animation: _cursorController,
              builder: (context, _) {
                final opacity = _cursorController.value;
                return Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 2.5,
                    height: fontSize * 0.65,
                    margin: EdgeInsets.only(top: fontSize * 0.25),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                );
              },
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
