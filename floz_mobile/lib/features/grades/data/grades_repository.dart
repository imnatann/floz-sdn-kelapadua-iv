import '../domain/grades_models.dart';
import 'grades_api.dart';

class GradesRepository {
  final GradesApi _api;

  GradesRepository(this._api);

  Future<List<SubjectGradeSummary>> getGradesSummary() async {
    final data = await _api.getGradesSummary();
    return data.map((e) => SubjectGradeSummary.fromJson(e)).toList();
  }

  Future<SubjectGradeDetailResponse> getGradeDetail(int subjectId) async {
    final data = await _api.subjectGradeDetail(subjectId);
    return SubjectGradeDetailResponse.fromJson(data);
  }
}
