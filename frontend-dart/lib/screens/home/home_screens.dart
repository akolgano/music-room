import '../../core/navigation_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_providers.dart';
import '../../providers/music_providers.dart';
import '../../providers/profile_providers.dart';
import '../../providers/friend_providers.dart';
import '../../services/player_services.dart';
import '../../core/locator_core.dart';
import '../../core/theme_core.dart';
import '../../core/responsive_core.dart';
import '../../core/constants_core.dart';
import '../../core/logging_core.dart';
import '../../core/animations_core.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/status_widgets.dart';
import '../../models/music_models.dart';
import '../profile/profile_screens.dart';
import '../music/search_music.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, UserActionLoggingMixin, WidgetsBindingObserver {
  late TabController _tabController;
  int _currentIndex = 0;
  bool _isInitialLoading = true;
  DateTime? _lastPlaylistRefresh;
  bool get isLandscape => MediaQuery.of(context).orientation == Orientation.landscape;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    _currentIndex = 0;
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        final newIndex = _tabController.index;
        final tabNames = ['Playlists', 'Search', 'Friends', 'Profile'];
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
    if (isLandscape) {
      return ConnectionStatusBanner(
        child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: null,
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
                            icon: Icon(Icons.library_music_outlined),
                            selectedIcon: Icon(Icons.library_music),
                            label: Text('Playlists'),
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
                      children: [_buildPlaylistsWithAppBar(), _buildSearchWithAppBar(),
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
        ),
      );
    } else {
      return ConnectionStatusBanner(
        child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: null,
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildPlaylistsWithAppBar(), _buildSearchWithAppBar(),
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
                  Tab(icon: Icon(Icons.library_music, size: ThemeUtils.getResponsiveIconSize(context)), text: 'Playlists'),
                  Tab(icon: Icon(Icons.search, size: ThemeUtils.getResponsiveIconSize(context)), text: 'Search'),
                  Tab(icon: Icon(Icons.people, size: ThemeUtils.getResponsiveIconSize(context)), text: 'Friends'),
                  Tab(icon: Icon(Icons.person, size: ThemeUtils.getResponsiveIconSize(context)), text: 'Profile'),
                ],
              ),
            ),
            const MiniPlayerWidget(),
          ],
        ),
        ),
      );
    }
  }

  Widget _buildPlaylistsWithAppBar() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Music Room'),
        automaticallyImplyLeading: false,
        toolbarHeight: isLandscape ? (MusicAppResponsive.isSmallScreen(context) ? 40 : 48) : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
          ),
        ],
      ),
      body: _buildCombinedHomeAndPlaylists(),
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
        toolbarHeight: isLandscape ? (MusicAppResponsive.isSmallScreen(context) ? 40 : 48) : null,
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

  Widget _buildPlaylistCard(Playlist playlist, bool isOwn) {
    IconData leadingIcon;
    Color iconColor;
    String typeLabel;
    
    if (isOwn) {
      leadingIcon = Icons.library_music;
      iconColor = AppTheme.primary;
      typeLabel = playlist.isPublic ? 'Your Public Playlist' : 'Your Private Playlist';
    } else {
      leadingIcon = playlist.isPublic ? Icons.public : Icons.people;
      iconColor = playlist.isPublic ? Colors.blue : Colors.purple;
      typeLabel = playlist.isPublic ? 'Public Playlist' : 'Shared Playlist';
    }
    
    return Card(
      margin: EdgeInsets.only(bottom: ThemeUtils.getResponsiveMargin(context)),
      color: AppTheme.surface,
      child: ListTile(
        leading: Container(
          width: 56,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(leadingIcon, color: iconColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                playlist.name, 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
            if (!isOwn) ...[
              const SizedBox(width: 8),
              Icon(
                playlist.isPublic ? Icons.public : Icons.people,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${playlist.tracks.length} tracks',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              isOwn ? typeLabel : 'by ${playlist.creator}',
              style: TextStyle(
                color: iconColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PulsingContainer(
          child: IconButton(
            icon: PulsingIcon(
              icon: Icons.play_arrow,
              size: 24,
            ),
            onPressed: () => _playPlaylist(playlist),
          ),
        ),
        onTap: () {
          AppLogger.debug('Navigating to playlist with ID: ${playlist.id}', 'HomeScreen');
          if (playlist.id.isNotEmpty && playlist.id != 'null') {
            Navigator.pushNamed(context, AppRoutes.playlistDetail, arguments: playlist.id);
          } else {
            _showError('Invalid playlist ID');
          }
        },
      ),
    );
  }

  List<Widget> _buildOrganizedPlaylists(List<Playlist> playlists, String? currentUsername) {
    final ownPlaylists = playlists.where((p) => p.creator == currentUsername).toList();
    final publicPlaylists = playlists.where((p) => p.creator != currentUsername && p.isPublic).toList();
    final sharedPlaylists = playlists.where((p) => p.creator != currentUsername && !p.isPublic).toList();
    
    final widgets = <Widget>[];
    
    if (ownPlaylists.isNotEmpty) {
      widgets.add(AppWidgets.sectionTitle('Your Playlists'));
      widgets.add(const SizedBox(height: 8));
      widgets.addAll(ownPlaylists.map((playlist) => _buildPlaylistCard(playlist, true)));
      widgets.add(const SizedBox(height: 16));
    }
    
    if (publicPlaylists.isNotEmpty) {
      widgets.add(AppWidgets.sectionTitle('Public Playlists'));
      widgets.add(const SizedBox(height: 8));
      widgets.addAll(publicPlaylists.map((playlist) => _buildPlaylistCard(playlist, false)));
      widgets.add(const SizedBox(height: 16));
    }
    
    if (sharedPlaylists.isNotEmpty) {
      widgets.add(AppWidgets.sectionTitle('Friend Shared Playlists'));
      widgets.add(const SizedBox(height: 8));
      widgets.addAll(sharedPlaylists.map((playlist) => _buildPlaylistCard(playlist, false)));
    }
    
    return widgets;
  }

  Widget _buildCombinedHomeAndPlaylists() {
    return Consumer<MusicProvider>(
      builder: (context, music, _) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        
        if (music.isLoading || _isInitialLoading) {
          return AppWidgets.loading('Loading your music room...');
        }
        
        return RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primary,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ThemeUtils.getResponsivePadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(auth),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                if (music.playlists.isEmpty)
                  _buildEmptyPlaylistsState()
                else
                  ..._buildOrganizedPlaylists(music.playlists, auth.username),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.2),
            AppTheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${auth.username ?? 'Music Lover'}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Discover, create, and share your favorite playlists',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.music_note,
            color: AppTheme.primary,
            size: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: PulsingContainer(
                child: Card(
                  color: AppTheme.surface,
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.add, color: AppTheme.primary, size: 32),
                          const SizedBox(height: 8),
                          const Text(
                            'Create Playlist',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                color: AppTheme.surface,
                child: InkWell(
                  onTap: () => _tabController.animateTo(1),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.search, color: AppTheme.primary, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'Search Music',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyPlaylistsState() {
    return AppWidgets.emptyState(
      icon: Icons.playlist_play,
      title: 'No playlists found',
      subtitle: 'Create your first playlist to get started!',
      buttonText: 'Create Playlist',
      onButtonPressed: () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
    );
  }

  Widget _buildFriendsTab() {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, _) {
        if (friendProvider.isLoading) return AppWidgets.loading('Loading friends...');
        final pendingRequests = friendProvider.receivedInvitations;
        return SingleChildScrollView(
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
                      buildLoggingButton<TextButton>(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.friendRequests),
                        child: const Text(
                          'View',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                        buttonName: 'view_friend_requests_notification',
                        buttonBuilder: ({required onPressed, required child, style}) => 
                            TextButton(onPressed: onPressed, style: style, child: child),
                        metadata: {'pending_requests_count': pendingRequests.length},
                      ),
                    ],
                  ),
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: PulsingContainer(
                      child: buildLoggingButton<ElevatedButton>(
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_add),
                            SizedBox(width: 8),
                            Text('Add Friend'),
                          ],
                        ),
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.addFriend),
                        buttonName: 'add_friend_button_friends_section',
                        buttonBuilder: ({required onPressed, required child, style}) => 
                            ElevatedButton(onPressed: onPressed, style: style, child: child),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildLoggingButton<ElevatedButton>(
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.list),
                          SizedBox(width: 8),
                          Text('View All'),
                        ],
                      ),
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.friends),
                      buttonName: 'view_all_friends_button',
                      buttonBuilder: ({required onPressed, required child, style}) => 
                          ElevatedButton(onPressed: onPressed, style: style, child: child),
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
                    final friend = friendProvider.friends[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      color: AppTheme.surface,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ThemeUtils.getColorFromString(friend.id),
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          friend.username,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text('ID: ${friend.id}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        trailing: Icon(Icons.music_note, color: AppTheme.primary, size: 20),
                        onTap: () => Navigator.pushNamed(
                          context, 
                          AppRoutes.userPage, 
                          arguments: {
                            'userId': friend.id,
                            'username': friend.username,
                          }
                        ),
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
          _loadPlaylistsWithRetry(music, auth.token!), 
          profileProvider.loadProfile(auth.token),
          friendProvider.fetchFriends(auth.token!),
          friendProvider.fetchReceivedInvitations(auth.token!),
          friendProvider.fetchSentInvitations(auth.token!),
        ]);
      }
    } catch (e) {
      AppLogger.error('Failed to load data', e, null, 'HomeScreen');
      _showError('Failed to load data: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _loadPlaylistsWithRetry(MusicProvider music, String token) async {
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 1);

    while (retryCount < maxRetries) {
      try {
        AppLogger.debug('Loading playlists attempt ${retryCount + 1}/$maxRetries', 'HomeScreen');
        await music.fetchAllPlaylists(token);
        _lastPlaylistRefresh = DateTime.now();
        
        if (mounted) {
          setState(() {});
        }
        
        if (music.playlists.isNotEmpty || retryCount == maxRetries - 1) {
          AppLogger.debug('Playlists loaded successfully: ${music.playlists.length} playlists', 'HomeScreen');
          break;
        }
        
        if (music.playlists.isEmpty && retryCount < maxRetries - 1) {
          AppLogger.debug('No playlists found, retrying in ${retryDelay.inSeconds} seconds...', 'HomeScreen');
          retryCount++;
          await Future.delayed(retryDelay);
        } else {
          break;
        }
      } catch (e) {
        retryCount++;
        AppLogger.error('Playlist load attempt $retryCount failed', e, null, 'HomeScreen');
        
        if (retryCount < maxRetries) {
          AppLogger.debug('Retrying playlist load in ${retryDelay.inSeconds} seconds...', 'HomeScreen');
          await Future.delayed(retryDelay);
        } else {
          rethrow;
        }
      }
    }
  }

  void _playPlaylist(Playlist playlist) async {
    if (playlist.tracks.isNotEmpty != true) {
      _showInfo('This playlist is empty or tracks are not loaded');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    try {
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      await musicProvider.fetchPlaylistTracks(playlist.id, token!);
      
      final playlistTracks = musicProvider.playlistTracks;
      if (playlistTracks.isEmpty) {
        _showInfo('This playlist has no tracks to play');
        return;
      }

      final musicPlayerService = getIt<MusicPlayerService>();
      await musicPlayerService.setPlaylistAndPlay(
        playlist: playlistTracks,
        startIndex: 0,
        playlistId: playlist.id,
        authToken: token,
      );
      
      if (mounted) {
        AppWidgets.showSnackBar(context, 'Playing ${playlist.name}', backgroundColor: Colors.green);
      }
    } catch (e) {
      AppLogger.error('Failed to play playlist', e, null, 'HomeScreen');
      if (mounted) {
        _showError('Failed to play playlist: ${e.toString()}');
      }
    }
  }

  void _showInfo(String message) {
    AppWidgets.showSnackBar(context, message);
  }

  void _showError(String message) {
    AppWidgets.showSnackBar(context, message, backgroundColor: AppTheme.error);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refreshPlaylistsIfNeeded();
    }
  }

  void _refreshPlaylistsIfNeeded() {
    if (_lastPlaylistRefresh == null || DateTime.now().difference(_lastPlaylistRefresh!).inSeconds > 30) {
      AppLogger.debug('Auto-refreshing playlists due to app resume', 'HomeScreen');
      final music = Provider.of<MusicProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;
      if (token != null && mounted) {
        music.fetchAllPlaylists(token).then((_) {
          _lastPlaylistRefresh = DateTime.now();
          if (mounted) setState(() {});
        });
      }
    }
  }
}
