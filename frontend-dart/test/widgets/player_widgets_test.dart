import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_room/widgets/player_widgets.dart';
import 'package:music_room/models/music_models.dart';

class MockMusicPlayerService extends ChangeNotifier {
  Track? _currentTrack;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(minutes: 3);
  bool _hasNextTrack = false;
  bool _hasPreviousTrack = false;
  bool _hasPlaylist = false;
  double _playbackSpeed = 1.0;
  bool _isUsingFullAudio = false;
  final String _currentTrackInfo = '1/10';

  Track? get currentTrack => _currentTrack;

  bool get isPlaying => _isPlaying;

  Duration get position => _position;

  Duration get duration => _duration;

  bool get hasNextTrack => _hasNextTrack;

  bool get hasPreviousTrack => _hasPreviousTrack;

  bool get hasPlaylist => _hasPlaylist;

  double get playbackSpeed => _playbackSpeed;

  bool get isUsingFullAudio => _isUsingFullAudio;

  String get currentTrackInfo => _currentTrackInfo;

  void setCurrentTrack(Track? track) {
    _currentTrack = track;
    notifyListeners();
  }

  void setIsPlaying(bool playing) {
    _isPlaying = playing;
    notifyListeners();
  }

  void setPosition(Duration position) {
    _position = position;
    notifyListeners();
  }

  void setDuration(Duration duration) {
    _duration = duration;
    notifyListeners();
  }

  void setHasNextTrack(bool hasNext) {
    _hasNextTrack = hasNext;
    notifyListeners();
  }

  void setHasPreviousTrack(bool hasPrevious) {
    _hasPreviousTrack = hasPrevious;
    notifyListeners();
  }

  void setHasPlaylist(bool hasPlaylist) {
    _hasPlaylist = hasPlaylist;
    notifyListeners();
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    notifyListeners();
  }

  void setIsUsingFullAudio(bool isUsingFullAudio) {
    _isUsingFullAudio = isUsingFullAudio;
    notifyListeners();
  }

  Future<void> togglePlay() async {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  Future<void> playNext() async {
  }

  Future<void> playPrevious() async {
  }

  Future<void> stop() async {
    _isPlaying = false;
    _currentTrack = null;
    _position = Duration.zero;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    _position = position;
    notifyListeners();
  }
}

void main() {
  group('MiniPlayerWidget', () {
    late MockMusicPlayerService mockPlayerService;

    setUp(() {
      mockPlayerService = MockMusicPlayerService();
    });

    Widget createTestWidget({Widget? child}) {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<MockMusicPlayerService>.value(
            value: mockPlayerService,
            child: child ?? const MiniPlayerWidget(),
          ),
        ),
      );
    }

    testWidgets('should show nothing when no current track', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      expect(find.byType(MiniPlayerWidget), findsOneWidget);
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('should display current track information', (tester) async {
      final testTrack = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://example.com/track.mp3',
        imageUrl: 'https://example.com/image.jpg',
      );

      mockPlayerService.setCurrentTrack(testTrack);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Test Song'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);
    });

    testWidgets('should show play button when not playing', (tester) async {
      final testTrack = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://example.com/track.mp3',
      );

      mockPlayerService.setCurrentTrack(testTrack);
      mockPlayerService.setIsPlaying(false);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('should show pause button when playing', (tester) async {
      final testTrack = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://example.com/track.mp3',
      );

      mockPlayerService.setCurrentTrack(testTrack);
      mockPlayerService.setIsPlaying(true);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('should toggle play/pause when play button is tapped', (tester) async {
      final testTrack = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://example.com/track.mp3',
      );

      mockPlayerService.setCurrentTrack(testTrack);
      mockPlayerService.setIsPlaying(false);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(mockPlayerService.isPlaying, isFalse);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      expect(mockPlayerService.isPlaying, isTrue);
    });

    testWidgets('should enable previous button when has previous track', (tester) async {
      final testTrack = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://example.com/track.mp3',
      );

      mockPlayerService.setCurrentTrack(testTrack);
      mockPlayerService.setHasPreviousTrack(true);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final previousButton = find.byIcon(Icons.skip_previous);
      expect(previousButton, findsOneWidget);

      final iconButton = tester.widget<IconButton>(find.ancestor(
        of: previousButton,
        matching: find.byType(IconButton),
      ));
      expect(iconButton.onPressed, isNotNull);
    });

    testWidgets('should disable previous button when no previous track', (tester) async {
      final testTrack = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://example.com/track.mp3',
      );

      mockPlayerService.setCurrentTrack(testTrack);
      mockPlayerService.setHasPreviousTrack(false);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final previousButton = find.byIcon(Icons.skip_previous);
      expect(previousButton, findsOneWidget);

      final iconButton = tester.widget<IconButton>(find.ancestor(
        of: previousButton,
        matching: find.byType(IconButton),
      ));
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('should enable next button when has next track', (tester) async {
      final testTrack = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://example.com/track.mp3',
      );

      mockPlayerService.setCurrentTrack(testTrack);
      mockPlayerService.setHasNextTrack(true);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final nextButton = find.byIcon(Icons.skip_next);
      expect(nextButton, findsOneWidget);

      final iconButton = tester.widget<IconButton>(find.ancestor(
        of: nextButton,
        matching: find.byType(IconButton),
      ));
      expect(iconButton.onPressed, isNotNull);
    });

    testWidgets('should disable next button when no next track', (tester) async {
      final testTrack = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://example.com/track.mp3',
      );

      mockPlayerService.setCurrentTrack(testTrack);
      mockPlayerService.setHasNextTrack(false);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final nextButton = find.byIcon(Icons.skip_next);
      expect(nextButton, findsOneWidget);

      final iconButton = tester.widget<IconButton>(find.ancestor(
        of: nextButton,
        matching: find.byType(IconButton),
      ));
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('should show full audio indicator when using full audio', (tester) async {
      final testTrack = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://example.com/track.mp3',
      );

      mockPlayerService.setCurrentTrack(testTrack);
      mockPlayerService.setIsUsingFullAudio(true);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('FULL'), findsOneWidget);
    });

    testWidgets('should show playlist info when has playlist', (tester) async {
      final testTrack = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://example.com/track.mp3',
      );

      mockPlayerService.setCurrentTrack(testTrack);
      mockPlayerService.setHasPlaylist(true);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('1/10'), findsOneWidget);
    });

    testWidgets('should show playback speed button', (tester) async {
      final testTrack = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://example.com/track.mp3',
      );

      mockPlayerService.setCurrentTrack(testTrack);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.speed), findsOneWidget);
    });

    testWidgets('should show speed indicator when speed is not 1.0x', (tester) async {
      final testTrack = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://example.com/track.mp3',
      );

      mockPlayerService.setCurrentTrack(testTrack);
      mockPlayerService.setPlaybackSpeed(1.5);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('1.5x'), findsOneWidget);
    });

    testWidgets('should show progress bar with correct position', (tester) async {
      final testTrack = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://example.com/track.mp3',
      );

      mockPlayerService.setCurrentTrack(testTrack);
      mockPlayerService.setDuration(const Duration(minutes: 3));
      mockPlayerService.setPosition(const Duration(minutes: 1));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      final sliderWidget = tester.widget<Slider>(slider);
      expect(sliderWidget.value, equals(60.0)); // 1 minute in seconds
      expect(sliderWidget.max, equals(180.0)); // 3 minutes in seconds
    });

    testWidgets('should show minimal progress bar when duration is zero', (tester) async {
      final testTrack = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://example.com/track.mp3',
      );

      mockPlayerService.setCurrentTrack(testTrack);
      mockPlayerService.setDuration(Duration.zero);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Slider), findsNothing);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should handle stop button tap', (tester) async {
      final testTrack = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://example.com/track.mp3',
      );

      mockPlayerService.setCurrentTrack(testTrack);
      mockPlayerService.setIsPlaying(true);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(mockPlayerService.isPlaying, isTrue);
      expect(mockPlayerService.currentTrack, isNotNull);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(mockPlayerService.isPlaying, isFalse);
      expect(mockPlayerService.currentTrack, isNull);
    });

    testWidgets('should handle different screen orientations', (tester) async {
      final testTrack = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://example.com/track.mp3',
      );

      mockPlayerService.setCurrentTrack(testTrack);
      
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      
      expect(find.byType(MiniPlayerWidget), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(800, 400));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      
      expect(find.byType(MiniPlayerWidget), findsOneWidget);
    });
  });
}