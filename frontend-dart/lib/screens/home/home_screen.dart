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
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showSnackBar('Notifications coming soon!'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
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
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.playlistEditor),
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.add, color: Colors.black),
            ) : null,
    );
  }

  Widget _buildConnectionErrorBar(MusicProvider musicProvider) {
    return Container(
      width: double.infinity,
      color: musicProvider.isRetrying ? AppTheme.primary.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(musicProvider.isRetrying ? Icons.refresh : Icons.error_outline,
               color: musicProvider.isRetrying ? AppTheme.primary : AppTheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              musicProvider.isRetrying 
                  ? 'Retrying connection...' 
                  : 'Connection error: ${musicProvider.errorMessage}',
              style: TextStyle(color: musicProvider.isRetrying ? AppTheme.primary : AppTheme.error),
            ),
          ),
          if (!musicProvider.isRetrying)
            IconButton(
              icon: Icon(Icons.refresh, color: AppTheme.error),
              onPressed: () {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                if (authProvider.token != null) {
                  musicProvider.fetchUserPlaylists(authProvider.token!);
                }
              },
            ),
          if (musicProvider.isRetrying)
            const SizedBox(
              width: 24, height: 24, 
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary)),
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
                Text(authProvider.username ?? 'Guest', 
                     style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14)),
              ],
            ),
          ),
          ..._buildDrawerItems(authProvider, musicProvider),
        ],
      ),
    );
  }

  List<Widget> _buildDrawerItems(AuthProvider authProvider, MusicProvider musicProvider) {
    final items = [
      _DrawerItem(Icons.home, 'Home', selected: _selectedIndex == 0, 
                  onTap: () => _selectTab(0)),
      _DrawerItem(Icons.library_music, 'Your Library', selected: _selectedIndex == 1, 
                  onTap: () => _selectTab(1)),
      const Divider(color: AppTheme.surfaceVariant),
      _DrawerItem(Icons.public, 'Discover Playlists', 
                  onTap: () => _navigateAndPop(AppRoutes.publicPlaylists)),
      _DrawerItem(Icons.how_to_vote, 'Track Voting', 
                  onTap: () => _navigateAndPop(AppRoutes.trackVote)),
      _DrawerItem(Icons.people, 'Control Delegation', 
                  onTap: () => _navigateAndPop(AppRoutes.controlDelegation)),
      _DrawerItem(Icons.add, 'Create Playlist', 
                  onTap: () => _navigateAndPop(AppRoutes.playlistEditor)),
      const Divider(color: AppTheme.surfaceVariant),
      _DrawerItem(Icons.person, 'Profile', selected: _selectedIndex == 2, 
                  onTap: () => _selectTab(2)),
      _DrawerItem(Icons.settings, 'Settings', 
                  onTap: () => _showSnackBar('Settings coming soon!')),
      const Divider(color: AppTheme.surfaceVariant),
      _DrawerItem(Icons.people, 'Friends', 
                  subtitle: 'Connect with other users',
                  onTap: () => _navigateAndPop(AppRoutes.friends)),
      const Divider(color: AppTheme.surfaceVariant),
      _DrawerItem(Icons.logout, 'Logout', 
                  onTap: () => _showLogoutDialog(authProvider)),
    ];
    
    return items;
  }

  Widget _DrawerItem(IconData icon, String title, {
    String? subtitle,
    bool selected = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: selected ? AppTheme.primary : Colors.white),
      title: Text(title, style: TextStyle(
        color: selected ? AppTheme.primary : Colors.white,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      )),
      subtitle: subtitle != null ? Text(subtitle, 
                                      style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)) : null,
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
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to logout?', 
                           style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              authProvider.logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('LOGOUT'),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
            const Text('Events Coming Soon', style: TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Collaborative music events will be added in a future update', 
                 style: TextStyle(color: Colors.white.withOpacity(0.7)), 
                 textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.musicFeatures),
              child: const Text('Explore Music Features'),
            ),
          ],
        ),
      ),
    );
  }
}
