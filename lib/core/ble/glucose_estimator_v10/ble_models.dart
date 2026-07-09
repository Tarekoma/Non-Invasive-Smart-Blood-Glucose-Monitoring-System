// lib/core/ble/glucose_estimator_v10/ble_models.dart

import '../../../l10n/generated/app_localizations.dart';

// ── BLE connection status ──────────────────────────────────────

enum BleStatus { disconnected, scanning, connecting, connected }

extension BleStatusX on BleStatus {
  /// True while a transition is in progress (dots should pulse in UI).
  bool get isActive =>
      this == BleStatus.scanning || this == BleStatus.connecting;

  /// Internal/debug-only English label — used in log lines (see
  /// [real_ble_service.dart]'s `_log`), never shown to end users, so it is
  /// intentionally not localized.
  String get label => switch (this) {
    BleStatus.connected => 'Connected',
    BleStatus.scanning => 'Scanning…',
    BleStatus.connecting => 'Connecting…',
    BleStatus.disconnected => 'Disconnected',
  };

  /// User-facing localized label for [ble_status_bar.dart].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    BleStatus.connected => l10n.bleConnected,
    BleStatus.scanning => l10n.bleScanning,
    BleStatus.connecting => l10n.bleConnecting,
    BleStatus.disconnected => l10n.bleDisconnected,
  };
}

// ── Glucose reading produced by a single BLE measurement ──────

/// Immutable result returned by [BleService.takeMeasurement].
///
/// Fields map 1-to-1 to the JSON the firmware notifies:
///   {"g": 120.5, "hr": 72, "spo2": 98.1, "cal": 1}
///
/// [spo2] is null when the firmware returns −1 (insufficient signal).
class GlucoseReading {
  const GlucoseReading({
    required this.glucoseMgDl,
    required this.heartRateBpm,
    this.spo2,
    this.isCalibrated = false,
  });

  /// Glucose in mg/dL — already calibrated by the firmware.
  final double glucoseMgDl;

  /// Heart rate in BPM — measured during the same PPG scan.
  final int heartRateBpm;

  /// SpO2 percentage (80–100 %). Null when firmware signals no data.
  final double? spo2;

  /// True when firmware's calState == 1 (at least one calibration point).
  final bool isCalibrated;

  GlucoseReading copyWith({
    double? glucoseMgDl,
    int? heartRateBpm,
    double? spo2,
    bool? isCalibrated,
  }) => GlucoseReading(
    glucoseMgDl: glucoseMgDl ?? this.glucoseMgDl,
    heartRateBpm: heartRateBpm ?? this.heartRateBpm,
    spo2: spo2 ?? this.spo2,
    isCalibrated: isCalibrated ?? this.isCalibrated,
  );

  @override
  String toString() =>
      'GlucoseReading(g:$glucoseMgDl mg/dL, hr:$heartRateBpm bpm, '
      'spo2:$spo2%, cal:$isCalibrated)';
}
