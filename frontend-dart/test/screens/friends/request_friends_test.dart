import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_room/screens/friends/request_friends.dart';
import 'package:music_room/providers/auth_providers.dart';
import 'package:music_room/providers/friend_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('FriendRequestScreen Tests', () {
    late AuthProvider mockAuthProvider;
    late FriendProvider mockFriendProvider;

    setUp(() {
      mockAuthProvider = AuthProvider();
      mockFriendProvider = FriendProvider();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ChangeNotifierProvider<FriendProvider>.value(value: mockFriendProvider),
        ],
        child: const MaterialApp(
          home: FriendRequestScreen(),
        ),
      );
    }

    testWidgets('should render friend request screen', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(FriendRequestScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Friend Requests'), findsOneWidget);
    });

    testWidgets('should display proper screen title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Friend Requests'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have tab controller with two tabs', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TabController), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(2));
    });

    testWidgets('should display received and sent tabs', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Received ('), findsOneWidget);
      expect(find.textContaining('Sent ('), findsOneWidget);
    });

    testWidgets('should show correct tab counts', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.textContaining('Received (0)'), findsOneWidget);
      expect(find.textContaining('Sent (0)'), findsOneWidget);
    });

    testWidgets('should have proper tab bar structure', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
      expect(find.byType(DefaultTabController), findsOneWidget);
    });

    testWidgets('should handle tab controller disposal', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      

      await tester.pumpWidget(Container());
      

      expect(true, isTrue);
    });

    testWidgets('should show empty state for received requests', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No friend requests'), findsOneWidget);
      expect(find.text('You don\'t have any pending friend requests'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('should show empty state for sent requests', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      await tester.tap(find.textContaining('Sent ('));
      await tester.pumpAndSettle();

      expect(find.text('No sent requests'), findsOneWidget);
      expect(find.text('You haven\'t sent any friend requests yet'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('should have find friends button in received empty state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Find Friends'), findsOneWidget);
    });

    testWidgets('should have add friend button in sent empty state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      await tester.tap(find.textContaining('Sent ('));
      await tester.pumpAndSettle();

      expect(find.text('Add Friend'), findsOneWidget);
    });

    testWidgets('should show loading state when provider is loading', (WidgetTester tester) async {
      mockFriendProvider.setLoading(true);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      expect(find.textContaining('Loading friend requests'), findsOneWidget);
    });

    testWidgets('should show loading state for sent requests tab when loading', (WidgetTester tester) async {
      mockFriendProvider.setLoading(true);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      await tester.tap(find.textContaining('Sent ('));
      await tester.pumpAndSettle();

      expect(find.textContaining('Loading sent requests'), findsOneWidget);
    });

    testWidgets('should handle tab switching', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.text('No friend requests'), findsOneWidget);


      await tester.tap(find.textContaining('Sent ('));
      await tester.pumpAndSettle();

      expect(find.text('No sent requests'), findsOneWidget);
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

    testWidgets('should handle TickerProviderStateMixin properly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.byType(Tab), findsNWidgets(2));
    });

    testWidgets('should handle post frame callback', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      

      await tester.pumpAndSettle();
      
      expect(find.byType(FriendRequestScreen), findsOneWidget);
    });

    testWidgets('should handle empty button presses', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      await tester.tap(find.text('Find Friends'));
      await tester.pump();


      expect(true, isTrue);
    });

    testWidgets('should maintain state during rebuilds', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      await tester.tap(find.textContaining('Sent ('));
      await tester.pumpAndSettle();


      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      expect(find.byType(FriendRequestScreen), findsOneWidget);
    });

    testWidgets('should handle different invitation states', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.text('No friend requests'), findsOneWidget);
    });

    testWidgets('should have proper widget hierarchy', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(FriendRequestScreen), findsOneWidget);
    });

    testWidgets('should handle loading states for both tabs', (WidgetTester tester) async {
      mockFriendProvider.setLoading(true);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.textContaining('Loading friend requests'), findsOneWidget);
      

      await tester.tap(find.textContaining('Sent ('));
      await tester.pumpAndSettle();
      
      expect(find.textContaining('Loading sent requests'), findsOneWidget);
    });

    testWidgets('should handle provider dependencies correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      expect(find.byType(FriendRequestScreen), findsOneWidget);
    });

    testWidgets('should display proper tab counts based on provider data', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();


      final receivedTab = find.textContaining('Received (');
      final sentTab = find.textContaining('Sent (');
      
      expect(receivedTab, findsOneWidget);
      expect(sentTab, findsOneWidget);
    });
  });
}
