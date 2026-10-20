import '../domain/facades/auth_facade.dart';
import '../domain/facades/evaluation_facade.dart';
import '../domain/facades/ranking_facade.dart';
import '../domain/facades/student_use_cases_facade.dart';
import '../domain/facades/theme_use_cases_facade.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/evaluation_repository.dart';
import '../domain/repositories/student_repository.dart';
import '../domain/repositories/theme_repository.dart';
import '../domain/use_cases/auth_use_cases.dart';
import '../domain/use_cases/evaluation_use_cases.dart';
import '../domain/use_cases/ranking_use_cases.dart';
import '../domain/use_cases/create_student_use_case.dart';
import '../domain/use_cases/update_student_use_case.dart';
import '../domain/use_cases/delete_student_use_case.dart';
import '../domain/use_cases/get_students_use_case.dart';
import '../domain/use_cases/get_student_by_id_use_case.dart';
import '../domain/use_cases/get_theme_mode_use_case.dart';
import '../domain/use_cases/update_theme_mode_use_case.dart';
import '../presentation/viewmodels/auth_viewmodel.dart';
import '../presentation/viewmodels/evaluation_viewmodel.dart';
import '../presentation/viewmodels/ranking_viewmodel.dart';
import '../presentation/viewmodels/student_viewmodel.dart';
import '../presentation/viewmodels/theme_viewmodel.dart';

class AppViewModels {
  AppViewModels({
    required AuthRepository authRepository,
    required StudentRepository studentRepository,
    required EvaluationRepository evaluationRepository,
    required ThemeRepository themeRepository,
  }) : auth = AuthViewModel(
         AuthFacade(
           registerUser: RegisterUserUseCase(authRepository),
           loginUser: LoginUseCase(authRepository),
           loginGoogle: LoginWithGoogleUseCase(authRepository),
           restore: RestoreSessionUseCase(authRepository),
           watch: WatchSessionUseCase(authRepository),
           signOut: LogoutUseCase(authRepository),
         ),
       ),
       students = StudentViewModel(
         StudentUseCasesFacade(
           createStudent: CreateStudentUseCase(studentRepository),
           updateStudent: UpdateStudentUseCase(studentRepository),
           deleteStudent: DeleteStudentUseCase(studentRepository),
           getStudents: GetStudentsUseCase(studentRepository),
           getStudentById: GetStudentByIdUseCase(studentRepository),
         ),
       ),
       evaluations = EvaluationViewModel(
         EvaluationFacade(
           saveEvaluation: SaveEvaluationUseCase(
             evaluationRepository,
             studentRepository,
             authRepository,
           ),
           getEvaluation: GetEvaluationUseCase(
             evaluationRepository,
             authRepository,
           ),
           getMyEvaluations: GetMyEvaluationsUseCase(
             evaluationRepository,
             authRepository,
           ),
         ),
       ),
       rankings = RankingViewModel(
         RankingFacade(
           personalRanking: CalculatePersonalRankingUseCase(
             studentRepository,
             evaluationRepository,
             authRepository,
           ),
           globalRanking: CalculateGlobalRankingUseCase(
             studentRepository,
             evaluationRepository,
             authRepository,
           ),
         ),
       ),
       theme = ThemeViewModel(
         ThemeUseCasesFacade(
           getThemeMode: GetThemeModeUseCase(themeRepository),
           updateThemeMode: UpdateThemeModeUseCase(themeRepository),
         ),
       );

  final AuthViewModel auth;
  final StudentViewModel students;
  final EvaluationViewModel evaluations;
  final RankingViewModel rankings;
  final ThemeViewModel theme;

  void clearSession() {
    students.clearSession();
    evaluations.clearSession();
    rankings.clearSession();
  }
}
