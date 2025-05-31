// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/unified_widgets.dart';
import '../../widgets/app_navigation_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }
  
  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final music = Provider.of<MusicProvider>(context, listen: false);
    
    if (auth.isLoggedIn && auth.token != null) {
      await music.fetchUserPlaylists(auth.token!);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(_getTitle()),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Dashboard'),
            Tab(icon: Icon(Icons.library_music), text: 'Library'),
            Tab(icon: Icon(Icons.person), text: 'Profile'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.trackSearch),
            tooltip: 'Search Music',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
            tooltip: 'Create Playlist',
          ),
        ],
      ),
      drawer: const AppNavigationDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboard(),
          _buildPlaylists(),
          _buildProfile(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  String _getTitle() {
    return 'Music Room';
  }

  Widget? _buildFloatingActionButton() {
    switch (_tabController.index) {
      case 1: 
        return FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add),
          label: const Text('New Playlist'),
        );
      case 0: 
        return FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.trackSearch),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.black,
          child: const Icon(Icons.search),
          tooltip: 'Search Music',
        );
      default:
        return null;
    }
  }

  Widget _buildDashboard() {
    final auth = Provider.of<AuthProvider>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: AppTheme.primary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.music_note, color: Colors.black, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, ${auth.displayName}!',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Ready to discover and share music?',
                              style: TextStyle(color: Colors.white70),
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
          
          const SizedBox(height: 24),
          
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildQuickActionCard(
                'Search Music',
                Icons.search,
                Colors.blue,
                () => Navigator.pushNamed(context, AppRoutes.trackSearch),
              ),
              _buildQuickActionCard(
                'Create Playlist',
                Icons.add_circle,
                Colors.green,
                () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
              ),
              _buildQuickActionCard(
                'Find Friends',
                Icons.people,
                Colors.purple,
                () => Navigator.pushNamed(context, AppRoutes.friends),
              ),
              _buildQuickActionCard(
                'Public Playlists',
                Icons.public,
                Colors.orange,
                () => Navigator.pushNamed(context, AppRoutes.publicPlaylists),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Card(
            color: AppTheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history, color: AppTheme.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.music_note, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No recent activity',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Start creating playlists to see your activity here',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      color: AppTheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylists() {
    return Consumer<MusicProvider>(
      builder: (context, music, _) {
        if (music.isLoading) {
          return const LoadingWidget(message: 'Loading playlists...');
        }

        if (music.playlists.isEmpty) {
          return const EmptyState(
            icon: Icons.playlist_play,
            title: 'No playlists yet',
            subtitle: 'Create your first playlist to get started',
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: music.playlists.length,
            itemBuilder: (context, index) {
              final playlist = music.playlists[index];
              return PlaylistCard(
                playlist: playlist,
                onTap: () => Navigator.pushNamed(
                  context, 
                  AppRoutes.playlistEditor, 
                  arguments: playlist.id,
                ),
                onPlay: () => showAppSnackBar(context, 'Playing ${playlist.name}'),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProfile() {
    final auth = Provider.of<AuthProvider>(context);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: AppTheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primary,
                  child: Icon(Icons.person, size: 40, color: Colors.black),
                ),
                const SizedBox(height: 16),
                Text(
                  auth.displayName,
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'User ID: ${auth.userId ?? "Unknown"}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildProfileItem(
          Icons.people, 
          'Friends', 
          () => Navigator.pushNamed(context, AppRoutes.friends),
        ),
        _buildProfileItem(
          Icons.featured_play_list, 
          'Music Features', 
          () => Navigator.pushNamed(context, AppRoutes.musicFeatures),
        ),
        _buildProfileItem(
          Icons.settings, 
          'Settings', 
          () => showAppSnackBar(context, 'Coming soon!'),
        ),
        _buildProfileItem(
          Icons.help, 
          'Help', 
          () => showAppSnackBar(context, 'Coming soon!'),
        ),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String title, VoidCallback onTap) {
    return Card(
      color: AppTheme.surface,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
