import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme_bloc.dart';
import 'theme_event.dart';
import 'theme_state.dart';
import 'simple_bloc_observer.dart';

void main() {
  // Sets the BlocObserver for debugging purposes
  Bloc.observer = SimpleBlocObserver();

  runApp(
    BlocProvider(
      create: (_) => ThemeBloc(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: state.themeData.copyWith(useMaterial3: true),
          home: const ThemeScreen(),
        );
      },
    );
  }
}

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Theme Switcher BLoC",
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [

            Icon(
              isDark
                  ? Icons.dark_mode
                  : Icons.light_mode,
              size: 100,
            ),

            const SizedBox(height: 20),

            Text(
              isDark
                  ? "Dark Mode"
                  : "Light Mode",
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton.icon(
              onPressed: () {
                context
                    .read<ThemeBloc>()
                    .add(ToggleTheme());
              },
              icon: const Icon(Icons.swap_horiz),
              label: const Text(
                "Switch Theme",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
