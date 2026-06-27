import 'dart:ui';
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
import '../../ai/screens/ai_screen.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final calc = context.read<CalculatorProvider>();
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return Scaffold(
      drawer: Drawer(
        elevation: 0,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: brightness == Brightness.dark
                    ? const Color(0xFF1A1A2E).withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95),
                border: Border(
                  right: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
              ),
              child: const SettingsPanel(),
            ),
          ),
        ),
      ),
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
    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Settings',
        ),
      ),
      title: const Text(AppConstants.appName),
      centerTitle: true,
      actions: [
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
        IconButton(
          icon: const Icon(Icons.auto_awesome),
          onPressed: () => _openAI(context),
          tooltip: 'AI Math Solver',
        ),
      ],
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
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.calculate_outlined),
              selectedIcon: Icon(Icons.calculate),
              label: 'Standard',
            ),
            const NavigationDestination(
              icon: Icon(Icons.science_outlined),
              selectedIcon: Icon(Icons.science),
              label: 'Scientific',
            ),
            const NavigationDestination(
              icon: Icon(Icons.show_chart_outlined),
              selectedIcon: Icon(Icons.show_chart),
              label: 'Graphing',
            ),
            NavigationDestination(
              icon: AnimatedRotation(
                turns: mode == CalculatorMode.converter ? 0.5 : 0,
                duration: const Duration(milliseconds: 400),
                child: const Icon(Icons.swap_horiz_outlined),
              ),
              selectedIcon: AnimatedRotation(
                turns: mode == CalculatorMode.converter ? 0.5 : 0,
                duration: const Duration(milliseconds: 400),
                child: const Icon(Icons.swap_horiz),
              ),
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
        final bg = Theme.of(context).scaffoldBackgroundColor;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Container(
            key: ValueKey(mode),
            color: bg,
            child: _buildContent(context, c),
          ),
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

        int displayFlex = showScientific ? 4 : 4;
        int sciFlex = showScientific ? 3 : 0;
        int keyFlex = showScientific ? 4 : 5;

        if (isShort) {
          displayFlex = showScientific ? 3 : 3;
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
                cursorIndex: c.cursorIndex,
              ),
              builder: (context, data, _) {
                return Column(
                  children: [
                    Expanded(
                      flex: displayFlex,
                      child: DisplaySection(
                        expression: data.expression,
                        result: data.result,
                        previousExpression: data.previousExpression,
                        hasResult: data.hasResult,
                        cursorIndex: data.cursorIndex,
                      ),
                    ),
                  ],
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
                  hapticFeedback: false,
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
                hapticFeedback: false,
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

  void _openAI(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AIScreen(),
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

}

class _DisplayData {
  final String expression;
  final String result;
  final String previousExpression;
  final bool hasResult;
  final int cursorIndex;

  const _DisplayData({
    required this.expression,
    required this.result,
    required this.previousExpression,
    required this.hasResult,
    required this.cursorIndex,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _DisplayData &&
          expression == other.expression &&
          result == other.result &&
          previousExpression == other.previousExpression &&
          hasResult == other.hasResult &&
          cursorIndex == other.cursorIndex;

  @override
  int get hashCode =>
      Object.hash(expression, result, previousExpression, hasResult, cursorIndex);
}
