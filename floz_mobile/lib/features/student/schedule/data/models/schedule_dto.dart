import '../../domain/entities/weekly_schedule.dart';

class ScheduleDto {
  static WeeklySchedule fromJson(List<dynamic> json) {
    final days = json
        .whereType<Map<String, dynamic>>()
        .map(_dayFromJson)
        .toList(growable: false);
    return WeeklySchedule(days: days);
  }

  static ScheduleDay _dayFromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_entryFromJson)
        .toList(growable: false);
    return ScheduleDay(
      day: (json['day'] as num?)?.toInt() ?? 0,
      dayName: json['day_name'] as String? ?? '-',
      items: items,
    );
  }

  static ScheduleEntry _entryFromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      id: json['id']?.toString() ?? '',
      startTime: _trimTime(json['start_time']?.toString() ?? ''),
      endTime: _trimTime(json['end_time']?.toString() ?? ''),
      subject: json['subject']?.toString() ?? '-',
      teacher: json['teacher']?.toString() ?? '-',
    );
  }

  static String _trimTime(String raw) {
    if (raw.length >= 5) return raw.substring(0, 5);
    return raw;
  }
}
