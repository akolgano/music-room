// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/core.dart';
import '../../widgets/app_widgets.dart';
import '../../models/models.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.trackSearch),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AppWidgets.tabScaffold(
              tabs: const [
                Tab(icon: Icon(Icons.home), text: 'Home'),
                Tab(icon: Icon(Icons.library_music), text: 'Library'),
                Tab(icon: Icon(Icons.person), text: 'Profile'),
              ],
              tabViews: [_buildDashboard(auth), _buildPlaylists(), const ProfileScreen(isEmbedded: true)],
              controller: _tabController,
            ),
          ),
          const MiniPlayerWidget(),
        ],
      ),
    );
  }

  Widget _buildDashboard(AuthProvider auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppWidgets.infoBanner(
            title: 'Welcome back, ${auth.displayName}!',
            message: 'Ready to discover and share music?',
            icon: Icons.music_note,
          ),
          const SizedBox(height: 32),
          AppWidgets.sectionTitle('Quick Actions'),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              AppWidgets.quickActionCard(
                title: 'Search Tracks',
                icon: Icons.search,
                color: Colors.blue,
                onTap: () => Navigator.pushNamed(context, AppRoutes.trackSearch),
              ),
              AppWidgets.quickActionCard(
                title: 'Create Playlist',
                icon: Icons.add_circle,
                color: Colors.green,
                onTap: () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
              ),
              AppWidgets.quickActionCard(
                title: 'Find Friends',
                icon: Icons.people,
                color: Colors.purple,
                onTap: () => Navigator.pushNamed(context, AppRoutes.friends),
              ),
              AppWidgets.quickActionCard(
                title: 'Public Playlists',
                icon: Icons.public,
                color: Colors.orange,
                onTap: () => Navigator.pushNamed(context, AppRoutes.publicPlaylists),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylists() {
    return Consumer<MusicProvider>(
      builder: (context, music, _) {
        if (music.isLoading) {
          return AppWidgets.loading('Loading playlists...');
        }

        if (music.playlists.isEmpty) {
          return AppWidgets.emptyState(
            icon: Icons.playlist_play,
            title: 'No playlists yet',
            subtitle: 'Create your first playlist to get started!',
            buttonText: 'Create Playlist',
            onButtonPressed: () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
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
              print('Playlist ID: ${playlist.id}, Name: ${playlist.name}'); 
              
              return AppWidgets.playlistCard(
                playlist: playlist,
                onTap: () {
                  print('Navigating to playlist with ID: ${playlist.id}'); 
                  if (playlist.id.isNotEmpty && playlist.id != 'null') {
                    Navigator.pushNamed(context, AppRoutes.playlistDetail, arguments: playlist.id);
                  } else {
                    _showError('Invalid playlist ID');
                  }
                },
                onPlay: () => _playPlaylist(playlist),
                showPlayButton: true,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _loadData() async {
    try {
      final music = Provider.of<MusicProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      
      if (auth.isLoggedIn && auth.token != null) {
        await Future.wait([
          music.fetchUserPlaylists(auth.token!),
          profileProvider.loadProfile(auth.token),
        ]);
      }
    } catch (e) {
      _showError('Failed to load data: $e');
    }
  }

  void _playPlaylist(Playlist playlist) {
    _showInfo('Playing "${playlist.name}"');
  }

  void _showInfo(String message) {
    AppWidgets.showSnackBar(context, message);
  }

  void _showError(String message) {
    AppWidgets.showSnackBar(context, message, backgroundColor: AppTheme.error);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
