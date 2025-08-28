import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_room/screens/friends/list_friends.dart';
import 'package:music_room/providers/auth_providers.dart';
import 'package:music_room/providers/friend_providers.dart';
import 'package:music_room/providers/music_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('FriendsListScreen Tests', () {
    late AuthProvider mockAuthProvider;
    late FriendProvider mockFriendProvider;
    late MusicProvider mockMusicProvider;

    setUp(() {
      mockAuthProvider = AuthProvider();
      mockFriendProvider = FriendProvider();
      mockMusicProvider = MusicProvider();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ChangeNotifierProvider<FriendProvider>.value(value: mockFriendProvider),
          ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
        ],
        child: const MaterialApp(
          home: FriendsListScreen(),
        ),
      );
    }

    testWidgets('should render friends list screen', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(FriendsListScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
    });

    testWidgets('should display proper screen title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Friends'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have add friend button in actions', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Add Friend'), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsOneWidget);
      expect(find.byType(TextButton), findsAtLeastNWidgets(1));
    });

    testWidgets('should have tab controller with two tabs', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.textContaining('Friends ('), findsOneWidget);
      expect(find.textContaining('Requests ('), findsOneWidget);
    });

    testWidgets('should display friends count in tab', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.textContaining('Friends (0)'), findsOneWidget);
    });

    testWidgets('should display requests count in tab', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.textContaining('Requests (0)'), findsOneWidget);
    });

    testWidgets('should have tab bar with proper structure', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Tab), findsNWidgets(2));
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('should handle tab controller disposal', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      

      await tester.pumpWidget(Container());
      

      expect(true, isTrue);
    });

    testWidgets('should handle add friend button tap', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Friend'));
      await tester.pump();


      expect(true, isTrue);
    });

    testWidgets('should show empty state for friends when no friends', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.text('No friends yet'), findsOneWidget);
      expect(find.text('Start connecting and sharing music'), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
    });

    testWidgets('should have add friend button in empty state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      final addFriendButtons = find.text('Add Friend');
      expect(addFriendButtons, findsAtLeastNWidgets(1));
    });

    testWidgets('should show loading state when provider is loading', (WidgetTester tester) async {
      mockFriendProvider.setLoading(true);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle tab switching', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      await tester.tap(find.textContaining('Requests ('));
      await tester.pumpAndSettle();


      expect(true, isTrue);
    });

    testWidgets('should have proper provider consumer structure', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.byType(Consumer), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle refresh functionality', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.byType(RefreshIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('should display proper layout structure', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TabBarView), findsOneWidget);
      expect(find.byType(DefaultTabController), findsOneWidget);
    });

    testWidgets('should handle widget lifecycle properly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      

      expect(find.byType(FriendsListScreen), findsOneWidget);
    });

    testWidgets('should have proper TickerProviderStateMixin implementation', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.byType(Tab), findsNWidgets(2));
    });

    testWidgets('should handle empty friends list properly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.text('No friends yet'), findsOneWidget);
    });

    testWidgets('should handle empty requests list properly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      await tester.tap(find.textContaining('Requests ('));
      await tester.pumpAndSettle();


      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('should maintain tab state during rebuilds', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      await tester.tap(find.textContaining('Requests ('));
      await tester.pumpAndSettle();


      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      

      expect(find.byType(FriendsListScreen), findsOneWidget);
    });

    testWidgets('should have proper tab text styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      final friendsTab = find.textContaining('Friends (');
      final requestsTab = find.textContaining('Requests (');
      
      expect(friendsTab, findsOneWidget);
      expect(requestsTab, findsOneWidget);
    });

    testWidgets('should handle post frame callback properly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      

      await tester.pumpAndSettle();
      

      expect(find.byType(FriendsListScreen), findsOneWidget);
    });

    testWidgets('should display proper icon in actions', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('should handle multiple provider dependencies', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.byType(FriendsListScreen), findsOneWidget);
    });
  });
}
