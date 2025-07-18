import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  bool get isLandscape => MediaQuery.of(context).orientation == Orientation.landscape;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() => _currentIndex = _tabController.index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    if (isLandscape) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _currentIndex == 0 ? AppBar(
          backgroundColor: AppTheme.background,
          title: Text(AppConstants.appName),
          automaticallyImplyLeading: false,
          toolbarHeight: 48,
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
        ) : null,
        body: Row(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        backgroundColor: AppTheme.surface,
                        selectedIndex: _currentIndex,
                        onDestinationSelected: (index) {
                          setState(() {
                            _currentIndex = index;
                            _tabController.index = index;
                          });
                        },
                        labelType: NavigationRailLabelType.all,
                        leading: const SizedBox(height: 8),
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.home_outlined),
                            selectedIcon: Icon(Icons.home),
                            label: Text('Home'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.library_music_outlined),
                            selectedIcon: Icon(Icons.library_music),
                            label: Text('Library'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.search_outlined),
                            selectedIcon: Icon(Icons.search),
                            label: Text('Search'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.people_outline),
                            selectedIcon: Icon(Icons.people),
                            label: Text('Friends'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.person_outline),
                            selectedIcon: Icon(Icons.person),
                            label: Text('Profile'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildDashboard(auth), _buildLibraryWithAppBar(), _buildSearchWithAppBar(),
                        _buildFriendsWithAppBar(),
                        _buildProfileWithAppBar(),
                      ],
                    ),
                  ),
                  const MiniPlayerWidget(),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _currentIndex == 0 ? AppBar(
          backgroundColor: AppTheme.background,
          title: Text(AppConstants.appName),
          automaticallyImplyLeading: false,
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
        ) : null,
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildDashboard(auth), _buildLibraryWithAppBar(), _buildSearchWithAppBar(),
                  _buildFriendsWithAppBar(),
                  _buildProfileWithAppBar(),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border(
                  top: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3), width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primary,
                labelStyle: const TextStyle(fontSize: 12),
                tabs: const [
                  Tab(icon: Icon(Icons.home), text: 'Home'),
                  Tab(icon: Icon(Icons.library_music), text: 'Library'),
                  Tab(icon: Icon(Icons.search), text: 'Search'),
                  Tab(icon: Icon(Icons.people), text: 'Friends'),
                  Tab(icon: Icon(Icons.person), text: 'Profile'),
                ],
              ),
            ),
            const MiniPlayerWidget(),
          ],
        ),
      );
    }
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

  Widget _buildLibraryWithAppBar() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Your Library'),
        automaticallyImplyLeading: false,
        toolbarHeight: isLandscape ? 48 : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
          ),
        ],
      ),
      body: _buildPlaylists(),
    );
  }

  Widget _buildSearchWithAppBar() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: const TrackSearchScreen(isEmbedded: true),
    );
  }

  Widget _buildFriendsWithAppBar() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Friends'),
        automaticallyImplyLeading: false,
        toolbarHeight: isLandscape ? 48 : null,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addFriend),
            icon: const Icon(Icons.person_add, color: AppTheme.primary),
            label: const Text('Add Friend', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
      body: _buildFriendsTab(),
    );
  }

  Widget _buildProfileWithAppBar() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: const ProfileScreen(isEmbedded: true),
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
              if (kDebugMode) {
                developer.log('Playlist ID: ${playlist.id}, Name: ${playlist.name}', name: 'HomeScreen');
              }
              return AppWidgets.playlistCard(
                playlist: playlist,
                onTap: () {
                  if (kDebugMode) {
                    developer.log('Navigating to playlist with ID: ${playlist.id}', name: 'HomeScreen');
                  }
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
        final pendingRequests = friendProvider.receivedInvitations;
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
              if (pendingRequests.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You have ${pendingRequests.length} pending friend request${pendingRequests.length == 1 ? '' : 's'}',
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.friendRequests),
                        child: const Text(
                          'View',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                        subtitle: Text('User ID: $friendId',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        trailing: Icon(Icons.music_note, color: AppTheme.primary, size: 20),
                        onTap: () => _showInfo('Friend features coming soon!'),
                      ),
                    );
                  },
                ),
              if (friendProvider.friends.length > 5) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.friends),
                    child: Text('View all ${friendProvider.friends.length} friends', style: const TextStyle(color: AppTheme.primary)),
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
        await Future.wait([
          music.fetchUserPlaylists(auth.token!), 
          profileProvider.loadProfile(auth.token),
          friendProvider.fetchAllFriendData(auth.token!),
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
