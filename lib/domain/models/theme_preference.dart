enum AppThemePreference {
  light('light'),
  dark('dark');

  const AppThemePreference(this.storageValue);

  final String storageValue;

  bool get isDark => this == AppThemePreference.dark;

  AppThemePreference get toggled =>
      isDark ? AppThemePreference.light : AppThemePreference.dark;

  static AppThemePreference fromStorage(String? value) {
    return AppThemePreference.values.firstWhere(
      (preference) => preference.storageValue == value,
      orElse: () => AppThemePreference.light,
    );
  }
}
