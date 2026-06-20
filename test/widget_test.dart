import 'package:flutter_test/flutter_test.dart';
import 'package:calculator/app.dart';
import 'package:provider/provider.dart';
import 'package:calculator/features/settings/providers/settings_provider.dart';
import 'package:calculator/features/history/providers/history_provider.dart';
import 'package:calculator/features/calculator/providers/calculator_provider.dart';

void main() {
  testWidgets('App renders splash then calculator', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ChangeNotifierProvider(create: (_) => CalculatorProvider()),
        ],
        child: const NexaCalcApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Calculator'), findsOneWidget);
    expect(find.text('Next-Gen Calculator'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 5100));
    await tester.pump();

    expect(find.text('7'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
  });
}
