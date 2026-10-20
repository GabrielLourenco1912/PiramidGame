import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../core/command/command.dart';
import '../../core/result/result.dart';
import '../../domain/facades/theme_use_cases_facade.dart';
import '../../domain/models/theme_preference.dart';

class ThemeViewModel {
  ThemeViewModel(this._facade) {
    loadThemeCommand = Command(_loadTheme);
    toggleThemeCommand = Command(_toggleTheme);
  }

  final ThemeUseCasesFacade _facade;

  final currentTheme = signal(AppThemePreference.light);
  final loading = signal(false);
  final errorMessage = signal<String?>(null);

  late final Command<AppThemePreference> loadThemeCommand;
  late final Command<AppThemePreference> toggleThemeCommand;

  ThemeMode get themeMode =>
      currentTheme.value.isDark ? ThemeMode.dark : ThemeMode.light;

  Future<Result<AppThemePreference>> _loadTheme() async {
    return _run(() async {
      final result = await _facade.current();
      if (result case Success<AppThemePreference>(:final data)) {
        currentTheme.value = data;
      }
      return result;
    });
  }

  Future<Result<AppThemePreference>> _toggleTheme() async {
    return _run(() async {
      final nextTheme = currentTheme.value.toggled;
      final result = await _facade.update(nextTheme);
      if (result case Success<AppThemePreference>(:final data)) {
        currentTheme.value = data;
      }
      return result;
    });
  }

  Future<Result<T>> _run<T>(Future<Result<T>> Function() action) async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final result = await action();
      if (result case Failure<T>(:final message)) {
        errorMessage.value = message;
      }
      return result;
    } catch (error) {
      const message = 'Nao foi possivel atualizar as preferencias.';
      errorMessage.value = message;
      return Failure<T>(message, cause: error);
    } finally {
      loading.value = false;
    }
  }
}
