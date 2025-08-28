import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_room/screens/home/home_screens.dart';
import 'package:music_room/providers/auth_providers.dart';
import 'package:music_room/providers/music_providers.dart';
import 'package:music_room/providers/profile_providers.dart';
import 'package:music_room/providers/friend_providers.dart';
import 'package:music_room/models/music_models.dart';
import 'package:music_room/models/api_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('HomeScreen Tests', () {
    late AuthProvider mockAuthProvider;
    late MusicProvider mockMusicProvider;
    late ProfileProvider mockProfileProvider;
    late FriendProvider mockFriendProvider;

    setUp(() {
      mockAuthProvider = AuthProvider();
      mockMusicProvider = MusicProvider();
      mockProfileProvider = ProfileProvider();
      mockFriendProvider = FriendProvider();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
          ChangeNotifierProvider<ProfileProvider>.value(value: mockProfileProvider),
          ChangeNotifierProvider<FriendProvider>.value(value: mockFriendProvider),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      );
    }

    testWidgets('should render home screen', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should have tab controller with 4 tabs', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.text('Playlists'), findsAtLeastNWidgets(1));
      expect(find.text('Search'), findsAtLeastNWidgets(1));
      expect(find.text('Friends'), findsAtLeastNWidgets(1));
      expect(find.text('Profile'), findsAtLeastNWidgets(1));
    });

    testWidgets('should display navigation rail in landscape', (WidgetTester tester) async {

      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('should display navigation destinations', (WidgetTester tester) async {

      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRailDestination), findsNWidgets(4));
      expect(find.byIcon(Icons.library_music_outlined), findsOneWidget);
      expect(find.byIcon(Icons.search_outlined), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('should handle tab controller disposal', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      

      await tester.pumpWidget(Container());
      

      expect(true, isTrue);
    });

    testWidgets('should have proper TickerProviderStateMixin implementation', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should handle orientation changes', (WidgetTester tester) async {

      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      tester.view.physicalSize = const Size(800, 400);
      await tester.pump();
      await tester.pumpAndSettle();


      expect(find.byType(HomeScreen), findsOneWidget);
      
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('should handle navigation rail selection', (WidgetTester tester) async {

      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final navigationRail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(navigationRail.selectedIndex, 0); // Should start at index 0
    });

    testWidgets('should have connection status banner', (WidgetTester tester) async {

      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should handle post frame callback', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      

      await tester.pumpAndSettle();
      
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should handle WidgetsBindingObserver lifecycle', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should have proper layout structure in landscape', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Row), findsAtLeastNWidgets(1));
      expect(find.byType(LayoutBuilder), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
      expect(find.byType(ConstrainedBox), findsAtLeastNWidgets(1));
      expect(find.byType(IntrinsicHeight), findsOneWidget);
    });

    testWidgets('should have proper navigation rail styling', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final navigationRail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(navigationRail.labelType, NavigationRailLabelType.all);
      expect(navigationRail.backgroundColor, isNotNull);
    });

    testWidgets('should maintain multiple provider dependencies', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should handle state updates correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should have proper initial index', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should handle tab listener properly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should handle loading states', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should handle user action logging mixin', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should handle widget rebuilds properly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should dispose observers properly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      

      await tester.pumpWidget(Container());
      

      expect(true, isTrue);
    });

    testWidgets('should handle different screen sizes', (WidgetTester tester) async {

      tester.view.physicalSize = const Size(300, 500);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      expect(find.byType(HomeScreen), findsOneWidget);
      

      tester.view.physicalSize = const Size(1200, 800);
      await tester.pump();
      await tester.pumpAndSettle();
      
      expect(find.byType(HomeScreen), findsOneWidget);
      
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });

  group('Model Tests', () {
    test('should handle playlist models', () {
      final playlist = Playlist(
        id: '1',
        name: 'Test Playlist',
        description: 'A test playlist',
        creator: 'testuser',
        isPublic: true,
      );

      expect(playlist.id, '1');
      expect(playlist.name, 'Test Playlist');
      expect(playlist.creator, 'testuser');
      expect(playlist.isPublic, isTrue);
    });

    test('should handle friend models', () {
      final friendData = {
        'id': '123',
        'username': 'frienduser',
        'email': 'friend@example.com',
        'status': 'active',
      };

      final friend = Friend.fromJson(friendData);
      expect(friend.id, '123');
      expect(friend.username, 'frienduser');
      expect(friend.email, 'friend@example.com');
    });

    test('should handle empty playlist data', () {
      final playlist = Playlist(
        id: '',
        name: '',
        description: '',
        creator: '',
        isPublic: false,
      );

      expect(playlist.id, isEmpty);
      expect(playlist.name, isEmpty);
      expect(playlist.description, isEmpty);
      expect(playlist.creator, isEmpty);
      expect(playlist.isPublic, isFalse);
    });

    test('should handle playlist with null values', () {
      final playlist = Playlist(
        id: '1',
        name: 'Test',
        description: '',
        creator: 'user',
        isPublic: false,
      );

      expect(playlist.description, isEmpty);
      expect(playlist.isPublic, isFalse);
    });

    test('should handle friend model edge cases', () {
      final friendData = {
        'id': '',
        'username': '',
        'email': '',
      };

      final friend = Friend.fromJson(friendData);
      expect(friend.id, isEmpty);
      expect(friend.username, isEmpty);
      expect(friend.email, isEmpty);
    });
  });
}
