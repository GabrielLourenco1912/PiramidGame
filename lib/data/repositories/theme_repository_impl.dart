import '../../core/result/result.dart';
import '../../domain/models/theme_preference.dart';
import '../../domain/repositories/theme_repository.dart';
import '../services/theme_local_service.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  const ThemeRepositoryImpl(this._service);

  final ThemeLocalService _service;

  @override
  Future<Result<AppThemePreference>> getThemePreference() async {
    try {
      return Success(await _service.fetchThemePreference());
    } catch (error) {
      return Failure('Nao foi possivel carregar o tema.', cause: error);
    }
  }

  @override
  Future<Result<AppThemePreference>> updateThemePreference(
    AppThemePreference preference,
  ) async {
    try {
      await _service.saveThemePreference(preference);
      return Success(preference);
    } catch (error) {
      return Failure('Nao foi possivel atualizar o tema.', cause: error);
    }
  }
}
