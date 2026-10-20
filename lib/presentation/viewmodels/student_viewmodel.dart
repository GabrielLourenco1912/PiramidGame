import 'package:signals_flutter/signals_flutter.dart';
import '../../core/command/command.dart';
import '../../core/result/result.dart';
import '../../domain/facades/student_use_cases_facade.dart';
import '../../domain/models/student.dart';
import 'async_viewmodel.dart';

class StudentViewModel extends AsyncViewModel {
  StudentViewModel(this._facade) {
    loadStudentsCommand = Command(
      () => run(_facade.all, onSuccess: (data) => students.value = data),
    );
    loadStudentByIdCommand = Command1((String id) {
      selectedStudent.value = null;
      return run(() async {
        final result = await _facade.byId(id);
        return result.when(
          success: (person) => person == null
              ? const Failure<Student>('Pessoa não encontrada.')
              : Success(person),
          failure: Failure<Student>.new,
        );
      }, onSuccess: (person) => selectedStudent.value = person);
    });
    createStudentCommand = Command1(
      (Student person) => run(
        () => _facade.create(person),
        onSuccess: (created) => students.value = [...students.value, created],
        successText: 'Pessoa cadastrada com sucesso.',
      ),
    );
    updateStudentCommand = Command1(
      (Student person) => run(
        () => _facade.update(person),
        onSuccess: (updated) {
          selectedStudent.value = updated;
          students.value = [
            for (final item in students.value)
              item.id == updated.id ? updated : item,
          ];
        },
        successText: 'Pessoa atualizada com sucesso.',
      ),
    );
    deleteStudentCommand = Command1(
      (String id) => run(
        () => _facade.delete(id),
        onSuccess: (_) {
          students.value = students.value
              .where((person) => person.id != id)
              .toList();
          if (selectedStudent.value?.id == id) selectedStudent.value = null;
        },
        successText: 'Pessoa removida dos perfis e rankings.',
      ),
    );
  }

  final StudentUseCasesFacade _facade;
  final students = signal<List<Student>>([]);
  final selectedStudent = signal<Student?>(null);

  late final Command<List<Student>> loadStudentsCommand;
  late final Command1<String, Student> loadStudentByIdCommand;
  late final Command1<Student, Student> createStudentCommand;
  late final Command1<Student, Student> updateStudentCommand;
  late final Command1<String, void> deleteStudentCommand;

  @override
  void clearData() {
    students.value = [];
    selectedStudent.value = null;
  }
}
