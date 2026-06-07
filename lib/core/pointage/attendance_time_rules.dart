import '../../shared/models/attendance_model.dart';

/// Règles horaires de présence — Mercredi/Vendredi/Dimanche/Samedi.
class AttendanceTimeRules {
  AttendanceTimeRules._();

  /// Détermine si l'heure actuelle est « à l'heure » ou « retard » selon le jour.
  static MediaAttendanceStatus statusForNow({
    required DateTime dateTime,
    required MediaSessionType sessionType,
  }) {
    if (sessionType != MediaSessionType.sundayService &&
        sessionType != MediaSessionType.rehearsal) {
      return MediaAttendanceStatus.present;
    }

    final weekday = dateTime.weekday;
    final minutes = dateTime.hour * 60 + dateTime.minute;

    // Mercredi (3) et Vendredi (5) : 15h00–17h00 à l'heure, 17h01+ retard
    if (weekday == DateTime.wednesday || weekday == DateTime.friday) {
      if (minutes < 15 * 60) return MediaAttendanceStatus.present;
      if (minutes <= 17 * 60) return MediaAttendanceStatus.present;
      return MediaAttendanceStatus.late;
    }

    // Dimanche (7) : 06h30–07h15 à l'heure, 07h16+ retard
    if (weekday == DateTime.sunday) {
      if (minutes < 6 * 60 + 30) return MediaAttendanceStatus.present;
      if (minutes <= 7 * 60 + 15) return MediaAttendanceStatus.present;
      return MediaAttendanceStatus.late;
    }

    // Samedi : présence samedi — règle spéciale dimanche (autorisation)
    if (weekday == DateTime.saturday) {
      return MediaAttendanceStatus.present;
    }

    return MediaAttendanceStatus.present;
  }

  static String statusLabel(MediaAttendanceStatus status) => status.label;
}
