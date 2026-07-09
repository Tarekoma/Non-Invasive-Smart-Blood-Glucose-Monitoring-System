// lib/features/measurements/providers/measurement_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/patients/models/patient_model.dart';
import '../../../features/patients/repository/patient_repository.dart';
import '../models/measurement_model.dart';
import '../repository/measurement_repository.dart';

// ── Repository ──────────────────────────────────────────────────────────────

final measurementRepositoryProvider = Provider<MeasurementRepository>(
  (_) => const MeasurementRepository(),
);

// ── Personal patient ID ─────────────────────────────────────────────────────

const _kPersonalPatientIdKey = 'personal_patient_id';

/// Persists and exposes the single personal-mode patient's row id.
class PersonalPatientIdNotifier extends AsyncNotifier<int?> {
  @override
  Future<int?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kPersonalPatientIdKey);
  }

  Future<void> setId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPersonalPatientIdKey, id);
    state = AsyncData(id);
    ref.invalidate(personalPatientProvider);
    ref.invalidate(personalMeasurementsProvider);
    ref.invalidate(measurementStatsProvider);
  }
}

final personalPatientIdProvider =
    AsyncNotifierProvider<PersonalPatientIdNotifier, int?>(
  PersonalPatientIdNotifier.new,
);

// ── Personal patient record ─────────────────────────────────────────────────

final personalPatientProvider = FutureProvider<PatientModel?>((ref) async {
  final id = ref.watch(personalPatientIdProvider).valueOrNull;
  if (id == null) return null;
  return PatientRepository().getPatientById(id);
});

// ── Chart range ─────────────────────────────────────────────────────────────

/// Drives which time window the chart shows.
/// Values: 'daily' | 'weekly' | 'monthly'.  Default: 'daily'.
final chartRangeProvider = StateProvider<String>((_) => 'daily');

// ── BLE scanning flag ───────────────────────────────────────────────────────

/// True while a BLE measurement acquisition is in progress.
final isScanningProvider = StateProvider<bool>((_) => false);

// ── Countdown (UI only, 20 → 0) ────────────────────────────────────────────

/// Drives the countdown number shown in the scan dialog.
/// Reset to 20 before each scan; ticked down by the dialog's Timer.
final scanCountdownProvider = StateProvider<int>((_) => 20);

// ── Chart data (last 30 in selected range) ──────────────────────────────────

final personalMeasurementsProvider =
    FutureProvider<List<MeasurementModel>>((ref) async {
  final id = ref.watch(personalPatientIdProvider).valueOrNull;
  if (id == null) return [];
  final repo  = ref.watch(measurementRepositoryProvider);
  final range = ref.watch(chartRangeProvider);
  final now   = DateTime.now();

  final from = switch (range) {
    'daily'   => DateTime(now.year, now.month, now.day),
    'monthly' => DateTime(now.year, now.month - 1, now.day),
    _         => DateTime(now.year, now.month, now.day - 7), // weekly
  };

  return repo.getMeasurementsInRange(id, from, now);
});

// ── Recent readings (last 30 for home list) ─────────────────────────────────

final recentMeasurementsProvider =
    FutureProvider<List<MeasurementModel>>((ref) async {
  final id = ref.watch(personalPatientIdProvider).valueOrNull;
  if (id == null) return [];
  return ref.watch(measurementRepositoryProvider)
      .getMeasurementsForPatient(id, limit: 30);
});

// ── Stats ────────────────────────────────────────────────────────────────────

final measurementStatsProvider =
    FutureProvider<MeasurementStats>((ref) async {
  final id = ref.watch(personalPatientIdProvider).valueOrNull;
  if (id == null) return MeasurementStats.empty;
  return ref.watch(measurementRepositoryProvider).getStats(id);
});

// ── Save notifier ────────────────────────────────────────────────────────────

class MeasurementNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<int> save(MeasurementModel m) async {
    state = const AsyncLoading();
    final repo = ref.read(measurementRepositoryProvider);
    try {
      final id = await repo.insertMeasurement(m);
      state = const AsyncData(null);
      ref.invalidate(personalMeasurementsProvider);
      ref.invalidate(recentMeasurementsProvider);
      ref.invalidate(measurementStatsProvider);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final measurementNotifierProvider =
    AsyncNotifierProvider<MeasurementNotifier, void>(MeasurementNotifier.new);
