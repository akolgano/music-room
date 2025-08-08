import '../../core/logging_navigation_observer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/friend_provider.dart';
import '../../core/theme_utils.dart';
import '../../core/responsive_utils.dart';
import '../../core/constants.dart';
import '../../core/user_action_logging_mixin.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/scrollbar.dart';
import '../../models/music_models.dart';
import '../profile/profile_screen.dart';
import '../music/track_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, UserActionLoggingMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  bool get isLandscape => MediaQuery.of(context).orientation == Orientation.landscape;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        final newIndex = _tabController.index;
        final tabNames = ['Home', 'Playlists', 'Search', 'Friends', 'Profile'];
        logButtonClick('tab_${tabNames[newIndex].toLowerCase()}', metadata: {
          'previous_tab': _currentIndex,
          'new_tab': newIndex,
          'tab_name': tabNames[newIndex],
        });
        setState(() => _currentIndex = newIndex);
      }
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
          toolbarHeight: MusicAppResponsive.isVerySmall(context) ? 40 : 48,
          actions: [
            buildLoggingIconButton(
              icon: Icon(Icons.search, size: ThemeUtils.getResponsiveIconSize(context)),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.trackSearch),
              buttonName: 'search_icon_header',
            ),
            buildLoggingIconButton(
              icon: Icon(Icons.add, size: ThemeUtils.getResponsiveIconSize(context)),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
              buttonName: 'add_playlist_icon_header',
            ),
          ],
        ) : null,
        body: Row(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return CustomSingleChildScrollView(
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
            buildLoggingIconButton(
              icon: Icon(Icons.search, size: ThemeUtils.getResponsiveIconSize(context)),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.trackSearch),
              buttonName: 'search_icon_header',
            ),
            buildLoggingIconButton(
              icon: Icon(Icons.add, size: ThemeUtils.getResponsiveIconSize(context)),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
              buttonName: 'add_playlist_icon_header',
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
                labelStyle: ThemeUtils.getCaptionStyle(context),
                tabs: [
                  Tab(icon: Icon(Icons.home, size: ThemeUtils.getResponsiveIconSize(context)), text: 'Home'),
                  Tab(icon: Icon(Icons.library_music, size: ThemeUtils.getResponsiveIconSize(context)), text: 'Library'),
                  Tab(icon: Icon(Icons.search, size: ThemeUtils.getResponsiveIconSize(context)), text: 'Search'),
                  Tab(icon: Icon(Icons.people, size: ThemeUtils.getResponsiveIconSize(context)), text: 'Friends'),
                  Tab(icon: Icon(Icons.person, size: ThemeUtils.getResponsiveIconSize(context)), text: 'Profile'),
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
    return CustomSingleChildScrollView(
      padding: EdgeInsets.all(ThemeUtils.getResponsivePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: ThemeUtils.getResponsiveGridColumns(context),
            mainAxisSpacing: ThemeUtils.getResponsiveMargin(context),
            crossAxisSpacing: ThemeUtils.getResponsiveMargin(context),
            children: [
              AppWidgets.quickActionCard(
                title: 'Search Tracks',
                icon: Icons.search,
                color: Colors.blue,
                onTap: () {
                  logButtonClick('quick_action_search_tracks', metadata: {'action': 'search_tracks'});
                  _tabController.animateTo(2);
                },
              ),
              AppWidgets.quickActionCard(
                title: 'Create Playlist',
                icon: Icons.add_circle,
                color: Colors.green,
                onTap: () {
                  logButtonClick('quick_action_create_playlist', metadata: {'action': 'create_playlist'});
                  Navigator.pushNamed(context, AppRoutes.playlistEditor);
                },
              ),
              AppWidgets.quickActionCard(
                title: 'Find Friends',
                icon: Icons.people,
                color: Colors.purple,
                onTap: () {
                  logButtonClick('quick_action_find_friends', metadata: {'action': 'find_friends'});
                  _tabController.animateTo(3);
                },
              ),
              AppWidgets.quickActionCard(
                title: 'Public Playlists',
                icon: Icons.public,
                color: Colors.orange,
                onTap: () {
                  logButtonClick('quick_action_public_playlists', metadata: {'action': 'public_playlists'});
                  Navigator.pushNamed(context, AppRoutes.publicPlaylists);
                },
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
        toolbarHeight: isLandscape ? (MusicAppResponsive.isVerySmall(context) ? 40 : 48) : null,
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
        toolbarHeight: isLandscape ? (MusicAppResponsive.isVerySmall(context) ? 40 : 48) : null,
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
          child: CustomListView(
            padding: EdgeInsets.all(ThemeUtils.getResponsivePadding(context)),
            children: music.playlists.map((playlist) {
              AppLogger.debug('Playlist ID: ${playlist.id}, Name: ${playlist.name}', 'HomeScreen');
              return AppWidgets.playlistCard(
                playlist: playlist,
                onTap: () {
                  AppLogger.debug('Navigating to playlist with ID: ${playlist.id}', 'HomeScreen');
                  if (playlist.id.isNotEmpty && playlist.id != 'null') {
                    Navigator.pushNamed(context, AppRoutes.playlistDetail, arguments: playlist.id);
                  } else {
                    _showError('Invalid playlist ID');
                  }
                },
                onPlay: () => _playPlaylist(playlist),
                showPlayButton: true,
              );
            }).toList(),
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
        return CustomSingleChildScrollView(
          padding: EdgeInsets.all(ThemeUtils.getResponsivePadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppWidgets.infoBanner(
                title: 'Connect with Friends',
                message: 'Add friends to share and collaborate on playlists together!',
                icon: Icons.people,
              ),
              SizedBox(height: ThemeUtils.getResponsivePadding(context) * 2),
              if (pendingRequests.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.all(ThemeUtils.getResponsivePadding(context)),
                  margin: EdgeInsets.only(bottom: ThemeUtils.getResponsivePadding(context)),
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
                      buildLoggingTextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.friendRequests),
                        child: const Text(
                          'View',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                        buttonName: 'view_friend_requests_notification',
                        metadata: {'pending_requests_count': pendingRequests.length},
                      ),
                    ],
                  ),
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: buildLoggingElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.addFriend),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_add),
                          SizedBox(width: 8),
                          Text('Add Friend'),
                        ],
                      ),
                      buttonName: 'add_friend_button_friends_section',
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildLoggingElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.friends),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.list),
                          SizedBox(width: 8),
                          Text('View All'),
                        ],
                      ),
                      buttonName: 'view_all_friends_button',
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surface,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 6),
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
                      margin: const EdgeInsets.only(bottom: 4),
                      color: AppTheme.surface,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ThemeUtils.getColorFromString(friendId),
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
