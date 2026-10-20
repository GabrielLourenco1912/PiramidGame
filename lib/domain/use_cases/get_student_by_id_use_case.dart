import '../../core/result/result.dart';
import '../models/student.dart';
import '../repositories/student_repository.dart';

class GetStudentByIdUseCase {
  const GetStudentByIdUseCase(this._repository);

  final StudentRepository _repository;

  Future<Result<Student?>> call(String id) => _repository.getStudentById(id);
}
