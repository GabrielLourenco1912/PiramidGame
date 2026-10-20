import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../app/app_dependencies.dart';
import '../../core/constants/app_constants.dart';
import 'ifpr_mark.dart';

class AppScaffold extends SignalWidget {
  const AppScaffold({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final themeViewModel = AppDependencies.of(context).themeViewModel;
    final auth = AppDependencies.of(context).authViewModel;
    final isDark = themeViewModel.currentTheme.value.isDark;
    final selectedIndex = _selectedIndex(location);
    final width = MediaQuery.sizeOf(context).width;
    final showRail = width >= 840;
    final extendRail = width >= 1120;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        leading: _isStudentSubpage(location)
            ? IconButton(
                tooltip: 'Voltar para alunos',
                onPressed: () => context.go(AppRoutes.students),
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IfprMark(size: 30),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                _titleFor(location),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sair da conta',
            icon: const Icon(Icons.logout_rounded),
            onPressed: auth.busy.value
                ? null
                : () async {
                    final result = await auth.logoutCommand.execute();
                    if (!context.mounted || result.isSuccess) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          auth.errorMessage.value ?? 'Não foi possível sair.',
                        ),
                      ),
                    );
                  },
          ),
          IconButton.filledTonal(
            tooltip: isDark ? 'Usar tema claro' : 'Usar tema escuro',
            onPressed: () => themeViewModel.toggleThemeCommand.execute(),
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
          ),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      body: showRail
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  extended: extendRail,
                  labelType: extendRail
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  groupAlignment: -0.72,
                  minExtendedWidth: 212,
                  onDestinationSelected: (index) => _goTo(index, context),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: Text('Início'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.groups_outlined),
                      selectedIcon: Icon(Icons.groups_rounded),
                      label: Text('Pessoas'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.leaderboard_outlined),
                      selectedIcon: Icon(Icons.leaderboard_rounded),
                      label: Text('Rankings'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.info_outline_rounded),
                      selectedIcon: Icon(Icons.info_rounded),
                      label: Text('Sobre'),
                    ),
                  ],
                ),
                VerticalDivider(
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(child: child),
              ],
            )
          : child,
      bottomNavigationBar: showRail
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _goTo(index, context),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Início',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups_rounded),
                  label: 'Pessoas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.leaderboard_outlined),
                  selectedIcon: Icon(Icons.leaderboard_rounded),
                  label: 'Rankings',
                ),
                NavigationDestination(
                  icon: Icon(Icons.info_outline_rounded),
                  selectedIcon: Icon(Icons.info_rounded),
                  label: 'Sobre',
                ),
              ],
            ),
    );
  }

  void _goTo(int index, BuildContext context) {
    final route = switch (index) {
      0 => AppRoutes.home,
      1 => AppRoutes.students,
      2 => AppRoutes.ranking,
      _ => AppRoutes.about,
    };
    if (route != location) {
      context.go(route);
    }
  }

  bool _isStudentSubpage(String path) {
    return path.startsWith('${AppRoutes.students}/') &&
        path != AppRoutes.students;
  }

  int _selectedIndex(String location) {
    if (location.startsWith(AppRoutes.students)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.ranking)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.about)) {
      return 3;
    }
    return 0;
  }

  String _titleFor(String location) {
    if (location == AppRoutes.newStudent) {
      return 'Nova pessoa';
    }
    if (location.endsWith('/edit')) {
      return 'Editar perfil';
    }
    if (location.endsWith('/evaluate')) return 'Avaliar pessoa';
    if (_isStudentSubpage(location)) {
      return 'Perfil da pessoa';
    }
    if (location.startsWith(AppRoutes.students)) {
      return 'Pessoas';
    }
    if (location.startsWith(AppRoutes.ranking)) {
      return location == AppRoutes.globalRanking
          ? 'Ranking global'
          : 'Ranking pessoal';
    }
    if (location.startsWith(AppRoutes.about)) {
      return 'Sobre o app';
    }
    return AppConstants.appName;
  }
}
