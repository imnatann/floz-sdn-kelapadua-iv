import '../domain/announcement_models.dart';
import 'announcement_api.dart';

class AnnouncementRepository {
  final AnnouncementApi _api;

  AnnouncementRepository(this._api);

  Future<List<AnnouncementItem>> getAnnouncements() async {
    final data = await _api.getAnnouncements();
    return data.map((e) => AnnouncementItem.fromJson(e)).toList();
  }

  Future<AnnouncementItem> getAnnouncementDetail(int id) async {
    final data = await _api.getAnnouncementDetail(id);
    return AnnouncementItem.fromJson(data);
  }
}
