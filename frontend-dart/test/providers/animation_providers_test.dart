import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/core/animations_core.dart';

void main() {
  group('AnimationSettingsProvider', () {
    late AnimationSettingsProvider provider;

    setUp(() {
      provider = AnimationSettingsProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    group('Initial State', () {
      test('should have correct default values', () {
        expect(provider.pulsingEnabled, isTrue);
        expect(provider.pulsingDuration, const Duration(seconds: 2));
        expect(provider.pulsingIntensity, 1.0);
      });
    });

    group('Pulsing Enabled', () {
      test('should update pulsing enabled state', () {
        bool notified = false;
        provider.addListener(() => notified = true);

        provider.setPulsingEnabled(false);

        expect(provider.pulsingEnabled, isFalse);
        expect(notified, isTrue);
      });

      test('should not notify if setting same value', () {
        bool notified = false;
        provider.addListener(() => notified = true);

        provider.setPulsingEnabled(true); // Same as default

        expect(provider.pulsingEnabled, isTrue);
        expect(notified, isFalse);
      });

      test('should toggle pulsing enabled state', () {
        expect(provider.pulsingEnabled, isTrue);

        provider.setPulsingEnabled(false);
        expect(provider.pulsingEnabled, isFalse);

        provider.setPulsingEnabled(true);
        expect(provider.pulsingEnabled, isTrue);
      });
    });

    group('Pulsing Duration', () {
      test('should update pulsing duration', () {
        const newDuration = Duration(seconds: 3);
        bool notified = false;
        provider.addListener(() => notified = true);

        provider.setPulsingDuration(newDuration);

        expect(provider.pulsingDuration, newDuration);
        expect(notified, isTrue);
      });

      test('should not notify if setting same duration', () {
        const defaultDuration = Duration(seconds: 2);
        bool notified = false;
        provider.addListener(() => notified = true);

        provider.setPulsingDuration(defaultDuration); // Same as default

        expect(provider.pulsingDuration, defaultDuration);
        expect(notified, isFalse);
      });

      test('should handle different duration values', () {
        const fastDuration = Duration(milliseconds: 500);
        const slowDuration = Duration(seconds: 5);

        provider.setPulsingDuration(fastDuration);
        expect(provider.pulsingDuration, fastDuration);

        provider.setPulsingDuration(slowDuration);
        expect(provider.pulsingDuration, slowDuration);
      });
    });

    group('Pulsing Intensity', () {
      test('should update pulsing intensity', () {
        const newIntensity = 2.0;
        bool notified = false;
        provider.addListener(() => notified = true);

        provider.setPulsingIntensity(newIntensity);

        expect(provider.pulsingIntensity, newIntensity);
        expect(notified, isTrue);
      });

      test('should not notify if setting same intensity', () {
        const defaultIntensity = 1.0;
        bool notified = false;
        provider.addListener(() => notified = true);

        provider.setPulsingIntensity(defaultIntensity); // Same as default

        expect(provider.pulsingIntensity, defaultIntensity);
        expect(notified, isFalse);
      });

      test('should clamp intensity to valid range', () {
        // Test minimum clamp
        provider.setPulsingIntensity(0.05); // Below minimum
        expect(provider.pulsingIntensity, 0.1);

        // Test maximum clamp
        provider.setPulsingIntensity(5.0); // Above maximum
        expect(provider.pulsingIntensity, 3.0);
      });

      test('should handle edge case intensity values', () {
        // Test exact minimum
        provider.setPulsingIntensity(0.1);
        expect(provider.pulsingIntensity, 0.1);

        // Test exact maximum
        provider.setPulsingIntensity(3.0);
        expect(provider.pulsingIntensity, 3.0);

        // Test valid middle value
        provider.setPulsingIntensity(1.5);
        expect(provider.pulsingIntensity, 1.5);
      });

      test('should handle negative intensity values', () {
        provider.setPulsingIntensity(-1.0);
        expect(provider.pulsingIntensity, 0.1); // Clamped to minimum
      });

      test('should handle zero intensity', () {
        provider.setPulsingIntensity(0.0);
        expect(provider.pulsingIntensity, 0.1); // Clamped to minimum
      });
    });

    group('Listener Notifications', () {
      test('should notify listeners when pulsing enabled changes', () {
        int notificationCount = 0;
        provider.addListener(() => notificationCount++);

        provider.setPulsingEnabled(false);
        provider.setPulsingEnabled(true);
        provider.setPulsingEnabled(false);

        expect(notificationCount, 3);
      });

      test('should notify listeners when duration changes', () {
        int notificationCount = 0;
        provider.addListener(() => notificationCount++);

        provider.setPulsingDuration(const Duration(seconds: 1));
        provider.setPulsingDuration(const Duration(seconds: 3));
        provider.setPulsingDuration(const Duration(milliseconds: 500));

        expect(notificationCount, 3);
      });

      test('should notify listeners when intensity changes', () {
        int notificationCount = 0;
        provider.addListener(() => notificationCount++);

        provider.setPulsingIntensity(0.5);
        provider.setPulsingIntensity(2.0);
        provider.setPulsingIntensity(1.5);

        expect(notificationCount, 3);
      });

      test('should not notify when setting identical values', () {
        int notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Set to same values multiple times
        provider.setPulsingEnabled(true);
        provider.setPulsingDuration(const Duration(seconds: 2));
        provider.setPulsingIntensity(1.0);

        expect(notificationCount, 0);
      });
    });

    group('Multiple Listeners', () {
      test('should notify all listeners', () {
        bool listener1Notified = false;
        bool listener2Notified = false;
        bool listener3Notified = false;

        provider.addListener(() => listener1Notified = true);
        provider.addListener(() => listener2Notified = true);
        provider.addListener(() => listener3Notified = true);

        provider.setPulsingEnabled(false);

        expect(listener1Notified, isTrue);
        expect(listener2Notified, isTrue);
        expect(listener3Notified, isTrue);
      });

      test('should handle listener removal', () {
        bool listener1Notified = false;
        bool listener2Notified = false;

        void listener1() => listener1Notified = true;
        void listener2() => listener2Notified = true;

        provider.addListener(listener1);
        provider.addListener(listener2);

        // Remove first listener
        provider.removeListener(listener1);

        provider.setPulsingEnabled(false);

        expect(listener1Notified, isFalse);
        expect(listener2Notified, isTrue);
      });
    });

    group('State Combinations', () {
      test('should handle multiple property changes in sequence', () {
        int notificationCount = 0;
        provider.addListener(() => notificationCount++);

        provider.setPulsingEnabled(false);
        provider.setPulsingDuration(const Duration(seconds: 1));
        provider.setPulsingIntensity(2.5);
        provider.setPulsingEnabled(true);

        expect(provider.pulsingEnabled, isTrue);
        expect(provider.pulsingDuration, const Duration(seconds: 1));
        expect(provider.pulsingIntensity, 2.5);
        expect(notificationCount, 4);
      });

      test('should maintain state consistency', () {
        provider.setPulsingEnabled(false);
        provider.setPulsingDuration(const Duration(milliseconds: 100));
        provider.setPulsingIntensity(0.2);

        expect(provider.pulsingEnabled, isFalse);
        expect(provider.pulsingDuration, const Duration(milliseconds: 100));
        expect(provider.pulsingIntensity, 0.2);
      });
    });

    group('Edge Cases', () {
      test('should handle extremely short durations', () {
        const veryShortDuration = Duration(microseconds: 1);
        provider.setPulsingDuration(veryShortDuration);
        expect(provider.pulsingDuration, veryShortDuration);
      });

      test('should handle extremely long durations', () {
        const veryLongDuration = Duration(hours: 24);
        provider.setPulsingDuration(veryLongDuration);
        expect(provider.pulsingDuration, veryLongDuration);
      });

      test('should handle rapid successive changes', () {
        int finalNotificationCount = 0;
        provider.addListener(() => finalNotificationCount++);

        // Rapid changes
        for (int i = 0; i < 100; i++) {
          provider.setPulsingIntensity(i % 3 == 0 ? 1.0 : 2.0);
        }

        expect(finalNotificationCount, greaterThan(0));
        expect(provider.pulsingIntensity, anyOf(1.0, 2.0));
      });
    });

    group('Dispose', () {
      test('should dispose without throwing', () {
        expect(() => provider.dispose(), returnsNormally);
      });

      test('should not notify listeners after dispose', () {
        bool notified = false;
        provider.addListener(() => notified = true);

        provider.dispose();

        // This should not throw or notify
        expect(() => provider.setPulsingEnabled(false), returnsNormally);
        expect(notified, isFalse);
      });
    });
  });
}