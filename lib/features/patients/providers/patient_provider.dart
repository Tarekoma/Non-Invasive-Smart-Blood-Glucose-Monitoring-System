// lib/features/patients/providers/patient_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/patient_model.dart';
import '../repository/patient_repository.dart';

// ── Repository ─────────────────────────────────────────────────────────────

final patientRepositoryProvider = Provider<PatientRepository>(
  (_) => const PatientRepository(),
);

// ── Search ─────────────────────────────────────────────────────────────────

/// Holds the live search string typed by the user.
/// FutureProviders that depend on this auto-rebuild on every keystroke.
final searchQueryProvider = StateProvider<String>((_) => '');

/// Reactive patient search — re-runs whenever [searchQueryProvider] changes.
final patientSearchProvider = FutureProvider<List<PatientModel>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final repo  = ref.watch(patientRepositoryProvider);
  return repo.searchPatients(query);
});

// ── All patients ───────────────────────────────────────────────────────────

/// Full patient list ordered by created_at DESC.
/// Invalidate after insert/update so the list refreshes automatically.
final allPatientsProvider = FutureProvider<List<PatientModel>>((ref) {
  final repo = ref.watch(patientRepositoryProvider);
  return repo.getAllPatients();
});

// ── Selection ──────────────────────────────────────────────────────────────

/// The patient currently being viewed or measured in the clinic workflow.
/// null between selections.
final selectedPatientProvider = StateProvider<PatientModel?>((_) => null);

// ── Save helper ────────────────────────────────────────────────────────────

/// Notifier that wraps insert + update and refreshes dependent providers.
class PatientNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<int> save(PatientModel patient) async {
    state = const AsyncLoading();
    final repo = ref.read(patientRepositoryProvider);
    try {
      final int id;
      if (patient.id == null) {
        id = await repo.insertPatient(patient);
      } else {
        await repo.updatePatient(patient);
        id = patient.id!;
      }
      // Invalidate list providers so UI refreshes without manual reload.
      ref.invalidate(allPatientsProvider);
      ref.invalidate(patientSearchProvider);
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final patientNotifierProvider =
    AsyncNotifierProvider<PatientNotifier, void>(PatientNotifier.new);
