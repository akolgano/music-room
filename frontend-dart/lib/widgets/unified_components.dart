// lib/widgets/unified_components.dart
import 'package:flutter/material.dart';
import '../core/consolidated_core.dart';
import '../models/models.dart';
import 'app_widgets.dart';

class UnifiedComponents {
  static Widget sectionTitle(String title) => AppWidgets.sectionTitle(title);

  static Widget featureCard({
    required IconData icon,
    required String title,
    required String description,
    VoidCallback? onTap,
  }) => AppWidgets.featureCard(
    icon: icon,
    title: title,
    description: description,
    onTap: onTap,
  );

  static Widget playlistCard({
    required Playlist playlist,
    required VoidCallback? onTap,
    VoidCallback? onPlay,
    bool showPlayButton = false,
  }) => AppWidgets.playlistCard(
    playlist: playlist,
    onTap: onTap,
    onPlay: onPlay,
    showPlayButton: showPlayButton,
  );

  static Widget settingsSection({
    required String title,
    required List<Widget> items,
  }) => AppWidgets.settingsSection(
    title: title,
    items: items,
  );

  static Widget settingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color color = Colors.white,
  }) => AppWidgets.settingsItem(
    icon: icon,
    title: title,
    subtitle: subtitle,
    onTap: onTap,
    color: color,
  );

  static Widget emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) => AppWidgets.emptyState(
    icon: icon,
    title: title,
    subtitle: subtitle,
    buttonText: buttonText,
    onButtonPressed: onButtonPressed,
  );
}
