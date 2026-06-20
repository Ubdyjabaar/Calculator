import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/glass_container.dart';

class DisplaySection extends StatelessWidget {
  final String expression;
  final String result;
  final String previousExpression;
  final bool hasResult;

  const DisplaySection({
    super.key,
    required this.expression,
    required this.result,
    required this.previousExpression,
    required this.hasResult,
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
          final vPad = tight ? 8.0 : 14.0;
          final topFontSize = tight ? 14.0 : AppConstants.fontSizeExpression;
          final resultFontSize = _resultFontSize(result, tight);

          return GlassContainer(
            borderRadius: AppConstants.borderRadiusLarge,
            padding:
                EdgeInsets.symmetric(horizontal: 24, vertical: vPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomRight,
                    child: Text(
                      previousExpression.isNotEmpty
                          ? previousExpression
                          : expression,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.textTheme.headlineMedium?.color
                            ?.withValues(alpha: 0.5),
                        fontSize: topFontSize,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(height: tight ? 4 : 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomRight,
                    child: Text(
                      hasResult
                          ? result
                          : (expression.isEmpty ? '0' : expression),
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontSize: resultFontSize,
                        fontWeight: FontWeight.w300,
                        color: hasResult
                            ? Theme.of(context).colorScheme.primary
                            : theme.textTheme.displayMedium?.color,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
