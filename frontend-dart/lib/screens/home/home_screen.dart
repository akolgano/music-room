// screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import 'events_tab.dart';
import 'playlists_tab.dart';
import '../profile/profile_screen.dart';

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
  
  @override
  void initState() {
    super.initState();
    Provider.of<MusicProvider>(context, listen: false).fetchPublicPlaylists();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null && authProvider.userId != null) {
      Provider.of<MusicProvider>(context, listen: false).fetchUserPlaylists(
        authProvider.token!,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Room'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_play),
            label: 'Playlists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedIndex == 0) {
            _showCreateEventDialog(context);
          } else if (_selectedIndex == 1) {
            _showCreatePlaylistDialog(context);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  void _showCreateEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Event'),
        content: const Text('Event creation would be implemented here'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showCreatePlaylistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Playlist'),
        content: const Text('Playlist creation would be implemented here'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
