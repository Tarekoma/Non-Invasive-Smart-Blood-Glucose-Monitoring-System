// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'app/app_widget.dart';
import 'core/constants/app_constants.dart';
import 'core/database/db_helper.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers/app_mode_provider.dart';
import 'features/profile/providers/profile_provider.dart';

Future<void> main() async {
  // Ensure Flutter binding is ready before any platform calls.
  WidgetsFlutterBinding.ensureInitialized();

  // ScreenUtil needs binding initialised; call before runApp.
  await ScreenUtil.ensureScreenSize();

  // Warm-up the SQLite database — creates tables & indexes on first run.
  await DatabaseHelper.instance.database;

  // Required by flutter_local_notifications for timezone-aware scheduling.
  // Must run before NotificationService.init() and before runApp().
  tzdata.initializeTimeZones();

  // Initialise the notification plugin and request permissions.
  await NotificationService.instance.init();

  // Read the persisted app mode so the router can set the correct
  // initial location synchronously (no async redirect needed).
  final prefs = await SharedPreferences.getInstance();
  final savedMode = prefs.getString(AppConstants.appModeKey);

  // Read the persisted language the same way, so the correct locale is
  // applied on the very first frame — otherwise the app always boots in
  // English and silently ignores a previously-saved Arabic preference.
  final savedLanguage = prefs.getString(AppConstants.languageKey) ?? 'en';

  runApp(
    ProviderScope(
      overrides: [
        // Seed the appModeProvider with the value we just read.
        // This makes ref.read(appModeProvider) available before the first
        // build, allowing GoRouter to start on the right screen.
        appModeProvider.overrideWith((ref) => savedMode),
        // Seed languageProvider so GlucoTrackApp's first build already uses
        // the persisted locale instead of the 'en' default.
        languageProvider.overrideWith(() => _SeededLanguageNotifier(savedLanguage)),
      ],
      child: const GlucoTrackApp(),
    ),
  );
}

/// [LanguageNotifier] is a [Notifier], so seeding it requires overriding
/// [Notifier.build] (unlike [appModeProvider], a plain [StateProvider] whose
/// initial value can be overridden directly).
class _SeededLanguageNotifier extends LanguageNotifier {
  _SeededLanguageNotifier(this._initial);
  final String _initial;

  @override
  String build() => _initial;
}
