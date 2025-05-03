// screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/scheduler.dart';
import 'events_tab.dart';
import 'playlists_tab.dart';
import '../profile/profile_screen.dart';
import '../music/public_playlists_screen.dart';
import '../music/control_delegation_screen.dart';
import '../music/track_vote_screen.dart';
import '../music/enhanced_playlist_editor_screen.dart';
import '../all_screens_demo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';

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
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }
  
  Future<void> _loadData() async {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    await musicProvider.fetchPublicPlaylists();
    
    if (authProvider.token != null && authProvider.userId != null) {
      await musicProvider.fetchUserPlaylists(authProvider.token!);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.indigo,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.music_note,
                      size: 30,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Music Room',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    authProvider.username ?? 'Guest',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.playlist_play),
              title: Text('My Playlists'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.public),
              title: Text('Discover Public Playlists'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/public_playlists');
              },
            ),
            ListTile(
              leading: Icon(Icons.how_to_vote),
              title: Text('Track Voting'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/track_vote');
              },
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Control Delegation'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/control_delegation');
              },
            ),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Create New Playlist'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/enhanced_playlist_editor');
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Settings will be implemented in the future'),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.apps),
              title: Text('All Screens Demo'),
              subtitle: Text('Access all app screens'),
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
          ],
        ),
      ),
      body: Column(
        children: [
          if (musicProvider.hasConnectionError)
            Container(
              width: double.infinity,
              color: musicProvider.isRetrying ? Colors.blue.shade100 : Colors.red.shade100,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    musicProvider.isRetrying ? Icons.refresh : Icons.error_outline,
                    color: musicProvider.isRetrying ? Colors.blue : Colors.red,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      musicProvider.isRetrying 
                          ? 'Retrying connection... (${musicProvider.errorMessage})' 
                          : 'Connection error: ${musicProvider.errorMessage}',
                      style: TextStyle(
                        color: musicProvider.isRetrying ? Colors.blue.shade900 : Colors.red.shade900
                      ),
                    ),
                  ),
                  if (!musicProvider.isRetrying)
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.red.shade900),
                      onPressed: () {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        if (authProvider.isLoggedIn && authProvider.token != null) {
                          musicProvider.fetchUserPlaylists(authProvider.token!);
                        } else {
                          musicProvider.fetchPublicPlaylists();
                        }
                      },
                    ),
                  if (musicProvider.isRetrying)
                    SizedBox(
                      width: 24, 
                      height: 24, 
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamed('/track_vote');
            },
            child: const Text('Create Sample Event'),
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
        content: const Text('How would you like to create your playlist?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamed('/enhanced_playlist_editor');
            },
            child: const Text('Enhanced Editor'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamed('/playlist_editor');
            },
            child: const Text('Simple Editor'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamed('/track_selection');
            },
            child: const Text('Track Selection'),
          ),
        ],
      ),
    );
  }
}
