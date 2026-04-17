import 'material_item.dart';

class MeetingHeader {
  final int id;
  final int meetingNumber;
  final String title;
  final String? description;
  final bool isLocked;
  final String subjectName;
  final String className;

  const MeetingHeader({
    required this.id,
    required this.meetingNumber,
    required this.title,
    this.description,
    required this.isLocked,
    required this.subjectName,
    required this.className,
  });
}

class MeetingDetail {
  final MeetingHeader meeting;
  final List<MaterialItem> materials;

  const MeetingDetail({
    required this.meeting,
    required this.materials,
  });
}
