// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/scheduler.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../models/playlist.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import 'playlists_tab.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const _EventsTab(),
    const PlaylistsTab(),
    const ProfileScreen(),
  ];

  final List<String> _pageTitles = ['Home', 'Library', 'Profile'];

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _loadData());
  }
  
  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    
    if (authProvider.isLoggedIn && authProvider.token != null) {
      await musicProvider.fetchUserPlaylists(authProvider.token!);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final musicProvider = Provider.of<MusicProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(_pageTitles[_selectedIndex], 
                   style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            label: const Text('Alerts', style: TextStyle(color: Colors.white, fontSize: 12)),
            onPressed: () => _showSnackBar('Notifications coming soon!'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.menu, color: Colors.white),
            label: const Text('Menu', style: TextStyle(color: Colors.white, fontSize: 12)),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(authProvider, musicProvider),
      body: Column(
        children: [
          if (musicProvider.hasConnectionError) _buildConnectionErrorBar(musicProvider),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _selectedIndex == 1 
          ? _buildVerboseFloatingActionButton()
          : null,
    );
  }

  Widget _buildVerboseFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.playlistEditor),
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.black,
      icon: const Icon(Icons.add),
      label: const Text('New Playlist'),
      tooltip: 'Create a new playlist',
    );
  }

  Widget _buildConnectionErrorBar(MusicProvider musicProvider) {
    return Container(
      width: double.infinity,
      color: musicProvider.isRetrying ? AppTheme.primary.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(musicProvider.isRetrying ? Icons.refresh : Icons.error_outline,
               color: musicProvider.isRetrying ? AppTheme.primary : AppTheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  musicProvider.isRetrying 
                      ? 'Reconnecting to Music Service...' 
                      : 'Connection Problem',
                  style: TextStyle(
                    color: musicProvider.isRetrying ? AppTheme.primary : AppTheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (!musicProvider.isRetrying)
                  Text(
                    'Unable to connect to the music server. Check your internet connection.',
                    style: TextStyle(
                      color: AppTheme.error,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (!musicProvider.isRetrying)
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
              onPressed: () {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                if (authProvider.token != null) {
                  musicProvider.fetchUserPlaylists(authProvider.token!);
                }
              },
            ),
          if (musicProvider.isRetrying)
            const SizedBox(
              width: 20, height: 20, 
              child: CircularProgressIndicator(
                strokeWidth: 2, 
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildDrawer(AuthProvider authProvider, MusicProvider musicProvider) {
    return Drawer(
      backgroundColor: AppTheme.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.surface),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primary,
                  child: Icon(Icons.music_note, size: 30, color: Colors.black),
                ),
                const SizedBox(height: 10),
                const Text('Music Room', 
                           style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Welcome, ${authProvider.username ?? 'Guest'}!', 
                     style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14)),
              ],
            ),
          ),
          _DrawerItem(
            Icons.home, 
            'Home Dashboard', 
            'Your music overview and activities',
            selected: _selectedIndex == 0, 
            onTap: () => _selectTab(0)
          ),
          _DrawerItem(
            Icons.library_music, 
            'My Music Library', 
            'Browse your playlists and saved music',
            selected: _selectedIndex == 1, 
            onTap: () => _selectTab(1)
          ),
          const Divider(color: AppTheme.surfaceVariant),
          _DrawerItem(
            Icons.public, 
            'Discover Public Playlists', 
            'Explore music shared by other users',
            onTap: () => _navigateAndPop(AppRoutes.publicPlaylists)
          ),
          _DrawerItem(
            Icons.how_to_vote, 
            'Collaborative Voting', 
            'Vote on tracks for group playlists',
            onTap: () => _navigateAndPop(AppRoutes.trackVote)
          ),
          _DrawerItem(
            Icons.admin_panel_settings, 
            'Music Control Sharing', 
            'Let friends control your music',
            onTap: () => _navigateAndPop(AppRoutes.controlDelegation)
          ),
          _DrawerItem(
            Icons.add_circle_outline, 
            'Create New Playlist', 
            'Start building a new music collection',
            onTap: () => _navigateAndPop(AppRoutes.playlistEditor)
          ),
          const Divider(color: AppTheme.surfaceVariant),
          _DrawerItem(
            Icons.person_outline, 
            'My Profile', 
            'View and edit your account settings',
            selected: _selectedIndex == 2, 
            onTap: () => _selectTab(2)
          ),
          _DrawerItem(
            Icons.settings, 
            'App Settings', 
            'Customize your Music Room experience',
            onTap: () => _showSnackBar('Settings menu coming soon!')
          ),
          const Divider(color: AppTheme.surfaceVariant),
          _DrawerItem(
            Icons.people_outline, 
            'Friends & Social', 
            'Connect with other music lovers',
            onTap: () => _navigateAndPop(AppRoutes.friends)
          ),
          const Divider(color: AppTheme.surfaceVariant),
          _DrawerItem(
            Icons.logout, 
            'Sign Out', 
            'Log out of your account',
            onTap: () => _showLogoutDialog(authProvider)
          ),
        ],
      ),
    );
  }

  Widget _DrawerItem(IconData icon, String title, String description, {
    bool selected = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: selected ? AppTheme.primary : Colors.white),
      title: Text(title, style: TextStyle(
        color: selected ? AppTheme.primary : Colors.white,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      )),
      subtitle: Text(description, 
                    style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
      selected: selected,
      onTap: onTap,
    );
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }

  void _navigateAndPop(String route) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }

  void _showLogoutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to sign out?', 
                 style: TextStyle(color: Colors.white)),
            SizedBox(height: 8),
            Text('You\'ll need to sign in again to access your playlists and music.', 
                 style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(), 
            child: const Text('Stay Signed In')
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              authProvider.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.surfaceVariant, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home), 
            label: 'Home',
            tooltip: 'Go to home dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music), 
            label: 'My Library',
            tooltip: 'Browse your music library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), 
            label: 'Profile',
            tooltip: 'View your profile',
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event, size: 64, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('Music Events Coming Soon', 
                       style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Join collaborative music events with friends. Create listening parties, vote on tracks, and share musical experiences together.', 
                 style: TextStyle(color: Colors.white.withOpacity(0.7)), 
                 textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.musicFeatures),
              icon: const Icon(Icons.explore),
              label: const Text('Explore Music Features'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
