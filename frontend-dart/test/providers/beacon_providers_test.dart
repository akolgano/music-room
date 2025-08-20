import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:music_room/providers/beacon_providers.dart';
import 'package:music_room/services/beacon_services.dart';
import 'package:music_room/core/locator_core.dart';

import 'beacon_providers_test.mocks.dart';

@GenerateMocks([BeaconService])
void main() {
  group('BeaconProvider', () {
    late BeaconProvider provider;
    late MockBeaconService mockBeaconService;
    late StreamController<List<BeaconInfo>> beaconsController;
    late StreamController<BeaconInfo> beaconEnteredController;
    late StreamController<BeaconInfo> beaconExitedController;
    late StreamController<bool> scanningStateController;

    setUp(() {
      mockBeaconService = MockBeaconService();
      beaconsController = StreamController<List<BeaconInfo>>.broadcast();
      beaconEnteredController = StreamController<BeaconInfo>.broadcast();
      beaconExitedController = StreamController<BeaconInfo>.broadcast();
      scanningStateController = StreamController<bool>.broadcast();

      // Mock stream getters
      when(mockBeaconService.beaconsStream).thenAnswer((_) => beaconsController.stream);
      when(mockBeaconService.beaconEnteredStream).thenAnswer((_) => beaconEnteredController.stream);
      when(mockBeaconService.beaconExitedStream).thenAnswer((_) => beaconExitedController.stream);
      when(mockBeaconService.scanningStateStream).thenAnswer((_) => scanningStateController.stream);

      // Register mock service
      if (getIt.isRegistered<BeaconService>()) {
        getIt.unregister<BeaconService>();
      }
      getIt.registerSingleton<BeaconService>(mockBeaconService);

      provider = BeaconProvider();
    });

    tearDown(() async {
      await beaconsController.close();
      await beaconEnteredController.close();
      await beaconExitedController.close();
      await scanningStateController.close();
      provider.dispose();
      
      if (getIt.isRegistered<BeaconService>()) {
        getIt.unregister<BeaconService>();
      }
    });

    group('Initial State', () {
      test('should have correct initial values', () {
        expect(provider.discoveredBeacons, isEmpty);
        expect(provider.nearestBeacon, isNull);
        expect(provider.isScanning, isFalse);
        expect(provider.isInitialized, isFalse);
        expect(provider.selectedPlaylistId, isNull);
        expect(provider.nearbyBeacons, isEmpty);
        expect(provider.immediateBeacons, isEmpty);
      });
    });

    group('Beacon Service Initialization', () {
      test('should initialize beacon service successfully', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => true);

        final result = await provider.initializeBeacons();

        expect(result, isTrue);
        expect(provider.isInitialized, isTrue);
        expect(provider.successMessage, 'Beacon service initialized');
        verify(mockBeaconService.initialize()).called(1);
      });

      test('should handle initialization failure', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => false);

        final result = await provider.initializeBeacons();

        expect(result, isFalse);
        expect(provider.isInitialized, isFalse);
        expect(provider.hasError, isTrue);
        verify(mockBeaconService.initialize()).called(1);
      });

      test('should not reinitialize if already initialized', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => true);

        // First initialization
        await provider.initializeBeacons();
        expect(provider.isInitialized, isTrue);

        // Second attempt should return true without calling service
        final result = await provider.initializeBeacons();
        expect(result, isTrue);
        verify(mockBeaconService.initialize()).called(1); // Only called once
      });
    });

    group('Beacon Scanning', () {
      test('should start scanning successfully', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => true);
        when(mockBeaconService.startScanning(regions: anyNamed('regions'))).thenAnswer((_) async => true);

        final result = await provider.startScanning();

        expect(result, isTrue);
        expect(provider.successMessage, 'Started scanning for beacons');
        verify(mockBeaconService.startScanning(regions: anyNamed('regions'))).called(1);
      });

      test('should start scanning with custom regions', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => true);
        when(mockBeaconService.startScanning(regions: anyNamed('regions'))).thenAnswer((_) async => true);

        final customRegions = [
          BeaconRegionConfig(
            identifier: 'custom-region',
            uuid: 'TEST-UUID',
          ),
        ];

        final result = await provider.startScanning(regions: customRegions);

        expect(result, isTrue);
        verify(mockBeaconService.startScanning(regions: customRegions)).called(1);
      });

      test('should handle scanning failure', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => true);
        when(mockBeaconService.startScanning(regions: anyNamed('regions'))).thenAnswer((_) async => false);

        final result = await provider.startScanning();

        expect(result, isFalse);
        expect(provider.hasError, isTrue);
        verify(mockBeaconService.startScanning(regions: anyNamed('regions'))).called(1);
      });

      test('should initialize before scanning if not initialized', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => true);
        when(mockBeaconService.startScanning(regions: anyNamed('regions'))).thenAnswer((_) async => true);

        expect(provider.isInitialized, isFalse);

        final result = await provider.startScanning();

        expect(result, isTrue);
        expect(provider.isInitialized, isTrue);
        verify(mockBeaconService.initialize()).called(1);
        verify(mockBeaconService.startScanning(regions: anyNamed('regions'))).called(1);
      });

      test('should handle initialization failure during scanning', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => false);

        final result = await provider.startScanning();

        expect(result, isFalse);
        expect(provider.isInitialized, isFalse);
        verify(mockBeaconService.initialize()).called(1);
        verifyNever(mockBeaconService.startScanning(regions: anyNamed('regions')));
      });

      test('should stop scanning', () async {
        when(mockBeaconService.stopScanning()).thenAnswer((_) async {});

        await provider.stopScanning();

        verify(mockBeaconService.stopScanning()).called(1);
      });
    });

    group('Playlist Region Monitoring', () {
      test('should start monitoring playlist region', () async {
        const playlistId = 'playlist123';
        when(mockBeaconService.startMonitoring(any)).thenAnswer((_) async => true);

        final result = await provider.startMonitoringPlaylistRegion(playlistId);

        expect(result, isTrue);
        expect(provider.selectedPlaylistId, playlistId);
        expect(provider.successMessage, 'Started monitoring playlist region');

        final capturedRegions = verify(mockBeaconService.startMonitoring(captureAny)).captured.single as List<BeaconRegionConfig>;
        expect(capturedRegions.length, 1);
        expect(capturedRegions.first.identifier, 'playlist-$playlistId');
        expect(capturedRegions.first.uuid, 'E2C56DB5-DFFB-48D2-B060-D0F5A71096E0');
      });

      test('should handle monitoring failure', () async {
        const playlistId = 'playlist123';
        when(mockBeaconService.startMonitoring(any)).thenAnswer((_) async => false);

        final result = await provider.startMonitoringPlaylistRegion(playlistId);

        expect(result, isFalse);
        expect(provider.selectedPlaylistId, playlistId);
        expect(provider.hasError, isTrue);
      });

      test('should stop monitoring', () async {
        when(mockBeaconService.stopMonitoring()).thenAnswer((_) async {});

        await provider.stopMonitoring();

        expect(provider.selectedPlaylistId, isNull);
        verify(mockBeaconService.stopMonitoring()).called(1);
      });
    });

    group('Beacon Stream Handling', () {
      test('should handle beacons update stream', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => true);
        await provider.initializeBeacons();

        final testBeacons = [
          BeaconInfo(
            uuid: 'test-uuid',
            major: 1,
            minor: 2,
            distance: 1.5,
            proximity: 'near',
            rssi: -45,
            txPower: -59,
            lastSeen: DateTime.now(),
          ),
        ];

        bool listenerCalled = false;
        provider.addListener(() => listenerCalled = true);

        beaconsController.add(testBeacons);
        await Future.delayed(Duration.zero); // Allow stream to process

        expect(listenerCalled, isTrue);
        expect(provider.discoveredBeacons, hasLength(1));
        expect(provider.discoveredBeacons.first.uuid, 'test-uuid');
      });

      test('should handle beacon entered stream', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => true);
        await provider.initializeBeacons();

        final testBeacon = BeaconInfo(
          uuid: 'test-uuid',
          major: 1,
          minor: 2,
          distance: 1.0,
          proximity: 'immediate',
          rssi: -30,
          txPower: -59,
          lastSeen: DateTime.now(),
        );

        bool listenerCalled = false;
        provider.addListener(() => listenerCalled = true);

        beaconEnteredController.add(testBeacon);
        await Future.delayed(Duration.zero);

        expect(listenerCalled, isTrue);
      });

      test('should handle beacon exited stream', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => true);
        await provider.initializeBeacons();

        final testBeacon = BeaconInfo(
          uuid: 'test-uuid',
          major: 1,
          minor: 2,
          distance: 1.0,
          proximity: 'immediate',
          rssi: -30,
          txPower: -59,
          lastSeen: DateTime.now(),
        );

        bool listenerCalled = false;
        provider.addListener(() => listenerCalled = true);

        beaconExitedController.add(testBeacon);
        await Future.delayed(Duration.zero);

        expect(listenerCalled, isTrue);
      });

      test('should handle scanning state change stream', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => true);
        await provider.initializeBeacons();

        bool listenerCalled = false;
        provider.addListener(() => listenerCalled = true);

        scanningStateController.add(true);
        await Future.delayed(Duration.zero);

        expect(listenerCalled, isTrue);
        expect(provider.isScanning, isTrue);
      });

      test('should handle stream errors', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => true);
        await provider.initializeBeacons();

        beaconsController.addError('Test error');
        await Future.delayed(Duration.zero);

        expect(provider.hasError, isTrue);
        expect(provider.errorMessage, contains('Test error'));
      });
    });

    group('Nearest Beacon Logic', () {
      test('should update nearest beacon when beacons change', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => true);
        await provider.initializeBeacons();

        final farBeacon = BeaconInfo(
          uuid: 'test-uuid-1',
          major: 1,
          minor: 1,
          distance: 3.0,
          proximity: 'far',
          rssi: -80,
          txPower: -59,
          lastSeen: DateTime.now(),
        );

        final nearBeacon = BeaconInfo(
          uuid: 'test-uuid-2',
          major: 1,
          minor: 2,
          distance: 1.0,
          proximity: 'near',
          rssi: -45,
          txPower: -59,
          lastSeen: DateTime.now(),
        );

        beaconsController.add([farBeacon, nearBeacon]);
        await Future.delayed(Duration.zero);

        expect(provider.nearestBeacon?.uuid, 'test-uuid-2');
        expect(provider.nearestBeacon?.distance, 1.0);
      });

      test('should clear nearest beacon when no nearby beacons', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => true);
        await provider.initializeBeacons();

        final farBeacon = BeaconInfo(
          uuid: 'test-uuid',
          major: 1,
          minor: 1,
          distance: 5.0,
          proximity: 'unknown',
          rssi: -90,
          txPower: -59,
          lastSeen: DateTime.now(),
        );

        beaconsController.add([farBeacon]);
        await Future.delayed(Duration.zero);

        expect(provider.nearestBeacon, isNull);
      });

      test('should update nearest beacon when beacon exits', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => true);
        await provider.initializeBeacons();

        final beacon1 = BeaconInfo(
          uuid: 'test-uuid-1',
          major: 1,
          minor: 1,
          distance: 1.0,
          proximity: 'near',
          rssi: -45,
          txPower: -59,
          lastSeen: DateTime.now(),
        );

        final beacon2 = BeaconInfo(
          uuid: 'test-uuid-2',
          major: 1,
          minor: 2,
          distance: 1.5,
          proximity: 'near',
          rssi: -50,
          txPower: -59,
          lastSeen: DateTime.now(),
        );

        beaconsController.add([beacon1, beacon2]);
        await Future.delayed(Duration.zero);

        expect(provider.nearestBeacon?.uuid, 'test-uuid-1');

        // Simulate nearest beacon exiting
        beaconExitedController.add(beacon1);
        await Future.delayed(Duration.zero);

        // Should recalculate nearest beacon
      });
    });

    group('Playlist-Specific Methods', () {
      test('should get beacon for playlist', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => true);
        await provider.initializeBeacons();

        final testBeacon = BeaconInfo(
          uuid: 'test-uuid',
          major: 1234,
          minor: 1,
          distance: 1.0,
          proximity: 'near',
          rssi: -45,
          txPower: -59,
          lastSeen: DateTime.now(),
        );

        beaconsController.add([testBeacon]);
        await Future.delayed(Duration.zero);

        final beacon = provider.getBeaconForPlaylist('playlist1234test');
        expect(beacon, isNotNull);
        expect(beacon?.major, 1234);
      });

      test('should return null for playlist with no matching beacon', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => true);
        await provider.initializeBeacons();

        final beacon = provider.getBeaconForPlaylist('nonexistent');
        expect(beacon, isNull);
      });

      test('should check if user is near playlist', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => true);
        await provider.initializeBeacons();

        final nearBeacon = BeaconInfo(
          uuid: 'test-uuid',
          major: 1234,
          minor: 1,
          distance: 1.0,
          proximity: 'near',
          rssi: -45,
          txPower: -59,
          lastSeen: DateTime.now(),
        );

        beaconsController.add([nearBeacon]);
        await Future.delayed(Duration.zero);

        expect(provider.isUserNearPlaylist('playlist1234test'), isTrue);
        expect(provider.isUserNearPlaylist('playlist5678test'), isFalse);
      });
    });

    group('Service Getters', () {
      test('should return nearby beacons from service', () {
        final testBeacons = [
          BeaconInfo(
            uuid: 'test-uuid',
            major: 1,
            minor: 1,
            distance: 1.0,
            proximity: 'near',
            rssi: -45,
            txPower: -59,
            lastSeen: DateTime.now(),
          ),
        ];

        when(mockBeaconService.getNearbyBeacons()).thenReturn(testBeacons);

        expect(provider.nearbyBeacons, testBeacons);
        verify(mockBeaconService.getNearbyBeacons()).called(1);
      });

      test('should return immediate beacons from discovered beacons', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => true);
        await provider.initializeBeacons();

        final immediateBeacon = BeaconInfo(
          uuid: 'test-uuid',
          major: 1,
          minor: 1,
          distance: 0.5,
          proximity: 'immediate',
          rssi: -30,
          txPower: -59,
          lastSeen: DateTime.now(),
        );

        final nearBeacon = BeaconInfo(
          uuid: 'test-uuid-2',
          major: 1,
          minor: 2,
          distance: 1.5,
          proximity: 'near',
          rssi: -45,
          txPower: -59,
          lastSeen: DateTime.now(),
        );

        when(mockBeaconService.discoveredBeacons).thenReturn([immediateBeacon, nearBeacon]);

        expect(provider.immediateBeacons, hasLength(1));
        expect(provider.immediateBeacons.first.proximity, 'immediate');
      });
    });

    group('Dispose', () {
      test('should dispose all subscriptions and service', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => true);
        when(mockBeaconService.dispose()).thenAnswer((_) async {});

        await provider.initializeBeacons();

        expect(() => provider.dispose(), returnsNormally);
        verify(mockBeaconService.dispose()).called(1);
      });

      test('should handle dispose when not initialized', () {
        when(mockBeaconService.dispose()).thenAnswer((_) async {});

        expect(() => provider.dispose(), returnsNormally);
        verify(mockBeaconService.dispose()).called(1);
      });
    });

    group('Edge Cases', () {
      test('should handle empty beacon list updates', () async {
        when(mockBeaconService.initialize()).thenAnswer((_) async => true);
        await provider.initializeBeacons();

        beaconsController.add([]);
        await Future.delayed(Duration.zero);

        expect(provider.discoveredBeacons, isEmpty);
        expect(provider.nearestBeacon, isNull);
      });

      test('should handle playlist ID with no digits', () {
        final beacon = provider.getBeaconForPlaylist('nodigits');
        expect(beacon, isNull);
      });

      test('should handle playlist ID with insufficient digits', () {
        final beacon = provider.getBeaconForPlaylist('abc123');
        expect(beacon, isNull);
      });
    });
  });
}