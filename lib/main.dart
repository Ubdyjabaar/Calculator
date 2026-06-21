import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'features/calculator/providers/calculator_provider.dart';
import 'features/history/providers/history_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/converter/providers/converter_provider.dart';
import 'features/ai/providers/ai_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProxyProvider<HistoryProvider, CalculatorProvider>(
          create: (_) => CalculatorProvider(),
          update: (_, history, calc) => calc!..setHistoryProvider(history),
        ),
        ChangeNotifierProvider(create: (_) => ConverterProvider()),
        ChangeNotifierProvider(create: (_) => AIProvider()),
      ],
      child: const NexaCalcApp(),
    ),
  );
}
