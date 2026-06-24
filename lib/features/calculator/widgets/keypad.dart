import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/animated_button.dart';

class Keypad extends StatelessWidget {
  final void Function(String) onNumber;
  final void Function(String) onOperator;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final VoidCallback onEquals;
  final VoidCallback onToggleSign;
  final VoidCallback onPercent;
  final VoidCallback onDecimal;
  final bool hapticFeedback;

  const Keypad({
    super.key,
    required this.onNumber,
    required this.onOperator,
    required this.onClear,
    required this.onBackspace,
    required this.onEquals,
    required this.onToggleSign,
    required this.onPercent,
    required this.onDecimal,
    this.hapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textColorMuted =
        isDark ? Colors.white70 : const Color(0xFF1A1A2E).withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 4.0;
          const totalRows = 5;
          const overhead = (totalRows - 1) * gap;
          final buttonHeight =
              ((constraints.maxHeight - overhead) / totalRows).clamp(20.0, 74.0);
          const innerPad = 3.0;

          return Column(
            children: [
              _buildRow([
                _buildUtilityButton('AC', onClear, textColorMuted, isDark, buttonHeight, innerPad),
                _buildUtilityButton('±', onToggleSign, textColorMuted, isDark, buttonHeight, innerPad),
                _buildUtilityButton('%', onPercent, textColorMuted, isDark, buttonHeight, innerPad),
                _buildOperatorButton('÷', () => onOperator('÷'), primaryColor, isDark, buttonHeight, innerPad),
              ]),
              SizedBox(height: gap),
              _buildRow([
                _buildNumberButton('7', textColor, isDark, buttonHeight, innerPad),
                _buildNumberButton('8', textColor, isDark, buttonHeight, innerPad),
                _buildNumberButton('9', textColor, isDark, buttonHeight, innerPad),
                _buildOperatorButton('×', () => onOperator('×'), primaryColor, isDark, buttonHeight, innerPad),
              ]),
              SizedBox(height: gap),
              _buildRow([
                _buildNumberButton('4', textColor, isDark, buttonHeight, innerPad),
                _buildNumberButton('5', textColor, isDark, buttonHeight, innerPad),
                _buildNumberButton('6', textColor, isDark, buttonHeight, innerPad),
                _buildOperatorButton('-', () => onOperator('-'), primaryColor, isDark, buttonHeight, innerPad),
              ]),
              SizedBox(height: gap),
              _buildRow([
                _buildNumberButton('1', textColor, isDark, buttonHeight, innerPad),
                _buildNumberButton('2', textColor, isDark, buttonHeight, innerPad),
                _buildNumberButton('3', textColor, isDark, buttonHeight, innerPad),
                _buildOperatorButton('+', () => onOperator('+'), primaryColor, isDark, buttonHeight, innerPad),
              ]),
              SizedBox(height: gap),
              _buildRow([
                _buildNumberButton('0', textColor, isDark, buttonHeight, innerPad, flex: 2),
                _buildNumberButton('.', textColor, isDark, buttonHeight, innerPad),
                _buildBackspaceButton(textColorMuted, isDark, buttonHeight, innerPad),
                _buildEqualsButton(primaryColor, buttonHeight, innerPad),
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
          .map((w) => w is Expanded ? w : Expanded(child: w))
          .toList(),
    );
  }

  Widget _buildNumberButton(String digit, Color textColor, bool isDark,
      double buttonHeight, double innerPad,
      {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: innerPad, vertical: innerPad / 2),
        child: AnimatedButton(
          onTap: () => onNumber(digit),
          hapticFeedback: hapticFeedback,
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: AppConstants.borderRadiusSmall,
          height: buttonHeight,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
          tapBoxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF4F80BF).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const List<Color> _actionGradient = [
    Color(0xFF0D7D55),
    Color(0xFF4F80BF),
  ];

  Widget _buildOperatorButton(String op, VoidCallback onTap,
      Color primaryColor, bool isDark, double buttonHeight, double innerPad) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: innerPad, vertical: innerPad / 2),
      child: AnimatedButton(
        onTap: onTap,
        hapticFeedback: hapticFeedback,
        backgroundColor: primaryColor.withValues(alpha: 0.15),
        tapGradient: LinearGradient(
          colors: _actionGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppConstants.borderRadiusSmall,
        height: buttonHeight,
        tapBoxShadow: [
          BoxShadow(
            color: const Color(0xFF0D7D55).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        child: Center(
          child: Text(
            op,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUtilityButton(String label, VoidCallback onTap,
      Color textColor, bool isDark, double buttonHeight, double innerPad) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: innerPad, vertical: innerPad / 2),
      child: AnimatedButton(
        onTap: onTap,
        hapticFeedback: hapticFeedback,
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: AppConstants.borderRadiusSmall,
        height: buttonHeight,
        tapBoxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(
      Color textColor, bool isDark, double buttonHeight, double innerPad) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: innerPad, vertical: innerPad / 2),
      child: AnimatedButton(
        onTap: onBackspace,
        hapticFeedback: hapticFeedback,
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: AppConstants.borderRadiusSmall,
        height: buttonHeight,
        tapBoxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            color: textColor,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildEqualsButton(Color primaryColor, double buttonHeight, double innerPad) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: innerPad, vertical: innerPad / 2),
      child: AnimatedButton(
        onTap: onEquals,
        hapticFeedback: hapticFeedback,
        backgroundColor: primaryColor.withValues(alpha: 0.2),
        tapGradient: LinearGradient(
          colors: _actionGradient.reversed.toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppConstants.borderRadiusSmall,
        height: buttonHeight,
        tapBoxShadow: [
          BoxShadow(
            color: const Color(0xFF0D7D55).withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        child: Center(
          child: Text(
            '=',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
