// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../core/app_core.dart';
import '../../widgets/app_widgets.dart';
import '../base_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends BaseScreen<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  String get screenTitle => AppConstants.appName;
  
  @override
  List<Widget> get actions => [
    IconButton(
      icon: const Icon(Icons.search),
      onPressed: () => Navigator.pushNamed(context, AppRoutes.trackSearch),
    ),
    IconButton(
      icon: const Icon(Icons.add),
      onPressed: () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }
  
  Future<void> _loadData() async {
    final music = Provider.of<MusicProvider>(context, listen: false);
    if (auth.isLoggedIn && auth.token != null) {
      await music.fetchUserPlaylists(auth.token!);
    }
  }

  @override
  PreferredSizeWidget? buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.background,
      title: Text(screenTitle),
      bottom: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primary,
        tabs: const [
          Tab(icon: Icon(Icons.home), text: 'Home'),
          Tab(icon: Icon(Icons.library_music), text: 'Library'),
          Tab(icon: Icon(Icons.person), text: 'Profile'),
        ],
      ),
      actions: actions,
    );
  }
  
  @override
  Widget buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildDashboard(),
        _buildPlaylists(),
        _buildProfile(),
      ],
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: AppTheme.primary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.music_note, color: AppTheme.primary, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${auth.displayName}!',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const Text(
                          'Ready to discover and share music?',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _buildQuickActionCard(AppStrings.searchTracks, Icons.search, Colors.blue,
                  () => Navigator.pushNamed(context, AppRoutes.trackSearch)),
              _buildQuickActionCard(AppStrings.createPlaylist, Icons.add_circle, Colors.green,
                  () => Navigator.pushNamed(context, AppRoutes.playlistEditor)),
              _buildQuickActionCard('Find Friends', Icons.people, Colors.purple,
                  () => Navigator.pushNamed(context, AppRoutes.friends)),
              _buildQuickActionCard(AppStrings.publicPlaylists, Icons.public, Colors.orange,
                  () => Navigator.pushNamed(context, AppRoutes.publicPlaylists)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      color: AppTheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
            subtitle: 'Create your first playlist to get started!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: music.playlists.length,
          itemBuilder: (context, index) {
            final playlist = music.playlists[index];
            return PlaylistCard(
              playlist: playlist,
              onTap: () => Navigator.pushNamed(context, AppRoutes.playlistEditor, arguments: playlist.id),
              onPlay: () => SnackBarUtils.showInfo(context, 'Playing ${playlist.name}'),
            );
          },
        );
      },
    );
  }

  Widget _buildProfile() {
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
                  radius: 50,
                  backgroundColor: AppTheme.primary,
                  child: Icon(Icons.person, size: 50, color: Colors.black),
                ),
                const SizedBox(height: 16),
                Text(
                  auth.displayName,
                  style: const TextStyle(fontSize: 24, color: Colors.white),
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
        _buildProfileItem(Icons.people, AppStrings.friends,
            () => Navigator.pushNamed(context, AppRoutes.friends)),
        _buildProfileItem(Icons.settings, 'Settings',
            () => SnackBarUtils.showInfo(context, AppStrings.featureComingSoon)),
        _buildProfileItem(Icons.help, 'Help',
            () => SnackBarUtils.showInfo(context, AppStrings.featureComingSoon)),
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
