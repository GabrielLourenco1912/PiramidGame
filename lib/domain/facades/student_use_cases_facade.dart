import '../../core/result/result.dart';
import '../models/student.dart';
import '../use_cases/create_student_use_case.dart';
import '../use_cases/delete_student_use_case.dart';
import '../use_cases/get_student_by_id_use_case.dart';
import '../use_cases/get_students_use_case.dart';
import '../use_cases/update_student_use_case.dart';

class StudentUseCasesFacade {
  const StudentUseCasesFacade({
    required this.createStudent,
    required this.updateStudent,
    required this.deleteStudent,
    required this.getStudents,
    required this.getStudentById,
  });

  final CreateStudentUseCase createStudent;
  final UpdateStudentUseCase updateStudent;
  final DeleteStudentUseCase deleteStudent;
  final GetStudentsUseCase getStudents;
  final GetStudentByIdUseCase getStudentById;

  Future<Result<Student>> create(Student student) => createStudent(student);
  Future<Result<Student>> update(Student student) => updateStudent(student);
  Future<Result<void>> delete(String id) => deleteStudent(id);
  Future<Result<List<Student>>> all() => getStudents();
  Future<Result<Student?>> byId(String id) => getStudentById(id);
}
