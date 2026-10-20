import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../app/app_dependencies.dart';
import '../../core/constants/app_constants.dart';
import '../../core/result/result.dart';
import '../../domain/models/student.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/responsive_page.dart';
import '../widgets/student_card.dart';

class StudentListPage extends SignalStatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final _searchController = TextEditingController();
  bool _loaded = false;
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }
    _loaded = true;
    final command = AppDependencies.of(
      context,
    ).studentViewModel.loadStudentsCommand;
    Future.microtask(command.execute);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = AppDependencies.of(context).studentViewModel;
    final students = viewModel.students.value;
    final uid = AppDependencies.of(context).authViewModel.user.value?.uid;
    final loading = viewModel.loading.value && students.isEmpty;
    final normalizedQuery = _query.trim().toLowerCase();
    final filteredStudents = normalizedQuery.isEmpty
        ? students
        : students.where((student) {
            return student.nome.toLowerCase().contains(normalizedQuery) ||
                student.apelido.toLowerCase().contains(normalizedQuery) ||
                student.curso.toLowerCase().contains(normalizedQuery) ||
                student.turmaAno.toString().contains(normalizedQuery);
          }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ResponsivePage(
        maxWidth: 780,
        child: Builder(
          builder: (context) {
            if (loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage.value != null) {
              return EmptyState(
                title: 'Não foi possível carregar as pessoas',
                message: viewModel.errorMessage.value!,
                action: FilledButton(
                  onPressed: () => viewModel.loadStudentsCommand.execute(),
                  child: const Text('Tentar novamente'),
                ),
              );
            }
            if (students.isEmpty) {
              return EmptyState(
                title: 'Nenhuma pessoa cadastrada ainda',
                message:
                    'Crie o primeiro perfil para começar o ranking do campus.',
                action: FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.newStudent),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Cadastrar pessoa'),
                ),
              );
            }

            return Padding(
              padding: ResponsivePage.padding(context, bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${students.length} ${students.length == 1 ? 'perfil cadastrado' : 'perfis cadastrados'}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toque em um perfil para ver detalhes e avaliar.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome, apelido, curso ou turma',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpar busca',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredStudents.isEmpty
                        ? EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'Nenhum resultado',
                            message:
                                'Tente buscar com outro nome, apelido, curso ou ano.',
                            action: TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Limpar busca'),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async =>
                                viewModel.loadStudentsCommand.execute(),
                            child: ListView.separated(
                              padding: const EdgeInsets.only(bottom: 96),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: filteredStudents.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final student = filteredStudents[index];
                                return StudentCard(
                                  student: student,
                                  onTap: () => context.go(
                                    AppRoutes.studentDetail(student.id),
                                  ),
                                  onEdit: student.criadoPor != uid
                                      ? null
                                      : () => context.go(
                                          AppRoutes.studentEdit(student.id),
                                        ),
                                  onDelete: student.criadoPor != uid
                                      ? null
                                      : () => _confirmDelete(context, student),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: students.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.go(AppRoutes.newStudent),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nova pessoa'),
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDeleteDialog(studentName: student.nome),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final viewModel = AppDependencies.of(context).studentViewModel;
    final result = await viewModel.deleteStudentCommand.execute(student.id);
    if (!context.mounted) {
      return;
    }
    _showResult(context, result);
  }

  void _showResult(BuildContext context, Result<void> result) {
    final message = result.when(
      success: (_) => 'Aluno removido com sucesso.',
      failure: (message) => message,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
