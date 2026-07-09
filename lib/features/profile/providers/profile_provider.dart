// lib/features/profile/providers/profile_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_mode_provider.dart';
import '../../patients/models/patient_model.dart';
import '../../patients/providers/patient_provider.dart';

// ── Personal patient ID ────────────────────────────────────────────────────

/// The SQLite ID of the personal-mode patient.
/// Seeded from SharedPreferences in main.dart.
/// Updated immediately after first registration.
final personalPatientIdProvider = StateProvider<int?>((ref) => null);

// ── Personal patient record ────────────────────────────────────────────────

/// Loads and caches the personal patient from SQLite.
/// Refreshed whenever [personalPatientIdProvider] changes.
final personalPatientProvider = FutureProvider.autoDispose<PatientModel?>((
  ref,
) async {
  final id = ref.watch(personalPatientIdProvider);
  if (id == null) return null;
  return ref.read(patientRepositoryProvider).getPatientById(id);
});

// ── Save personal patient ID ───────────────────────────────────────────────

/// Called once after first-run registration to persist and seed the ID.
Future<void> savePersonalPatientId(WidgetRef ref, int id) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(AppConstants.personalPatientIdKey, id);
  ref.read(personalPatientIdProvider.notifier).state = id;
}

// ── Calibration offset (background / automatic only) ──────────────────────
//
// Per requirements: calibration is automatic/background — NOT manually
// adjustable by the user through the UI. The CalibrationNotifier is kept
// here for use by BLE measurement pipeline (auto-apply offset from EEPROM),
// but the manual slider widget has been removed from ProfileScreen.
//
// How auto-calibration works:
//   1. ESP32 EEPROM stores a calOffset computed from user-entered fingerstick
//      values (on-device menu — see glucose_estimator_v10.ino).
//   2. The firmware already applies calOffset before sending JSON over BLE.
//   3. The app-side calibrationOffsetProvider is therefore reserved for any
//      future app-level correction; default is 0.0 (pass-through).

/// App-level calibration offset (currently 0.0 — corrections done on device).
final calibrationOffsetProvider = StateProvider<double>((ref) => 0.0);

/// Background-only notifier. Not exposed in any UI widget.
class CalibrationNotifier extends Notifier<double> {
  @override
  double build() => 0.0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble(AppConstants.calibrationOffsetKey) ?? 0.0;
  }

  /// Called by BLE measurement pipeline — NOT by UI.
  Future<void> applyAutoOffset(double offset) async {
    state = offset;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.calibrationOffsetKey, offset);
  }
}

final calibrationNotifierProvider =
    NotifierProvider<CalibrationNotifier, double>(CalibrationNotifier.new);

// ── Personal extra fields (SharedPreferences) ──────────────────────────────

class PersonalExtrasState {
  const PersonalExtrasState({
    this.doctorName = '',
    this.doctorContact = '',
    this.emergencyContact = '',
  });

  final String doctorName;
  final String doctorContact;
  final String emergencyContact;

  PersonalExtrasState copyWith({
    String? doctorName,
    String? doctorContact,
    String? emergencyContact,
  }) => PersonalExtrasState(
    doctorName: doctorName ?? this.doctorName,
    doctorContact: doctorContact ?? this.doctorContact,
    emergencyContact: emergencyContact ?? this.emergencyContact,
  );
}

class PersonalExtrasNotifier extends AsyncNotifier<PersonalExtrasState> {
  @override
  Future<PersonalExtrasState> build() async {
    final prefs = await SharedPreferences.getInstance();
    return PersonalExtrasState(
      doctorName: prefs.getString(AppConstants.doctorNameKey) ?? '',
      doctorContact: prefs.getString(AppConstants.doctorContactKey) ?? '',
      emergencyContact: prefs.getString(AppConstants.emergencyContactKey) ?? '',
    );
  }

  Future<void> save({
    String? doctorName,
    String? doctorContact,
    String? emergencyContact,
  }) async {
    final current = state.valueOrNull ?? const PersonalExtrasState();
    final updated = current.copyWith(
      doctorName: doctorName,
      doctorContact: doctorContact,
      emergencyContact: emergencyContact,
    );
    state = AsyncData(updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.doctorNameKey, updated.doctorName);
    await prefs.setString(AppConstants.doctorContactKey, updated.doctorContact);
    await prefs.setString(
      AppConstants.emergencyContactKey,
      updated.emergencyContact,
    );
  }

  Future<void> saveFromRegistration({
    required String doctorName,
    required String doctorContact,
    required String emergencyContact,
    required double calibration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.doctorNameKey, doctorName);
    await prefs.setString(AppConstants.doctorContactKey, doctorContact);
    await prefs.setString(AppConstants.emergencyContactKey, emergencyContact);
    await prefs.setDouble(AppConstants.calibrationOffsetKey, calibration);
    state = AsyncData(
      PersonalExtrasState(
        doctorName: doctorName,
        doctorContact: doctorContact,
        emergencyContact: emergencyContact,
      ),
    );
  }
}

final personalExtrasProvider =
    AsyncNotifierProvider<PersonalExtrasNotifier, PersonalExtrasState>(
      PersonalExtrasNotifier.new,
    );

// ── Language preference ────────────────────────────────────────────────────

/// 'en' | 'ar'
class LanguageNotifier extends Notifier<String> {
  @override
  String build() => 'en';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(AppConstants.languageKey) ?? 'en';
  }

  Future<void> set(String lang) async {
    if (kDebugMode) {
      debugPrint('[i18n] Current locale: $state');
      debugPrint('[i18n] User selected: $lang');
      debugPrint('[i18n] Saving locale...');
    }
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.languageKey, lang);
    if (kDebugMode) {
      debugPrint('[i18n] Locale saved. Current locale after rebuild: $state');
    }
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, String>(
  LanguageNotifier.new,
);

// ── Reset app mode ─────────────────────────────────────────────────────────

Future<void> resetAppMode(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(AppConstants.appModeKey);
  await prefs.remove(AppConstants.personalPatientIdKey);
  ref.read(appModeProvider.notifier).state = null;
  ref.read(personalPatientIdProvider.notifier).state = null;
}
