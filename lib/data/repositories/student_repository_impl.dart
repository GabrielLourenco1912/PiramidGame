import '../../core/result/result.dart';
import '../../domain/models/student.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/student_repository.dart';
import '../firebase_error_message.dart';
import '../services/firestore_service.dart';

class StudentRepositoryImpl implements StudentRepository {
  const StudentRepositoryImpl(this._service, this._auth);
  final FirestoreService _service;
  final AuthRepository _auth;

  Future<Result<T>> _run<T>(
    Future<T> Function(String uid) action,
    String message,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return const Failure('Entre para continuar.');
    try {
      return Success(await action(user.uid));
    } catch (error) {
      return Failure(firebaseErrorMessage(error, message), cause: error);
    }
  }

  @override
  Future<Result<List<Student>>> getStudents() => _run(
    (_) => _service.fetchStudents(),
    'Não foi possível carregar as pessoas.',
  );
  @override
  Future<Result<Student?>> getStudentById(String id) => _run(
    (_) => _service.fetchStudentById(id),
    'Não foi possível localizar a pessoa.',
  );
  @override
  Future<Result<Student>> createStudent(Student student) => _run(
    (uid) => _service.createStudent(student, uid),
    'Não foi possível cadastrar a pessoa.',
  );
  @override
  Future<Result<Student>> updateStudent(Student student) => _run(
    (uid) => _service.updateStudent(student, uid),
    'Não foi possível atualizar a pessoa.',
  );
  @override
  Future<Result<void>> deleteStudent(String id) => _run(
    (uid) => _service.removeStudent(id, uid),
    'Não foi possível remover a pessoa.',
  );
}
