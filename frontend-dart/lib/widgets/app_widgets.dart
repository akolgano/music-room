import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/music_models.dart';
import '../services/player_services.dart';
import '../providers/theme_providers.dart';
import 'votes_widgets.dart';
import '../models/voting_models.dart';
import 'action_widgets.dart';
export 'player_widgets.dart';
export 'action_widgets.dart';
export 'card_widgets.dart';
export 'app_core_widgets.dart';

double _responsiveWidth(double size) => _responsive(size, type: 'w');
double _responsiveHeight(double size) => _responsive(size, type: 'h');
double _responsiveValue(double value) => _responsive(value);

double _responsive(double value, {String type = 'sp'}) {
  if (kIsWeb) return value;
  switch (type) {
    case 'w': return value.w.toDouble();
    case 'h': return value.h.toDouble();
    case 'sp': default: return value.sp.toDouble();
  }
}

Color _getTrackCardColor(ColorScheme colorScheme, bool isSelected, bool isCurrentTrack) {
  if (isSelected) return colorScheme.primary.withValues(alpha: 0.2);
  if (isCurrentTrack) return colorScheme.primary.withValues(alpha: 0.1);
  return colorScheme.surface;
}

Widget _buildImage(String? imageUrl, double size) {
  if (imageUrl == null || imageUrl.isEmpty) {
    return Container(
      width: kIsWeb ? size : size.w.toDouble(),
      height: kIsWeb ? size : size.h.toDouble(),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(kIsWeb ? 8.0 : 8.r.toDouble())
      ),
      child: Icon(
        Icons.music_note,
        color: Colors.grey.shade600,
        size: kIsWeb ? size * 0.5 : (size * 0.5).sp.toDouble()
      ),
    );
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(kIsWeb ? 8.0 : 8.r.toDouble()),
    child: CachedNetworkImage(
      imageUrl: imageUrl,
      width: kIsWeb ? size : size.w.toDouble(),
      height: kIsWeb ? size : size.h.toDouble(),
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade300,
        child: Icon(
          Icons.music_note,
          color: Colors.grey.shade600,
          size: kIsWeb ? size * 0.5 : (size * 0.5).sp.toDouble()
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade300,
        child: Icon(
          Icons.music_note,
          color: Colors.grey.shade600,
          size: kIsWeb ? size * 0.5 : (size * 0.5).sp.toDouble()
        ),
      ),
    ),
  );
}

class TrackCardWidget extends StatelessWidget {
  final Track track;
  final bool isSelected;
  final bool isInPlaylist;
  final bool showAddButton;
  final bool showPlayButton;
  final bool showVotingControls;
  final String? playlistContext;
  final String? playlistId;
  final String? playlistOwnerId;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final VoidCallback? onPlay;
  final VoidCallback? onRemove;
  final VoidCallback? onAddToLibrary;
  final ValueChanged<bool?>? onSelectionChanged;

  const TrackCardWidget({
    super.key,
    required this.track,
    this.isSelected = false,
    this.isInPlaylist = false,
    this.showAddButton = true,
    this.showPlayButton = true,
    this.showVotingControls = false,
    this.playlistContext,
    this.playlistId,
    this.playlistOwnerId,
    this.onTap,
    this.onAdd,
    this.onPlay,
    this.onRemove,
    this.onAddToLibrary,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<MusicPlayerService, DynamicThemeProvider>(
      builder: (context, playerService, themeProvider, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isCurrentTrack = playerService.currentTrack?.id == track.id;

        String displayArtist = track.artist;
        if (displayArtist.isEmpty && track.deezerTrackId != null) {
          displayArtist = 'Unknown Artist';
        }

        return Container(
          margin: EdgeInsets.symmetric(
            vertical: _responsiveHeight(2.0),
            horizontal: _responsiveWidth(4.0),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: _getTrackCardColor(colorScheme, isSelected, isCurrentTrack),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8.0),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(_responsiveWidth(8.0)),
              child: Row(
                children: [
                  if (onSelectionChanged != null)
                    Container(
                      margin: EdgeInsets.only(right: _responsiveWidth(8.0)),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: onSelectionChanged,
                      ),
                    ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6.0),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: _buildImage(track.imageUrl, 56),
                    ),
                  ),
                  SizedBox(width: _responsiveWidth(12.0)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: _responsiveValue(14.0),
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (displayArtist.isNotEmpty)
                          Text(
                            displayArtist,
                            style: TextStyle(
                              fontSize: _responsiveValue(12.0),
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showVotingControls && playlistId != null)
                        Container(
                          margin: EdgeInsets.only(bottom: _responsiveHeight(4.0)),
                          child: TrackVotingControls(
                            playlistId: playlistId!,
                            trackId: track.id,
                            trackIndex: 0,
                            stats: VoteStats(
                              totalVotes: 0,
                              upvotes: 0,
                              downvotes: 0,
                              userHasVoted: false,
                              voteScore: 0.0,
                            ),
                            playlistOwnerId: playlistOwnerId,
                          ),
                        ),
                      if (onSelectionChanged == null)
                        TrackActionsWidget(
                          trackIsPlaying: isCurrentTrack,
                          showAddButton: showAddButton,
                          showPlayButton: showPlayButton,
                          onAdd: onAdd,
                          onPlay: onPlay,
                          onRemove: onRemove,
                          isInPlaylist: isInPlaylist,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}