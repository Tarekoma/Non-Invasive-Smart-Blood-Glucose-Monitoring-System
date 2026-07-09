// lib/features/reminders/models/reminder_models.dart
//
// Pure Dart — zero Flutter imports.

import 'dart:convert';

import 'package:flutter/material.dart' show TimeOfDay;

// ── Water reminder ─────────────────────────────────────────────────────────

class WaterReminderSettings {
  const WaterReminderSettings({
    this.enabled       = false,
    this.intervalHours = 2,
    this.wakeHour      = 7,
    this.sleepHour     = 22,
    this.dailyCount    = 0,
  });

  final bool enabled;
  final int  intervalHours; // 1 | 2 | 3 | 4
  final int  wakeHour;      // 0–23
  final int  sleepHour;     // 0–23
  final int  dailyCount;    // today's consumed glasses

  WaterReminderSettings copyWith({
    bool? enabled,
    int?  intervalHours,
    int?  wakeHour,
    int?  sleepHour,
    int?  dailyCount,
  }) =>
      WaterReminderSettings(
        enabled:       enabled       ?? this.enabled,
        intervalHours: intervalHours ?? this.intervalHours,
        wakeHour:      wakeHour      ?? this.wakeHour,
        sleepHour:     sleepHour     ?? this.sleepHour,
        dailyCount:    dailyCount    ?? this.dailyCount,
      );

  Map<String, dynamic> toMap() => {
        'enabled':       enabled,
        'intervalHours': intervalHours,
        'wakeHour':      wakeHour,
        'sleepHour':     sleepHour,
        'dailyCount':    dailyCount,
      };

  factory WaterReminderSettings.fromMap(Map<String, dynamic> m) =>
      WaterReminderSettings(
        enabled:       m['enabled']       as bool? ?? false,
        intervalHours: m['intervalHours'] as int?  ?? 2,
        wakeHour:      m['wakeHour']      as int?  ?? 7,
        sleepHour:     m['sleepHour']     as int?  ?? 22,
        dailyCount:    m['dailyCount']    as int?  ?? 0,
      );

  String toJson() => jsonEncode(toMap());
  factory WaterReminderSettings.fromJson(String json) =>
      WaterReminderSettings.fromMap(
        jsonDecode(json) as Map<String, dynamic>,
      );
}

// ── Glucose measurement reminder ───────────────────────────────────────────

/// A single daily glucose reminder time.
class GlucoseReminderTime {
  const GlucoseReminderTime({
    required this.id,
    required this.hour,
    required this.minute,
  });

  final int id;     // unique, maps to notification ID offset
  final int hour;
  final int minute;

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);

  String get label {
    final h  = hour   % 12 == 0 ? 12 : hour   % 12;
    final m  = minute.toString().padLeft(2, '0');
    final ap = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ap';
  }

  Map<String, dynamic> toMap() => {
        'id':     id,
        'hour':   hour,
        'minute': minute,
      };

  factory GlucoseReminderTime.fromMap(Map<String, dynamic> m) =>
      GlucoseReminderTime(
        id:     m['id']     as int,
        hour:   m['hour']   as int,
        minute: m['minute'] as int,
      );

  static List<GlucoseReminderTime> listFromJson(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) =>
            GlucoseReminderTime.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<GlucoseReminderTime> items) =>
      jsonEncode(items.map((e) => e.toMap()).toList());
}

// ── Medication reminder ────────────────────────────────────────────────────

enum MedicationStatus { pending, taken, missed }

class MedicationReminder {
  const MedicationReminder({
    required this.id,
    required this.name,
    required this.dose,
    required this.hour,
    required this.minute,
    this.frequency   = 'daily',
    this.statusToday = MedicationStatus.pending,
    this.lastStatusDate,
  });

  final int               id;
  final String            name;
  final String            dose;
  final int               hour;
  final int               minute;
  final String            frequency;
  final MedicationStatus  statusToday;
  final String?           lastStatusDate; // ISO8601 date string

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);

  String get timeLabel {
    final h  = hour   % 12 == 0 ? 12 : hour   % 12;
    final m  = minute.toString().padLeft(2, '0');
    final ap = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ap';
  }

  MedicationReminder copyWith({
    int?               id,
    String?            name,
    String?            dose,
    int?               hour,
    int?               minute,
    String?            frequency,
    MedicationStatus?  statusToday,
    String?            lastStatusDate,
  }) =>
      MedicationReminder(
        id:             id             ?? this.id,
        name:           name           ?? this.name,
        dose:           dose           ?? this.dose,
        hour:           hour           ?? this.hour,
        minute:         minute         ?? this.minute,
        frequency:      frequency      ?? this.frequency,
        statusToday:    statusToday    ?? this.statusToday,
        lastStatusDate: lastStatusDate ?? this.lastStatusDate,
      );

  Map<String, dynamic> toMap() => {
        'id':             id,
        'name':           name,
        'dose':           dose,
        'hour':           hour,
        'minute':         minute,
        'frequency':      frequency,
        'statusToday':    statusToday.index,
        'lastStatusDate': lastStatusDate,
      };

  factory MedicationReminder.fromMap(Map<String, dynamic> m) =>
      MedicationReminder(
        id:             m['id']             as int,
        name:           m['name']           as String,
        dose:           m['dose']           as String,
        hour:           m['hour']           as int,
        minute:         m['minute']         as int,
        frequency:      m['frequency']      as String? ?? 'daily',
        statusToday:    MedicationStatus
            .values[(m['statusToday'] as int? ?? 0)],
        lastStatusDate: m['lastStatusDate'] as String?,
      );

  static List<MedicationReminder> listFromJson(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) =>
            MedicationReminder.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<MedicationReminder> items) =>
      jsonEncode(items.map((e) => e.toMap()).toList());
}
