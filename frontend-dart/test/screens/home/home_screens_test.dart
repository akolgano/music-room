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

class MockAuthProvider extends AuthProvider {
  bool _isLoggedIn = true;
  String? _token = 'mock_token';
  final String _username = 'testuser';

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  String? get token => _token;

  @override
  String? get username => _username;

  void setLoggedIn(bool loggedIn) {
    _isLoggedIn = loggedIn;
    notifyListeners();
  }

  void setToken(String? token) {
    _token = token;
    notifyListeners();
  }
}

class MockMusicProvider extends MusicProvider {
  List<Playlist> _playlists = [];
  bool _isLoading = false;

  @override
  List<Playlist> get playlists => _playlists;

  @override
  List<Playlist> get userPlaylists => _playlists.where((p) => !p.isPublic).toList();

  @override
  List<Playlist> get publicPlaylists => _playlists.where((p) => p.isPublic).toList();

  @override
  bool get isLoading => _isLoading;

  void setPlaylists(List<Playlist> playlists) {
    _playlists = playlists;
    notifyListeners();
  }

  @override
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  Future<void> fetchAllPlaylists(String token) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 100));
    _isLoading = false;
    notifyListeners();
  }
}

class MockProfileProvider extends ProfileProvider {
  String? _name = 'Test User';
  final String _email = 'test@example.com';
  bool _isLoading = false;

  @override
  String? get name => _name;

  String? get email => _email;

  @override
  bool get isLoading => _isLoading;

  void setName(String? name) {
    _name = name;
    notifyListeners();
  }

  @override
  Future<bool> loadProfile(String? token) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 50));
    _isLoading = false;
    notifyListeners();
    return true;
  }
}

class MockFriendProvider extends FriendProvider {
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = false;

  @override
  List<Friend> get friends => _friends.map((f) => Friend.fromJson(f)).toList();

  @override
  bool get isLoading => _isLoading;

  void setFriends(List<Map<String, dynamic>> friends) {
    _friends = friends;
    notifyListeners();
  }

  Future<void> loadFriends(String token) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 50));
    _isLoading = false;
    notifyListeners();
  }
}

void main() {
  group('HomeScreen', () {
    late MockAuthProvider mockAuthProvider;
    late MockMusicProvider mockMusicProvider;
    late MockProfileProvider mockProfileProvider;
    late MockFriendProvider mockFriendProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockMusicProvider = MockMusicProvider();
      mockProfileProvider = MockProfileProvider();
      mockFriendProvider = MockFriendProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ChangeNotifierProvider<ProfileProvider>.value(value: mockProfileProvider),
            ChangeNotifierProvider<FriendProvider>.value(value: mockFriendProvider),
          ],
          child: const HomeScreen(),
        ),
      );
    }

    testWidgets('should render home screen with tab bar when logged in', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('should show 4 tabs in correct order', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Playlists'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      expect(find.byIcon(Icons.queue_music), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
      expect(find.byIcon(Icons.account_circle), findsOneWidget);
    });

    testWidgets('should start with Playlists tab selected', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final tabBar = find.byType(TabBar);
      expect(tabBar, findsOneWidget);

      final TabBar tabBarWidget = tester.widget(tabBar);
      final TabController? controller = tabBarWidget.controller;
      expect(controller?.index, equals(0));
    });

    testWidgets('should switch tabs when tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      final tabBar = find.byType(TabBar);
      final TabBar tabBarWidget = tester.widget(tabBar);
      final TabController? controller = tabBarWidget.controller;
      expect(controller?.index, equals(1));

      await tester.tap(find.text('Friends'));
      await tester.pumpAndSettle();

      expect(controller?.index, equals(2));

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(controller?.index, equals(3));
    });

    testWidgets('should load data when initialized', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should show welcome message with username', (tester) async {
      mockAuthProvider.setToken('valid_token');
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Welcome back, testuser'), findsOneWidget);
    });

    testWidgets('should handle logged out state', (tester) async {
      mockAuthProvider.setLoggedIn(false);
      mockAuthProvider.setToken(null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should show playlists in first tab', (tester) async {
      final testPlaylists = [
        Playlist(
          id: '1',
          name: 'Test Playlist 1',
          description: 'Description 1',
          creator: 'User 1',
          isPublic: true,
        ),
        Playlist(
          id: '2',
          name: 'Test Playlist 2',
          description: 'Description 2',
          creator: 'User 2',
          isPublic: false,
        ),
      ];

      mockMusicProvider.setPlaylists(testPlaylists);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Test Playlist 1'), findsOneWidget);
      expect(find.text('Test Playlist 2'), findsOneWidget);
    });

    testWidgets('should show loading state initially', (tester) async {
      mockMusicProvider.setLoading(true);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle empty playlists state', (tester) async {
      mockMusicProvider.setPlaylists([]);
      mockMusicProvider.setLoading(false);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should dispose properly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    });

    group('Responsive behavior', () {
      testWidgets('should handle portrait orientation', (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 800));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(TabBar), findsOneWidget);
      });

      testWidgets('should handle landscape orientation', (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 400));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(TabBar), findsOneWidget);
      });

      testWidgets('should handle small screen size', (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 568));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
      });
    });

    group('Tab content', () {
      testWidgets('should show search content in search tab', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Search'));
        await tester.pumpAndSettle();

        final tabBar = find.byType(TabBar);
        final TabBar tabBarWidget = tester.widget(tabBar);
        expect(tabBarWidget.controller?.index, equals(1));
      });

      testWidgets('should show friends content in friends tab', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Friends'));
        await tester.pumpAndSettle();

        final tabBar = find.byType(TabBar);
        final TabBar tabBarWidget = tester.widget(tabBar);
        expect(tabBarWidget.controller?.index, equals(2));
      });

      testWidgets('should show profile content in profile tab', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        final tabBar = find.byType(TabBar);
        final TabBar tabBarWidget = tester.widget(tabBar);
        expect(tabBarWidget.controller?.index, equals(3));
      });
    });
  });
}