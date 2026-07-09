// lib/core/providers/app_mode_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

// ── App mode ───────────────────────────────────────────────────────────────

/// Holds the currently selected app mode ('personal' | 'clinic' | null).
/// Overridden in main.dart with the value read from SharedPreferences before
/// runApp, so the initial route is determined synchronously.
final appModeProvider = StateProvider<String?>((ref) => null);

// ── Theme mode ─────────────────────────────────────────────────────────────

/// Persisted theme mode notifier.
///
/// [build] returns the Light default for a bare `ProviderScope`; the real
/// startup value is seeded from SharedPreferences in main.dart via
/// `themeModeProvider.overrideWith(...)`, the same way [LanguageNotifier]
/// is seeded — see `_SeededThemeModeNotifier`.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.themeModeKey, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
