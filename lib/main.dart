import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'app/ifcm_app_root.dart';
import 'app/theme.dart';
import 'core/bootstrap/app_silent_error_handler.dart';
import 'core/logging/app_logger.dart';
import 'core/logging/technical_error_repository.dart';
import 'features/auth/presentation/app_recovery_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  ErrorWidget.builder = (FlutterErrorDetails details) {
    TechnicalErrorRepository.record(
      source: 'widget_build',
      error: details.exception,
      stack: details.stack,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: AppRecoveryScreen(
        onRetry: () {},
        onContinue: () {},
      ),
    );
  };

  AppSilentErrorHandler.install();
  AppLogger.startup('Démarrage ${DateTime.now().toIso8601String()}');

  unawaited(
    initializeDateFormatting('fr_FR').catchError((e, st) {
      TechnicalErrorRepository.record(source: 'locale', error: e, stack: st);
    }),
  );

  runZonedGuarded(
    () {
      runApp(
        const ProviderScope(
          child: IfcmAppRoot(),
        ),
      );
    },
    (error, stack) {
      TechnicalErrorRepository.record(
        source: 'zone',
        error: error,
        stack: stack,
      );
    },
  );
}
