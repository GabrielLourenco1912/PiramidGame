import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app_viewmodels.dart';
import 'app/app_widget.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/evaluation_repository_impl.dart';
import 'data/repositories/student_repository_impl.dart';
import 'data/repositories/theme_repository_impl.dart';
import 'data/services/auth_service.dart';
import 'data/services/firestore_service.dart';
import 'data/services/theme_local_service.dart';
import 'firebase_options.dart';
import 'presentation/pages/firebase_setup_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final preferences = await SharedPreferences.getInstance();
    final firestore = FirestoreService(FirebaseFirestore.instance);
    final auth = AuthRepositoryImpl(
      AuthService(FirebaseAuth.instance),
      firestore,
    );
    final models = AppViewModels(
      authRepository: auth,
      studentRepository: StudentRepositoryImpl(firestore, auth),
      evaluationRepository: EvaluationRepositoryImpl(firestore, auth),
      themeRepository: ThemeRepositoryImpl(ThemeLocalService(preferences)),
    );
    await models.theme.loadThemeCommand.execute();
    runApp(AppWidget(models: models));
  } catch (error) {
    runApp(FirebaseSetupPage(message: error.toString()));
  }
}
