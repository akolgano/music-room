// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/friend_provider.dart';
import '../../core/core.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';
import '../profile/profile_screen.dart';
import '../music/track_search_screen.dart';
import '../friends/friends_list_screen.dart';

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
    _tabController = TabController(length: 5, vsync: this); 
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
                Tab(icon: Icon(Icons.search), text: 'Search'),
                Tab(icon: Icon(Icons.people), text: 'Friends'),
                Tab(icon: Icon(Icons.person), text: 'Profile'),
              ],
              tabViews: [
                _buildDashboard(auth),
                _buildPlaylists(),
                const TrackSearchScreen(isEmbedded: true), 
                _buildFriendsTab(),
                const ProfileScreen(isEmbedded: true)
              ],
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
                onTap: () => _tabController.animateTo(2), 
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
                onTap: () => _tabController.animateTo(3), 
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

  Widget _buildFriendsTab() {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, _) {
        if (friendProvider.isLoading) return AppWidgets.loading('Loading friends...');
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppWidgets.infoBanner(
                title: 'Connect with Friends',
                message: 'Add friends to share and collaborate on playlists together!',
                icon: Icons.people,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.addFriend),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Friend'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.friends),
                      icon: const Icon(Icons.list),
                      label: const Text('View All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surface,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppWidgets.sectionTitle('Recent Friends'),
              const SizedBox(height: 16),
              if (friendProvider.friends.isEmpty)
                AppWidgets.emptyState(
                  icon: Icons.people_outline,
                  title: 'No friends yet',
                  subtitle: 'Add some friends to start sharing music!',
                  buttonText: 'Add Friend',
                  onButtonPressed: () => Navigator.pushNamed(context, AppRoutes.addFriend),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: friendProvider.friends.length > 5 ? 5 : friendProvider.friends.length,
                  itemBuilder: (context, index) {
                    final friendId = friendProvider.friends[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: AppTheme.surface,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.primaries[friendId % Colors.primaries.length],
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          'Friend #$friendId',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          'User ID: $friendId',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        trailing: Icon(Icons.music_note, color: AppTheme.primary, size: 20),
                        onTap: () {
                          _showInfo('Friend features coming soon!');
                        },
                      ),
                    );
                  },
                ),
              if (friendProvider.friends.length > 5) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.friends),
                    child: Text('View all ${friendProvider.friends.length} friends',
                      style: const TextStyle(color: AppTheme.primary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadData() async {
    try {
      final music = Provider.of<MusicProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);

      if (auth.isLoggedIn && auth.token != null) {
        await Future.wait([music.fetchUserPlaylists(auth.token!), profileProvider.loadProfile(auth.token),
          friendProvider.fetchFriends(auth.token!),
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
