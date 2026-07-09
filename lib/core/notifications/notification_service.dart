// lib/core/notifications/notification_service.dart
//
// ⚠️  PLATFORM SETUP REQUIRED (one-time, outside Dart):
//
// Android — android/app/src/main/AndroidManifest.xml:
//   <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
//   <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
//   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
//   Inside <application>:
//     <receiver android:exported="false"
//       android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
//       <intent-filter>
//         <action android:name="android.intent.action.BOOT_COMPLETED"/>
//         <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
//       </intent-filter>
//     </receiver>
//
// iOS — ios/Runner/AppDelegate.swift:
//   UNUserNotificationCenter.current().delegate = self  (in didFinishLaunchingWithOptions)
//
// ⚠️  Add to main.dart before runApp():
//   import 'package:timezone/data/latest_all.dart' as tzdata;
//   tzdata.initializeTimeZones();
//   await NotificationService.instance.init();

import 'package:flutter/material.dart' show Locale, TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/generated/app_localizations.dart';
import '../constants/app_constants.dart';

/// Singleton wrapper around [FlutterLocalNotificationsPlugin].
///
/// All notification scheduling goes through this service.
/// Every method is async/await — never synchronous.
///
/// This service runs outside any widget tree (background scheduling, no
/// `BuildContext`), so it can't use `AppLocalizations.of(context)`. Instead
/// it reads the persisted language directly from `SharedPreferences` and
/// resolves strings via the context-free `lookupAppLocalizations(Locale)`
/// helper that gen-l10n generates alongside `AppLocalizations`.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Current localized strings, resolved from the persisted language
  /// preference (defaults to English if never set).
  Future<AppLocalizations> _l10n() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(AppConstants.languageKey) ?? 'en';
    return lookupAppLocalizations(Locale(lang));
  }

  /// Android notification channels are created once and their stored name
  /// does not update for existing installs if the app later requests the
  /// same channel ID with a different name — so each language gets its own
  /// channel ID. Old-language channels are simply left unused after a
  /// switch; flutter_local_notifications has no channel-delete API and
  /// unused channels are harmless.
  String _channelId(String base, String langCode) => '${base}_$langCode';

  // ── Initialise ─────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS:     iosSettings,
      ),
    );

    // Request Android 13+ notification permission.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ── Water reminder ─────────────────────────────────────────────

  /// Cancels existing water slots, then schedules up to 64 absolute-time
  /// notifications for the next 8 days between [wakeHour] and [sleepHour],
  /// firing every [intervalHours] hours.
  Future<void> scheduleWaterReminder({
    required int intervalHours,
    required int wakeHour,
    required int sleepHour,
  }) async {
    await cancelWaterReminder();

    final l10n = await _l10n();
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(AppConstants.languageKey) ?? 'en';

    final now  = tz.TZDateTime.now(tz.local);
    int   slot = 0;

    for (int day = 0; day < 8; day++) {
      for (int h = wakeHour; h < sleepHour; h += intervalHours) {
        final scheduled = tz.TZDateTime(
          tz.local,
          now.year, now.month, now.day + day, h,
        );
        if (scheduled.isBefore(now)) continue;

        await _plugin.zonedSchedule(
          AppConstants.notifIdWater + slot,
          l10n.notifWaterTitle,
          l10n.notifWaterBody,
          scheduled,
          _details(
            channelId:   _channelId(AppConstants.notifChannelWater, langCode),
            channelName: l10n.notifWaterChannelName,
          ),
          androidScheduleMode:
              AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        slot++;
        if (slot >= 64) break;
      }
      if (slot >= 64) break;
    }
  }

  Future<void> cancelWaterReminder() async {
    for (int i = 0; i < 64; i++) {
      await _plugin.cancel(AppConstants.notifIdWater + i);
    }
  }

  // ── Glucose measurement reminder ───────────────────────────────

  /// Schedules a daily repeating notification at [time].
  /// [matchDateTimeComponents: DateTimeComponents.time] makes it fire
  /// every day at the same clock time without needing to reschedule.
  /// [index] must be unique per time slot (0–9).
  Future<void> scheduleGlucoseReminder({
    required int       index,
    required TimeOfDay time,
  }) async {
    final l10n = await _l10n();
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(AppConstants.languageKey) ?? 'en';

    await _plugin.zonedSchedule(
      AppConstants.notifIdGlucoseBase + index,
      l10n.notifGlucoseTitle,
      l10n.notifGlucoseBody,
      _nextInstanceOf(time.hour, time.minute),
      _details(
        channelId:   _channelId(AppConstants.notifChannelGlucose, langCode),
        channelName: l10n.notifGlucoseChannelName,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelGlucoseReminder(int index) async {
    await _plugin.cancel(AppConstants.notifIdGlucoseBase + index);
  }

  Future<void> cancelAllGlucoseReminders() async {
    for (int i = 0; i < 10; i++) {
      await _plugin.cancel(AppConstants.notifIdGlucoseBase + i);
    }
  }

  // ── Medication reminder ────────────────────────────────────────

  /// Schedules a daily notification for a medication at [time].
  /// [index] must be unique per medication (0–19).
  Future<void> scheduleMedicationReminder({
    required int       index,
    required String    medicationName,
    required String    dose,
    required TimeOfDay time,
  }) async {
    final l10n = await _l10n();
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(AppConstants.languageKey) ?? 'en';

    await _plugin.zonedSchedule(
      AppConstants.notifIdMedBase + index,
      l10n.notifMedTitle,
      l10n.notifMedBody(medicationName, dose),
      _nextInstanceOf(time.hour, time.minute),
      _details(
        channelId:   _channelId(AppConstants.notifChannelMed, langCode),
        channelName: l10n.notifMedChannelName,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelMedicationReminder(int index) async {
    await _plugin.cancel(AppConstants.notifIdMedBase + index);
  }

  // ── Cancel all ─────────────────────────────────────────────────

  Future<void> cancelAll() async => _plugin.cancelAll();

  // ── Private helpers ────────────────────────────────────────────

  /// Returns the next [tz.TZDateTime] for [hour]:[minute] in the local
  /// timezone. If that time has already passed today, returns tomorrow.
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now       = tz.TZDateTime.now(tz.local);
    var   scheduled = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day, hour, minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  NotificationDetails _details({
    required String channelId,
    required String channelName,
  }) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority:   Priority.high,
          playSound:  true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
}
