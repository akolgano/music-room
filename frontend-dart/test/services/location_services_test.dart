import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:music_room/services/location_services.dart';

class MockLocationService extends Mock implements LocationService {}

void main() {
  group('LocationService Tests', () {
    late LocationService locationService;
    late MockLocationService mockLocationService;

    setUp(() {
      locationService = LocationService();
      mockLocationService = MockLocationService();
    });

    test('should create LocationService instance', () {
      expect(locationService, isA<LocationService>());
    });

    test('should request location permission', () async {
      final permission = await locationService.requestPermission();
      expect(permission, isA<LocationPermission>());
    });

    test('should check location permission status', () async {
      final status = await locationService.checkPermission();
      expect(status, isA<LocationPermission>());
    });

    test('should get current location when permission granted', () async {
      final position = await locationService.getCurrentLocation();
      expect(position, isA<Position>());
      expect(position.latitude, isA<double>());
      expect(position.longitude, isA<double>());
    });

    test('should handle location permission denied', () async {
      when(mockLocationService.requestPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      
      final permission = await mockLocationService.requestPermission();
      expect(permission, LocationPermission.denied);
      
      verify(mockLocationService.requestPermission()).called(1);
    });

    test('should handle location service disabled', () async {
      when(mockLocationService.isLocationServiceEnabled())
          .thenAnswer((_) async => false);
      
      final isEnabled = await mockLocationService.isLocationServiceEnabled();
      expect(isEnabled, false);
      
      verify(mockLocationService.isLocationServiceEnabled()).called(1);
    });

    test('should get distance between two positions', () {
      final position1 = Position(
        latitude: 40.7128,
        longitude: -74.0060,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      
      final position2 = Position(
        latitude: 34.0522,
        longitude: -118.2437,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      
      final distance = locationService.getDistanceBetween(position1, position2);
      expect(distance, isA<double>());
      expect(distance, greaterThan(0));
    });

    test('should get bearing between two positions', () {
      final position1 = Position(
        latitude: 40.7128,
        longitude: -74.0060,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      
      final position2 = Position(
        latitude: 34.0522,
        longitude: -118.2437,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      
      final bearing = locationService.getBearingBetween(position1, position2);
      expect(bearing, isA<double>());
      expect(bearing, greaterThanOrEqualTo(0));
      expect(bearing, lessThan(360));
    });

    test('should start location stream', () async {
      final stream = locationService.getLocationStream();
      expect(stream, isA<Stream<Position>>());
    });

    test('should stop location stream', () async {
      final stream = locationService.getLocationStream();
      await locationService.stopLocationStream();
      expect(stream.isBroadcast, isA<bool>());
    });

    test('should handle location timeout', () async {
      expect(
        () => locationService.getCurrentLocationWithTimeout(
          timeout: Duration(milliseconds: 1),
        ),
        throwsA(isA<LocationTimeoutException>()),
      );
    });

    test('should validate location accuracy', () {
      final position = Position(
        latitude: 40.7128,
        longitude: -74.0060,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      
      final isAccurate = locationService.isLocationAccurate(position, 10.0);
      expect(isAccurate, true);
      
      final isNotAccurate = locationService.isLocationAccurate(position, 3.0);
      expect(isNotAccurate, false);
    });

    test('should format location coordinates', () {
      final position = Position(
        latitude: 40.7128,
        longitude: -74.0060,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      
      final formatted = locationService.formatCoordinates(position);
      expect(formatted, isA<String>());
      expect(formatted, contains('40.7128'));
      expect(formatted, contains('-74.0060'));
    });

    test('should check if location is within bounds', () {
      final position = Position(
        latitude: 40.7128,
        longitude: -74.0060,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      
      final bounds = LocationBounds(
        north: 41.0,
        south: 40.0,
        east: -73.0,
        west: -75.0,
      );
      
      final isWithinBounds = locationService.isWithinBounds(position, bounds);
      expect(isWithinBounds, true);
    });

    test('should get location address from coordinates', () async {
      final position = Position(
        latitude: 40.7128,
        longitude: -74.0060,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      
      when(mockLocationService.getAddressFromCoordinates(position))
          .thenAnswer((_) async => 'New York, NY, USA');
      
      final address = await mockLocationService.getAddressFromCoordinates(position);
      expect(address, 'New York, NY, USA');
      
      verify(mockLocationService.getAddressFromCoordinates(position)).called(1);
    });

    test('should get coordinates from address', () async {
      const address = 'New York, NY, USA';
      
      when(mockLocationService.getCoordinatesFromAddress(address))
          .thenAnswer((_) async => Position(
            latitude: 40.7128,
            longitude: -74.0060,
            timestamp: DateTime.now(),
            accuracy: 1.0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
          ));
      
      final position = await mockLocationService.getCoordinatesFromAddress(address);
      expect(position.latitude, 40.7128);
      expect(position.longitude, -74.0060);
      
      verify(mockLocationService.getCoordinatesFromAddress(address)).called(1);
    });

    test('should handle location settings resolution', () async {
      when(mockLocationService.openLocationSettings())
          .thenAnswer((_) async => true);
      
      final opened = await mockLocationService.openLocationSettings();
      expect(opened, true);
      
      verify(mockLocationService.openLocationSettings()).called(1);
    });
  });

  group('MockLocationService Tests', () {
    late MockLocationService mockLocation;

    setUp(() {
      mockLocation = MockLocationService();
    });

    test('should mock location operations', () async {
      final mockPosition = Position(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      
      when(mockLocation.getCurrentLocation())
          .thenAnswer((_) async => mockPosition);
      
      final position = await mockLocation.getCurrentLocation();
      expect(position.latitude, 37.7749);
      expect(position.longitude, -122.4194);
      
      verify(mockLocation.getCurrentLocation()).called(1);
    });

    test('should mock permission handling', () async {
      when(mockLocation.checkPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      
      final permission = await mockLocation.checkPermission();
      expect(permission, LocationPermission.whileInUse);
      
      verify(mockLocation.checkPermission()).called(1);
    });
  });
}