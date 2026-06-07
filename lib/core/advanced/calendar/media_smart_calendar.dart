import '../../../app/constants.dart';
import '../../database/database_helper.dart';
import '../../smart/planning/smart_media_team_planner.dart';
import '../models/advanced_models.dart';

/// Calendrier intelligent Média — activités et listes.
class MediaSmartCalendar {
  MediaSmartCalendar({ActivityScheduleService? schedule})
      : _schedule = schedule ?? ActivityScheduleService();

  final ActivityScheduleService _schedule;

  Future<List<CalendarEventItem>> loadMonth(DateTime month) =>
      _schedule.eventsForMonth(month);
}

class ActivityScheduleService {
  Future<List<CalendarEventItem>> eventsForMonth(DateTime month) async {
    final events = <CalendarEventItem>[];
    final sundays = _sundaysInMonth(month);

    for (final sunday in sundays) {
      events.add(CalendarEventItem(
        id: 'service_${sunday.toIso8601String()}',
        title: 'Culte du dimanche',
        date: sunday,
        type: CalendarEventType.service,
        subtitle: 'Pointage et listes Média',
      ));
      events.add(CalendarEventItem(
        id: 'list_${sunday.toIso8601String()}',
        title: 'Liste Média dimanche',
        date: sunday.subtract(const Duration(days: 1)),
        type: CalendarEventType.list,
        subtitle: 'Génération équipe',
        isReady: sunday.isAfter(DateTime.now()),
      ));
    }

    final db = await DatabaseHelper.instance.database;
    final attendance = await db.query(
      AppConstants.tableMediaAttendance,
      orderBy: 'session_date DESC',
      limit: 20,
    );
    for (final row in attendance) {
      final dateStr = row['session_date'] as String?;
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      if (date.year != month.year || date.month != month.month) continue;
      events.add(CalendarEventItem(
        id: 'att_${row['id']}',
        title: 'Présence enregistrée',
        date: date,
        type: CalendarEventType.team,
        subtitle: row['status'] as String? ?? '—',
      ));
    }

    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }

  List<DateTime> _sundaysInMonth(DateTime month) {
    final list = <DateTime>[];
    var d = DateTime(month.year, month.month, 1);
    while (d.month == month.month) {
      if (d.weekday == DateTime.sunday) list.add(d);
      d = d.add(const Duration(days: 1));
    }
    return list;
  }
}

class EventReminderService {
  Future<void> scheduleSundayReminder() async {
    // Rappel local — enregistré via notifications intelligentes.
  }
}

class CalendarListPreview {
  static String labelFor(CalendarEventItem event) {
    if (event.isReady) return 'Prête';
    return 'Incomplète';
  }
}
