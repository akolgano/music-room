import '../services/api_services.dart';
import '../models/api_models.dart';
import '../core/locator_core.dart';

class ActivityService {
  final ApiService _api = getIt<ApiService>();

  Future<void> logUserActivity({
    required String action,
    required String token,
    String? details,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final request = ActivityLogRequest(
        action: action,
        details: details,
        metadata: metadata,
      );
      await _api.logActivity(token, request);
    } catch (e) {
      // Silent fail for activity logging to not disrupt user experience
    }
  }

  Future<void> logButtonClick(String buttonName, String token, {Map<String, dynamic>? metadata}) async {
    await logUserActivity(
      action: 'button_click',
      token: token,
      details: buttonName,
      metadata: metadata,
    );
  }

  Future<void> logScreenView(String screenName, String token, {Map<String, dynamic>? metadata}) async {
    await logUserActivity(
      action: 'screen_view',
      token: token,
      details: screenName,
      metadata: metadata,
    );
  }

  Future<void> logPlaylistAction(String action, String playlistId, String token, {Map<String, dynamic>? metadata}) async {
    await logUserActivity(
      action: 'playlist_$action',
      token: token,
      details: playlistId,
      metadata: metadata,
    );
  }

  Future<void> logTrackAction(String action, String trackId, String token, {Map<String, dynamic>? metadata}) async {
    await logUserActivity(
      action: 'track_$action',
      token: token,
      details: trackId,
      metadata: metadata,
    );
  }
}