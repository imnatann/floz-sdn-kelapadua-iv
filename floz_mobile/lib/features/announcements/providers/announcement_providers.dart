import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/announcement_api.dart';
import '../data/announcement_repository.dart';
import '../domain/announcement_models.dart';

final announcementApiProvider = Provider<AnnouncementApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return AnnouncementApi(client);
});

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  final api = ref.watch(announcementApiProvider);
  return AnnouncementRepository(api);
});

final announcementsProvider =
    FutureProvider.autoDispose<List<AnnouncementItem>>((ref) async {
      final repo = ref.watch(announcementRepositoryProvider);
      return repo.getAnnouncements();
    });

final announcementDetailProvider = FutureProvider.autoDispose
    .family<AnnouncementItem, int>((ref, id) async {
      final repo = ref.watch(announcementRepositoryProvider);
      return repo.getAnnouncementDetail(id);
    });
