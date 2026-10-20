import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/pages/about_page.dart';
import '../../presentation/pages/auth_page.dart';
import '../../presentation/pages/evaluation_page.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/pages/ranking_page.dart';
import '../../presentation/pages/splash_page.dart';
import '../../presentation/pages/student_detail_page.dart';
import '../../presentation/pages/student_form_page.dart';
import '../../presentation/pages/student_list_page.dart';
import '../../presentation/widgets/app_scaffold.dart';

class AppRouter {
  const AppRouter._();

  static GoRouter create(AuthViewModel auth) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: auth,
      redirect: (context, state) {
        final path = state.uri.path;
        if (!auth.splashFinished.value || !auth.initialized.value) {
          return path == AppRoutes.splash ? null : AppRoutes.splash;
        }
        final isPublic = path == AppRoutes.login || path == AppRoutes.register;
        if (!auth.isAuthenticated) return isPublic ? null : AppRoutes.login;
        if (isPublic || path == AppRoutes.splash) return AppRoutes.home;
        return null;
      },
      routes: [
        GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
        GoRoute(path: AppRoutes.login, builder: (_, _) => const AuthPage()),
        GoRoute(
          path: AppRoutes.register,
          builder: (_, _) => const AuthPage(registration: true),
        ),
        ShellRoute(
          builder: (_, state, child) =>
              AppScaffold(location: state.uri.path, child: child),
          routes: [
            GoRoute(
              path: AppRoutes.home,
              pageBuilder: (_, _) => _page(const HomePage()),
            ),
            GoRoute(
              path: AppRoutes.students,
              pageBuilder: (_, _) => _page(const StudentListPage()),
            ),
            GoRoute(
              path: AppRoutes.newStudent,
              pageBuilder: (_, _) => _page(const StudentFormPage()),
            ),
            GoRoute(
              path: '/students/:id/edit',
              pageBuilder: (_, state) => _page(
                StudentFormPage(studentId: state.pathParameters['id']!),
              ),
            ),
            GoRoute(
              path: '/students/:id/evaluate',
              pageBuilder: (_, state) =>
                  _page(EvaluationPage(studentId: state.pathParameters['id']!)),
            ),
            GoRoute(
              path: '/students/:id',
              pageBuilder: (_, state) => _page(
                StudentDetailPage(studentId: state.pathParameters['id']!),
              ),
            ),
            GoRoute(
              path: AppRoutes.ranking,
              pageBuilder: (_, _) => _page(const RankingPage()),
            ),
            GoRoute(
              path: AppRoutes.globalRanking,
              pageBuilder: (_, _) => _page(const RankingPage(global: true)),
            ),
            GoRoute(
              path: AppRoutes.about,
              pageBuilder: (_, _) => _page(const AboutPage()),
            ),
          ],
        ),
      ],
    );
  }

  static NoTransitionPage<void> _page(Widget child) =>
      NoTransitionPage<void>(child: child);
}
