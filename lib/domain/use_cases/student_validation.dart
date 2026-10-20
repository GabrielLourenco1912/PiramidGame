import '../../core/constants/app_constants.dart';
import '../../core/constants/course_constants.dart';
import '../models/student.dart';

class StudentValidation {
  const StudentValidation._();

  static String? validate(Student student) {
    if (student.nome.trim().isEmpty) {
      return 'Informe o nome da pessoa.';
    }
    if (student.apelido.trim().isEmpty) {
      return 'Informe o apelido da pessoa.';
    }
    if (!CourseConstants.courses.contains(student.curso)) {
      return 'Selecione um curso valido.';
    }
    if (student.turmaAno < AppConstants.minClassYear ||
        student.turmaAno > AppConstants.maxClassYear) {
      return 'Selecione uma turma entre 1998 e 2026.';
    }
    if (student.nome.trim().length > 120 ||
        student.apelido.trim().length > 60) {
      return 'Use até 120 caracteres no nome e 60 no apelido.';
    }
    final today = DateTime.now();
    if (student.dataNascimento.isBefore(DateTime(1900)) ||
        student.dataNascimento.isAfter(today)) {
      return 'Selecione uma data de nascimento válida.';
    }
    return null;
  }
}
