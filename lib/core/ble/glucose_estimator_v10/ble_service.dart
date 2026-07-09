// lib/core/ble/glucose_estimator_v10/ble_service.dart

import 'ble_models.dart';

/// Controls the BLE flag — flip to false when hardware is ready.
/// Zero other changes needed anywhere in the app.
const bool kUseMockBle = false;

/// Abstract BLE service contract.
///
/// Implementations:
///   [MockBleService]  — pure Dart, no hardware needed (kUseMockBle = true)
///   [RealBleService]  — flutter_blue_plus, real ESP32 (kUseMockBle = false)
abstract class BleService {
  /// Stream of BLE connection state changes.
  Stream<BleStatus> get statusStream;

  /// Stream of completed [GlucoseReading] results.
  Stream<GlucoseReading> get readingsStream;

  /// Scan for and connect to the GlucoTrack device.
  Future<void> connect();

  /// Convenience method — same as [connect] for callers that
  /// want an explicit "start scanning" verb.
  Future<void> startScan();

  /// Disconnect from the device.
  Future<void> disconnect();

  /// Run a full PPG measurement and return the result.
  ///
  /// Will auto-connect if not already connected.
  /// Throws [TimeoutException] if the device doesn't respond in time.
  Future<GlucoseReading> takeMeasurement();

  /// Release all stream controllers and subscriptions.
  /// Called automatically by [bleServiceProvider] on dispose.
  void dispose();
}
