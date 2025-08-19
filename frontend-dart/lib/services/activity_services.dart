import 'package:flutter/foundation.dart';
import '../services/api_services.dart';
import '../models/api_models.dart';
import '../providers/auth_providers.dart';
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

  // Convenience methods that automatically get token from AuthProvider
  Future<void> logActivity({
    required String action,
    String? details,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final authProvider = getIt<AuthProvider>();
      final token = authProvider.token;
      if (token != null) {
        await logUserActivity(
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

  Future<void> logButtonClickAuto(String buttonName, {Map<String, dynamic>? metadata}) async {
    await logActivity(action: 'button_click', details: buttonName, metadata: metadata);
  }

  Future<void> logScreenViewAuto(String screenName, {Map<String, dynamic>? metadata}) async {
    await logActivity(action: 'screen_view', details: screenName, metadata: metadata);
  }

  Future<void> logPlaylistActionAuto(String action, String playlistId, {Map<String, dynamic>? metadata}) async {
    await logActivity(action: 'playlist_$action', details: playlistId, metadata: metadata);
  }

  Future<void> logTrackActionAuto(String action, String trackId, {Map<String, dynamic>? metadata}) async {
    await logActivity(action: 'track_$action', details: trackId, metadata: metadata);
  }
}