import '../../core/result/result.dart';
import '../models/theme_preference.dart';
import '../repositories/theme_repository.dart';

class GetThemeModeUseCase {
  const GetThemeModeUseCase(this._repository);

  final ThemeRepository _repository;

  Future<Result<AppThemePreference>> call() => _repository.getThemePreference();
}
