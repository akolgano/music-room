// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/app_core.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/snackbar_utils.dart';
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
          InfoBanner(
            title: 'Welcome back, ${auth.displayName}!',
            message: 'Ready to discover and share music?',
            icon: Icons.music_note,
          ),
          const SizedBox(height: 32),
          const SectionTitle('Quick Actions'),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              QuickActionCard(
                title: AppStrings.searchTracks,
                icon: Icons.search,
                color: Colors.blue,
                onTap: () => navigateTo(AppRoutes.trackSearch),
              ),
              QuickActionCard(
                title: AppStrings.createPlaylist,
                icon: Icons.add_circle,
                color: Colors.green,
                onTap: () => navigateTo(AppRoutes.playlistEditor),
              ),
              QuickActionCard(
                title: 'Find Friends',
                icon: Icons.people,
                color: Colors.purple,
                onTap: () => navigateTo(AppRoutes.friends),
              ),
              QuickActionCard(
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
          return buildLoadingState('Loading playlists...');
        }

        if (music.playlists.isEmpty) {
          return EmptyState(
            icon: Icons.playlist_play,
            title: 'No playlists yet',
            subtitle: 'Create your first playlist to get started!',
            buttonText: 'Create Playlist',
            onButtonPressed: () => navigateTo(AppRoutes.playlistEditor),
          );
        }

        return buildListWithRefresh<Playlist>(
          items: music.playlists,
          onRefresh: _loadData,
          itemBuilder: (playlist, index) => PlaylistCard(
            playlist: playlist,
            onTap: () => navigateTo(AppRoutes.playlistEditor, arguments: playlist.id),
            onPlay: () => showInfo('Playing ${playlist.name}'),
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
