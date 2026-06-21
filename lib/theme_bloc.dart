import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';

import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {

  ThemeBloc()
      : super(
    ThemeState(AppTheme.light()),
  ) {

    on<ToggleTheme>((event, emit) {

      if (state.themeData.brightness ==
          Brightness.light) {

        emit(
          ThemeState(
            AppTheme.dark(),
          ),
        );

      } else {

        emit(
          ThemeState(
            AppTheme.light(),
          ),
        );
      }
    });
  }
}
