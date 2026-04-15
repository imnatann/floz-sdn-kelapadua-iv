class ScheduleItem {
  final String id;
  final String startTime;
  final String endTime;
  final String subject;
  final String teacher;
  final String schoolClass;

  ScheduleItem({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacher,
    required this.schoolClass,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      subject: json['subject'],
      teacher: json['teacher'],
      schoolClass: json['class'],
    );
  }
}

class WeeklySchedule {
  final int day;
  final List<ScheduleItem> items;

  WeeklySchedule({required this.day, required this.items});

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) {
    return WeeklySchedule(
      day: json['day'] is int ? json['day'] : int.parse(json['day'].toString()),
      items: (json['items'] as List? ?? [])
          .map((e) => ScheduleItem.fromJson(e))
          .toList(),
    );
  }
}
