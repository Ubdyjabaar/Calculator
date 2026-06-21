import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../widgets/display_section.dart';
import '../widgets/keypad.dart';
import '../widgets/scientific_keypad.dart';
import '../widgets/graph_widget.dart';
import '../widgets/scan_screen.dart';
import '../widgets/graph_input.dart';
import '../../history/screens/history_screen.dart';
import '../../../shared/widgets/settings_panel.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/responsive_wrapper.dart';
import '../../converter/screens/converter_screen.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final calc = context.read<CalculatorProvider>();
    return Scaffold(
      body: SafeArea(
        child: ResponsiveWrapper(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(child: _buildBody(context, calc)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final mode = context.watch<CalculatorProvider>().mode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _showSettingsPanel(context),
            tooltip: 'Settings',
          ),
          const Spacer(),
          Text(
            AppConstants.appName,
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
          const Spacer(),
          if (mode == CalculatorMode.scientific)
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined),
              onPressed: () => _openScan(context),
              tooltip: 'Scan & Solve',
            ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(context),
            tooltip: 'History',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Selector<CalculatorProvider, CalculatorMode>(
      selector: (_, calc) => calc.mode,
      builder: (context, mode, _) {
        return NavigationBar(
          selectedIndex: mode.index,
          onDestinationSelected: (i) {
            context.read<CalculatorProvider>().setMode(CalculatorMode.values[i]);
          },
          backgroundColor: Colors.transparent,
          indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          shadowColor: Colors.transparent,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calculate_outlined),
              selectedIcon: Icon(Icons.calculate),
              label: 'Standard',
            ),
            NavigationDestination(
              icon: Icon(Icons.science_outlined),
              selectedIcon: Icon(Icons.science),
              label: 'Scientific',
            ),
            NavigationDestination(
              icon: Icon(Icons.show_chart_outlined),
              selectedIcon: Icon(Icons.show_chart),
              label: 'Graphing',
            ),
            NavigationDestination(
              icon: Icon(Icons.swap_horiz_outlined),
              selectedIcon: Icon(Icons.swap_horiz),
              label: 'Convert',
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CalculatorProvider calc) {
    return Selector<CalculatorProvider, CalculatorMode>(
      selector: (_, c) => c.mode,
      builder: (context, mode, _) {
        final c = context.read<CalculatorProvider>();
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _buildContent(context, c),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, CalculatorProvider calc) {
    switch (calc.mode) {
      case CalculatorMode.standard:
        return _buildCalculatorLayout(context, calc, showScientific: false);
      case CalculatorMode.scientific:
        return _buildCalculatorLayout(context, calc, showScientific: true);
      case CalculatorMode.graphing:
        return _buildGraphingLayout(context, calc);
      case CalculatorMode.converter:
        return const ConverterScreen();
    }
  }

  Widget _buildCalculatorLayout(
      BuildContext context, CalculatorProvider calc,
      {required bool showScientific}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final isShort = totalHeight < 600;

        int displayFlex = showScientific ? 3 : 3;
        int sciFlex = showScientific ? 3 : 0;
        int keyFlex = showScientific ? 4 : 5;

        if (isShort) {
          displayFlex = showScientific ? 2 : 2;
          sciFlex = showScientific ? 2 : 0;
          keyFlex = showScientific ? 5 : 5;
        }

        return Column(
          key: ValueKey('calc_$showScientific'),
          children: [
            Selector<CalculatorProvider, _DisplayData>(
              selector: (_, c) => _DisplayData(
                expression: c.expression,
                result: c.result,
                previousExpression: c.previousExpression,
                hasResult: c.hasResult,
              ),
              builder: (context, data, _) {
                return Expanded(
                  flex: displayFlex,
                  child: DisplaySection(
                    expression: data.expression,
                    result: data.result,
                    previousExpression: data.previousExpression,
                    hasResult: data.hasResult,
                  ),
                );
              },
            ),
            if (showScientific)
              Expanded(
                flex: sciFlex,
                child: ScientificKeypad(
                  onFunction: calc.inputFunction,
                  onLeftParen: calc.inputLeftParen,
                  onRightParen: calc.inputRightParen,
                  onToggleDegrees: calc.toggleDegrees,
                  degreesMode: calc.degreesMode,
                  hapticFeedback: true,
                ),
              ),
            Expanded(
              flex: keyFlex,
              child: Keypad(
                onNumber: calc.inputNumber,
                onOperator: calc.inputOperator,
                onClear: calc.clear,
                onBackspace: calc.backspace,
                onEquals: calc.calculate,
                onToggleSign: calc.toggleSign,
                onPercent: calc.percent,
                onDecimal: calc.inputDecimal,
                hapticFeedback: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGraphingLayout(BuildContext context, CalculatorProvider calc) {
    return Column(
      key: const ValueKey('graph'),
      children: [
        const GraphInput(),
        Expanded(
          child: GraphWidget(evaluate: calc.evaluateGraphFunction),
        ),
      ],
    );
  }

  void _openScan(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ScanScreen(),
      ),
    );
  }

  void _showHistory(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const HistoryScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _showSettingsPanel(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Settings',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const Material(
          type: MaterialType.transparency,
          child: SettingsPanel(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FractionallySizedBox(
            widthFactor: 0.88,
            child: child,
          ),
        );
      },
    );
  }
}

class _DisplayData {
  final String expression;
  final String result;
  final String previousExpression;
  final bool hasResult;

  const _DisplayData({
    required this.expression,
    required this.result,
    required this.previousExpression,
    required this.hasResult,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _DisplayData &&
          expression == other.expression &&
          result == other.result &&
          previousExpression == other.previousExpression &&
          hasResult == other.hasResult;

  @override
  int get hashCode =>
      Object.hash(expression, result, previousExpression, hasResult);
}
