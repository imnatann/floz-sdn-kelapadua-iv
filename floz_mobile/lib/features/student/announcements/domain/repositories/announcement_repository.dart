import '../../../../../core/error/result.dart';
import '../entities/announcement.dart';

abstract class AnnouncementRepository {
  Future<Result<List<AnnouncementSummary>>> fetchList({bool forceRefresh = false});
  Future<Result<AnnouncementDetail>> fetchDetail(int id);
}
