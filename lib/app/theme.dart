import 'package:flutter/material.dart';

/// IFCM professional dark theme with gold accent.
class AppTheme {
  AppTheme._();

  static const Color goldAccent = Color(0xFFC9A227);
  static const Color goldLight = Color(0xFFE8C547);
  static const Color goldDark = Color(0xFF9A7B1A);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceContainer = Color(0xFF1E1E1E);
  static const Color surfaceElevated = Color(0xFF2A2A2A);
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color danger = Color(0xFFCF6679);
  static const Color success = Color(0xFF4CAF50);
  static const Color info = Color(0xFF42A5F5);
  static const Color warning = Color(0xFFFFB74D);
  static const Color actionPrimary = Color(0xFFFF9800);

  // Palette IFCM Lubumbashi — écrans membre / choix connexion
  static const Color premiumBlack = Color(0xFF050505);
  static const Color cardDark = Color(0xFF111827);
  static const Color brandOrange = Color(0xFFF45A1F);
  static const Color brandBlue = Color(0xFF0067B1);
  static const Color brandWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color cardSecondary = Color(0xFF1F2937);
  static const Color successProd = Color(0xFF22C55E);
  static const Color errorProd = Color(0xFFEF4444);
  static const Color warningProd = Color(0xFFF59E0B);

  /// Alias production (spec utilisateur).
  static const Color productionBackground = premiumBlack;
  static const Color productionCard = cardDark;
  static const Color productionCardAlt = cardSecondary;

  static const String memberChoiceSecurityMessage =
      'Chaque utilisateur accède uniquement à son espace autorisé.';
  static const String memberLoginHintMessage =
      'Connectez-vous avec l\'identifiant donné par l\'administration.';
  static const String memberForgotPasswordMessage =
      'Mot de passe oublié ? Contactez votre responsable.';

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: goldAccent,
      onPrimary: Colors.black,
      primaryContainer: goldDark,
      onPrimaryContainer: textPrimary,
      secondary: goldLight,
      onSecondary: Colors.black,
      surface: premiumBlack,
      onSurface: textPrimary,
      error: danger,
      onError: Colors.black,
      outline: Color(0xFF3D3D3D),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: premiumBlack,
      appBarTheme: const AppBarTheme(
        backgroundColor: premiumBlack,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF333333)),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: surfaceContainer,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3D3D3D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3D3D3D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: goldAccent, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldAccent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: goldAccent),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF333333)),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: goldAccent,
        textColor: textPrimary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: goldAccent,
      ),
    );
  }
}
