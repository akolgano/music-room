// lib/screens/playlists/playlist_detail_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/dynamic_theme_provider.dart';
import '../../providers/voting_provider.dart';
import '../../models/models.dart';
import '../../core/core.dart';
import '../../widgets/widgets.dart';
import '../../core/theme_utils.dart';

class PlaylistDetailWidgets {
  static Widget buildThemedPlaylistHeader(BuildContext context, Playlist playlist) {
    return Consumer<DynamicThemeProvider>(
      builder: (context, themeProvider, _) {
        return ThemeUtils.buildThemedHeaderCard(
          context: context,
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, 
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primary.withOpacity(0.8), AppTheme.primary.withOpacity(0.4)],
                  ),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: playlist.imageUrl?.isNotEmpty == true
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        playlist.imageUrl!, 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          Icon(Icons.library_music, size: 60, color: ThemeUtils.getOnSurface(context)),
                      ),
                    )
                  : Icon(Icons.library_music, size: 60, color: ThemeUtils.getOnSurface(context)),
              ),
              const SizedBox(height: 20),
              Text(
                playlist.name,
                style: ThemeUtils.getHeadingStyle(context).copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (playlist.description.isNotEmpty) ...[
                Text(
                  playlist.description,
                  style: ThemeUtils.getCaptionStyle(context).copyWith(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Created by ${playlist.creator}',
                    style: ThemeUtils.getCaptionStyle(context),
                  ),
                  const SizedBox(width: 12),
                  buildThemedVisibilityChip(context, playlist.isPublic),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, color: Colors.blue, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Pull down to refresh • Auto-refresh every 30s',
                      style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500),
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
      shadowColor: ThemeUtils.getPrimary(context).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildThemedStatItem(context, icon: Icons.queue_music, label: 'Tracks', value: '${tracks.length}'),
            buildThemedStatItem(
              context,
              icon: Icons.access_time,
              label: 'Duration',
              value: '${totalDuration}m',
            ),
            buildThemedStatItem(
              context,
              icon: Icons.favorite,
              label: 'Likes',
              value: '0',
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildPlaylistActions({
    required VoidCallback onPlayAll,
    required VoidCallback onShuffle,
  }) {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onPlayAll,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onShuffle,
                icon: const Icon(Icons.shuffle),
                label: const Text('Shuffle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white), 
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildThemedPlaylistActions(BuildContext context, {
    required VoidCallback onPlayAll,
    required VoidCallback onShuffle,
  }) {
    return Card(
      color: ThemeUtils.getSurface(context),
      elevation: 4,
      shadowColor: ThemeUtils.getPrimary(context).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onPlayAll,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play All'),
                style: ThemeUtils.getPrimaryButtonStyle(context).copyWith(
                  padding: MaterialStateProperty.all(
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
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 12)
                  ),
                ),
              ),
            ),
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
    
    if (track == null) {
      return buildErrorTrackItem(key, playlistTrack, index);
    }

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            buildTrackImage(track),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
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
            if (playlistId != null) 
              Expanded(flex: 1, child: buildVotingSection(context, index, playlistTrack)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: AppTheme.primary, size: 20),
                  onPressed: onPlay,
                  tooltip: 'Play track',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                if (isOwner && onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                    onPressed: onRemove,
                    tooltip: 'Remove from playlist', 
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildVotingSection(BuildContext context, int index, PlaylistTrack playlistTrack) {
    return Consumer<VotingProvider>(
      builder: (context, votingProvider, _) {
        final currentPoints = playlistTrack.points;
        final hasUserVoted = votingProvider.hasUserVotedByIndex(index);
        final canVote = votingProvider.canVote && !hasUserVoted;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: getPointsColor(currentPoints).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: getPointsColor(currentPoints).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: canVote ? () {
                } : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    hasUserVoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: hasUserVoted 
                      ? Colors.green 
                      : (canVote ? getPointsColor(currentPoints) : Colors.grey),
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '+$currentPoints',
                style: TextStyle(
                  color: getPointsColor(currentPoints), 
                  fontSize: 12, 
                  fontWeight: FontWeight.w600
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget buildEmptyTracksState({
    required bool isOwner,
    VoidCallback? onAddTracks,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.music_note, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
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
              const SizedBox(height: 16),
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

  static Widget buildVisibilityChip(bool isPublic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isPublic ? Colors.green : Colors.orange).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPublic ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Icons.public : Icons.lock,
            size: 14,
            color: isPublic ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isPublic ? 'Public' : 'Private',
            style: TextStyle(
              color: isPublic ? Colors.green : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildThemedVisibilityChip(BuildContext context, bool isPublic) {
    final chipColor = isPublic ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
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
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
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
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.2), 
        borderRadius: BorderRadius.circular(8)
      ),
      child: track.imageUrl?.isNotEmpty == true
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                track.imageUrl!, 
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.music_note, color: Colors.white, size: 24),
              ),
            )
          : const Icon(Icons.music_note, color: Colors.white, size: 24),
    );
  }

  static Widget buildErrorTrackItem(Key? key, PlaylistTrack playlistTrack, int index) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.3), 
            borderRadius: BorderRadius.circular(8)
          ),
          child: const Icon(Icons.music_off, color: Colors.white),
        ),
        title: Text(
          playlistTrack.name,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: const Text(
          'Track details unavailable', 
          style: TextStyle(color: Colors.grey)
        ),
      ),
    );
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
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.music_note, color: Colors.white),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          playlistTrack.track?.name ?? playlistTrack.name,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: const Text('Loading track details...', style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  static Color getPointsColor(int points) {
    if (points > 5) return Colors.green;
    if (points > 0) return Colors.orange;
    return Colors.grey;
  }
}
