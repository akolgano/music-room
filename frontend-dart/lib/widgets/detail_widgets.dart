import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_providers.dart';
import '../../providers/voting_providers.dart';
import '../../providers/auth_providers.dart';
import '../models/music_models.dart';
import '../core/theme_core.dart';
import '../core/responsive_core.dart';
import '../services/cache_services.dart';
import '../core/locator_core.dart';
import '../widgets/app_widgets.dart';

class PlaylistDetailWidgets {
  static Widget buildThemedPlaylistHeader(BuildContext context, Playlist playlist) {
    return Consumer<DynamicThemeProvider>(
      builder: (context, themeProvider, _) {
        return Card(
          color: Theme.of(context).colorScheme.surface,
          elevation: () {
            switch (MusicAppResponsive.getScreenSize(context)) {
              case ScreenSize.tiny: return 4.0;
              case ScreenSize.small: return 5.0;
              case ScreenSize.medium: return 6.0;
              case ScreenSize.large: return 7.0;
              case ScreenSize.xlarge: return 8.0;
              case ScreenSize.xxlarge: return 10.0;
            }
          }(),
          margin: EdgeInsets.all(ThemeUtils.getResponsiveMargin(context)),
          shadowColor: AppTheme.primary.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ThemeUtils.getResponsiveBorderRadius(context))),
          child: Padding(
            padding: EdgeInsets.all(ThemeUtils.getResponsivePadding(context)),
            child: Column(
            children: [
              Container(
                width: MusicAppResponsive.isSmallScreen(context) ? 80 : 120,
                height: MusicAppResponsive.isSmallScreen(context) ? 70 : 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ThemeUtils.getResponsiveBorderRadius(context)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, 
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primary.withValues(alpha: 0.8), AppTheme.primary.withValues(alpha: 0.4)],
                  ),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: MusicAppResponsive.isSmallScreen(context) ? 10 : 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: playlist.imageUrl?.isNotEmpty == true
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(ThemeUtils.getResponsiveBorderRadius(context)),
                      child: Image.network(
                        playlist.imageUrl!, 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          Icon(Icons.library_music, size: MusicAppResponsive.isSmallScreen(context) ? 40 : 60, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    )
                  : Icon(Icons.library_music, size: MusicAppResponsive.isSmallScreen(context) ? 40 : 60, color: Theme.of(context).colorScheme.onSurface),
              ),
              SizedBox(height: MusicAppResponsive.isSmallScreen(context) ? 6 : 12),
              Text(
                playlist.name,
                style: ThemeUtils.getHeadingStyle(context),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              SizedBox(height: MusicAppResponsive.isSmallScreen(context) ? 3 : 6),
              if (playlist.description.isNotEmpty) ...[
                Text(
                  playlist.description,
                  style: ThemeUtils.getCaptionStyle(context),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
                SizedBox(height: MusicAppResponsive.isSmallScreen(context) ? 4 : 8),
              ],
              if (MusicAppResponsive.isSmallScreen(context))
                Column(
                  children: [
                    Text('Created by ${playlist.creator}', style: ThemeUtils.getCaptionStyle(context)),
                    SizedBox(height: ThemeUtils.getResponsiveMargin(context)),
                    buildThemedVisibilityChip(context, playlist.isPublic),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(child: Text('Created by ${playlist.creator}', style: ThemeUtils.getCaptionStyle(context), overflow: TextOverflow.ellipsis)),
                    SizedBox(width: ThemeUtils.getResponsivePadding(context)),
                    buildThemedVisibilityChip(context, playlist.isPublic),
                  ],
                ),
            ],
            ),
          ),
        );
      },
    );
  }

  static Widget buildThemedPlaylistStats(BuildContext context, List<PlaylistTrack> tracks, {bool isEvent = false}) {
    final totalDuration = tracks.length * 0.5;
    final totalVotes = tracks.fold<int>(0, (sum, track) => sum + track.points);
    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 4,
      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      child: Padding(
        padding: EdgeInsets.all(ThemeUtils.getResponsivePadding(context)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildThemedStatItem(context, icon: Icons.queue_music, label: 'Tracks', value: '${tracks.length}'),
            buildThemedStatItem(context, icon: Icons.access_time, label: 'Duration', value: '${totalDuration}m'),
            if (isEvent)
              buildThemedStatItem(context, icon: Icons.favorite, label: 'Votes', value: '$totalVotes'),
          ],
        ),
      ),
    );
  }

  static Widget buildThemedPlaylistActions(BuildContext context, {
    required VoidCallback onPlayAll,
    required VoidCallback onPlayRandom,
    VoidCallback? onAddRandomTrack,
    bool hasTracks = true,
  }) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 4,
      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      child: Padding(
        padding: EdgeInsets.all(ThemeUtils.getResponsivePadding(context)),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: hasTracks ? onPlayAll : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play All'),
                    style: ThemeUtils.getPrimaryButtonStyle(context),
                  ),
                ),
                SizedBox(width: MusicAppResponsive.getSpacing(context)),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasTracks ? onPlayRandom : null,
                    icon: const Icon(Icons.casino),
                    label: const Text('Random'),
                    style: ThemeUtils.getSecondaryButtonStyle(context),
                  ),
                ),
              ],
            ),
            if (onAddRandomTrack != null) ...[
              SizedBox(height: MusicAppResponsive.getSpacing(context, tiny: 6.0, small: 8.0)),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onAddRandomTrack,
                  icon: const Icon(Icons.casino),
                  label: const Text('Add Random Track'),
                  style: ThemeUtils.getSecondaryButtonStyle(context).copyWith(
                    foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
                    side: WidgetStateProperty.all(BorderSide(color: Theme.of(context).colorScheme.primary)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget buildTrackItem({
    required BuildContext context,
    required PlaylistTrack playlistTrack,
    required int index,
    required bool isOwner,
    required VoidCallback onPlay,
    required VoidCallback? onRemove,
    VoidCallback? onMoveUp,
    VoidCallback? onMoveDown,
    bool canReorder = false,
    String? playlistId,
    String? playlistOwnerId,
    bool isEvent = false,
    bool isVotingMode = false,
    VoidCallback? onVoteSuccess,
    Key? key,
  }) {
    final track = playlistTrack.track;
    if (track == null) { return buildErrorTrackItem(key, playlistTrack, index); }

    return Container(
      key: key,
      margin: EdgeInsets.only(
        bottom: MusicAppResponsive.getSpacing(context, tiny: 1.0, small: 1.5, medium: 2.0)
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3), width: 1),
          bottom: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: MusicAppResponsive.getSpacing(context, tiny: 8.0, small: 10.0, medium: 12.0),
          bottom: MusicAppResponsive.getSpacing(context, tiny: 8.0, small: 10.0, medium: 12.0),
          right: MusicAppResponsive.getSpacing(context, tiny: 8.0, small: 10.0, medium: 12.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildTrackImage(track),
            SizedBox(width: MusicAppResponsive.getSpacing(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    track.name,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.w600, 
                      fontSize: 14
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (playlistId != null && isEvent) ...[
              SizedBox(width: MusicAppResponsive.getSpacing(context, tiny: 4.0, small: 5.0, medium: 6.0)),
              buildCompactVotingSection(context, index, playlistTrack, 
                playlistId: playlistId, 
                playlistOwnerId: playlistOwnerId,
                onVoteSuccess: onVoteSuccess,
                isVotingMode: isVotingMode,
              ),
            ],
            SizedBox(width: MusicAppResponsive.getSpacing(context, tiny: 4.0, small: 5.0, medium: 6.0)),
            Flexible(
              child: buildActionButtons(
                context, 
                onPlay, 
                onRemove, 
                isOwner,
                onMoveUp: onMoveUp,
                onMoveDown: onMoveDown,
                canReorder: canReorder,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildCompactVotingSection(BuildContext context, int index, PlaylistTrack playlistTrack, {
    String? playlistId, 
    String? playlistOwnerId,
    VoidCallback? onVoteSuccess,
    bool isVotingMode = false,
  }) {
    return Consumer<VotingProvider>(
      builder: (context, votingProvider, _) {
        final currentPoints = playlistTrack.points;
        final hasUserVoted = votingProvider.hasUserVotedForPlaylist;
        final canVote = votingProvider.canVote && !hasUserVoted && isVotingMode;
        
        return GestureDetector(
          onTap: canVote ? () async {
            if (playlistId == null) return;
            
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            if (!authProvider.isLoggedIn || authProvider.token == null) {
              AppWidgets.showSnackBar(context, 'Please login to vote', backgroundColor: Colors.orange);
              return;
            }
            
            final success = await votingProvider.voteForTrackByIndex(
              playlistId: playlistId,
              trackIndex: index,
              token: authProvider.token!,
              playlistOwnerId: playlistOwnerId,
              currentUserId: authProvider.userId,
              currentUsername: authProvider.username,
            );
            
            if (context.mounted) {
              if (success) {
                AppWidgets.showSnackBar(context, 'Vote submitted successfully!', backgroundColor: Colors.green);
                onVoteSuccess?.call();
              } else if (votingProvider.hasError) {
                AppWidgets.showSnackBar(context, votingProvider.errorMessage ?? 'Failed to vote', backgroundColor: Colors.red);
              }
            }
          } : null,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: getPointsColor(currentPoints).withValues(alpha: 0.1), 
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: getPointsColor(currentPoints).withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasUserVoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: hasUserVoted 
                      ? Colors.green 
                      : (isVotingMode && votingProvider.canVote && !hasUserVoted ? getPointsColor(currentPoints) : Colors.grey),
                    size: 14,
                  ),
                  Text(
                    '$currentPoints',
                    style: TextStyle(color: getPointsColor(currentPoints), fontSize: 8, fontWeight: FontWeight.w600, height: 1),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget buildActionButtons(
    BuildContext context, 
    VoidCallback onPlay, 
    VoidCallback? onRemove, 
    bool isOwner, {
    VoidCallback? onMoveUp,
    VoidCallback? onMoveDown,
    bool canReorder = false,
  }) {
    return Wrap(
      spacing: 2,
      alignment: WrapAlignment.center,
      children: [
        if (canReorder && onMoveUp != null) ...[
          GestureDetector(
            onTap: onMoveUp,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(child: Icon(Icons.keyboard_arrow_up, color: AppTheme.primary, size: 20)),
            ),
          ),
        ],
        if (canReorder && onMoveDown != null) ...[
          GestureDetector(
            onTap: onMoveDown,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(child: Icon(Icons.keyboard_arrow_down, color: AppTheme.primary, size: 20)),
            ),
          ),
        ],
        GestureDetector(
          onTap: onPlay,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(child: Icon(Icons.play_arrow, color: AppTheme.primary, size: 20)),
          ),
        ),
        if (isOwner && onRemove != null) ...[
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(child: Icon(Icons.remove_circle_outline, color: Colors.red, size: 20)),
            ),
          ),
        ],
      ],
    );
  }

  static Widget buildEmptyTracksState({required bool isOwner, VoidCallback? onAddTracks}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.music_note, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No tracks yet',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: Colors.white
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOwner ? 'Add some tracks to get started!' : 'This playlist is empty',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (isOwner && onAddTracks != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onAddTracks,
                icon: const Icon(Icons.add),
                label: const Text('Add Tracks'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary, 
                  foregroundColor: Colors.black
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget buildThemedVisibilityChip(BuildContext context, bool isPublic) {
    final chipColor = isPublic ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Icons.public : Icons.lock,
            size: 14,
            color: chipColor,
          ),
          Text(
            isPublic ? 'Public' : 'Private',
            style: TextStyle(color: chipColor, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  static Widget buildThemedStatItem(BuildContext context, {required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primary, size: 24),
        const SizedBox(height: 4),
        Text(value, style: ThemeUtils.getSubheadingStyle(context)),
        Text(label, style: ThemeUtils.getCaptionStyle(context).copyWith(fontSize: 12)),
      ],
    );
  }

  static Widget buildTrackImage(Track track) {
    return Container(
      width: 56, 
      height: 50,
      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
      child: track.imageUrl?.isNotEmpty == true
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                track.imageUrl!, 
                fit: BoxFit.cover,
                width: 56,
                height: 50,
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.music_note, color: Colors.white, size: 24),
              ),
            )
          : const Icon(Icons.music_note, color: Colors.white, size: 24),
    );
  }

  static Widget buildErrorTrackItem(Key? key, PlaylistTrack playlistTrack, int index, {bool isLoading = false}) {
    final trackCacheService = getIt<TrackCacheService>();
    final trackId = playlistTrack.trackId;
    final isRetrying = (trackCacheService.retryCount[trackId] ?? 0) > 0;
    
    Color backgroundColor;
    Widget leadingIcon;
    String subtitleText;
    Color subtitleColor;
    Widget? trailingWidget;
    
    if (isLoading) {
      backgroundColor = Colors.grey.withValues(alpha: 0.3);
      leadingIcon = const Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.music_note, color: Colors.white),
          SizedBox(
            width: 20,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
          ),
        ],
      );
      subtitleText = 'Loading track details...';
      subtitleColor = Colors.grey;
      trailingWidget = null;
    } else {
      backgroundColor = isRetrying 
          ? Colors.orange.withValues(alpha: 0.3) 
          : Colors.red.withValues(alpha: 0.3);
      leadingIcon = isRetrying
          ? const SizedBox(
              width: 24,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            )
          : const Icon(Icons.music_off, color: Colors.white);
      subtitleText = _getTrackStatusText(trackCacheService, trackId);
      subtitleColor = isRetrying ? Colors.orange : Colors.grey;
      trailingWidget = isRetrying
          ? IconButton(
              icon: const Icon(Icons.cancel, color: Colors.orange),
              onPressed: () => trackCacheService.cancelRetries(trackId),
              tooltip: 'Cancel retries',
            )
          : null;
    }
    
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1),
      ),
      child: ListTile(
        leading: Container(
          width: 56,
          height: 50,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8)
          ),
          child: leadingIcon,
        ),
        title: Text(
          playlistTrack.track?.name ?? playlistTrack.name,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          subtitleText,
          style: TextStyle(color: subtitleColor),
        ),
        trailing: trailingWidget,
      ),
    );
  }

  static String _getTrackStatusText(TrackCacheService cacheService, String trackId) {
    if ((cacheService.retryCount[trackId] ?? 0) > 0) {
      final retryCount = cacheService.retryCount[trackId] ?? 0;
      final maxRetries = cacheService.retryConfig.maxRetries;
      return 'Retrying... (attempt $retryCount/$maxRetries)';
    } else {
      return 'Track details unavailable';
    }
  }

  static Color getPointsColor(int points) {
    if (points > 5) { return Colors.green; }
    if (points > 0) { return Colors.orange; }
    return Colors.grey;
  }
}
