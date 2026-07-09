// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'app/app_widget.dart';
import 'core/constants/app_constants.dart';
import 'core/database/db_helper.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers/app_mode_provider.dart';
import 'features/profile/providers/profile_provider.dart';

Future<void> main() async {
  // Ensure Flutter binding is ready before any platform calls.
  WidgetsFlutterBinding.ensureInitialized();

  Object? bootstrapError;
  SharedPreferences? prefs;

  try {
    // ScreenUtil needs binding initialised; call before runApp.
    await ScreenUtil.ensureScreenSize();

    // Warm-up the SQLite database — creates tables & indexes on first run.
    await DatabaseHelper.instance.database;

    // Required by flutter_local_notifications for timezone-aware scheduling.
    // Must run before NotificationService.init() and before runApp().
    tzdata.initializeTimeZones();
    try {
      // Without this, tz.local silently defaults to UTC and every scheduled
      // reminder fires at the wrong clock time for non-UTC users. Kept in
      // its own try/catch: a failed timezone lookup shouldn't abort startup
      // — falling back to UTC is preferable to not launching at all.
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      if (kDebugMode) debugPrint('[bootstrap] timezone lookup failed: $e');
    }

    // Initialise the notification plugin and request permissions.
    await NotificationService.instance.init();

    // Read the persisted app mode so the router can set the correct
    // initial location synchronously (no async redirect needed).
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    bootstrapError = e;
  }

  if (bootstrapError != null || prefs == null) {
    if (kDebugMode) debugPrint('[bootstrap] failed: $bootstrapError');
    runApp(_BootstrapErrorApp(error: bootstrapError));
    return;
  }

  final savedMode = prefs.getString(AppConstants.appModeKey);

  // Read the persisted language the same way, so the correct locale is
  // applied on the very first frame — otherwise the app always boots in
  // English and silently ignores a previously-saved Arabic preference.
  final savedLanguage = prefs.getString(AppConstants.languageKey) ?? 'en';

  // Read the persisted theme mode the same way. Previously nothing ever
  // seeded this provider, so the app silently ignored a saved Dark/System
  // preference and always cold-booted in Light mode.
  final savedThemeMode = switch (prefs.getString(AppConstants.themeModeKey)) {
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => ThemeMode.light,
  };

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
        // Seed themeModeProvider so the first frame already uses the
        // persisted theme instead of always starting in Light mode.
        themeModeProvider.overrideWith(() => _SeededThemeModeNotifier(savedThemeMode)),
      ],
      child: const GlucoTrackApp(),
    ),
  );
}

/// Minimal, dependency-free fallback UI shown when app bootstrap
/// (database, notifications, timezone data, SharedPreferences) throws.
/// Deliberately does not use [AppLocalizations] or the app theme — both
/// depend on state this screen exists specifically because we couldn't
/// initialise.
class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    "GlucoTrack couldn't start",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please close and reopen the app. If this keeps '
                    'happening, reinstalling the app may help.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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

/// Seeds [ThemeModeNotifier] the same way — see [_SeededLanguageNotifier].
class _SeededThemeModeNotifier extends ThemeModeNotifier {
  _SeededThemeModeNotifier(this._initial);
  final ThemeMode _initial;

  @override
  ThemeMode build() => _initial;
}
