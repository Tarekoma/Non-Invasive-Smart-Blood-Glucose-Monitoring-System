// lib/app/theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/glucose_zone.dart'; // AppColorExtension lives here

// ── Medical Brand Palette ──────────────────────────────────────────────────
// These raw Color values seed ColorScheme / extensions ONLY.
// Use Theme.of(context).colorScheme or context.appColors everywhere else.

// Primary — Clinical Teal (trust, health, precision)
const _kPrimary = Color(0xFF006E7F);
const _kPrimaryLight = Color(0xFF4DA8BA); // hover / splash states
const _kPrimaryDark = Color(0xFF004D5A); // pressed states

// Semantic — desaturated for clinical readability (not alarm-red app colours)
const _kSuccess = Color(0xFF2E7D5E); // in-range glucose
const _kWarning = Color(0xFFB36A00); // borderline glucose
const _kDanger = Color(0xFFB02A2A); // critical glucose / error

// Light mode surfaces
const _kSurfaceLight = Color(0xFFFFFFFF);
const _kBackgroundLight = Color(0xFFEEF2F7); // cool clinical gray
const _kCardLight = Color(0xFFFFFFFF);
const _kDividerLight = Color(0xFFCFD8E3);
const _kOnSurfaceLight = Color(0xFF0F1923);
const _kOnSurfaceVarLight = Color(0xFF52647A);

// Dark mode surfaces — navy-tinted, never pure black
const _kSurfaceDark = Color(0xFF1A2744); // card / elevated surface
const _kBackgroundDark = Color(0xFF0D1B2A); // scaffold
const _kCardDark = Color(0xFF1E2E48); // slightly lighter than bg
const _kDividerDark = Color(0xFF2C3E58);
const _kOnSurfaceDark = Color(0xFFE8EDF5);
const _kOnSurfaceVarDark = Color(0xFF8EA4BE);

// ── Shared shape tokens ────────────────────────────────────────────────────
const _kRadiusCard = 12.0; // clinical — sharper than consumer apps
const _kRadiusInput = 10.0;
const _kRadiusButton = 10.0;

// ── Theme factory ─────────────────────────────────────────────────────────
abstract final class AppTheme {
  // ── Light ────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final cs = ColorScheme(
      brightness: Brightness.light,
      primary: _kPrimary,
      onPrimary: _kSurfaceLight,
      primaryContainer: const Color(0xFFCCEFF5),
      onPrimaryContainer: _kPrimaryDark,
      secondary: const Color(0xFF4A6FA5),
      onSecondary: _kSurfaceLight,
      secondaryContainer: const Color(0xFFD4E3F7),
      onSecondaryContainer: const Color(0xFF1A3558),
      tertiary: _kSuccess,
      onTertiary: _kSurfaceLight,
      error: _kDanger,
      onError: _kSurfaceLight,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF7A0000),
      surface: _kSurfaceLight,
      onSurface: _kOnSurfaceLight,
      onSurfaceVariant: _kOnSurfaceVarLight,
      outline: _kDividerLight,
      outlineVariant: const Color(0xFFE2EAF3),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: const Color(0xFF162032),
      onInverseSurface: _kOnSurfaceDark,
      inversePrimary: _kPrimaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,
      scaffoldBackgroundColor: _kBackgroundLight,

      // AppBar — clean white, no shadow, status bar dark icons
      appBarTheme: AppBarTheme(
        backgroundColor: _kSurfaceLight,
        foregroundColor: _kOnSurfaceLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: _kDividerLight,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: _kOnSurfaceLight,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),

      // Cards — subtle, clean, no heavy shadows
      cardTheme: CardThemeData(
        color: _kCardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kRadiusCard),
          side: const BorderSide(color: _kDividerLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated button — primary teal, rounded rect (not stadium)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: _kSurfaceLight,
          disabledBackgroundColor: _kDividerLight,
          disabledForegroundColor: _kOnSurfaceVarLight,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kRadiusButton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _kPrimary,
          side: const BorderSide(color: _kPrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kRadiusButton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _kPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kRadiusButton),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Input fields — clinical, not rounded pill
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _kSurfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadiusInput),
          borderSide: const BorderSide(color: _kDividerLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadiusInput),
          borderSide: const BorderSide(color: _kDividerLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadiusInput),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadiusInput),
          borderSide: const BorderSide(color: _kDanger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadiusInput),
          borderSide: const BorderSide(color: _kDanger, width: 1.5),
        ),
        labelStyle: const TextStyle(
          color: _kOnSurfaceVarLight,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: _kOnSurfaceVarLight.withOpacity(0.7),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: _kDividerLight,
        thickness: 1,
        space: 1,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE8F4F7),
        selectedColor: _kPrimary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        side: const BorderSide(color: _kDividerLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _kSurfaceLight,
        selectedItemColor: _kPrimary,
        unselectedItemColor: _kOnSurfaceVarLight,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),

      // NavigationBar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _kSurfaceLight,
        indicatorColor: const Color(0xFFCCEFF5),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _kPrimary, size: 22);
          }
          return const IconThemeData(color: _kOnSurfaceVarLight, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: _kOnSurfaceVarLight,
          );
        }),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),

      // Typography
      textTheme: _buildTextTheme(Brightness.light),

      extensions: const [
        AppColorExtension(
          success: _kSuccess,
          warning: _kWarning,
          danger: _kDanger,
        ),
      ],
    );
  }

  // ── Dark ─────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final cs = ColorScheme(
      brightness: Brightness.dark,
      primary: _kPrimaryLight,
      onPrimary: const Color(0xFF003640),
      primaryContainer: _kPrimaryDark,
      onPrimaryContainer: const Color(0xFFB3E8F2),
      secondary: const Color(0xFF8CAFD8),
      onSecondary: const Color(0xFF0D2244),
      secondaryContainer: const Color(0xFF1F3A64),
      onSecondaryContainer: const Color(0xFFD4E3F7),
      tertiary: const Color(0xFF66BB98),
      onTertiary: const Color(0xFF003826),
      error: const Color(0xFFFF8A80),
      onError: const Color(0xFF5C0000),
      errorContainer: const Color(0xFF7A0000),
      onErrorContainer: const Color(0xFFFFDAD6),
      surface: _kSurfaceDark,
      onSurface: _kOnSurfaceDark,
      onSurfaceVariant: _kOnSurfaceVarDark,
      outline: _kDividerDark,
      outlineVariant: const Color(0xFF223352),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: _kOnSurfaceDark,
      onInverseSurface: const Color(0xFF162032),
      inversePrimary: _kPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: _kBackgroundDark,

      appBarTheme: AppBarTheme(
        backgroundColor: _kBackgroundDark,
        foregroundColor: _kOnSurfaceDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: _kDividerDark,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: _kOnSurfaceDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),

      cardTheme: CardThemeData(
        color: _kCardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kRadiusCard),
          side: const BorderSide(color: _kDividerDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimaryLight,
          foregroundColor: const Color(0xFF003640),
          disabledBackgroundColor: _kDividerDark,
          disabledForegroundColor: _kOnSurfaceVarDark,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kRadiusButton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _kPrimaryLight,
          side: const BorderSide(color: _kPrimaryLight, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kRadiusButton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _kPrimaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kRadiusButton),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _kSurfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadiusInput),
          borderSide: const BorderSide(color: _kDividerDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadiusInput),
          borderSide: const BorderSide(color: _kDividerDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadiusInput),
          borderSide: const BorderSide(color: _kPrimaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadiusInput),
          borderSide: const BorderSide(color: Color(0xFFFF8A80)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadiusInput),
          borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1.5),
        ),
        labelStyle: const TextStyle(
          color: _kOnSurfaceVarDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: _kOnSurfaceVarDark.withOpacity(0.6),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),

      dividerTheme: const DividerThemeData(
        color: _kDividerDark,
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1A2E48),
        selectedColor: _kPrimaryLight,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _kOnSurfaceDark,
        ),
        side: const BorderSide(color: _kDividerDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _kSurfaceDark,
        selectedItemColor: _kPrimaryLight,
        unselectedItemColor: _kOnSurfaceVarDark,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _kSurfaceDark,
        indicatorColor: _kPrimaryDark,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _kPrimaryLight, size: 22);
          }
          return const IconThemeData(color: _kOnSurfaceVarDark, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kPrimaryLight,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: _kOnSurfaceVarDark,
          );
        }),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),

      textTheme: _buildTextTheme(Brightness.dark),

      extensions: const [
        AppColorExtension(
          success: _kSuccess,
          warning: _kWarning,
          danger: _kDanger,
        ),
      ],
    );
  }

  // ── Shared typography ─────────────────────────────────────────────
  // Clean, legible medical type scale — no decorative fonts.
  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseColor = brightness == Brightness.light
        ? _kOnSurfaceLight
        : _kOnSurfaceDark;
    final secondaryColor = brightness == Brightness.light
        ? _kOnSurfaceVarLight
        : _kOnSurfaceVarDark;

    return TextTheme(
      // Large display — glucose number widget
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w300,
        color: baseColor,
        letterSpacing: -1.5,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w300,
        color: baseColor,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: baseColor,
        letterSpacing: 0,
      ),
      // Headings — section / screen titles
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: -0.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: -0.2,
      ),
      // Titles — card headers
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: -0.1,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: 0,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        letterSpacing: 0.1,
      ),
      // Body
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: baseColor,
        letterSpacing: 0,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: baseColor,
        letterSpacing: 0,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      // Labels — badges, captions, input hints
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        letterSpacing: 0.4,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        letterSpacing: 0.5,
      ),
    );
  }
}
