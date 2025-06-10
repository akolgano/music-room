// lib/screens/music/player_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_core.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/dialog_utils.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Music Player'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => DialogUtils.showFeatureComingSoon(context, 'Full Music Player'),
          ),
        ],
      ),
      body: CommonWidgets.emptyState(
        icon: Icons.music_note,
        title: 'Music Player',
        subtitle: 'Full music player functionality coming soon!',
        buttonText: 'Learn More',
        onButtonPressed: () => DialogUtils.showInfoDialog(
          context: context,
          title: 'Music Player Features',
          icon: Icons.music_note,
          message: 'The full music player will include:',
          points: [
            'Full track playback controls',
            'Queue management',
            'Lyrics display',
            'Audio visualizations',
            'Playlist integration',
          ],
          tip: 'Currently you can play track previews from the search screen!',
        ),
      ),
    );
  }
}

class SimpleComingSoonScreen extends StatelessWidget {
  final String title;
  final String feature;
  final IconData icon;

  const SimpleComingSoonScreen({
    Key? key,
    required this.title,
    required this.feature,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(title),
      ),
      body: CommonWidgets.emptyState(
        icon: icon,
        title: title,
        subtitle: 'Coming Soon',
        buttonText: 'Learn More',
        onButtonPressed: () => DialogUtils.showFeatureComingSoon(context, feature),
      ),
    );
  }
}
