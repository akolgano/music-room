import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:music_room/screens/base_screens.dart';
import 'package:music_room/providers/auth_providers.dart';
import 'package:music_room/providers/music_providers.dart';
import 'package:music_room/core/locator_core.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';

@GenerateMocks([AuthProvider, MusicProvider])
import 'base_screens_test.mocks.dart';

void main() {
  group('BaseScreen Tests', () {
    late MockAuthProvider mockAuthProvider;
    late MockMusicProvider mockMusicProvider;

    setUp(() {
      GetIt.instance.reset();
      mockAuthProvider = MockAuthProvider();
      mockMusicProvider = MockMusicProvider();
      
      getIt.registerSingleton<AuthProvider>(mockAuthProvider);
      getIt.registerSingleton<MusicProvider>(mockMusicProvider);
      
      when(mockAuthProvider.isLoggedIn).thenReturn(true);
      when(mockAuthProvider.currentUser).thenReturn(null);
      when(mockMusicProvider.isPlaying).thenReturn(false);
      when(mockMusicProvider.currentTrack).thenReturn(null);
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    testWidgets('should render main navigation structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should show home tab by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('should navigate between tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      
      expect(find.text('Search'), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.library_music));
      await tester.pumpAndSettle();
      
      expect(find.text('Library'), findsOneWidget);
    });

    testWidgets('should show profile tab when authenticated', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('should show music player when track is playing', (WidgetTester tester) async {
      when(mockMusicProvider.isPlaying).thenReturn(true);
      when(mockMusicProvider.currentTrack).thenReturn(MockTrack());
      
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      expect(find.byType(MiniPlayer), findsOneWidget);
    });

    testWidgets('should hide music player when no track is playing', (WidgetTester tester) async {
      when(mockMusicProvider.isPlaying).thenReturn(false);
      when(mockMusicProvider.currentTrack).thenReturn(null);
      
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      expect(find.byType(MiniPlayer), findsNothing);
    });

    testWidgets('should handle back button navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      
      expect(find.text('Search'), findsOneWidget);
      
      final bool result = await tester.binding.defaultBinaryMessenger
          .handlePlatformMessage('flutter/platform', null, (data) {});
      
      expect(result, isNull);
    });

    testWidgets('should show logout option in app drawer', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      
      expect(find.text('Logout'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('should handle logout action', (WidgetTester tester) async {
      when(mockAuthProvider.logout()).thenAnswer((_) async => true);
      
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      
      verify(mockAuthProvider.logout()).called(1);
    });

    testWidgets('should show correct tab icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.library_music), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should show correct tab labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      final bottomNavBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      
      expect(bottomNavBar.items[0].label, 'Home');
      expect(bottomNavBar.items[1].label, 'Search');
      expect(bottomNavBar.items[2].label, 'Library');
      expect(bottomNavBar.items[3].label, 'Profile');
    });

    testWidgets('should maintain selected tab state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      
      final bottomNavBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNavBar.currentIndex, 1);
    });

    testWidgets('should handle tab selection changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.library_music));
      await tester.pumpAndSettle();
      
      expect(find.text('Library'), findsOneWidget);
    });

    testWidgets('should show app bar with correct title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      expect(find.text('Music Room'), findsOneWidget);
    });

    testWidgets('should handle user avatar in app bar', (WidgetTester tester) async {
      when(mockAuthProvider.currentUser).thenReturn(MockUser());
      
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('should show notification icon in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('should handle notification tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();
      
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('should show proper theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNotNull);
    });

    testWidgets('should handle screen size adaptations', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800, 600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    });

    testWidgets('should show loading state when appropriate', (WidgetTester tester) async {
      when(mockAuthProvider.isLoading).thenReturn(true);
      
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle deep linking navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(initialIndex: 2),
          ),
        ),
      );

      final bottomNavBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNavBar.currentIndex, 2);
      expect(find.text('Library'), findsOneWidget);
    });

    testWidgets('should preserve state across tab switches', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();
      
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('should show floating action button when appropriate', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ],
            child: const BaseScreen(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.library_music));
      await tester.pumpAndSettle();
      
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}

class MockTrack extends Mock {
  @override
  String get title => 'Test Track';
  
  @override
  String get artist => 'Test Artist';
}

class MockUser extends Mock {
  @override
  String get username => 'testuser';
  
  @override
  String? get profilePicture => 'https://example.com/avatar.jpg';
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.grey,
      child: const Text('Mini Player'),
    );
  }
}
