// lib/screens/friends/friends_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/friend_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/unified_widgets.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({Key? key}) : super(key: key);

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> with TickerProviderStateMixin {
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
      SnackBarUtils.showError(context, 'Unable to load friends data');
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Friends'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addFriend),
            icon: const Icon(Icons.person_add, color: AppTheme.primary),
            label: const Text('Add Friend', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Friends (${_friends.length})'),
            Tab(text: 'Requests (${_pendingRequests.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(),
                _buildRequestsTab(),
              ],
            ),
    );
  }

  Widget _buildFriendsTab() {
    if (_friends.isEmpty) {
      return EmptyState(
        icon: Icons.people,
        title: 'No friends yet',
        subtitle: 'Add friends to start sharing music together!',
        buttonText: 'Add Friend',
        onButtonPressed: () => Navigator.pushNamed(context, AppRoutes.addFriend),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriendsData,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friendId = _friends[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: AppTheme.surface,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.primaries[friendId % Colors.primaries.length],
                child: const Icon(Icons.person, color: Colors.white),
              ),
              title: Text('Friend #$friendId', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              subtitle: Text('User ID: $friendId', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'remove':
                      _showRemoveDialog(friendId);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
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
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_pendingRequests.isEmpty) {
      return const EmptyState(
        icon: Icons.mail_outline,
        title: 'No friend requests',
        subtitle: 'When someone sends you a friend request, it will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriendsData,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          final request = _pendingRequests[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: AppTheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User ID: ${request['from_user'] ?? 'Unknown'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text('Status: ${request['status'] ?? 'pending'}', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => _rejectRequest(request['id']?.toString() ?? '0'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                        child: const Text('REJECT'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => _acceptRequest(request['id']?.toString() ?? '0'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('ACCEPT'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRemoveDialog(int friendId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Remove Friend', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to remove Friend #$friendId?', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFriend(friendId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(String friendshipId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);
      
      final message = await friendProvider.acceptFriendRequest(authProvider.token!, int.parse(friendshipId));
      SnackBarUtils.showSuccess(context, message ?? 'Friend request accepted');
      _loadFriendsData();
    } catch (error) {
      SnackBarUtils.showError(context, 'Failed to accept request');
    }
  }

  Future<void> _rejectRequest(String friendshipId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);
      
      final message = await friendProvider.rejectFriendRequest(authProvider.token!, int.parse(friendshipId));
      SnackBarUtils.showSuccess(context, message ?? 'Friend request rejected');
      _loadFriendsData();
    } catch (error) {
      SnackBarUtils.showError(context, 'Failed to reject request');
    }
  }

  Future<void> _removeFriend(int friendId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);
      
      await friendProvider.removeFriend(authProvider.token!, friendId);
      SnackBarUtils.showSuccess(context, 'Friend removed');
      _loadFriendsData();
    } catch (e) {
      SnackBarUtils.showError(context, 'Failed to remove friend');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
