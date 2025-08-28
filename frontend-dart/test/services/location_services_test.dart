import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/services/location_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('LocationService Tests', () {
    late LocationService locationService;

    setUp(() {
      locationService = LocationService();
    });

    test('should create LocationService instance', () {
      expect(locationService, isA<LocationService>());
    });
  });
}