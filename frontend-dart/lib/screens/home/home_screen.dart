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
import 'events_tab.dart';
import '../profile/profile_screen.dart';
import '../playlists/public_playlists_screen.dart';
import '../music/control_delegation_screen.dart';
import '../music/track_vote_screen.dart';
import '../music/playlist_editor_screen.dart';
import '../all_screens_demo.dart';

class MusicColors {
  static const Color primary = Color(0xFF1DB954);
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF282828);
  static const Color surfaceVariant = Color(0xFF333333);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFFB3B3B3);
  static const Color error = Color(0xFFE91429);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const EventsTab(),
    const PlaylistsTab(),
    const ProfileScreen(),
  ];

  final List<String> _pageTitles = [
    'Home',
    'Library',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }
  
  Future<void> _loadData() async {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.token != null && authProvider.userId != null) {
      await musicProvider.fetchUserPlaylists(authProvider.token!);
      await musicProvider.fetchPublicPlaylists(authProvider.token!);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: MusicColors.background,
      appBar: AppBar(
        backgroundColor: MusicColors.background,
        elevation: 0,
        title: Text(
          _pageTitles[_selectedIndex],
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications will be implemented in the future'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
          ),
        ],
      ),
      drawer: _buildDrawer(authProvider),
      body: Column(
        children: [
          if (musicProvider.hasConnectionError)
            Container(
              width: double.infinity,
              color: musicProvider.isRetrying
                  ? MusicColors.primary.withOpacity(0.1)
                  : MusicColors.error.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    musicProvider.isRetrying ? Icons.refresh : Icons.error_outline,
                    color: musicProvider.isRetrying ? MusicColors.primary : MusicColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      musicProvider.isRetrying 
                          ? 'Retrying connection... (${musicProvider.errorMessage})' 
                          : 'Connection error: ${musicProvider.errorMessage}',
                      style: TextStyle(
                        color: musicProvider.isRetrying ? MusicColors.primary : MusicColors.error,
                      ),
                    ),
                  ),
                  if (!musicProvider.isRetrying)
                    IconButton(
                      icon: Icon(Icons.refresh, color: MusicColors.error),
                      onPressed: () {
                        if (authProvider.isLoggedIn && authProvider.token != null) {
                          musicProvider.fetchUserPlaylists(authProvider.token!);
                        }
                      },
                    ),
                  if (musicProvider.isRetrying)
                    SizedBox(
                      width: 24, 
                      height: 24, 
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(MusicColors.primary),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _selectedIndex == 1 
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.playlistEditor);
              },
              backgroundColor: MusicColors.primary,
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }
  
  Widget _buildDrawer(AuthProvider authProvider) {
    return Drawer(
      backgroundColor: MusicColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: MusicColors.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: MusicColors.primary,
                  child: Icon(
                    Icons.music_note,
                    size: 30,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Music Room',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  authProvider.username ?? 'Guest',
                  style: const TextStyle(
                    color: MusicColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.home,
            title: 'Home',
            selected: _selectedIndex == 0,
            onTap: () {
              setState(() {
                _selectedIndex = 0;
              });
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            icon: Icons.library_music,
            title: 'Your Library',
            selected: _selectedIndex == 1,
            onTap: () {
              setState(() {
                _selectedIndex = 1;
              });
              Navigator.pop(context);
            },
          ),
          const Divider(color: MusicColors.surfaceVariant),
          _buildDrawerItem(
            icon: Icons.public,
            title: 'Discover Playlists',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.publicPlaylists);
            },
          ),
          _buildDrawerItem(
            icon: Icons.how_to_vote,
            title: 'Track Voting',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.trackVote);
            },
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Control Delegation',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.controlDelegation);
            },
          ),
          _buildDrawerItem(
            icon: Icons.add,
            title: 'Create Playlist',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.playlistEditor);
            },
          ),
          const Divider(color: MusicColors.surfaceVariant),
          _buildDrawerItem(
            icon: Icons.person,
            title: 'Profile',
            selected: _selectedIndex == 2,
            onTap: () {
              setState(() {
                _selectedIndex = 2;
              });
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Settings will be implemented in the future'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const Divider(color: MusicColors.surfaceVariant),
          _buildDrawerItem(
            icon: Icons.apps,
            title: 'All Screens Demo',
            subtitle: 'Access all app screens',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllScreensDemo(),
                ),
              );
            },
          ),
        const Divider(color: MusicColors.surfaceVariant),
        _buildDrawerItem(
          icon: Icons.people,
          title: 'Friends',
          subtitle: 'Connect with other users',
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.friends);
          },
        ),
        _buildDrawerItem(
          icon: Icons.person_add,
          title: 'Add Friend',
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.addFriend);
          },
        ),
        _buildDrawerItem(
          icon: Icons.notifications,
          title: 'Friend Requests',
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.friendRequests);
          },
        ),
          const Divider(color: MusicColors.surfaceVariant),
          _buildDrawerItem(
            icon: Icons.api,
            title: 'API Documentation',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.apiDocs);
            },
          ),
          const Divider(color: MusicColors.surfaceVariant),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: MusicColors.surface,
                  title: const Text('Logout', style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'Are you sure you want to logout?',
                    style: TextStyle(color: Colors.white),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                        Provider.of<AuthProvider>(context, listen: false).logout();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: MusicColors.error,
                      ),
                      child: const Text('LOGOUT'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    bool selected = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? MusicColors.primary : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? MusicColors.primary : Colors.white,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: MusicColors.onSurfaceVariant,
                fontSize: 12,
              ),
            )
          : null,
      selected: selected,
      onTap: onTap,
    );
  }
  
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: MusicColors.surface,
        border: Border(
          top: BorderSide(
            color: MusicColors.surfaceVariant,
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: MusicColors.surface,
        selectedItemColor: MusicColors.primary,
        unselectedItemColor: MusicColors.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
