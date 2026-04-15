import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';

import '../providers/schedule_providers.dart';
import '../domain/schedule_models.dart';
import '../../../core/theme/app_colors.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  final CalendarController _calendarController = CalendarController();
  CalendarView _currentView = CalendarView.workWeek;
  String _headerText = '';

  @override
  void initState() {
    super.initState();
    _calendarController.view = _currentView;
    _headerText = DateFormat('MMMM yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  void _onViewChanged(CalendarView view) {
    setState(() {
      _currentView = view;
      _calendarController.view = view;
    });
  }

  void _onCalendarViewChanged(ViewChangedDetails details) {
    if (details.visibleDates.isNotEmpty) {
      // Pick the middle date of the visible dates for the header
      final date = details.visibleDates[details.visibleDates.length ~/ 2];
      final newHeader = DateFormat('MMMM yyyy').format(date);
      if (_headerText != newHeader) {
        // Schedule the state update for the next frame to avoid build phases errors
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _headerText = newHeader;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(scheduleProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Text(
          'Jadwal Pelajaran',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary600,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: scheduleAsync.when(
        data: (schedules) {
          final dataSource = ScheduleDataSource(_getAppointments(schedules));

          return Column(
            children: [
              // Custom Header & Segmented Control
              Container(
                padding: const EdgeInsets.only(
                  top: 16,
                  bottom: 12,
                  left: 16,
                  right: 16,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.neutral50,
                  border: Border(
                    bottom: BorderSide(color: AppColors.neutral200),
                  ),
                ),
                child: Column(
                  children: [
                    // Month/Year Selector row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const HeroIcon(
                            HeroIcons.chevronLeft,
                            color: AppColors.neutral700,
                          ),
                          onPressed: () {
                            _calendarController.backward!();
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary600,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary600.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _headerText,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const HeroIcon(
                                HeroIcons.chevronDown,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const HeroIcon(
                            HeroIcons.chevronRight,
                            color: AppColors.neutral700,
                          ),
                          onPressed: () {
                            _calendarController.forward!();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Segmented Control
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.neutral200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _buildSegmentButton(
                              'Month',
                              CalendarView.month,
                            ),
                          ),
                          Expanded(
                            child: _buildSegmentButton(
                              'Week',
                              CalendarView.workWeek,
                            ),
                          ),
                          Expanded(
                            child: _buildSegmentButton('Day', CalendarView.day),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Calendar Grid
              Expanded(
                child: SfCalendar(
                  controller: _calendarController,
                  view: _currentView,
                  dataSource: dataSource,
                  timeSlotViewSettings: const TimeSlotViewSettings(
                    startHour: 6,
                    endHour: 18,
                    nonWorkingDays: <int>[DateTime.saturday, DateTime.sunday],
                    timeFormat: 'H:mm',
                    timeIntervalHeight: 60,
                  ),
                  monthViewSettings: const MonthViewSettings(
                    showAgenda: true,
                    appointmentDisplayMode:
                        MonthAppointmentDisplayMode.indicator,
                    agendaItemHeight: 60,
                  ),
                  appointmentBuilder: _currentView == CalendarView.month
                      ? null
                      : _customAppointmentBuilder,
                  onViewChanged: _onCalendarViewChanged,
                  todayHighlightColor: AppColors.primary600,
                  selectionDecoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: AppColors.primary500, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const HeroIcon(
                HeroIcons.exclamationCircle,
                size: 48,
                color: AppColors.danger500,
              ),
              const SizedBox(height: 16),
              const Text('Gagal memuat jadwal'),
              TextButton(
                onPressed: () => ref.refresh(scheduleProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String text, CalendarView view) {
    final isSelected = _currentView == view;
    return GestureDetector(
      onTap: () => _onViewChanged(view),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isSelected ? AppColors.primary600 : AppColors.neutral500,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  List<Appointment> _getAppointments(List<WeeklySchedule> weeklySchedules) {
    final List<Appointment> appointments = [];
    final eventColor =
        AppColors.purple500; // Using purple to match the reference look

    for (var week in weeklySchedules) {
      // Create repeating events starting from the first day of the current year
      final now = DateTime.now();
      final baseDate = DateTime(now.year, 1, 1);
      final daysOffset = week.day - baseDate.weekday;
      final startDate = baseDate.add(
        Duration(days: daysOffset >= 0 ? daysOffset : daysOffset + 7),
      );

      for (var item in week.items) {
        final start = _parseTimeToDateTime(item.startTime, startDate);
        final end = _parseTimeToDateTime(item.endTime, startDate);

        if (start != null && end != null) {
          appointments.add(
            Appointment(
              startTime: start,
              endTime: end,
              subject: item.subject,
              color: eventColor,
              recurrenceRule:
                  'FREQ=WEEKLY;BYDAY=${_getRecurrenceDay(week.day)}',
              location: item.schoolClass,
              notes: item.teacher,
            ),
          );
        }
      }
    }
    return appointments;
  }

  DateTime? _parseTimeToDateTime(String timeString, DateTime baseDate) {
    try {
      if (timeString.contains('T')) {
        final parsed = DateTime.parse(timeString).toLocal();
        return DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          parsed.hour,
          parsed.minute,
        );
      }
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        return DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
    } catch (_) {}
    return null;
  }

  String _getRecurrenceDay(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return 'MO';
      case 2:
        return 'TU';
      case 3:
        return 'WE';
      case 4:
        return 'TH';
      case 5:
        return 'FR';
      case 6:
        return 'SA';
      case 7:
        return 'SU';
      default:
        return 'MO';
    }
  }

  Widget _customAppointmentBuilder(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    final Appointment appointment = details.appointments.first;
    return Container(
      decoration: BoxDecoration(
        color: appointment.color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: appointment.color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appointment.subject,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (details.bounds.height > 40) ...[
            const SizedBox(height: 2),
            Text(
              '${appointment.location} • ${appointment.notes}',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 9,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class ScheduleDataSource extends CalendarDataSource {
  ScheduleDataSource(List<Appointment> source) {
    appointments = source;
  }
}
