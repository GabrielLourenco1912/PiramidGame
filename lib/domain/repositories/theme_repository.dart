import '../../core/result/result.dart';
import '../models/theme_preference.dart';

abstract interface class ThemeRepository {
  Future<Result<AppThemePreference>> getThemePreference();
  Future<Result<AppThemePreference>> updateThemePreference(
    AppThemePreference preference,
  );
}
