import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/glass_container.dart';

class DisplaySection extends StatelessWidget {
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
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: vPad),
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
                        hasResult ? previousExpression : '',
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
                      if (!hasResult) {
                        _handleTap(context, details, tight);
                      }
                    },
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: _buildExpressionWithCursor(
                          context, theme, tight),
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
    final text = expression.isEmpty ? '0' : expression;
    final fontSize = _resultFontSize(text, tight);
    final approxCharWidth = fontSize * 0.6;
    final localX = details.localPosition.dx;
    final totalWidth = text.length * approxCharWidth;
    final ratio = (totalWidth - localX + 16) / totalWidth;
    final index = (text.length * (1 - ratio)).round().clamp(0, text.length);
    calc.setCursorPosition(index);
  }

  Widget _buildExpressionWithCursor(
      BuildContext context, ThemeData theme, bool tight) {
    final text = hasResult
        ? result
        : (expression.isEmpty ? '0' : expression);
    final fontSize = _resultFontSize(text, tight);

    if (hasResult) {
      return Text(
        text,
        style: theme.textTheme.displayMedium?.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w300,
          color: theme.colorScheme.primary,
        ),
        textAlign: TextAlign.right,
        maxLines: 1,
      );
    }

    final beforeCursor = expression.substring(0, cursorIndex);
    final afterCursor = expression.substring(cursorIndex);
    final isEmpty = expression.isEmpty;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: RichText(
        textAlign: TextAlign.right,
        text: TextSpan(
          children: [
            TextSpan(
              text: isEmpty ? '' : beforeCursor,
              style: theme.textTheme.displayMedium?.copyWith(
                fontSize: fontSize,
                fontWeight: FontWeight.w300,
                color: theme.textTheme.displayMedium?.color,
              ),
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                width: 2,
                height: fontSize * 0.85,
                color: theme.colorScheme.primary,
              ),
            ),
            TextSpan(
              text: afterCursor,
              style: theme.textTheme.displayMedium?.copyWith(
                fontSize: fontSize,
                fontWeight: FontWeight.w300,
                color: theme.textTheme.displayMedium?.color,
              ),
            ),
          ],
        ),
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
