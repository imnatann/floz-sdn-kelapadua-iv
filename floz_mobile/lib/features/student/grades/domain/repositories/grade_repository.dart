import '../../../../../core/error/result.dart';
import '../entities/student_grades.dart';

abstract class GradeRepository {
  Future<Result<List<SubjectGradeSummary>>> fetchList({bool forceRefresh = false});
  Future<Result<SubjectGradeInfo>> fetchDetail(int subjectId);
}
