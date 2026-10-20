import '../../core/result/result.dart';
import '../models/student.dart';
import '../repositories/student_repository.dart';
import 'student_validation.dart';

class UpdateStudentUseCase {
  const UpdateStudentUseCase(this._repository);

  final StudentRepository _repository;

  Future<Result<Student>> call(Student student) async {
    final validationMessage = StudentValidation.validate(student);
    if (validationMessage != null) {
      return Failure(validationMessage);
    }
    return _repository.updateStudent(student);
  }
}
