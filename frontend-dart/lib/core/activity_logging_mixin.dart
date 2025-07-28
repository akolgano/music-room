import 'package:flutter/widgets.dart';
import '../services/user_activity_service.dart';
import '../core/service_locator.dart';

mixin ActivityLoggingMixin<T extends StatefulWidget> on State<T> {
  late final UserActivityService _activityService;
  String get screenName;

  @override
  void initState() {
    super.initState();
    _activityService = getIt<UserActivityService>();
    _logScreenView();
  }

  void _logScreenView() {
    _activityService.logScreenView(screenName);
  }

  void logButtonTap(String buttonName, {Map<String, dynamic>? metadata}) {
    _activityService.logButtonTap(buttonName, screenName, metadata: metadata);
  }

  void logUserAction(String action, {Map<String, dynamic>? metadata}) {
    _activityService.logUserAction(
      action: action,
      screen: screenName,
      metadata: metadata,
    );
  }

  void logError(String error, {Map<String, dynamic>? metadata}) {
    _activityService.logError(error, screenName, metadata: metadata);
  }

  void logPlaylistAction(String action, String playlistId, {Map<String, dynamic>? metadata}) {
    _activityService.logPlaylistAction(action, playlistId, metadata: metadata);
  }

  void logTrackAction(String action, String trackId, {Map<String, dynamic>? metadata}) {
    _activityService.logTrackAction(action, trackId, metadata: metadata);
  }

  void logVoteAction(String playlistId, String trackId, String voteType) {
    _activityService.logVoteAction(playlistId, trackId, voteType);
  }

  void logAuthAction(String action, {Map<String, dynamic>? metadata}) {
    _activityService.logAuthAction(action, metadata: metadata);
  }
}