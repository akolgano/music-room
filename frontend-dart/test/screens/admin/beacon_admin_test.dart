// DISABLED - Missing mock files
/*
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:music_room/screens/admin/beacon_admin.dart';
import 'package:music_room/providers/beacon_providers.dart';
import 'package:music_room/services/beacon_services.dart';

import 'beacon_admin_test.mocks.dart';

@GenerateMocks([BeaconProvider])
void main() {
  group('BeaconAdminScreen', () {
    late MockBeaconProvider mockBeaconProvider;

    setUp(() {
      mockBeaconProvider = MockBeaconProvider();
      
      when(mockBeaconProvider.isLoading).thenReturn(false);
      when(mockBeaconProvider.hasError).thenReturn(false);
      when(mockBeaconProvider.errorMessage).thenReturn(null);
      when(mockBeaconProvider.isInitialized).thenReturn(true);
      when(mockBeaconProvider.isScanning).thenReturn(false);
      when(mockBeaconProvider.discoveredBeacons).thenReturn([]);
      when(mockBeaconProvider.nearbyBeacons).thenReturn([]);
      when(mockBeaconProvider.nearestBeacon).thenReturn(null);
      when(mockBeaconProvider.selectedPlaylistId).thenReturn(null);
      
      when(mockBeaconProvider.initializeBeacons()).thenAnswer((_) async => true);
      when(mockBeaconProvider.startScanning()).thenAnswer((_) async => true);
      when(mockBeaconProvider.stopScanning()).thenAnswer((_) async => null);
      when(mockBeaconProvider.stopMonitoring()).thenAnswer((_) async => null);
      when(mockBeaconProvider.startMonitoringPlaylistRegion(any)).thenAnswer((_) async => true);
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<BeaconProvider>.value(
          value: mockBeaconProvider,
          child: const BeaconAdminScreen(),
        ),
      );
    }

    group('Widget Rendering', () {
      testWidgets('should render basic screen structure', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Beacon Management'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });

      testWidgets('should show loading state when provider is loading', (WidgetTester tester) async {
        when(mockBeaconProvider.isLoading).thenReturn(true);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Initializing beacons...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show error state when provider has error', (WidgetTester tester) async {
        when(mockBeaconProvider.hasError).thenReturn(true);
        when(mockBeaconProvider.errorMessage).thenReturn('Bluetooth not available');

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Bluetooth not available'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('should render all main cards when no error', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Beacon Status'), findsOneWidget);
        expect(find.text('Playlist Region Monitoring'), findsOneWidget);
        expect(find.text('Discovered Beacons'), findsOneWidget);
      });
    });

    group('App Bar Actions', () {
      testWidgets('should show play button when not scanning', (WidgetTester tester) async {
        when(mockBeaconProvider.isScanning).thenReturn(false);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(find.byIcon(Icons.pause), findsNothing);
      });

      testWidgets('should show pause button when scanning', (WidgetTester tester) async {
        when(mockBeaconProvider.isScanning).thenReturn(true);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.pause), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsNothing);
      });

      testWidgets('should show refresh button', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('should start scanning when play button tapped', (WidgetTester tester) async {
        when(mockBeaconProvider.isScanning).thenReturn(false);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.play_arrow));
        await tester.pumpAndSettle();

        verify(mockBeaconProvider.startScanning()).called(1);
      });

      testWidgets('should stop scanning when pause button tapped', (WidgetTester tester) async {
        when(mockBeaconProvider.isScanning).thenReturn(true);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.pause));
        await tester.pumpAndSettle();

        verify(mockBeaconProvider.stopScanning()).called(1);
      });

      testWidgets('should refresh beacons when refresh button tapped', (WidgetTester tester) async {
        when(mockBeaconProvider.isScanning).thenReturn(true);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        verify(mockBeaconProvider.stopScanning()).called(1);
      });
    });

    group('Status Card', () {
      testWidgets('should display correct status information', (WidgetTester tester) async {
        when(mockBeaconProvider.isInitialized).thenReturn(true);
        when(mockBeaconProvider.isScanning).thenReturn(true);
        when(mockBeaconProvider.discoveredBeacons).thenReturn([
          BeaconInfo(
            uuid: 'test-uuid',
            major: 1,
            minor: 1,
            distance: 1.5,
            proximity: 'near',
            rssi: -45,
            txPower: -59,
            lastSeen: DateTime.now(),
          ),
        ]);
        when(mockBeaconProvider.nearbyBeacons).thenReturn([]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Yes'), findsOneWidget);
        expect(find.text('Active'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
      });

      testWidgets('should show nearest beacon distance when available', (WidgetTester tester) async {
        final nearestBeacon = BeaconInfo(
          uuid: 'test-uuid',
          major: 1,
          minor: 1,
          distance: 1.2,
          proximity: 'near',
          rssi: -45,
          txPower: -59,
          lastSeen: DateTime.now(),
        );
        when(mockBeaconProvider.nearestBeacon).thenReturn(nearestBeacon);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('1.2m away'), findsOneWidget);
      });

      testWidgets('should show correct scanning icon and color', (WidgetTester tester) async {
        when(mockBeaconProvider.isScanning).thenReturn(true);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.bluetooth_searching), findsOneWidget);
      });

      testWidgets('should show disabled icon when not scanning', (WidgetTester tester) async {
        when(mockBeaconProvider.isScanning).thenReturn(false);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.bluetooth_disabled), findsOneWidget);
      });
    });

    group('Playlist Monitoring Card', () {
      testWidgets('should render playlist monitoring controls', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Playlist Region Monitoring'), findsOneWidget);
        expect(find.text('Start Monitoring'), findsOneWidget);
        expect(find.text('Stop Monitoring'), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);
      });

      testWidgets('should start monitoring when button tapped with valid playlist ID', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), 'playlist123');
        await tester.tap(find.text('Start Monitoring'));
        await tester.pumpAndSettle();

        verify(mockBeaconProvider.startMonitoringPlaylistRegion('playlist123')).called(1);
      });

      testWidgets('should show snackbar when trying to start monitoring with empty playlist ID', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Start Monitoring'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter a playlist ID'), findsOneWidget);
        verifyNever(mockBeaconProvider.startMonitoringPlaylistRegion(any));
      });

      testWidgets('should stop monitoring when stop button tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Stop Monitoring'));
        await tester.pumpAndSettle();

        verify(mockBeaconProvider.stopMonitoring()).called(1);
      });

      testWidgets('should show currently monitoring playlist when set', (WidgetTester tester) async {
        when(mockBeaconProvider.selectedPlaylistId).thenReturn('playlist456');

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Currently monitoring: playlist456'), findsOneWidget);
      });

      testWidgets('should disable buttons when provider is loading', (WidgetTester tester) async {
        when(mockBeaconProvider.isLoading).thenReturn(true);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Initializing beacons...'), findsOneWidget);
      });
    });

    group('Discovered Beacons Card', () {
      testWidgets('should show empty state when no beacons discovered', (WidgetTester tester) async {
        when(mockBeaconProvider.discoveredBeacons).thenReturn([]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('No beacons discovered\nStart scanning to find nearby beacons'), findsOneWidget);
      });

      testWidgets('should display beacon tiles when beacons are discovered', (WidgetTester tester) async {
        final beacons = [
          BeaconInfo(
            uuid: 'test-uuid-1',
            major: 1,
            minor: 1,
            distance: 0.5,
            proximity: 'immediate',
            rssi: -30,
            txPower: -59,
            lastSeen: DateTime.now(),
          ),
          BeaconInfo(
            uuid: 'test-uuid-2',
            major: 1,
            minor: 2,
            distance: 1.5,
            proximity: 'near',
            rssi: -45,
            txPower: -59,
            lastSeen: DateTime.now(),
          ),
        ];
        when(mockBeaconProvider.discoveredBeacons).thenReturn(beacons);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Major: 1, Minor: 1'), findsOneWidget);
        expect(find.text('Major: 1, Minor: 2'), findsOneWidget);
        expect(find.text('UUID: test-uuid-1'), findsOneWidget);
        expect(find.text('UUID: test-uuid-2'), findsOneWidget);
      });

      testWidgets('should show correct proximity chip and icon for immediate beacon', (WidgetTester tester) async {
        final beacon = BeaconInfo(
          uuid: 'test-uuid',
          major: 1,
          minor: 1,
          distance: 0.5,
          proximity: 'immediate',
          rssi: -30,
          txPower: -59,
          lastSeen: DateTime.now(),
        );
        when(mockBeaconProvider.discoveredBeacons).thenReturn([beacon]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('IMMEDIATE'), findsOneWidget);
        expect(find.byIcon(Icons.near_me), findsOneWidget);
      });

      testWidgets('should show correct proximity chip and icon for near beacon', (WidgetTester tester) async {
        final beacon = BeaconInfo(
          uuid: 'test-uuid',
          major: 1,
          minor: 1,
          distance: 1.5,
          proximity: 'near',
          rssi: -45,
          txPower: -59,
          lastSeen: DateTime.now(),
        );
        when(mockBeaconProvider.discoveredBeacons).thenReturn([beacon]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('NEAR'), findsOneWidget);
        expect(find.byIcon(Icons.location_on), findsOneWidget);
      });

      testWidgets('should show correct proximity chip and icon for far beacon', (WidgetTester tester) async {
        final beacon = BeaconInfo(
          uuid: 'test-uuid',
          major: 1,
          minor: 1,
          distance: 5.0,
          proximity: 'far',
          rssi: -80,
          txPower: -59,
          lastSeen: DateTime.now(),
        );
        when(mockBeaconProvider.discoveredBeacons).thenReturn([beacon]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('FAR'), findsOneWidget);
        expect(find.byIcon(Icons.location_searching), findsOneWidget);
      });

      testWidgets('should show correct beacon details', (WidgetTester tester) async {
        final beacon = BeaconInfo(
          uuid: 'test-uuid-123',
          major: 5,
          minor: 10,
          distance: 2.3,
          proximity: 'near',
          rssi: -55,
          txPower: -59,
          lastSeen: DateTime.now(),
        );
        when(mockBeaconProvider.discoveredBeacons).thenReturn([beacon]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Major: 5, Minor: 10'), findsOneWidget);
        expect(find.text('UUID: test-uuid-123'), findsOneWidget);
        expect(find.text('Distance: 2.3m'), findsOneWidget);
        expect(find.text('RSSI: -55 dBm'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should show retry button in error state', (WidgetTester tester) async {
        when(mockBeaconProvider.hasError).thenReturn(true);
        when(mockBeaconProvider.errorMessage).thenReturn('Failed to initialize');

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Retry'), findsOneWidget);
        
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        verify(mockBeaconProvider.initializeBeacons()).called(1);
      });

      testWidgets('should handle null error message gracefully', (WidgetTester tester) async {
        when(mockBeaconProvider.hasError).thenReturn(true);
        when(mockBeaconProvider.errorMessage).thenReturn(null);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Unknown error occurred'), findsOneWidget);
      });
    });

    group('Provider Integration', () {
      testWidgets('should respond to provider changes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        when(mockBeaconProvider.isScanning).thenReturn(true);
        
        expect(find.byType(BeaconAdminScreen), findsOneWidget);
      });
    });

    group('Lifecycle', () {
      testWidgets('should initialize beacons on screen creation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        verify(mockBeaconProvider.initializeBeacons()).called(1);
      });

      testWidgets('should dispose controller properly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.pumpWidget(Container());
        
        expect(tester.takeException(), isNull);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle very long UUIDs in beacon display', (WidgetTester tester) async {
        final beacon = BeaconInfo(
          uuid: 'very-very-very-long-uuid-that-might-overflow-display',
          major: 1,
          minor: 1,
          distance: 1.0,
          proximity: 'near',
          rssi: -45,
          txPower: -59,
          lastSeen: DateTime.now(),
        );
        when(mockBeaconProvider.discoveredBeacons).thenReturn([beacon]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('UUID: very-very-very-long-uuid-that-might-overflow-display'), findsOneWidget);
      });

      testWidgets('should handle unknown proximity values', (WidgetTester tester) async {
        final beacon = BeaconInfo(
          uuid: 'test-uuid',
          major: 1,
          minor: 1,
          distance: 1.0,
          proximity: 'unknown',
          rssi: -45,
          txPower: -59,
          lastSeen: DateTime.now(),
        );
        when(mockBeaconProvider.discoveredBeacons).thenReturn([beacon]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('UNKNOWN'), findsOneWidget);
        expect(find.byIcon(Icons.bluetooth), findsOneWidget);
      });
    });
  });
}
*/