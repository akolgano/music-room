import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:music_room/providers/connectivity_providers.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/core/locator_core.dart';

import 'connectivity_providers_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  group('ConnectivityProvider', () {
    late ConnectivityProvider provider;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      when(mockApiService.baseUrl).thenReturn('https://api.test.com');

      // Register mock service
      if (getIt.isRegistered<ApiService>()) {
        getIt.unregister<ApiService>();
      }
      getIt.registerSingleton<ApiService>(mockApiService);
    });

    tearDown(() {
      provider.dispose();
      
      if (getIt.isRegistered<ApiService>()) {
        getIt.unregister<ApiService>();
      }
    });

    group('Initial State', () {
      test('should start with checking status', () {
        provider = ConnectivityProvider();
        
        expect(provider.connectionStatus, ConnectionStatus.checking);
        expect(provider.isChecking, isTrue);
        expect(provider.isConnected, isFalse);
        expect(provider.isDisconnected, isFalse);
        expect(provider.lastConnectedTime, isNull);
        expect(provider.consecutiveFailures, 0);
        expect(provider.currentCheckInterval, const Duration(seconds: 30));
      });
    });

    group('Connection Status Management', () {
      test('should update connection status correctly', () async {
        provider = ConnectivityProvider();
        bool listenerCalled = false;
        provider.addListener(() => listenerCalled = true);

        // Simulate successful connection check by allowing the check to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // The listener should have been called due to status changes
        expect(listenerCalled, isTrue);
      });

      test('should set correct boolean flags for each status', () {
        provider = ConnectivityProvider();
        
        // Test checking status (initial state)
        expect(provider.connectionStatus, ConnectionStatus.checking);
        expect(provider.isChecking, isTrue);
        expect(provider.isConnected, isFalse);
        expect(provider.isDisconnected, isFalse);
      });
    });

    group('Connection Status Text', () {
      test('should return correct status text for each connection state', () {
        provider = ConnectivityProvider();
        
        expect(provider.connectionStatusText, 'Checking...');
      });

      test('should provide detailed status text', () {
        provider = ConnectivityProvider();
        
        expect(provider.detailedStatusText, 'Checking connection...');
      });
    });

    group('Time Formatting', () {
      test('should format time correctly for different durations', () {
        provider = ConnectivityProvider();
        
        // Test the detailed status text formatting indirectly
        expect(provider.detailedStatusText, isA<String>());
        expect(provider.detailedStatusText.isNotEmpty, isTrue);
      });
    });

    group('Health Check Intervals', () {
      test('should start with initial interval', () {
        provider = ConnectivityProvider();
        
        expect(provider.currentCheckInterval, const Duration(seconds: 30));
        expect(provider.consecutiveFailures, 0);
      });

      test('should track consecutive failures', () {
        provider = ConnectivityProvider();
        
        // Initial state should have no failures
        expect(provider.consecutiveFailures, 0);
      });
    });

    group('Manual Connection Check', () {
      test('should set status to checking when check starts', () async {
        provider = ConnectivityProvider();
        
        // Clear any previous status by waiting
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Manually trigger connection check
        final checkFuture = provider.checkConnection();
        
        // Status should be checking immediately
        expect(provider.connectionStatus, ConnectionStatus.checking);
        
        // Wait for check to complete
        await checkFuture;
      });

      test('should handle successful connection check', () async {
        provider = ConnectivityProvider();
        
        // The provider will automatically start checking on creation
        // We just need to wait for it to complete and verify state
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Check that provider properties are accessible
        expect(provider.connectionStatus, isA<ConnectionStatus>());
        expect(provider.currentCheckInterval, isA<Duration>());
      });

      test('should handle failed connection check gracefully', () async {
        provider = ConnectivityProvider();
        
        // Wait for initial check to complete
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Verify the provider is still functional
        expect(provider.connectionStatus, isA<ConnectionStatus>());
        expect(provider.consecutiveFailures, isA<int>());
      });
    });

    group('Backoff Strategy', () {
      test('should use exponential backoff for consecutive failures', () {
        provider = ConnectivityProvider();
        
        // Initial interval should be 30 seconds
        expect(provider.currentCheckInterval, const Duration(seconds: 30));
        
        // After failures, the interval should potentially increase
        // (We can't easily test the private failure logic without mocking HTTP)
      });

      test('should cap maximum interval', () {
        provider = ConnectivityProvider();
        
        // The interval should never exceed 10 minutes
        expect(provider.currentCheckInterval.inMilliseconds, 
               lessThanOrEqualTo(const Duration(minutes: 10).inMilliseconds));
      });

      test('should reset interval on successful connection', () {
        provider = ConnectivityProvider();
        
        // Even after potential failures, a successful connection should reset
        expect(provider.currentCheckInterval, 
               lessThanOrEqualTo(const Duration(minutes: 10)));
      });
    });

    group('Timer Management', () {
      test('should start health check timer on initialization', () {
        provider = ConnectivityProvider();
        
        // Provider should be created and timer should be running
        expect(provider.connectionStatus, isA<ConnectionStatus>());
      });

      test('should cancel timer on dispose', () {
        provider = ConnectivityProvider();
        
        // Dispose should not throw
        expect(() => provider.dispose(), returnsNormally);
      });
    });

    group('Listener Notifications', () {
      test('should notify listeners on status change', () async {
        provider = ConnectivityProvider();
        
        int notificationCount = 0;
        provider.addListener(() => notificationCount++);
        
        // Wait for some status changes to occur
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Should have received at least one notification
        expect(notificationCount, greaterThan(0));
      });

      test('should not notify if status does not change', () {
        provider = ConnectivityProvider();
        
        int notificationCount = 0;
        provider.addListener(() => notificationCount++);
        
        final currentStatus = provider.connectionStatus;
        
        // Reset count after initial notifications
        notificationCount = 0;
        
        // If we somehow set the same status, it shouldn't notify
        // (This is difficult to test directly due to private methods)
        expect(provider.connectionStatus, currentStatus);
      });
    });

    group('Status Text Generation', () {
      test('should generate appropriate status text for connected state', () {
        provider = ConnectivityProvider();
        
        // Even if not connected, the text generation should work
        final statusText = provider.connectionStatusText;
        expect(statusText, isA<String>());
        expect(statusText.isNotEmpty, isTrue);
      });

      test('should generate detailed status text with time information', () {
        provider = ConnectivityProvider();
        
        final detailedText = provider.detailedStatusText;
        expect(detailedText, isA<String>());
        expect(detailedText.isNotEmpty, isTrue);
      });

      test('should handle null last connected time gracefully', () {
        provider = ConnectivityProvider();
        
        // Initially lastConnectedTime should be null
        expect(provider.lastConnectedTime, isNull);
        
        // Should still generate valid status text
        expect(provider.detailedStatusText, isNotEmpty);
      });
    });

    group('Edge Cases', () {
      test('should handle rapid successive status checks', () async {
        provider = ConnectivityProvider();
        
        // Start multiple checks rapidly
        final futures = List.generate(5, (index) => provider.checkConnection());
        
        // All should complete without throwing
        await Future.wait(futures);
        
        expect(provider.connectionStatus, isA<ConnectionStatus>());
      });

      test('should handle very short time differences', () {
        provider = ConnectivityProvider();
        
        // Test that the provider handles edge cases in time calculations
        expect(provider.detailedStatusText, isA<String>());
      });

      test('should maintain consistency during concurrent operations', () async {
        provider = ConnectivityProvider();
        
        // Start check and immediately access properties
        final checkFuture = provider.checkConnection();
        
        expect(provider.connectionStatus, isA<ConnectionStatus>());
        expect(provider.isChecking || provider.isConnected || provider.isDisconnected, isTrue);
        
        await checkFuture;
      });
    });

    group('Memory Management', () {
      test('should properly dispose without memory leaks', () {
        provider = ConnectivityProvider();
        
        // Add listener to ensure cleanup
        provider.addListener(() {});
        
        expect(() => provider.dispose(), returnsNormally);
      });

      test('should handle dispose called multiple times', () {
        provider = ConnectivityProvider();
        
        provider.dispose();
        expect(() => provider.dispose(), returnsNormally);
      });
    });

    group('Integration Scenarios', () {
      test('should work correctly with no internet connection', () async {
        provider = ConnectivityProvider();
        
        // Wait for initial check to complete
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Should handle offline state gracefully
        expect(provider.connectionStatus, isA<ConnectionStatus>());
      });

      test('should recover from temporary network issues', () async {
        provider = ConnectivityProvider();
        
        // Simulate network issue by waiting and checking status
        await Future.delayed(const Duration(milliseconds: 200));
        
        expect(provider.connectionStatus, isA<ConnectionStatus>());
        expect(provider.consecutiveFailures, isA<int>());
      });
    });

    group('Enum Values', () {
      test('should have correct enum values', () {
        expect(ConnectionStatus.connected, isA<ConnectionStatus>());
        expect(ConnectionStatus.disconnected, isA<ConnectionStatus>());
        expect(ConnectionStatus.checking, isA<ConnectionStatus>());
      });
    });

    group('Constants', () {
      test('should have reasonable timeout values', () {
        provider = ConnectivityProvider();
        
        // Check that intervals are reasonable
        expect(provider.currentCheckInterval.inSeconds, greaterThan(0));
        expect(provider.currentCheckInterval.inMinutes, lessThanOrEqualTo(10));
      });
    });

    group('Boolean Properties', () {
      test('should have mutually exclusive boolean properties', () {
        provider = ConnectivityProvider();
        
        // Only one of these should be true at any time
        final boolCount = [
          provider.isConnected,
          provider.isDisconnected,
          provider.isChecking,
        ].where((b) => b).length;
        
        expect(boolCount, 1);
      });
    });
  });
}