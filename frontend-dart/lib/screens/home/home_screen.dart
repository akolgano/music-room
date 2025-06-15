// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/consolidated_core.dart';
import '../../widgets/unified_components.dart';
import '../../models/models.dart';
import '../base_screen.dart';
import '../profile/profile_screen.dart'; 

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
      onPressed: () => navigateTo(AppRoutes.trackSearch),
    ),
    IconButton(
      icon: const Icon(Icons.add),
      onPressed: () => navigateTo(AppRoutes.playlistEditor),
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  Widget buildContent() {
    return buildTabScaffold(
      tabs: const [
        Tab(icon: Icon(Icons.home), text: 'Home'),
        Tab(icon: Icon(Icons.library_music), text: 'Library'),
        Tab(icon: Icon(Icons.person), text: 'Profile'),
      ],
      tabViews: [
        _buildDashboard(),
        _buildPlaylists(),
        const ProfileScreen(isEmbedded: true),
      ],
      controller: _tabController,
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: AppSizes.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UnifiedComponents.infoBanner(
            title: 'Welcome back, ${auth.displayName}!',
            message: 'Ready to discover and share music?',
            icon: Icons.music_note,
          ),
          const SizedBox(height: 32),
          UnifiedComponents.sectionTitle('Quick Actions'),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              UnifiedComponents.quickActionCard(
                title: AppStrings.searchTracks,
                icon: Icons.search,
                color: Colors.blue,
                onTap: () => navigateTo(AppRoutes.trackSearch),
              ),
              UnifiedComponents.quickActionCard(
                title: AppStrings.createPlaylist,
                icon: Icons.add_circle,
                color: Colors.green,
                onTap: () => navigateTo(AppRoutes.playlistEditor),
              ),
              UnifiedComponents.quickActionCard(
                title: 'Find Friends',
                icon: Icons.people,
                color: Colors.purple,
                onTap: () => navigateTo(AppRoutes.friends),
              ),
              UnifiedComponents.quickActionCard(
                title: AppStrings.publicPlaylists,
                icon: Icons.public,
                color: Colors.orange,
                onTap: () => navigateTo(AppRoutes.publicPlaylists),
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.primary),
                SizedBox(height: 16),
                Text('Loading playlists...', style: TextStyle(color: Colors.white)),
              ],
            ),
          );
        }

        if (music.playlists.isEmpty) {
          return UnifiedComponents.emptyState(
            icon: Icons.playlist_play,
            title: 'No playlists yet',
            subtitle: 'Create your first playlist to get started!',
            buttonText: 'Create Playlist',
            onButtonPressed: () => navigateTo(AppRoutes.playlistEditor),
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
              return UnifiedComponents.playlistCard(
                playlist: playlist,
                onTap: () => navigateTo(AppRoutes.playlistEditor, arguments: playlist.id),
                onPlay: () => showInfo('Playing ${playlist.name}'),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _loadData() async {
    await runAsyncAction(
      () async {
        final music = Provider.of<MusicProvider>(context, listen: false);
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
        
        if (auth.isLoggedIn && auth.token != null) {
          await music.fetchUserPlaylists(auth.token!);
        }
        await profileProvider.loadProfile(auth.token);
      },
      errorMessage: 'Failed to load data',
    );
  }
}
