// lib/core/ble/ble_provider.dart
//
// Replaces lib/core/providers/ble_provider.dart (Phase 1 stub).
// Import path for the rest of the app: 'core/ble/ble_provider.dart'

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ble_models.dart';
import 'ble_service.dart';
import 'mock_ble_service.dart';
import 'real_ble_service.dart';

// ── Service singleton ──────────────────────────────────────────────────────

/// Provides the correct [BleService] implementation based on [kUseMockBle].
///
/// The service is kept alive for the lifetime of the [ProviderScope];
/// its streams persist across widget rebuilds.
final bleServiceProvider = Provider<BleService>((ref) {
  final service = kUseMockBle ? MockBleService() : RealBleService();

  // BUG FIX: previously only MockBleService was disposed (via an `is` check).
  // RealBleService stream controllers were never closed → dart:async leak.
  // Now dispose() is declared on the BleService interface and called
  // polymorphically — no type check needed.
  ref.onDispose(service.dispose);

  return service;
});

// ── Status stream ──────────────────────────────────────────────────────────

/// Watches the BLE connection lifecycle.
///
/// Emits [BleStatus.connected] immediately in mock mode.
/// UI usage:
/// ```dart
/// final status = ref.watch(bleStatusProvider);
/// ```
final bleStatusProvider = StreamProvider<BleStatus>((ref) {
  return ref.watch(bleServiceProvider).statusStream;
});

// ── Latest reading stream ──────────────────────────────────────────────────

/// Emits the most recent [GlucoseReading] produced by [BleService.takeMeasurement].
///
/// Returns `null` before the first measurement of the session.
/// UI usage:
/// ```dart
/// final reading = ref.watch(latestReadingProvider).valueOrNull;
/// ```
final latestReadingProvider = StreamProvider<GlucoseReading?>((ref) {
  return ref.watch(bleServiceProvider).readingsStream.cast<GlucoseReading?>();
});
