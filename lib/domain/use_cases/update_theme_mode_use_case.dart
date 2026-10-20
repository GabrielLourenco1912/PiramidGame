import '../../core/result/result.dart';
import '../models/theme_preference.dart';
import '../repositories/theme_repository.dart';

class UpdateThemeModeUseCase {
  const UpdateThemeModeUseCase(this._repository);

  final ThemeRepository _repository;

  Future<Result<AppThemePreference>> call(AppThemePreference preference) {
    return _repository.updateThemePreference(preference);
  }
}
