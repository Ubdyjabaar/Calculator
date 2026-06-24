import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/animated_button.dart';

class ScientificKeypad extends StatelessWidget {
  final void Function(String) onFunction;
  final VoidCallback onLeftParen;
  final VoidCallback onRightParen;
  final VoidCallback onToggleDegrees;
  final bool degreesMode;
  final bool hapticFeedback;

  const ScientificKeypad({
    super.key,
    required this.onFunction,
    required this.onLeftParen,
    required this.onRightParen,
    required this.onToggleDegrees,
    required this.degreesMode,
    this.hapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 4.0;
          const rowCount = 3;
          const overhead = (rowCount - 1) * gap;
          final btnH =
              ((constraints.maxHeight - overhead) / rowCount).clamp(22.0, 56.0);

          return Column(
            children: [
              _buildRow([
                _sci(context, 'sin', btnH),
                _sci(context, 'cos', btnH),
                _sci(context, 'tan', btnH),
                _sci(context, 'log', btnH),
              ]),
              SizedBox(height: gap),
              _buildRow([
                _sci(context, 'ln', btnH),
                _sci(context, '√', btnH),
                _sci(context, 'π', btnH),
                _sci(context, 'e', btnH),
              ]),
              SizedBox(height: gap),
              _buildRow([
                _paren(context, '(', onLeftParen, btnH),
                _paren(context, ')', onRightParen, btnH),
                _op(context, '^', btnH),
                _deg(context, btnH),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Row(
      children: children
          .map((w) => Expanded(
              child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: w,
                  )))
          .toList(),
    );
  }

  Widget _sci(BuildContext context, String label, double height) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedButton(
      onTap: () => onFunction(_key(label)),
      hapticFeedback: hapticFeedback,
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.06),
      borderRadius: 12,
      height: height,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppConstants.fontSizeScientific,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
      ),
    );
  }

  Widget _paren(BuildContext context, String label, VoidCallback onTap, double height) {
    return AnimatedButton(
      onTap: onTap,
      hapticFeedback: hapticFeedback,
      backgroundColor: Theme.of(context)
          .colorScheme
          .primary
          .withValues(alpha: 0.15),
      borderRadius: 12,
      height: height,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _op(BuildContext context, String label, double height) {
    return AnimatedButton(
      onTap: () => onFunction('^'),
      hapticFeedback: hapticFeedback,
      backgroundColor: Theme.of(context)
          .colorScheme
          .secondary
          .withValues(alpha: 0.15),
      borderRadius: 12,
      height: height,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
    );
  }

  Widget _deg(BuildContext context, double height) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedButton(
      onTap: onToggleDegrees,
      hapticFeedback: hapticFeedback,
      backgroundColor: degreesMode
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
          : (isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04)),
      borderRadius: 12,
      height: height,
      child: Center(
        child: Text(
          degreesMode ? 'DEG' : 'RAD',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: degreesMode
                ? Theme.of(context).colorScheme.primary
                : (isDark
                    ? Colors.white70
                    : const Color(0xFF1A1A2E).withValues(alpha: 0.7)),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  String _key(String label) {
    return label == '√' ? 'sqrt' : label;
  }
}
