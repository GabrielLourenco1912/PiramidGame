import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../core/constants/app_constants.dart';
import 'app_dependencies.dart';
import 'app_viewmodels.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class AppWidget extends SignalStatefulWidget {
  const AppWidget({required this.models, super.key});
  final AppViewModels models;

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  late final GoRouter _router;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = widget.models.auth.user.value?.uid;
    widget.models.auth.addListener(_sessionChanged);
    _router = AppRouter.create(widget.models.auth);
  }

  void _sessionChanged() {
    final uid = widget.models.auth.user.value?.uid;
    if (uid != _uid) {
      _uid = uid;
      widget.models.clearSession();
    }
  }

  @override
  void dispose() {
    widget.models.auth.removeListener(_sessionChanged);
    _router.dispose();
    widget.models.auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: widget.models.theme.themeMode,
      routerConfig: _router,
      builder: (context, child) => AppDependencies(
        models: widget.models,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
