// lib/core/ble/glucose_estimator_v10/real_ble_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ble_models.dart';
import 'ble_service.dart';

void _log(String message) => debugPrint('[BLE] $message');

class RealBleService implements BleService {
  static const _deviceName = 'GlucoTrack';
  static const _serviceUuid = '00001523-1212-efde-1523-785feabcd123';
  static const _cmdCharUuid = '00001524-1212-efde-1523-785feabcd123';
  static const _resultCharUuid = '00001525-1212-efde-1523-785feabcd123';

  static const _measureTimeout = Duration(seconds: 40);
  static const _connectTimeout = Duration(seconds: 15);
  static const _scanTimeout = Duration(seconds: 10);

  BluetoothDevice? _device;
  StreamSubscription<dynamic>? _connectionStateSub;
  StreamSubscription<dynamic>? _notifySub;

  final _statusController = StreamController<BleStatus>.broadcast();
  final _readingsController = StreamController<GlucoseReading>.broadcast();

  BleStatus _currentStatus = BleStatus.disconnected;

  @override
  Stream<BleStatus> get statusStream => _statusController.stream;

  @override
  Stream<GlucoseReading> get readingsStream => _readingsController.stream;

  void _setStatus(BleStatus s) {
    _currentStatus = s;
    _log('status -> ${s.label}');
    if (!_statusController.isClosed) _statusController.add(s);
  }

  // ── startScan — delegates to connect() ────────────────────────
  // Satisfies the BleService interface. Both verbs do the same thing
  // on real hardware: scan → find → connect.
  @override
  Future<void> startScan() => connect();

  // ── Runtime permissions ────────────────────────────────────────
  //
  // Android's manifest-declared BLUETOOTH_SCAN/BLUETOOTH_CONNECT/
  // ACCESS_FINE_LOCATION are "dangerous" permissions on API 23+ — declaring
  // them in the manifest does not grant them. Without an explicit runtime
  // request here, FlutterBluePlus.startScan() throws (or silently returns
  // nothing) on every Android 12+ device. permission_handler internally
  // no-ops requests for permissions that don't apply to the running OS
  // version, so this is safe to call unconditionally on every connect().
  Future<void> _ensurePermissions() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    // Location matters only pre-Android-12 (BLUETOOTH_SCAN's
    // neverForLocation flag makes it unnecessary on 12+, where the manifest
    // also caps it with maxSdkVersion="30" so it isn't even requestable).
    // Best-effort only: if it's denied on an OS version that actually needs
    // it, the scan below simply finds no devices and the existing "device
    // not found" error further down handles that without a false permission
    // error on newer Android versions.
    await Permission.locationWhenInUse.request();

    final denied = statuses.values.any((s) => !s.isGranted && !s.isLimited);
    if (denied) {
      _log('required Bluetooth permissions denied: $statuses');
      throw StateError(
        'Bluetooth permission was denied. Enable it in system settings to '
        'connect to your device.',
      );
    }
  }

  // ── connect ───────────────────────────────────────────────────

  @override
  Future<void> connect() async {
    await _ensurePermissions();

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      _log('adapter is off — aborting connect');
      throw StateError('Bluetooth is off. Enable Bluetooth and try again.');
    }

    _log('scanning for "$_deviceName" (service $_serviceUuid)...');
    _setStatus(BleStatus.scanning);

    final scanCompleter = Completer<BluetoothDevice?>();

    final scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final nameMatch = r.device.platformName == _deviceName;
        final serviceMatch = r.advertisementData.serviceUuids.any(
          (u) => u.str.toLowerCase() == _serviceUuid,
        );
        if ((nameMatch || serviceMatch) && !scanCompleter.isCompleted) {
          _log('device found: ${r.device.remoteId} ("${r.device.platformName}")');
          scanCompleter.complete(r.device);
        }
      }
    });

    await FlutterBluePlus.startScan(
      withServices: [Guid(_serviceUuid)],
      timeout: _scanTimeout,
    );

    Future<void>.delayed(_scanTimeout).then((_) {
      if (!scanCompleter.isCompleted) scanCompleter.complete(null);
    });

    final found = await scanCompleter.future;
    await scanSub.cancel();
    await FlutterBluePlus.stopScan();

    if (found == null) {
      _log('scan timed out — no matching device in range');
      _setStatus(BleStatus.disconnected);
      throw StateError(
        'GlucoTrack device not found. '
        'Make sure it is powered on and within 5 m.',
      );
    }

    _device = found;
    _log('connecting to ${found.remoteId}...');
    _setStatus(BleStatus.connecting);

    _connectionStateSub?.cancel();
    _connectionStateSub = _device!.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _log('device connection dropped');
        _setStatus(BleStatus.disconnected);
      }
    });

    await _device!.connect(timeout: _connectTimeout, autoConnect: false);
    _log('connected');
    _setStatus(BleStatus.connected);
  }

  // ── disconnect ────────────────────────────────────────────────

  @override
  Future<void> disconnect() async {
    _log('disconnecting...');
    _connectionStateSub?.cancel();
    _connectionStateSub = null;
    _notifySub?.cancel();
    _notifySub = null;
    await _device?.disconnect();
    _device = null;
    _setStatus(BleStatus.disconnected);
    _log('disconnected');
  }

  // ── takeMeasurement ───────────────────────────────────────────

  @override
  Future<GlucoseReading> takeMeasurement() async {
    if (_device == null || _currentStatus != BleStatus.connected) {
      await connect();
    }

    _log('discovering services...');
    final services = await _device!.discoverServices();

    final svc = services.firstWhere(
      (s) => s.serviceUuid.str.toLowerCase() == _serviceUuid,
      orElse: () => throw StateError(
        'GlucoTrack service not found. Flash the updated firmware.',
      ),
    );
    _log('service discovered');

    final resultChar = svc.characteristics.firstWhere(
      (c) => c.characteristicUuid.str.toLowerCase() == _resultCharUuid,
      orElse: () => throw StateError('Result characteristic not found.'),
    );

    final cmdChar = svc.characteristics.firstWhere(
      (c) => c.characteristicUuid.str.toLowerCase() == _cmdCharUuid,
      orElse: () => throw StateError('Command characteristic not found.'),
    );
    _log('characteristics found (cmd + result)');

    // Subscribe FIRST, write SECOND — prevents race condition
    final resultCompleter = Completer<GlucoseReading>();

    _notifySub?.cancel();
    _notifySub = resultChar.lastValueStream.listen((data) {
      if (data.isEmpty) return;
      _log('packet received: ${utf8.decode(data, allowMalformed: true)}');
      try {
        final json = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
        final spo2 = (json['spo2'] as num?)?.toDouble();
        final reading = GlucoseReading(
          glucoseMgDl: (json['g'] as num).toDouble(),
          heartRateBpm: (json['hr'] as num).toInt(),
          spo2: (spo2 != null && spo2 > 0) ? spo2 : null,
          isCalibrated: (json['cal'] as int? ?? 0) == 1,
        );
        _log('parsed glucose value: ${reading.glucoseMgDl} mg/dL');
        if (!resultCompleter.isCompleted) {
          resultCompleter.complete(reading);
          _readingsController.add(reading);
          _log('UI stream updated with real reading');
        }
      } catch (e) {
        _log('bad payload: $e');
        if (!resultCompleter.isCompleted) {
          resultCompleter.completeError(StateError('Bad BLE payload: $e'));
        }
      }
    });

    await resultChar.setNotifyValue(true);
    _log('notifications enabled on result characteristic');
    await cmdChar.write([0x01], withoutResponse: false);
    _log('measurement command sent — waiting for device...');

    final reading = await resultCompleter.future.timeout(
      _measureTimeout,
      onTimeout: () {
        _notifySub?.cancel();
        _notifySub = null;
        _log('measurement timed out — no packet received');
        throw TimeoutException(
          'Measurement timed out. Keep your finger on the sensor and retry.',
        );
      },
    );

    _notifySub?.cancel();
    _notifySub = null;
    return reading;
  }

  // ── dispose ───────────────────────────────────────────────────

  @override
  void dispose() {
    _notifySub?.cancel();
    _connectionStateSub?.cancel();
    _device?.disconnect();
    _statusController.close();
    _readingsController.close();
  }
}
