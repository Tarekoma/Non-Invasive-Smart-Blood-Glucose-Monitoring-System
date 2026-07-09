// lib/features/mode_selection/providers/app_mode_provider.dart
//
// Feature-level app mode provider.
// The core-level StateProvider (core/providers/app_mode_provider.dart)
// is seeded at startup and used by GoRouter for the initial route.
// This AsyncNotifier handles the *save* side — writing the user's choice
// to SharedPreferences and then updating the core StateProvider.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_mode_provider.dart'
    show appModeProvider; // re-export from core

/// AsyncNotifier that persists the selected app mode.
///
/// Usage:
/// ```dart
/// await ref.read(appModeNotifierProvider.notifier).selectMode('personal');
/// ```
class AppModeNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.appModeKey);
  }

  /// Persists [mode] and updates the core [appModeProvider] so the router
  /// can react without a full app restart.
  Future<void> selectMode(String mode) async {
    state = const AsyncLoading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.appModeKey, mode);
    // Keep the core StateProvider in sync for any watchers.
    ref.read(appModeProvider.notifier).state = mode;
    state = AsyncData(mode);
  }
}

final appModeNotifierProvider =
    AsyncNotifierProvider<AppModeNotifier, String?>(AppModeNotifier.new);
