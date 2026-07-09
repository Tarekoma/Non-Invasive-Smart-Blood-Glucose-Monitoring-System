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
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(AppConstants.themeModeKey);
    state = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light,
    };
  }

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
