// lib/core/ble/glucose_estimator_v10/mock_ble_service.dart
//
// Pure Dart — no Flutter imports.

import 'dart:async';
import 'dart:math';

import 'ble_models.dart';
import 'ble_service.dart';

/// Simulates the ESP32-C3 + MAX30102 sensor for UI development.
///
/// Behaviour contract (mirrors what the real hardware will do):
///
/// ┌─────────────────────────────────────────────────────────────┐
/// │  startScan()        scanning → (2 s) → connected           │
/// │  takeMeasurement()  scanning → (3 s mock) → connected      │
/// │  disconnect()       → disconnected                         │
/// └─────────────────────────────────────────────────────────────┘
///
/// Mock measurement uses 3 s (not 40 s) so UI iteration is fast.
class MockBleService implements BleService {
  MockBleService() {
    // Seed status as connected so the UI is usable without
    // calling startScan() manually in development.
    _statusController.add(BleStatus.connected);
  }

  final _random = Random();

  // ── Internal stream controllers ────────────────────────────────

  final _statusController = StreamController<BleStatus>.broadcast();
  final _readingsController = StreamController<GlucoseReading>.broadcast();

  // ── BleService API ─────────────────────────────────────────────

  @override
  Stream<BleStatus> get statusStream => _statusController.stream;

  @override
  Stream<GlucoseReading> get readingsStream => _readingsController.stream;

  // ── startScan ──────────────────────────────────────────────────

  @override
  Future<void> startScan() async {
    _emit(BleStatus.scanning);
    await Future<void>.delayed(const Duration(seconds: 2));
    _emit(BleStatus.connected);
  }

  // ── connect ────────────────────────────────────────────────────

  @override
  Future<void> connect() async {
    _emit(BleStatus.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    _emit(BleStatus.connected);
  }

  // ── disconnect ─────────────────────────────────────────────────

  @override
  Future<void> disconnect() async {
    _emit(BleStatus.disconnected);
  }

  // ── takeMeasurement ────────────────────────────────────────────

  @override
  Future<GlucoseReading> takeMeasurement() async {
    _emit(BleStatus.scanning);

    // 3 s mock delay (real hardware = ~40 s including finger check).
    await Future<void>.delayed(const Duration(seconds: 3));

    final reading = GlucoseReading(
      glucoseMgDl: (_random.nextInt(141) + 70).toDouble(), // 70–210 mg/dL
      heartRateBpm: _random.nextInt(41) + 60, // 60–100 bpm
      spo2: 95.0 + _random.nextDouble() * 5, // 95–100 %
      isCalibrated: false,
    );

    _readingsController.add(reading);
    _emit(BleStatus.connected);

    return reading;
  }

  // ── Helpers ────────────────────────────────────────────────────

  void _emit(BleStatus status) {
    if (!_statusController.isClosed) _statusController.add(status);
  }

  @override
  void dispose() {
    _statusController.close();
    _readingsController.close();
  }
}
