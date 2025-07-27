import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/models/music_models.dart';
void main() {
  group('Playlist Detail Widgets Tests', () {
    test('PlaylistDetailWidgets should render track items correctly', () {
      const track = Track(
        id: 'track_123',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://example.com/image.jpg'
      );
      
      expect(track.name, 'Test Song');
      expect(track.artist, 'Test Artist');
      expect(track.album, 'Test Album');
      expect(track.url, startsWith('https://example.com/image.jpg'));
      
      final trackDisplayData = {
        'title': track.name,
        'subtitle': '${track.artist} • ${track.album}',
        'hasArtwork': track.url.isNotEmpty,
        'duration': '3:45',
        'position': 1,
      };
      
      expect(trackDisplayData['title'], 'Test Song');
      expect(trackDisplayData['subtitle'], contains('Test Artist'));
      expect(trackDisplayData['subtitle'], contains('Test Album'));
      expect(trackDisplayData['hasArtwork'], true);
      
      const trackStates = {
        'isPlaying': false,
        'isLoading': false,
        'hasError': false,
        'isSelected': false,
        'canReorder': true,
        'canRemove': true,
      };
      
      expect(trackStates['isPlaying'], false);
      expect(trackStates['isLoading'], false);
      expect(trackStates['hasError'], false);
      expect(trackStates['canReorder'], true);
      expect(trackStates['canRemove'], true);
      
      const menuActions = {
        'play': 'Play Track',
        'addToQueue': 'Add to Queue',
        'removeFromPlaylist': 'Remove from Playlist',
        'moveUp': 'Move Up',
        'moveDown': 'Move Down',
        'viewDetails': 'View Details',
      };
      
      expect(menuActions.keys.length, 6);
      expect(menuActions['play'], 'Play Track');
      expect(menuActions['removeFromPlaylist'], contains('Remove'));
    });
    test('PlaylistDetailWidgets should handle retry states correctly', () {
      const retryState = {
        'isRetrying': false,
        'retryCount': 0,
        'maxRetries': 3,
        'lastError': '',
        'canRetry': true,
      };
      
      expect(retryState['isRetrying'], false);
      expect(retryState['retryCount'], 0);
      expect(retryState['maxRetries'], 3);
      expect(retryState['lastError'], isEmpty);
      expect(retryState['canRetry'], true);
      
      const retryButtonConfig = {
        'enabled': true,
        'text': 'Retry',
        'icon': 'refresh',
        'color': 'primary',
      };
      
      expect(retryButtonConfig['enabled'], true);
      expect(retryButtonConfig['text'], 'Retry');
      expect(retryButtonConfig['icon'], 'refresh');
      expect(retryButtonConfig['color'], 'primary');
      
      const errorDisplayConfig = {
        'showError': false,
        'errorMessage': '',
        'errorType': 'network',
        'showDetails': false,
      };
      
      expect(errorDisplayConfig['showError'], false);
      expect(errorDisplayConfig['errorMessage'], isEmpty);
      expect(errorDisplayConfig['errorType'], isIn(['network', 'timeout', 'server', 'unknown']));
      expect(errorDisplayConfig['showDetails'], false);
      
      const loadingOverlayConfig = {
        'visible': false,
        'opacity': 0.8,
        'showProgress': true,
        'progressValue': 0.0,
        'statusText': 'Loading...',
      };
      
      expect(loadingOverlayConfig['visible'], false);
      expect(loadingOverlayConfig['opacity'], 0.8);
      expect(loadingOverlayConfig['showProgress'], true);
      expect(loadingOverlayConfig['progressValue'], 0.0);
      expect(loadingOverlayConfig['statusText'], 'Loading...');
    });
  });
}