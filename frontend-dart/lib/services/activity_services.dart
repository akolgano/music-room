import 'package:flutter/foundation.dart';
import '../services/api_services.dart';
import '../models/api_models.dart';
import '../providers/auth_providers.dart';
import '../core/locator_core.dart';
import '../core/navigation_core.dart';

class ActivityService {
  final ApiService _api = getIt<ApiService>();

  Future<void> logUserActivity({
    required String action,
    required String token,
    String? details,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _api.logActivity(token, ActivityLogRequest(
        action: action,
        details: details,
        metadata: metadata,
      ));
    } catch (e) {
      AppLogger.error('Failed to log user activity', e, null, 'ActivityService');
    }
  }

  Future<void> _logWithToken(String action, String? details, String token, Map<String, dynamic>? metadata) =>
    logUserActivity(action: action, token: token, details: details, metadata: metadata);

  Future<void> logButtonClick(String buttonName, String token, {Map<String, dynamic>? metadata}) =>
    _logWithToken('button_click', buttonName, token, metadata);

  Future<void> logScreenView(String screenName, String token, {Map<String, dynamic>? metadata}) =>
    _logWithToken('screen_view', screenName, token, metadata);

  Future<void> logPlaylistAction(String action, String playlistId, String token, {Map<String, dynamic>? metadata}) =>
    _logWithToken('playlist_$action', playlistId, token, metadata);

  Future<void> logTrackAction(String action, String trackId, String token, {Map<String, dynamic>? metadata}) =>
    _logWithToken('track_$action', trackId, token, metadata);

  Future<void> logActivity({
    required String action,
    String? details,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final token = getIt<AuthProvider>().token;
      if (token != null) {
        await logUserActivity(
          action: action,
          token: token,
          details: details,
          metadata: metadata,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to log activity: $e');
    }
  }

  Future<void> logPlaylistActionAuto(String action, String playlistId, {Map<String, dynamic>? metadata}) =>
    logActivity(action: 'playlist_$action', details: playlistId, metadata: metadata);

  Future<void> logTrackActionAuto(String action, String trackId, {Map<String, dynamic>? metadata}) =>
    logActivity(action: 'track_$action', details: trackId, metadata: metadata);
}