class AppConstants {
  const AppConstants._();

  static const appName = 'PiramidGame IFPR-Pgua';
  static const appAlias = 'O Nível Lenda do campus';
  static const campusName = 'IFPR - Campus Paranaguá';
  static const legendScoreLabel = 'Nível Lenda';

  static const minClassYear = 1998;
  static const maxClassYear = 2026;

  static const themeStorageKey = 'piramidgame_theme_mode';
}

class AppRoutes {
  const AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const students = '/students';
  static const newStudent = '/students/new';
  static const ranking = '/ranking';
  static const globalRanking = '/ranking/global';
  static const about = '/about';

  static String studentDetail(String id) => '/students/$id';
  static String studentEdit(String id) => '/students/$id/edit';
  static String studentEvaluation(String id) => '/students/$id/evaluate';
}
