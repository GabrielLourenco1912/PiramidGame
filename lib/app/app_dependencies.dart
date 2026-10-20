import 'package:flutter/widgets.dart';
import 'app_viewmodels.dart';
import '../presentation/viewmodels/auth_viewmodel.dart';
import '../presentation/viewmodels/student_viewmodel.dart';
import '../presentation/viewmodels/evaluation_viewmodel.dart';
import '../presentation/viewmodels/ranking_viewmodel.dart';
import '../presentation/viewmodels/theme_viewmodel.dart';

class AppDependencies extends InheritedWidget {
  const AppDependencies({
    required this.models,
    required super.child,
    super.key,
  });
  final AppViewModels models;
  AuthViewModel get authViewModel => models.auth;
  StudentViewModel get studentViewModel => models.students;
  EvaluationViewModel get evaluationViewModel => models.evaluations;
  RankingViewModel get rankingViewModel => models.rankings;
  ThemeViewModel get themeViewModel => models.theme;

  static AppDependencies of(BuildContext context) {
    final dependencies = context
        .dependOnInheritedWidgetOfExactType<AppDependencies>();
    assert(dependencies != null, 'AppDependencies não encontrado na árvore.');
    return dependencies!;
  }

  @override
  bool updateShouldNotify(AppDependencies oldWidget) =>
      models != oldWidget.models;
}
