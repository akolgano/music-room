import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dynamic_theme_provider.dart';
import '../../providers/voting_provider.dart';
import '../models/music_models.dart';
import '../core/theme_utils.dart';
import '../services/track_cache_service.dart';
import '../core/service_locator.dart';

class PlaylistDetailWidgets {
  static Widget buildThemedPlaylistHeader(BuildContext context, Playlist playlist) {
    return Consumer<DynamicThemeProvider>(
      builder: (context, themeProvider, _) {
        return ThemeUtils.buildThemedHeaderCard(
          context: context,
          child: Column(
            children: [
              Container(
                width: ThemeUtils.isSmallMobile(context) ? 80 : 120,
                height: ThemeUtils.isSmallMobile(context) ? 70 : 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ThemeUtils.getResponsiveBorderRadius(context)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, 
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primary.withValues(alpha: 0.8), AppTheme.primary.withValues(alpha: 0.4)],
                  ),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: ThemeUtils.isSmallMobile(context) ? 10 : 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: playlist.imageUrl?.isNotEmpty == true
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(ThemeUtils.getResponsiveBorderRadius(context)),
                      child: Image.network(
                        playlist.imageUrl!, 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          Icon(Icons.library_music, size: ThemeUtils.isSmallMobile(context) ? 40 : 60, color: ThemeUtils.getOnSurface(context)),
                      ),
                    )
                  : Icon(Icons.library_music, size: ThemeUtils.isSmallMobile(context) ? 40 : 60, color: ThemeUtils.getOnSurface(context)),
              ),
              SizedBox(height: ThemeUtils.isSmallMobile(context) ? 6 : 12),
              Text(
                playlist.name,
                style: ThemeUtils.getHeadingStyle(context),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              SizedBox(height: ThemeUtils.isSmallMobile(context) ? 3 : 6),
              if (playlist.description.isNotEmpty) ...[
                Text(
                  playlist.description,
                  style: ThemeUtils.getCaptionStyle(context),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
                SizedBox(height: ThemeUtils.isSmallMobile(context) ? 4 : 8),
              ],
              if (ThemeUtils.isSmallMobile(context))
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
              SizedBox(height: ThemeUtils.getResponsivePadding(context)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: ThemeUtils.getResponsivePadding(context), vertical: ThemeUtils.isSmallMobile(context) ? 4 : 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ThemeUtils.getResponsiveBorderRadius(context)),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, color: Colors.blue, size: ThemeUtils.isSmallMobile(context) ? 12 : 16),
                    SizedBox(width: ThemeUtils.isSmallMobile(context) ? 3 : 6),
                    Flexible(
                      child: Text(
                        ThemeUtils.isSmallMobile(context) ? 'Pull to refresh' : 'Pull down to refresh • Auto-refresh every 30s',
                        style: ThemeUtils.getCaptionStyle(context).copyWith(color: Colors.blue, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget buildThemedPlaylistStats(BuildContext context, List<PlaylistTrack> tracks) {
    final totalDuration = tracks.length * 3;
    return Card(
      color: ThemeUtils.getSurface(context),
      elevation: 4,
      shadowColor: ThemeUtils.getPrimary(context).withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildThemedStatItem(context, icon: Icons.queue_music, label: 'Tracks', value: '${tracks.length}'),
            buildThemedStatItem(context, icon: Icons.access_time, label: 'Duration', value: '${totalDuration}m'),
            buildThemedStatItem(context, icon: Icons.favorite, label: 'Votes', value: '0'),
          ],
        ),
      ),
    );
  }

  static Widget buildThemedPlaylistActions(BuildContext context, {
    required VoidCallback onPlayAll,
    required VoidCallback onShuffle,
    VoidCallback? onAddRandomTrack,
  }) {
    return Card(
      color: ThemeUtils.getSurface(context),
      elevation: 4,
      shadowColor: ThemeUtils.getPrimary(context).withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPlayAll,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play All'),
                    style: ThemeUtils.getPrimaryButtonStyle(context).copyWith(
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 12)
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onShuffle,
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Shuffle'),
                    style: ThemeUtils.getSecondaryButtonStyle(context).copyWith(
                      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ),
              ],
            ),
            if (onAddRandomTrack != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onAddRandomTrack,
                  icon: const Icon(Icons.casino),
                  label: const Text('Add Random Track'),
                  style: ThemeUtils.getSecondaryButtonStyle(context).copyWith(
                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
                    foregroundColor: WidgetStateProperty.all(ThemeUtils.getPrimary(context)),
                    side: WidgetStateProperty.all(BorderSide(color: ThemeUtils.getPrimary(context))),
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
    String? playlistId,
    Key? key,
  }) {
    final track = playlistTrack.track;
    if (track == null) { return buildErrorTrackItem(key, playlistTrack, index); }

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            buildTrackImage(track),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  ),
                ],
              ),
            ),
            if (playlistId != null) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: buildCompactVotingSection(context, index, playlistTrack),
              ),
            ],
            const SizedBox(width: 8),
            SizedBox(
              width: 32, 
              child: buildActionButtons(context, onPlay, onRemove, isOwner),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildCompactVotingSection(BuildContext context, int index, PlaylistTrack playlistTrack) {
    return Consumer<VotingProvider>(
      builder: (context, votingProvider, _) {
        final currentPoints = playlistTrack.points;
        final hasUserVoted = votingProvider.hasUserVotedByIndex(index);
        final canVote = votingProvider.canVote && !hasUserVoted;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: getPointsColor(currentPoints).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8),
            border: Border.all(color: getPointsColor(currentPoints).withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: canVote ? () {
                } : null,
                child: Icon(
                  hasUserVoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                  color: hasUserVoted 
                    ? Colors.green 
                    : (canVote ? getPointsColor(currentPoints) : Colors.grey),
                  size: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '+$currentPoints',
                style: TextStyle(color: getPointsColor(currentPoints), fontSize: 9, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget buildActionButtons(BuildContext context, VoidCallback onPlay, VoidCallback? onRemove, bool isOwner) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPlay,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.play_arrow, color: AppTheme.primary, size: 16),
          ),
        ),
        if (isOwner && onRemove != null) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 14),
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
          const SizedBox(width: 4),
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
      width: 48, 
      height: 40,
      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
      child: track.imageUrl?.isNotEmpty == true
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                track.imageUrl!, 
                fit: BoxFit.cover,
                width: 48,
                height: 40,
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.music_note, color: Colors.white, size: 20),
              ),
            )
          : const Icon(Icons.music_note, color: Colors.white, size: 20),
    );
  }

  static Widget buildErrorTrackItem(Key? key, PlaylistTrack playlistTrack, int index) {
    final trackCacheService = getIt<TrackCacheService>();
    final trackId = playlistTrack.trackId;
    
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 40,
          decoration: BoxDecoration(
            color: trackCacheService.isTrackRetrying(trackId) 
                ? Colors.orange.withValues(alpha: 0.3) 
                : Colors.red.withValues(alpha: 0.3), 
            borderRadius: BorderRadius.circular(8)
          ),
          child: trackCacheService.isTrackRetrying(trackId)
              ? const SizedBox(
                  width: 24,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                )
              : const Icon(Icons.music_off, color: Colors.white),
        ),
        title: Text(
          playlistTrack.name,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          _getTrackStatusText(trackCacheService, trackId),
          style: TextStyle(
            color: trackCacheService.isTrackRetrying(trackId) ? Colors.orange : Colors.grey
          ),
        ),
        trailing: trackCacheService.isTrackRetrying(trackId)
            ? IconButton(
                icon: const Icon(Icons.cancel, color: Colors.orange),
                onPressed: () => trackCacheService.cancelRetries(trackId),
                tooltip: 'Cancel retries',
              )
            : null,
      ),
    );
  }

  static String _getTrackStatusText(TrackCacheService cacheService, String trackId) {
    if (cacheService.isTrackRetrying(trackId)) {
      final retryCount = cacheService.getRetryCount(trackId);
      final maxRetries = cacheService.retryConfig.maxRetries;
      return 'Retrying... (attempt $retryCount/$maxRetries)';
    } else {
      return 'Track details unavailable';
    }
  }

  static Widget buildLoadingTrackItem(Key? key, PlaylistTrack playlistTrack, int index) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface, 
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 40,
          decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.music_note, color: Colors.white),
              SizedBox(
                width: 20,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
              ),
            ],
          ),
        ),
        title: Text(playlistTrack.track?.name ?? playlistTrack.name, style: const TextStyle(color: Colors.white)),
        subtitle: const Text('Loading track details...', style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  static Color getPointsColor(int points) {
    if (points > 5) { return Colors.green; }
    if (points > 0) { return Colors.orange; }
    return Colors.grey;
  }
}
