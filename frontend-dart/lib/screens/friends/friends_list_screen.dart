// lib/screens/friends/friends_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/core.dart';
import '../../providers/friend_provider.dart';
import '../../widgets/app_widgets.dart';  
import '../base_screen.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({Key? key}) : super(key: key);

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends BaseScreen<FriendsListScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  String get screenTitle => 'Friends';

  @override
  List<Widget> get actions => [
    TextButton.icon(
      onPressed: () => navigateTo(AppRoutes.addFriend),
      icon: const Icon(Icons.person_add, color: AppTheme.primary),
      label: const Text('Add Friend', style: TextStyle(color: AppTheme.primary)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFriendsData());
  }

  @override
  Widget buildContent() {
    return buildConsumerContent<FriendProvider>(
      builder: (context, friendProvider) {
        return buildTabContent(
          tabs: [
            Tab(text: 'Friends (${friendProvider.friends.length})'),
            Tab(text: 'Requests (${friendProvider.pendingRequests.length})'),
          ],
          tabViews: [
            _buildFriendsTab(friendProvider),
            _buildRequestsTab(friendProvider),
          ],
          controller: _tabController,
        );
      },
    );
  }

  Widget _buildFriendsTab(FriendProvider friendProvider) {
    return buildListContent<int>(
      items: friendProvider.friends,
      itemBuilder: (friendId, index) => _buildFriendCard(friendId),
      onRefresh: _loadFriendsData,
      emptyState: buildEmptyState(
        icon: Icons.people,
        title: 'No friends yet',
        subtitle: 'Add friends to start sharing music together!',
        buttonText: 'Add Friend',
        onButtonPressed: () => navigateTo(AppRoutes.addFriend),
      ),
    );
  }

  Widget _buildRequestsTab(FriendProvider friendProvider) {
    return buildListContent<Map<String, dynamic>>(
      items: friendProvider.pendingRequests,
      itemBuilder: (request, index) => _buildRequestCard(request),
      onRefresh: _loadFriendsData,
      emptyState: buildEmptyState(
        icon: Icons.mail_outline,
        title: 'No friend requests',
        subtitle: 'When someone sends you a friend request, it will appear here',
      ),
    );
  }

  Widget _buildFriendCard(int friendId) {
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
          onSelected: (value) => _handleFriendAction(value, friendId),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.playlist_play, size: 16), SizedBox(width: 8), Text('Share Playlist')])),
            const PopupMenuItem(value: 'remove', child: Row(children: [Icon(Icons.person_remove, size: 16, color: Colors.red), SizedBox(width: 8), Text('Remove Friend', style: TextStyle(color: Colors.red))])),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
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
                const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
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
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                  child: const Text('REJECT'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _acceptRequest(request['id']?.toString() ?? '0'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
                  child: const Text('ACCEPT'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadFriendsData() async {
    await runAsyncAction(
      () async {
        final friendProvider = getProvider<FriendProvider>();
        await Future.wait([
          friendProvider.fetchFriends(auth.token!),
          friendProvider.fetchPendingRequests(auth.token!),
        ]);
      },
      errorMessage: 'Unable to load friends data',
    );
  }

  void _handleFriendAction(String action, int friendId) {
    switch (action) {
      case 'share': showInfo('Playlist sharing coming soon!'); break;
      case 'remove': _showRemoveDialog(friendId); break;
    }
  }

  void _showRemoveDialog(int friendId) async {
    final confirmed = await showConfirmDialog('Remove Friend', 'Are you sure you want to remove Friend #$friendId?', isDangerous: true);
    if (confirmed) await _removeFriend(friendId);
  }

  Future<void> _acceptRequest(String friendshipId) async {
    await runAsyncAction(
      () async {
        final friendProvider = getProvider<FriendProvider>();
        await friendProvider.acceptFriendRequest(auth.token!, int.parse(friendshipId));
        await _loadFriendsData();
      },
      successMessage: 'Friend request accepted',
      errorMessage: 'Failed to accept request',
    );
  }

  Future<void> _rejectRequest(String friendshipId) async {
    await runAsyncAction(
      () async {
        final friendProvider = getProvider<FriendProvider>();
        await friendProvider.rejectFriendRequest(auth.token!, int.parse(friendshipId));
        await _loadFriendsData();
      },
      successMessage: 'Friend request rejected',
      errorMessage: 'Failed to reject request',
    );
  }

  Future<void> _removeFriend(int friendId) async {
    await runAsyncAction(
      () async {
        final friendProvider = getProvider<FriendProvider>();
        await friendProvider.removeFriend(auth.token!, friendId);
        await _loadFriendsData();
      },
      successMessage: 'Friend removed',
      errorMessage: 'Failed to remove friend',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
