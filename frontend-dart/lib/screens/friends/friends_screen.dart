// lib/screens/friends/friends_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/friend_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<int> _friends = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFriendsData();
  }

  Future<void> _loadFriendsData() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);
      
      await Future.wait([
        friendProvider.fetchFriends(authProvider.token!),
        friendProvider.fetchPendingRequests(authProvider.token!),
      ]);
      
      setState(() {
        _friends = friendProvider.friends;
        _pendingRequests = friendProvider.pendingRequests;
      });
    } catch (e) {
      _showSnackBar('Unable to load friends data. Please check your connection.', isError: true);
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Friends & Social'),
            Text(
              'Connect with other music lovers',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addFriend).then((_) => _loadFriendsData()),
            icon: const Icon(Icons.person_add, color: AppTheme.primary, size: 18),
            label: const Text('Add Friend', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.onSurfaceVariant,
          indicatorColor: AppTheme.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, size: 16),
                  const SizedBox(width: 4),
                  Text('My Friends'),
                  if (_friends.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_friends.length}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications, size: 16),
                  const SizedBox(width: 4),
                  Text('Requests'),
                  if (_pendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingRequests.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(),
                _buildRequestsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addFriend).then((_) => _loadFriendsData()),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Friend'),
        tooltip: 'Find and add new friends',
      ),
    );
  }

  Widget _buildFriendsTab() {
    if (_friends.isEmpty) {
      return _buildEmptyFriendsState();
    }

    return RefreshIndicator(
      onRefresh: _loadFriendsData,
      color: AppTheme.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildFriendsHeader(),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildFriendItem(_friends[index]),
              childCount: _friends.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_pendingRequests.isEmpty) {
      return _buildEmptyRequestsState();
    }

    return RefreshIndicator(
      onRefresh: _loadFriendsData,
      color: AppTheme.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildRequestsHeader(),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildRequestItem(_pendingRequests[index]),
              childCount: _pendingRequests.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Your Music Friends',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_friends.length} friend${_friends.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Share playlists, discover new music, and enjoy collaborative listening with your friends.',
            style: TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Friend Requests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_pendingRequests.length} pending',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'People who want to connect with you on Music Room. Accept to start sharing music together.',
            style: TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFriendsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 64,
                color: AppTheme.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No friends yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Music is better with friends! Connect with people to share playlists, discover new songs, and enjoy collaborative listening experiences.',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.addFriend).then((_) => _loadFriendsData()),
              icon: const Icon(Icons.person_add, size: 20),
              label: const Text('Find Friends'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                _showInviteDialog();
              },
              icon: const Icon(Icons.share, size: 20),
              label: const Text('Invite Friends'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRequestsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_read,
                size: 64,
                color: Colors.green.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'All caught up!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You don\'t have any pending friend requests right now. When someone wants to connect with you, they\'ll appear here.',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextButton.icon(
              onPressed: () => _loadFriendsData(),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Check for New Requests'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendItem(int friendId) {
    final colors = [Colors.purple, Colors.pink, Colors.blue, Colors.teal, Colors.orange, Colors.red];
    final color = colors[friendId % colors.length];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: AppTheme.surface,
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.8),
          child: Text(
            'F${friendId.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          'Music Friend #$friendId',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User ID: $friendId',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.music_note, size: 12, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Connected on Music Room',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'share':
                _sharePlaylistWithFriend(friendId);
                break;
              case 'remove':
                _removeFriend(friendId);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.playlist_play, size: 16),
                  SizedBox(width: 8),
                  Text('Share Playlist'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.person_remove, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Remove Friend', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.more_vert, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text('Actions', style: TextStyle(color: Colors.white, fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestItem(Map<String, dynamic> request) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: AppTheme.surface,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.2),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'User ID: ${request['from_user'] ?? 'Unknown'}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Wants to connect with you on Music Room',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _rejectRequest(request['id']?.toString() ?? '0'),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Decline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _acceptRequest(request['id']?.toString() ?? '0'),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sharePlaylistWithFriend(int friendId) {
    _showSnackBar('Playlist sharing with friends coming soon!');
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Invite Friends', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share Music Room with your friends!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Tell them to:\n• Download Music Room\n• Create an account\n• Search for your username to add you as a friend',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Invite feature coming soon!');
            },
            child: const Text('Share App'),
          ),
        ],
      ),
    );
  }

  void _acceptRequest(String friendshipId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);
      
      final message = await friendProvider.acceptFriendRequest(
        authProvider.token!,
        int.parse(friendshipId),
      );
      
      _showSnackBar(message ?? 'Friend request accepted! You can now share music together.');
      _loadFriendsData();
    } catch (error) {
      _showSnackBar('Unable to accept friend request. Please try again.', isError: true);
    }
  }

  void _rejectRequest(String friendshipId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);
      
      final message = await friendProvider.rejectFriendRequest(
        authProvider.token!,
        int.parse(friendshipId),
      );
      
      _showSnackBar(message ?? 'Friend request declined.');
      _loadFriendsData();
    } catch (error) {
      _showSnackBar('Unable to decline friend request. Please try again.', isError: true);
    }
  }

  Future<void> _removeFriend(int friendId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Remove Friend', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to remove Music Friend #$friendId?',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'You won\'t be able to share playlists or collaborate on music together anymore.',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Friend'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove Friend', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final friendProvider = Provider.of<FriendProvider>(context, listen: false);
        
        await friendProvider.removeFriend(authProvider.token!, friendId);
        _showSnackBar('Friend removed from your list.');
        _loadFriendsData();
      } catch (e) {
        _showSnackBar('Unable to remove friend. Please try again.', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppTheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        action: isError ? SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ) : null,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
