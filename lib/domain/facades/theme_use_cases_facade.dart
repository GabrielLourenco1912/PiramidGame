import '../../core/result/result.dart';
import '../models/theme_preference.dart';
import '../use_cases/get_theme_mode_use_case.dart';
import '../use_cases/update_theme_mode_use_case.dart';

class ThemeUseCasesFacade {
  const ThemeUseCasesFacade({
    required this.getThemeMode,
    required this.updateThemeMode,
  });

  final GetThemeModeUseCase getThemeMode;
  final UpdateThemeModeUseCase updateThemeMode;

  Future<Result<AppThemePreference>> current() => getThemeMode();
  Future<Result<AppThemePreference>> update(AppThemePreference preference) {
    return updateThemeMode(preference);
  }
}
