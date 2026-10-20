import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_dependencies.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/course_constants.dart';
import '../../core/result/result.dart';
import '../../core/utils/date_formatters.dart';
import '../../domain/models/student.dart';
import '../widgets/course_selector.dart';
import '../widgets/responsive_page.dart';
import '../widgets/year_selector.dart';

class StudentFormPage extends StatefulWidget {
  const StudentFormPage({this.studentId, super.key});
  final String? studentId;
  @override
  State<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends State<StudentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _apelido = TextEditingController();
  String _curso = CourseConstants.courses.first;
  int _turma = AppConstants.maxClassYear;
  DateTime? _nascimento;
  Student? _editing;
  String? _error;
  bool _myProfile = false;
  bool _loading = false;
  bool _saving = false;
  bool _loaded = false;
  bool get _isEditing => widget.studentId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    if (_isEditing) _load();
  }

  @override
  void dispose() {
    _nome.dispose();
    _apelido.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final dependencies = AppDependencies.of(context);
    final result = await dependencies.studentViewModel.loadStudentByIdCommand
        .execute(widget.studentId!);
    if (!mounted) return;
    if (result case Success<Student>(:final data)) {
      if (data.criadoPor != dependencies.authViewModel.user.value?.uid) {
        _error = 'Somente quem cadastrou pode editar esta pessoa.';
      } else {
        _editing = data;
        _nome.text = data.nome;
        _apelido.text = data.apelido;
        _curso = data.curso;
        _turma = data.turmaAno;
        _nascimento = data.dataNascimento;
      }
    } else if (result case Failure(:final message)) {
      _error = message;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nascimento == null) {
      setState(() => _error = 'Escolha a data de nascimento.');
      return;
    }
    final dependencies = AppDependencies.of(context);
    final uid = dependencies.authViewModel.user.value?.uid;
    if (uid == null || (_isEditing && _editing == null)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final person = _isEditing
        ? _editing!.copyWith(
            nome: _nome.text.trim(),
            apelido: _apelido.text.trim(),
            curso: _curso,
            turmaAno: _turma,
            dataNascimento: _nascimento,
          )
        : Student(
            id: '',
            nome: _nome.text.trim(),
            apelido: _apelido.text.trim(),
            curso: _curso,
            turmaAno: _turma,
            dataNascimento: _nascimento!,
            usuarioUid: _myProfile ? uid : null,
          );
    final result =
        await (_isEditing
                ? dependencies.studentViewModel.updateStudentCommand
                : dependencies.studentViewModel.createStudentCommand)
            .execute(person);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result case Success<Student>(:final data)) {
      context.go(AppRoutes.studentDetail(data.id));
    } else if (result case Failure(:final message)) {
      setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_isEditing && _editing == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Pessoa não encontrada.'),
              TextButton(
                onPressed: _load,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    return ResponsivePage(
      maxWidth: 700,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: ResponsivePage.padding(context),
          children: [
            Text(
              _isEditing ? 'Editar pessoa' : 'Nova pessoa',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Este cadastro cria um perfil para avaliação. As notas são atribuídas separadamente.',
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nome,
              enabled: !_saving,
              maxLength: 120,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe o nome.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _apelido,
              enabled: !_saving,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Apelido'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe o apelido.'
                  : null,
            ),
            const SizedBox(height: 12),
            IgnorePointer(
              ignoring: _saving,
              child: CourseSelector(
                value: _curso,
                onChanged: (value) => setState(() => _curso = value),
              ),
            ),
            const SizedBox(height: 16),
            IgnorePointer(
              ignoring: _saving,
              child: YearSelector(
                value: _turma,
                onChanged: (value) => setState(() => _turma = value),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _saving
                  ? null
                  : () async {
                      final now = DateTime.now();
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _nascimento ?? DateTime(2006),
                        firstDate: DateTime(1900),
                        lastDate: now,
                      );
                      if (selected != null && mounted) {
                        setState(() => _nascimento = selected);
                      }
                    },
              icon: const Icon(Icons.cake_outlined),
              label: Text(
                _nascimento == null
                    ? 'Escolher data de nascimento'
                    : formatBrazilianDate(_nascimento!),
              ),
            ),
            if (!_isEditing) ...[
              const SizedBox(height: 16),
              CheckboxListTile(
                value: _myProfile,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _myProfile = value ?? false),
                title: const Text('Este é meu perfil'),
                subtitle: const Text(
                  'Sua conta pode ser vinculada a uma única pessoa. Isso impede a autoavaliação.',
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _isEditing ? 'Salvar alterações' : 'Cadastrar pessoa',
              ),
            ),
            TextButton(
              onPressed: _saving ? null : () => context.go(AppRoutes.students),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
