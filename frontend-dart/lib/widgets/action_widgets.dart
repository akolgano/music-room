import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TrackActionsWidget extends StatelessWidget {
  final bool showAddButton;
  final bool showPlayButton;
  final VoidCallback? onAdd;
  final VoidCallback? onPlay;
  final VoidCallback? onRemove;
  final bool trackIsPlaying;
  final bool isInPlaylist;

  const TrackActionsWidget({
    super.key,
    required this.showAddButton,
    required this.showPlayButton,
    this.onAdd,
    this.onPlay,
    this.onRemove,
    required this.trackIsPlaying,
    required this.isInPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final actions = <Widget>[];
    
    if (showPlayButton && onPlay != null) {
      actions.add(_buildStyledIconButton(
        trackIsPlaying ? Icons.pause : Icons.play_arrow, 
        colorScheme.primary, 
        20.0, 
        onPlay!
      ));
    }
    
    if (showAddButton && onAdd != null && !isInPlaylist) {
      actions.add(_buildStyledIconButton(
        Icons.add_circle_outline, 
        colorScheme.onSurface, 
        18.0, 
        onAdd!, 
        tooltip: 'Add to Playlist'
      ));
    }
    
    if (isInPlaylist) {
      actions.add(Padding(
        padding: EdgeInsets.all(_responsiveWidth(4.0)),
        child: Icon(
          Icons.check_circle, 
          color: Colors.green, 
          size: _responsiveValue(18.0) 
        ),
      ));
    }
    
    if (onRemove != null) {
      actions.add(_buildStyledIconButton(
        Icons.remove_circle_outline, 
        colorScheme.error, 
        18.0, 
        onRemove!
      ));
    }
    
    if (actions.isEmpty) return const SizedBox.shrink();
    final displayedActions = actions.take(2).toList();
    return Row(mainAxisSize: MainAxisSize.min, children: displayedActions);
  }

  static IconButton _buildStyledIconButton(
    IconData icon,
    Color color,
    double size,
    VoidCallback onPressed, {
    String? tooltip,
  }) => IconButton(
    icon: Icon(icon, color: color, size: _responsiveValue(size)),
    onPressed: onPressed,
    tooltip: tooltip,
    padding: EdgeInsets.all(_responsiveWidth(4.0)),
    constraints: const BoxConstraints(minWidth: 32, minHeight: 32, maxWidth: 40),
  );

  static double _responsiveWidth(double size) => _responsive(size, type: 'w');
  static double _responsiveValue(double value) => _responsive(value);
  
  static double _responsive(double value, {String type = 'sp'}) {
    if (kIsWeb) return value;
    switch (type) {
      case 'w': return value.w.toDouble();
      case 'h': return value.h.toDouble();
      case 'sp': default: return value.sp.toDouble();
    }
  }
}