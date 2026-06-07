import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'professional_pointage_screen.dart';

/// Pointage Média — délègue à l'écran professionnel premium.
class MediaAttendanceScreen extends ConsumerWidget {
  const MediaAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ProfessionalPointageScreen();
  }
}
