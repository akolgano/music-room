import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/services/beacon_services.dart';
import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';

void main() {
  group('BeaconInfo', () {
    test('should create BeaconInfo with all properties', () {
      final lastSeen = DateTime.now();
      final beaconInfo = BeaconInfo(
        uuid: 'test-uuid',
        major: 1,
        minor: 2,
        distance: 1.5,
        proximity: 'near',
        rssi: -45,
        txPower: -59,
        lastSeen: lastSeen,
      );

      expect(beaconInfo.uuid, 'test-uuid');
      expect(beaconInfo.major, 1);
      expect(beaconInfo.minor, 2);
      expect(beaconInfo.distance, 1.5);
      expect(beaconInfo.proximity, 'near');
      expect(beaconInfo.rssi, -45);
      expect(beaconInfo.txPower, -59);
      expect(beaconInfo.lastSeen, lastSeen);
    });

    test('should create correct identifier', () {
      final beaconInfo = BeaconInfo(
        uuid: 'test-uuid',
        major: 1,
        minor: 2,
        distance: 1.5,
        proximity: 'near',
        rssi: -45,
        txPower: -59,
        lastSeen: DateTime.now(),
      );

      expect(beaconInfo.identifier, 'test-uuid-1-2');
    });

    test('should correctly identify nearby beacons', () {
      final nearbyBeacon = BeaconInfo(
        uuid: 'test-uuid',
        major: 1,
        minor: 2,
        distance: 1.5,
        proximity: 'near',
        rssi: -45,
        txPower: -59,
        lastSeen: DateTime.now(),
      );

      final farBeacon = BeaconInfo(
        uuid: 'test-uuid',
        major: 1,
        minor: 2,
        distance: 5.0,
        proximity: 'far',
        rssi: -80,
        txPower: -59,
        lastSeen: DateTime.now(),
      );

      final unknownBeacon = BeaconInfo(
        uuid: 'test-uuid',
        major: 1,
        minor: 2,
        distance: 1.0,
        proximity: 'unknown',
        rssi: -45,
        txPower: -59,
        lastSeen: DateTime.now(),
      );

      expect(nearbyBeacon.isNearby, isTrue);
      expect(farBeacon.isNearby, isFalse);
      expect(unknownBeacon.isNearby, isFalse);
    });

    test('should correctly identify proximity levels', () {
      final immediateBeacon = BeaconInfo(
        uuid: 'test-uuid',
        major: 1,
        minor: 2,
        distance: 0.5,
        proximity: 'immediate',
        rssi: -30,
        txPower: -59,
        lastSeen: DateTime.now(),
      );

      final nearBeacon = BeaconInfo(
        uuid: 'test-uuid',
        major: 1,
        minor: 2,
        distance: 1.5,
        proximity: 'near',
        rssi: -45,
        txPower: -59,
        lastSeen: DateTime.now(),
      );

      final farBeacon = BeaconInfo(
        uuid: 'test-uuid',
        major: 1,
        minor: 2,
        distance: 5.0,
        proximity: 'far',
        rssi: -80,
        txPower: -59,
        lastSeen: DateTime.now(),
      );

      expect(immediateBeacon.isImmediate, isTrue);
      expect(immediateBeacon.isNear, isFalse);
      expect(immediateBeacon.isFar, isFalse);

      expect(nearBeacon.isImmediate, isFalse);
      expect(nearBeacon.isNear, isTrue);
      expect(nearBeacon.isFar, isFalse);

      expect(farBeacon.isImmediate, isFalse);
      expect(farBeacon.isNear, isFalse);
      expect(farBeacon.isFar, isTrue);
    });

    test('should create BeaconInfo from Beacon object', () {
      final beacon = Beacon(
        proximityUUID: 'test-uuid',
        major: 1,
        minor: 2,
        rssi: -45,
        txPower: -59,
        accuracy: 1.5,
        proximity: Proximity.near,
      );

      final beaconInfo = BeaconInfo.fromBeacon(beacon);

      expect(beaconInfo.uuid, 'test-uuid');
      expect(beaconInfo.major, 1);
      expect(beaconInfo.minor, 2);
      expect(beaconInfo.distance, 1.5);
      expect(beaconInfo.proximity, 'near');
      expect(beaconInfo.rssi, -45);
      expect(beaconInfo.txPower, -59);
    });

    test('should handle null txPower with default value', () {
      final beacon = Beacon(
        proximityUUID: 'test-uuid',
        major: 1,
        minor: 2,
        rssi: -45,
        txPower: null,
        accuracy: 1.5,
        proximity: Proximity.near,
      );

      final beaconInfo = BeaconInfo.fromBeacon(beacon);

      expect(beaconInfo.txPower, -59);
    });
  });

  group('BeaconRegionConfig', () {
    test('should create BeaconRegionConfig with all properties', () {
      final config = BeaconRegionConfig(
        identifier: 'test-region',
        uuid: 'test-uuid',
        major: 1,
        minor: 2,
      );

      expect(config.identifier, 'test-region');
      expect(config.uuid, 'test-uuid');
      expect(config.major, 1);
      expect(config.minor, 2);
    });

    test('should create BeaconRegionConfig without major and minor', () {
      final config = BeaconRegionConfig(
        identifier: 'test-region',
        uuid: 'test-uuid',
      );

      expect(config.identifier, 'test-region');
      expect(config.uuid, 'test-uuid');
      expect(config.major, isNull);
      expect(config.minor, isNull);
    });

    test('should convert to Region object', () {
      final config = BeaconRegionConfig(
        identifier: 'test-region',
        uuid: 'test-uuid',
        major: 1,
        minor: 2,
      );

      final region = config.toRegion();

      expect(region.identifier, 'test-region');
      expect(region.proximityUUID, 'test-uuid');
      expect(region.major, 1);
      expect(region.minor, 2);
    });

    test('should convert to Region object without major and minor', () {
      final config = BeaconRegionConfig(
        identifier: 'test-region',
        uuid: 'test-uuid',
      );

      final region = config.toRegion();

      expect(region.identifier, 'test-region');
      expect(region.proximityUUID, 'test-uuid');
      expect(region.major, isNull);
      expect(region.minor, isNull);
    });
  });

  group('BeaconService', () {
    late BeaconService beaconService;

    setUp(() {
      beaconService = BeaconService();
    });

    test('should be a singleton', () {
      final instance1 = BeaconService();
      final instance2 = BeaconService();

      expect(identical(instance1, instance2), isTrue);
    });

    test('should have initial state', () {
      expect(beaconService.discoveredBeacons, isEmpty);
      expect(beaconService.isScanning, isFalse);
      expect(beaconService.isMonitoring, isFalse);
    });

    test('should provide stream access', () {
      expect(beaconService.beaconsStream, isNotNull);
      expect(beaconService.beaconEnteredStream, isNotNull);
      expect(beaconService.beaconExitedStream, isNotNull);
      expect(beaconService.scanningStateStream, isNotNull);
    });

    test('should create region config', () {
      final config = beaconService.createRegionConfig(
        identifier: 'test-region',
        uuid: 'test-uuid',
        major: 1,
        minor: 2,
      );

      expect(config.identifier, 'test-region');
      expect(config.uuid, 'test-uuid');
      expect(config.major, 1);
      expect(config.minor, 2);
    });

    test('should create region config without major and minor', () {
      final config = beaconService.createRegionConfig(
        identifier: 'test-region',
        uuid: 'test-uuid',
      );

      expect(config.identifier, 'test-region');
      expect(config.uuid, 'test-uuid');
      expect(config.major, isNull);
      expect(config.minor, isNull);
    });

    test('should get beacon by identifier', () {
      final beacon = beaconService.getBeaconByIdentifier('test-uuid-1-2');
      expect(beacon, isNull); // Should be null since no beacons are discovered
    });

    test('should filter beacons by proximity', () {
      final nearbyBeacons = beaconService.getBeaconsByProximity('near');
      expect(nearbyBeacons, isEmpty); // Should be empty since no beacons are discovered
    });

    test('should get strongest beacon', () {
      final strongestBeacon = beaconService.getStrongestBeacon();
      expect(strongestBeacon, isNull); // Should be null since no beacons are discovered
    });
  });
}
*/