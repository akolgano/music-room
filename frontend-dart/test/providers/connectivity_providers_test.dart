import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/providers/connectivity_providers.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/core/locator_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late ConnectivityProvider provider;
  late ApiService mockApiService;

  setUp(() {
    getIt.reset();
    mockApiService = _MockApiService();
    getIt.registerSingleton<ApiService>(mockApiService);
    provider = ConnectivityProvider();
  });

  tearDown(() {
    provider.dispose();
    getIt.reset();
  });

  group('ConnectivityProvider Tests', () {
    test('initial state should be checking', () {
      expect(provider.connectionStatus, equals(ConnectionStatus.checking));
      expect(provider.isChecking, isTrue);
      expect(provider.isConnected, isFalse);
      expect(provider.isDisconnected, isFalse);
    });

    test('connectionStatusText should return correct status text', () {
      provider = ConnectivityProvider();
      expect(provider.connectionStatusText, equals('Checking...'));
    });

    test('should have correct initial values', () {
      expect(provider.lastConnectedTime, isNull);
      expect(provider.currentCheckInterval, equals(Duration(seconds: 30)));
      expect(provider.consecutiveFailures, equals(0));
    });

    test('detailedStatusText should handle checking status', () {
      expect(provider.detailedStatusText, equals('Checking connection...'));
    });

    test('detailedStatusText should handle disconnected status with no last connected time', () {
      final testProvider = _TestConnectivityProvider();
      testProvider.setTestConnectionStatus(ConnectionStatus.disconnected);
      expect(testProvider.detailedStatusText, equals('Offline'));
    });

    test('detailedStatusText should show time ago when connected', () {
      final testProvider = _TestConnectivityProvider();
      testProvider.setTestConnectionStatus(ConnectionStatus.connected);
      testProvider.setTestLastConnectedTime(DateTime.now().subtract(Duration(minutes: 5)));
      expect(testProvider.detailedStatusText, contains('Connected (5m ago)'));
    });

    test('detailedStatusText should show hours ago when connected', () {
      final testProvider = _TestConnectivityProvider();
      testProvider.setTestConnectionStatus(ConnectionStatus.connected);
      testProvider.setTestLastConnectedTime(DateTime.now().subtract(Duration(hours: 2)));
      expect(testProvider.detailedStatusText, contains('Connected (2h ago)'));
    });

    test('detailedStatusText should show just now when recently connected', () {
      final testProvider = _TestConnectivityProvider();
      testProvider.setTestConnectionStatus(ConnectionStatus.connected);
      testProvider.setTestLastConnectedTime(DateTime.now());
      expect(testProvider.detailedStatusText, contains('Connected (just now)'));
    });

    test('detailedStatusText should show offline with next check interval', () {
      final testProvider = _TestConnectivityProvider();
      testProvider.setTestConnectionStatus(ConnectionStatus.disconnected);
      testProvider.setTestConsecutiveFailures(2);
      testProvider.setTestCurrentInterval(Duration(seconds: 60));
      expect(testProvider.detailedStatusText, contains('Next check in 60s'));
    });

    test('dispose should clean up resources', () {
      expect(() => provider.dispose(), returnsNormally);
    });

    test('should notify listeners when connection status changes', () {
      final testProvider = _TestConnectivityProvider();
      int listenerCallCount = 0;
      testProvider.addListener(() {
        listenerCallCount++;
      });
      
      testProvider.setTestConnectionStatus(ConnectionStatus.connected);
      expect(listenerCallCount, equals(1));
      
      testProvider.setTestConnectionStatus(ConnectionStatus.disconnected);
      expect(listenerCallCount, equals(2));
      
      testProvider.setTestConnectionStatus(ConnectionStatus.disconnected);
      expect(listenerCallCount, equals(2));
    });
  });
}

class _MockApiService extends ApiService {
  @override
  String get baseUrl => 'http://localhost:8000';
}

class _TestConnectivityProvider extends ConnectivityProvider {
  ConnectionStatus? _testStatus;
  DateTime? _testLastConnectedTime;
  int _testConsecutiveFailures = 0;
  Duration _testCurrentInterval = Duration(seconds: 30);

  @override
  ConnectionStatus get connectionStatus => _testStatus ?? super.connectionStatus;
  
  @override
  DateTime? get lastConnectedTime => _testLastConnectedTime ?? super.lastConnectedTime;
  
  @override
  int get consecutiveFailures => _testConsecutiveFailures;
  
  @override
  Duration get currentCheckInterval => _testCurrentInterval;

  void setTestConnectionStatus(ConnectionStatus status) {
    _testStatus = status;
    notifyListeners();
  }
  
  void setTestLastConnectedTime(DateTime? time) {
    _testLastConnectedTime = time;
  }
  
  void setTestConsecutiveFailures(int failures) {
    _testConsecutiveFailures = failures;
  }
  
  void setTestCurrentInterval(Duration interval) {
    _testCurrentInterval = interval;
  }
}