import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/navigation_core.dart';

class BeaconInfo {
  final String uuid;
  final int major;
  final int minor;
  final double distance;
  final String proximity;
  final int rssi;
  final int txPower;
  final DateTime lastSeen;
  
  BeaconInfo({
    required this.uuid,
    required this.major,
    required this.minor,
    required this.distance,
    required this.proximity,
    required this.rssi,
    required this.txPower,
    required this.lastSeen,
  });
  
  factory BeaconInfo.fromBeacon(Beacon beacon) {
    return BeaconInfo(
      uuid: beacon.proximityUUID,
      major: beacon.major,
      minor: beacon.minor,
      distance: beacon.accuracy,
      proximity: beacon.proximity.toString().split('.').last,
      rssi: beacon.rssi,
      txPower: beacon.txPower ?? -59,
      lastSeen: DateTime.now(),
    );
  }
  
  String get identifier => '$uuid-$major-$minor';
  
  bool get isNearby => distance <= 2.0 && proximity != 'unknown';
  bool get isImmediate => proximity == 'immediate';
  bool get isNear => proximity == 'near';
  bool get isFar => proximity == 'far';
}

class BeaconRegionConfig {
  final String identifier;
  final String uuid;
  final int? major;
  final int? minor;
  
  BeaconRegionConfig({
    required this.identifier,
    required this.uuid,
    this.major,
    this.minor,
  });
  
  Region toRegion() {
    return Region(
      identifier: identifier,
      proximityUUID: uuid,
      major: major,
      minor: minor,
    );
  }
}

class BeaconService {
  static final BeaconService _instance = BeaconService._internal();
  factory BeaconService() => _instance;
  BeaconService._internal();

  final Map<String, BeaconInfo> _discoveredBeacons = {};
  final Map<String, BeaconRegionConfig> _monitoredRegions = {};
  
  StreamSubscription<RangingResult>? _rangingSubscription;
  StreamSubscription<MonitoringResult>? _monitoringSubscription;
  StreamSubscription<BluetoothState>? _bluetoothStateSubscription;
  
  final StreamController<List<BeaconInfo>> _beaconsController = StreamController<List<BeaconInfo>>.broadcast();
  final StreamController<BeaconInfo> _beaconEnteredController = StreamController<BeaconInfo>.broadcast();
  final StreamController<BeaconInfo> _beaconExitedController = StreamController<BeaconInfo>.broadcast();
  final StreamController<bool> _scanningStateController = StreamController<bool>.broadcast();
  
  Stream<List<BeaconInfo>> get beaconsStream => _beaconsController.stream;
  Stream<BeaconInfo> get beaconEnteredStream => _beaconEnteredController.stream;
  Stream<BeaconInfo> get beaconExitedStream => _beaconExitedController.stream;
  Stream<bool> get scanningStateStream => _scanningStateController.stream;
  
  List<BeaconInfo> get discoveredBeacons => _discoveredBeacons.values.toList();
  bool get isScanning => _rangingSubscription != null;
  bool get isMonitoring => _monitoringSubscription != null;

  Future<bool> initialize() async {
    try {
      if (kIsWeb) {
        AppLogger.warning('iBeacon is not supported on web platform', 'BeaconService');
        return false;
      }

      await flutterBeacon.initializeScanning;
      AppLogger.info('Beacon service initialized successfully', 'BeaconService');
      
      _bluetoothStateSubscription = flutterBeacon.bluetoothStateChanged().listen((state) {
        AppLogger.debug('Bluetooth state changed: $state', 'BeaconService');
        if (state == BluetoothState.stateOff) {
          AppLogger.warning('Bluetooth disabled - stopping beacon operations', 'BeaconService');
          stopScanning();
          stopMonitoring();
        }
      });
      
      return true;
    } catch (e) {
      AppLogger.error('Failed to initialize beacon service: $e', null, null, 'BeaconService');
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) return false;

      Map<Permission, PermissionStatus> permissions = {};
      
      if (Platform.isAndroid) {
        permissions = await [
          Permission.location,
          Permission.bluetoothScan,
          Permission.bluetoothAdvertise,
          Permission.bluetoothConnect,
        ].request();
      } else if (Platform.isIOS) {
        permissions = await [
          Permission.locationWhenInUse,
          Permission.bluetooth,
        ].request();
      }

      final allGranted = permissions.values.every(
        (status) => status == PermissionStatus.granted
      );
      
      if (!allGranted) {
        AppLogger.warning('Not all beacon permissions granted: $permissions', 'BeaconService');
        return false;
      }

      AppLogger.info('All beacon permissions granted', 'BeaconService');
      return true;
    } catch (e) {
      AppLogger.error('Failed to request beacon permissions: $e', null, null, 'BeaconService');
      return false;
    }
  }

  Future<bool> startScanning({List<BeaconRegionConfig>? regions}) async {
    try {
      if (kIsWeb) {
        AppLogger.warning('Beacon scanning not supported on web', 'BeaconService');
        return false;
      }

      if (isScanning) {
        AppLogger.debug('Beacon scanning already active', 'BeaconService');
        return true;
      }

      final permissionsGranted = await requestPermissions();
      if (!permissionsGranted) {
        AppLogger.error('Cannot start scanning - permissions not granted', null, null, 'BeaconService');
        return false;
      }

      regions ??= [
        BeaconRegionConfig(
          identifier: 'music-room-default',
          uuid: 'E2C56DB5-DFFB-48D2-B060-D0F5A71096E0',
        ),
      ];

      final regionsList = regions.map((config) => config.toRegion()).toList();
      
      _rangingSubscription = flutterBeacon.ranging(regionsList).listen(
        _handleRangingResult,
        onError: _handleRangingError,
      );

      _scanningStateController.add(true);
      AppLogger.info('Started scanning for ${regionsList.length} beacon regions', 'BeaconService');
      return true;
    } catch (e) {
      AppLogger.error('Failed to start beacon scanning: $e', null, null, 'BeaconService');
      return false;
    }
  }

  Future<void> stopScanning() async {
    try {
      await _rangingSubscription?.cancel();
      _rangingSubscription = null;
      
      _scanningStateController.add(false);
      AppLogger.info('Stopped beacon scanning', 'BeaconService');
    } catch (e) {
      AppLogger.error('Error stopping beacon scanning: $e', null, null, 'BeaconService');
    }
  }

  Future<bool> startMonitoring(List<BeaconRegionConfig> regions) async {
    try {
      if (kIsWeb) return false;

      if (isMonitoring) {
        AppLogger.debug('Beacon monitoring already active', 'BeaconService');
        return true;
      }

      final permissionsGranted = await requestPermissions();
      if (!permissionsGranted) return false;

      final regionsList = regions.map((config) => config.toRegion()).toList();
      
      for (final config in regions) {
        _monitoredRegions[config.identifier] = config;
      }

      _monitoringSubscription = flutterBeacon.monitoring(regionsList).listen(
        _handleMonitoringResult,
        onError: _handleMonitoringError,
      );

      AppLogger.info('Started monitoring ${regionsList.length} beacon regions', 'BeaconService');
      return true;
    } catch (e) {
      AppLogger.error('Failed to start beacon monitoring: $e', null, null, 'BeaconService');
      return false;
    }
  }

  Future<void> stopMonitoring() async {
    try {
      await _monitoringSubscription?.cancel();
      _monitoringSubscription = null;
      _monitoredRegions.clear();
      
      AppLogger.info('Stopped beacon monitoring', 'BeaconService');
    } catch (e) {
      AppLogger.error('Error stopping beacon monitoring: $e', null, null, 'BeaconService');
    }
  }

  void _handleRangingResult(RangingResult result) {
    try {
      final currentTime = DateTime.now();
      final expiredBeacons = <String>[];
      
      for (final entry in _discoveredBeacons.entries) {
        if (currentTime.difference(entry.value.lastSeen).inSeconds > 10) {
          expiredBeacons.add(entry.key);
        }
      }
      
      for (final expired in expiredBeacons) {
        final beacon = _discoveredBeacons.remove(expired);
        if (beacon != null) {
          _beaconExitedController.add(beacon);
          AppLogger.debug('Beacon expired: ${beacon.identifier}', 'BeaconService');
        }
      }

      for (final beacon in result.beacons) {
        final beaconInfo = BeaconInfo.fromBeacon(beacon);
        final wasNew = !_discoveredBeacons.containsKey(beaconInfo.identifier);
        
        _discoveredBeacons[beaconInfo.identifier] = beaconInfo;
        
        if (wasNew && beaconInfo.isNearby) {
          _beaconEnteredController.add(beaconInfo);
          AppLogger.info('New beacon detected: ${beaconInfo.identifier} at ${beaconInfo.distance.toStringAsFixed(1)}m', 'BeaconService');
        }
      }

      _beaconsController.add(discoveredBeacons);
      
      if (result.beacons.isNotEmpty) {
        AppLogger.debug('Ranged ${result.beacons.length} beacons in region ${result.region.identifier}', 'BeaconService');
      }
    } catch (e) {
      AppLogger.error('Error handling ranging result: $e', null, null, 'BeaconService');
    }
  }

  void _handleMonitoringResult(MonitoringResult result) {
    try {
      final regionConfig = _monitoredRegions[result.region.identifier];
      if (regionConfig == null) return;

      AppLogger.info('Region ${result.region.identifier} ${result.monitoringEventType.toString().split('.').last}', 'BeaconService');
    } catch (e) {
      AppLogger.error('Error handling monitoring result: $e', null, null, 'BeaconService');
    }
  }

  void _handleRangingError(dynamic error) {
    AppLogger.error('Beacon ranging error: $error', null, null, 'BeaconService');
  }

  void _handleMonitoringError(dynamic error) {
    AppLogger.error('Beacon monitoring error: $error', null, null, 'BeaconService');
  }

  List<BeaconInfo> getNearbyBeacons({double maxDistance = 2.0}) {
    return discoveredBeacons
        .where((beacon) => beacon.distance <= maxDistance && beacon.proximity != 'unknown')
        .toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));
  }

  Future<void> dispose() async {
    try {
      await stopScanning();
      await stopMonitoring();
      await _bluetoothStateSubscription?.cancel();
      
      await _beaconsController.close();
      await _beaconEnteredController.close();
      await _beaconExitedController.close();
      await _scanningStateController.close();
      
      _discoveredBeacons.clear();
      _monitoredRegions.clear();
      
      AppLogger.info('Beacon service disposed', 'BeaconService');
    } catch (e) {
      AppLogger.error('Error disposing beacon service: $e', null, null, 'BeaconService');
    }
  }
}