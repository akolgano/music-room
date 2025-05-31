// lib/widgets/app_navigation_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Drawer(
      backgroundColor: AppTheme.background,
      child: Column(
        children: [
          _buildDrawerHeader(context, authProvider),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSection(
                  'Main',
                  [
                    _buildNavItem(
                      context,
                      icon: Icons.home,
                      title: 'Home',
                      route: AppRoutes.home,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.person,
                      title: 'Profile',
                      route: AppRoutes.profile,
                    ),
                  ],
                ),
                _buildSection(
                  'Music & Playlists',
                  [
                    _buildNavItem(
                      context,
                      icon: Icons.library_music,
                      title: 'My Playlists',
                      route: '/playlists',
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.public,
                      title: 'Public Playlists',
                      route: AppRoutes.publicPlaylists,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.add_circle,
                      title: 'Create Playlist',
                      route: AppRoutes.playlistEditor,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.search,
                      title: 'Search Tracks',
                      route: AppRoutes.trackSearch,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.library_add,
                      title: 'Track Selection',
                      route: AppRoutes.trackSelection,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.play_circle,
                      title: 'Music Player',
                      route: AppRoutes.player,
                    ),
                  ],
                ),
                _buildSection(
                  'Social',
                  [
                    _buildNavItem(
                      context,
                      icon: Icons.people,
                      title: 'Friends',
                      route: AppRoutes.friends,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.person_add,
                      title: 'Add Friend',
                      route: AppRoutes.addFriend,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.notifications,
                      title: 'Friend Requests',
                      route: AppRoutes.friendRequests,
                    ),
                  ],
                ),
                _buildSection(
                  'Advanced Features',
                  [
                    _buildNavItem(
                      context,
                      icon: Icons.featured_play_list,
                      title: 'Music Features',
                      route: AppRoutes.musicFeatures,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.how_to_vote,
                      title: 'Track Voting',
                      route: AppRoutes.trackVote,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.admin_panel_settings,
                      title: 'Control Delegation',
                      route: AppRoutes.controlDelegation,
                    ),
                  ],
                ),
                const Divider(color: AppTheme.surfaceVariant),
                _buildNavItem(
                  context,
                  icon: Icons.logout,
                  title: 'Sign Out',
                  onTap: () => _showLogoutDialog(context, authProvider),
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, AuthProvider authProvider) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      color: AppTheme.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Music Room',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'ID: ${authProvider.userId ?? "Unknown"}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? route,
    VoidCallback? onTap,
    Color? color,
  }) {
    final itemColor = color ?? Colors.white;
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isSelected = currentRoute == route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(
          color: AppTheme.primary.withOpacity(0.3),
        ) : null,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primary 
                : (color?.withOpacity(0.1) ?? AppTheme.surfaceVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected 
                ? Colors.black 
                : (color ?? Colors.white),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppTheme.primary : itemColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: isSelected 
            ? Icon(
                Icons.chevron_right,
                color: AppTheme.primary,
              )
            : null,
        onTap: onTap ?? () {
          if (route != null) {
            Navigator.of(context).pushNamed(route);
          }
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); 
              authProvider.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
