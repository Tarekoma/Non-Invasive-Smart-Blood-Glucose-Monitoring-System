// lib/features/reminders/providers/reminder_provider.dart

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/notifications/notification_service.dart';
import '../models/reminder_models.dart';

// ── Water reminder ─────────────────────────────────────────────────────────

class WaterReminderNotifier
    extends AsyncNotifier<WaterReminderSettings> {
  @override
  Future<WaterReminderSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final json  = prefs.getString('water_reminder_v2');
    if (json == null) return const WaterReminderSettings();
    return WaterReminderSettings.fromJson(json);
  }

  Future<void> _persist(WaterReminderSettings s) async {
    state = AsyncData(s);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('water_reminder_v2', s.toJson());
  }

  Future<void> setEnabled(bool enabled) async {
    final current = state.valueOrNull ?? const WaterReminderSettings();
    final updated = current.copyWith(enabled: enabled);
    await _persist(updated);
    if (enabled) {
      await NotificationService.instance.scheduleWaterReminder(
        intervalHours: updated.intervalHours,
        wakeHour:      updated.wakeHour,
        sleepHour:     updated.sleepHour,
      );
    } else {
      await NotificationService.instance.cancelWaterReminder();
    }
  }

  Future<void> setInterval(int hours) async {
    final current = state.valueOrNull ?? const WaterReminderSettings();
    final updated = current.copyWith(intervalHours: hours);
    await _persist(updated);
    if (updated.enabled) {
      await NotificationService.instance.scheduleWaterReminder(
        intervalHours: hours,
        wakeHour:      updated.wakeHour,
        sleepHour:     updated.sleepHour,
      );
    }
  }

  Future<void> setWakeTime(int hour) async {
    final current = state.valueOrNull ?? const WaterReminderSettings();
    await _persist(current.copyWith(wakeHour: hour));
  }

  Future<void> setSleepTime(int hour) async {
    final current = state.valueOrNull ?? const WaterReminderSettings();
    await _persist(current.copyWith(sleepHour: hour));
  }

  Future<void> increment() async {
    final current = state.valueOrNull ?? const WaterReminderSettings();
    final newCount = (current.dailyCount + 1)
        .clamp(0, AppConstants.waterDailyGoal + 5);
    await _persist(current.copyWith(dailyCount: newCount));
  }

  Future<void> decrement() async {
    final current = state.valueOrNull ?? const WaterReminderSettings();
    final newCount = (current.dailyCount - 1).clamp(0, 99);
    await _persist(current.copyWith(dailyCount: newCount));
  }

  Future<void> resetDailyCount() async {
    final current = state.valueOrNull ?? const WaterReminderSettings();
    await _persist(current.copyWith(dailyCount: 0));
  }
}

final waterReminderProvider =
    AsyncNotifierProvider<WaterReminderNotifier, WaterReminderSettings>(
        WaterReminderNotifier.new);

// ── Glucose measurement reminders ──────────────────────────────────────────

class GlucoseRemindersNotifier
    extends AsyncNotifier<List<GlucoseReminderTime>> {
  @override
  Future<List<GlucoseReminderTime>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final json  = prefs.getString(AppConstants.glucoseTimesKey);
    if (json == null) return [];
    return GlucoseReminderTime.listFromJson(json);
  }

  Future<void> _persist(List<GlucoseReminderTime> list) async {
    state = AsyncData(list);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        AppConstants.glucoseTimesKey,
        GlucoseReminderTime.listToJson(list));
  }

  Future<void> addTime(TimeOfDay time) async {
    final current = List<GlucoseReminderTime>.from(
        state.valueOrNull ?? []);
    // Assign the next available index
    final usedIds = current.map((e) => e.id).toSet();
    int nextId = 0;
    while (usedIds.contains(nextId)) nextId++;
    if (nextId >= 10) return; // max 10 reminders

    final item = GlucoseReminderTime(
      id:     nextId,
      hour:   time.hour,
      minute: time.minute,
    );
    current.add(item);
    current.sort((a, b) =>
        a.hour != b.hour ? a.hour - b.hour : a.minute - b.minute);
    await _persist(current);

    await NotificationService.instance.scheduleGlucoseReminder(
      index: nextId,
      time:  time,
    );
  }

  Future<void> remove(GlucoseReminderTime item) async {
    final current = List<GlucoseReminderTime>.from(
        state.valueOrNull ?? [])
      ..removeWhere((e) => e.id == item.id);
    await _persist(current);
    await NotificationService.instance.cancelGlucoseReminder(item.id);
  }
}

final glucoseRemindersProvider =
    AsyncNotifierProvider<GlucoseRemindersNotifier,
        List<GlucoseReminderTime>>(GlucoseRemindersNotifier.new);

// ── Medication reminders ───────────────────────────────────────────────────

class MedicationRemindersNotifier
    extends AsyncNotifier<List<MedicationReminder>> {
  @override
  Future<List<MedicationReminder>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final json  = prefs.getString(AppConstants.medicationsKey);
    if (json == null) return [];
    // Reset status if lastStatusDate is not today.
    final today = _todayStr();
    final list  = MedicationReminder.listFromJson(json);
    return list.map((m) {
      if (m.lastStatusDate != today) {
        return m.copyWith(
          statusToday:    MedicationStatus.pending,
          lastStatusDate: today,
        );
      }
      return m;
    }).toList();
  }

  Future<void> _persist(List<MedicationReminder> list) async {
    state = AsyncData(list);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        AppConstants.medicationsKey,
        MedicationReminder.listToJson(list));
  }

  Future<void> add(MedicationReminder med) async {
    final current = List<MedicationReminder>.from(
        state.valueOrNull ?? []);
    final usedIds = current.map((e) => e.id).toSet();
    int nextId = 0;
    while (usedIds.contains(nextId)) nextId++;
    if (nextId >= 20) return;

    final item = med.copyWith(id: nextId, lastStatusDate: _todayStr());
    current.add(item);
    await _persist(current);

    await NotificationService.instance.scheduleMedicationReminder(
      index:          nextId,
      medicationName: item.name,
      dose:           item.dose,
      time:           item.timeOfDay,
    );
  }

  Future<void> remove(MedicationReminder med) async {
    final current = List<MedicationReminder>.from(
        state.valueOrNull ?? [])
      ..removeWhere((e) => e.id == med.id);
    await _persist(current);
    await NotificationService.instance.cancelMedicationReminder(med.id);
  }

  Future<void> markStatus(
      MedicationReminder med, MedicationStatus status) async {
    final current = List<MedicationReminder>.from(
        state.valueOrNull ?? []);
    final idx = current.indexWhere((e) => e.id == med.id);
    if (idx == -1) return;
    current[idx] = current[idx].copyWith(
      statusToday:    status,
      lastStatusDate: _todayStr(),
    );
    await _persist(current);
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}'
        '-${n.day.toString().padLeft(2, '0')}';
  }
}

final medicationRemindersProvider =
    AsyncNotifierProvider<MedicationRemindersNotifier,
        List<MedicationReminder>>(MedicationRemindersNotifier.new);
