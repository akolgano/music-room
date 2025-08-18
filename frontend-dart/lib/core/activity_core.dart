import 'package:flutter/foundation.dart';
import '../services/activity_services.dart';
import '../providers/auth_providers.dart';
import 'locator_core.dart';

mixin ActivityLoggingMixin on ChangeNotifier {
  final ActivityService _activityService = getIt<ActivityService>();

  Future<void> logActivity({
    required String action,
    String? details,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final authProvider = getIt<AuthProvider>();
      final token = authProvider.token;
      if (token != null) {
        await _activityService.logUserActivity(
          action: action,
          token: token,
          details: details,
          metadata: metadata,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to log activity: $e');
      }
    }
  }

  Future<void> logButtonClick(String buttonName, {Map<String, dynamic>? metadata}) async {
    await logActivity(action: 'button_click', details: buttonName, metadata: metadata);
  }

  Future<void> logScreenView(String screenName, {Map<String, dynamic>? metadata}) async {
    await logActivity(action: 'screen_view', details: screenName, metadata: metadata);
  }

  Future<void> logPlaylistAction(String action, String playlistId, {Map<String, dynamic>? metadata}) async {
    await logActivity(action: 'playlist_$action', details: playlistId, metadata: metadata);
  }

  Future<void> logTrackAction(String action, String trackId, {Map<String, dynamic>? metadata}) async {
    await logActivity(action: 'track_$action', details: trackId, metadata: metadata);
  }
}