import '../../core/result/result.dart';
import '../repositories/student_repository.dart';

class DeleteStudentUseCase {
  const DeleteStudentUseCase(this._repository);

  final StudentRepository _repository;

  Future<Result<void>> call(String id) {
    if (id.trim().isEmpty) {
      return Future.value(const Failure('Aluno invalido para remocao.'));
    }
    return _repository.deleteStudent(id);
  }
}
