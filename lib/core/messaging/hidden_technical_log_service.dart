import '../logging/technical_error_repository.dart';

/// Stocke les détails techniques — visible uniquement dans Diagnostic Admin.
class HiddenTechnicalLogService {
  HiddenTechnicalLogService._();

  static void record({
    required String source,
    required Object error,
    StackTrace? stack,
    Map<String, dynamic>? context,
  }) {
    final detail = context != null ? '$error | $context' : error;
    TechnicalErrorRepository.record(
      source: source,
      error: detail,
      stack: stack,
    );
  }

  static void recordMessage({
    required String source,
    required String message,
  }) {
    TechnicalErrorRepository.record(
      source: source,
      error: message,
    );
  }
}
