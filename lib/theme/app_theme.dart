import 'package:flutter/material.dart';

/// The ELEVATE MERCH palette: ink on paper, with a warm neutral for image
/// tiles and restrained functional colours for order states.
class AppColors {
  const AppColors._();

  // Core Elevate Dark Obsidian & Crimson Smoke Palette
  static const Color ink = Color(0xFFFFFFFF); // Primary text (White)
  static const Color paper = Color(0xFF0C090A); // Deep dark background
  static const Color paperWhite = Color(0xFFFFFFFF); // Pure white for accents/contrast
  static const Color paperDark = Color(0xFF070506); // Deepest obsidian black
  static const Color muted = Color(0xFF9E9B9A); // Secondary muted silver-grey text
  static const Color line = Color(0xFF281719); // Subtle dark crimson-tinted border
  static const Color tile = Color(0xFF161213); // Dark card background
  static const Color tileDeep = Color(0xFF221A1B); // Slightly raised card / container

  // Elevate signature Red & Black palette
  static const Color elevateRed = Color(0xFFE50914); // Signature vibrant Elevate Red
  static const Color elevateCrimson = Color(0xFFB71C1C); // Deep rich crimson
  static const Color elevateDarkRed = Color(0xFF7A0409); // Dark atmospheric red
  static const Color elevateBlack = Color(0xFF0C090A); // Deep obsidian
  static const Color elevateSurface = Color(0xFF161213); // Card surface
  static const Color elevateRedSurface = Color(0xFF2E0A0D); // Crimson-tinted pill surface
  static const Color elevateRedGlow = Color(0x40E50914);

  // Background Gradient matching the official Elevate palette
  static const LinearGradient elevateGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: <Color>[
      Color(0xFF5A0206), // Glowing crimson atmospheric smoke at top-right
      Color(0xFF280204), // Deep crimson-burgundy transition
      Color(0xFF0E0B0C), // Dark velvet obsidian
      Color(0xFF070506), // Pitch black at bottom-left
    ],
    stops: <double>[0.0, 0.24, 0.60, 1.0],
  );

  static const Color success = Color(0xFF2E8555);
  static const Color warning = Color(0xFFD48B1C);
  static const Color danger = Color(0xFFE53935);

  static const Color successSurface = Color(0xFF0E2519);
  static const Color warningSurface = Color(0xFF281E0A);
  static const Color dangerSurface = Color(0xFF2E0F0E);
}

class AppTheme {
  const AppTheme._();

  static ThemeData build() {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.elevateRed,
      brightness: Brightness.dark,
    );

    final scheme = base.copyWith(
      primary: AppColors.elevateRed,
      onPrimary: AppColors.paperWhite,
      secondary: AppColors.elevateRed,
      onSecondary: AppColors.paperWhite,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      error: AppColors.danger,
      onError: AppColors.paperWhite,
      outline: AppColors.line,
      outlineVariant: AppColors.line,
      onSurfaceVariant: AppColors.muted,
      surfaceContainerLowest: AppColors.paperDark,
      surfaceContainerLow: AppColors.paper,
      surfaceContainer: AppColors.tile,
      surfaceContainerHigh: AppColors.tileDeep,
      surfaceContainerHighest: AppColors.tileDeep,
    );

    const textTheme = TextTheme(
      displayLarge: TextStyle(
        fontSize: 64,
        height: 0.9,
        fontWeight: FontWeight.w900,
        letterSpacing: -3.0,
      ),
      displayMedium: TextStyle(
        fontSize: 44,
        height: 0.95,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.8,
      ),
      displaySmall: TextStyle(
        fontSize: 34,
        height: 1.02,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.2,
      ),
      headlineLarge: TextStyle(
        fontSize: 30,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.55,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelSmall: TextStyle(
        fontSize: 10.5,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
      ),
    );

    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
      fontFamily: 'Archivo',
      textTheme: textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Archivo',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: AppColors.ink,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.tile,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 13, horizontal: 0),
        hintStyle: TextStyle(
          fontFamily: 'Archivo',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.muted,
        ),
        labelStyle: TextStyle(
          fontFamily: 'Archivo',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.muted,
        ),
        floatingLabelStyle: TextStyle(
          fontFamily: 'Archivo',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.elevateRed,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.line, width: 1),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.elevateRed, width: 1.5),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
        errorStyle: TextStyle(
          fontFamily: 'Archivo',
          fontSize: 11.5,
          color: AppColors.danger,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.elevateRed,
          foregroundColor: AppColors.paperWhite,
          disabledBackgroundColor: AppColors.line,
          disabledForegroundColor: AppColors.muted,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Archivo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          shape: buttonShape,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          side: const BorderSide(color: AppColors.line, width: 1.2),
          textStyle: const TextStyle(
            fontFamily: 'Archivo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          textStyle: const TextStyle(
            fontFamily: 'Archivo',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.ink,
          highlightColor: AppColors.tile,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.tileDeep,
        contentTextStyle: TextStyle(
          fontFamily: 'Archivo',
          fontSize: 13,
          height: 1.4,
          color: AppColors.paperWhite,
        ),
        actionTextColor: AppColors.elevateRed,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          side: BorderSide(color: AppColors.line),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.tile,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          side: BorderSide(color: AppColors.line),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Archivo',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: AppColors.ink,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Archivo',
          fontSize: 14,
          height: 1.5,
          color: AppColors.ink,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.tile,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          side: BorderSide(color: AppColors.line),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.elevateRed,
        selectionColor: Color(0x55E50914),
        selectionHandleColor: AppColors.elevateRed,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.elevateRed,
        linearTrackColor: AppColors.line,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.elevateRed
              : AppColors.tile;
        }),
        side: const BorderSide(color: AppColors.line, width: 1.2),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(1)),
        ),
      ),
    );
  }
}
