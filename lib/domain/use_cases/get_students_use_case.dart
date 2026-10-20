import '../../core/result/result.dart';
import '../models/student.dart';
import '../repositories/student_repository.dart';

class GetStudentsUseCase {
  const GetStudentsUseCase(this._repository);

  final StudentRepository _repository;

  Future<Result<List<Student>>> call() => _repository.getStudents();
}
