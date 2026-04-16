import '../../../../../core/error/result.dart';
import '../entities/grade_roster.dart';

abstract class GradeInputRepository {
  Future<Result<GradeRoster>> fetchRoster(int taId);
  Future<Result<GradeRoster>> submitGrades(int taId, List<Map<String, dynamic>> entries);
}
