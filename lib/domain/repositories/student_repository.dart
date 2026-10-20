import '../../core/result/result.dart';
import '../models/student.dart';

abstract interface class StudentRepository {
  Future<Result<List<Student>>> getStudents();
  Future<Result<Student?>> getStudentById(String id);
  Future<Result<Student>> createStudent(Student student);
  Future<Result<Student>> updateStudent(Student student);
  Future<Result<void>> deleteStudent(String id);
}
