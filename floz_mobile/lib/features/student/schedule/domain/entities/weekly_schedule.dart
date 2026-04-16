class ScheduleDay {
  final int day;
  final String dayName;
  final List<ScheduleEntry> items;

  const ScheduleDay({
    required this.day,
    required this.dayName,
    required this.items,
  });
}

class ScheduleEntry {
  final String id;
  final String startTime;
  final String endTime;
  final String subject;
  final String teacher;

  const ScheduleEntry({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacher,
  });
}

class WeeklySchedule {
  final List<ScheduleDay> days;
  const WeeklySchedule({required this.days});

  bool get isEmpty => days.isEmpty;
}
