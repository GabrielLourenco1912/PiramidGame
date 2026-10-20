import '../../core/constants/app_constants.dart';
import '../../domain/models/theme_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeLocalService {
  const ThemeLocalService(this._preferences);

  final SharedPreferences _preferences;

  Future<AppThemePreference> fetchThemePreference() async {
    return AppThemePreference.fromStorage(
      _preferences.getString(AppConstants.themeStorageKey),
    );
  }

  Future<void> saveThemePreference(AppThemePreference preference) async {
    final saved = await _preferences.setString(
      AppConstants.themeStorageKey,
      preference.storageValue,
    );
    if (!saved) throw StateError('Não foi possível salvar o tema.');
  }
}
