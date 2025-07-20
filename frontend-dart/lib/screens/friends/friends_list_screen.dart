import 'package:flutter/material.dart';
import '../../core/theme_utils.dart';
import '../../core/validators.dart';
import '../../core/constants.dart';
import '../../core/social_login.dart';
import '../../providers/friend_provider.dart';
import '../base_screen.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

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
        final totalRequests = friendProvider.receivedInvitations.length;
        
        return buildTabContent(
          tabs: [
            Tab(text: 'Friends (${friendProvider.friends.length})'),
            Tab(text: 'Requests ($totalRequests)'),
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
    if (friendProvider.isLoading) {
      return buildLoadingState(message: 'Loading friend requests...');
    }

    final receivedInvitations = friendProvider.receivedInvitations;

    if (receivedInvitations.isEmpty) {
      return buildEmptyState(
        icon: Icons.inbox,
        title: 'No friend requests',
        subtitle: 'You don\'t have any pending friend requests',
        buttonText: 'View All Requests',
        onButtonPressed: () => navigateTo(AppRoutes.friendRequests),
      );
    }

    return Column(
      children: [
        if (receivedInvitations.isNotEmpty) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => navigateTo(AppRoutes.friendRequests),
              icon: const Icon(Icons.visibility),
              label: const Text('View All Requests'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
        Expanded(
          child: buildListContent<Map<String, dynamic>>(
            items: receivedInvitations.take(3).toList(), 
            itemBuilder: (invitation, index) => _buildRequestPreviewCard(invitation, friendProvider),
            onRefresh: _loadFriendsData,
            emptyState: const SizedBox.shrink(),
          ),
        ),
      ],
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
        title: Text(
          'User ID: $friendId', 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)
        ),
        subtitle: Text(
          'Friend since you connected', 
          style: const TextStyle(color: Colors.grey, fontSize: 12)
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleFriendAction(value, friendId),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share', 
              child: Row(children: [Icon(Icons.playlist_play, size: 16), SizedBox(width: 8), Text('Share Playlist')])
            ),
            const PopupMenuItem(
              value: 'remove', 
              child: Row(children: [
                Icon(Icons.person_remove, size: 16, color: Colors.red), 
                SizedBox(width: 8), 
                Text('Remove Friend', style: TextStyle(color: Colors.red))
              ])
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestPreviewCard(Map<String, dynamic> invitation, FriendProvider friendProvider) {
    final fromUserId = friendProvider.getFromUserId(invitation);
    final fromUsername = friendProvider.getFromUsername(invitation) ?? 'User $fromUserId';
    final friendshipId = friendProvider.getFriendshipId(invitation);
    final status = friendProvider.getInvitationStatus(invitation);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: fromUserId != null 
                ? Colors.primaries[fromUserId % Colors.primaries.length]
                : Colors.grey,
              radius: 20,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fromUsername,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Text(
                    'Wants to be your friend',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (status == 'pending' && friendshipId != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _acceptFriendRequest(friendshipId, friendProvider),
                    icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Accept',
                  ),
                  IconButton(
                    onPressed: () => _rejectFriendRequest(friendshipId, friendProvider),
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Reject',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadFriendsData() async {
    await runAsyncAction(
      () async {
        final friendProvider = getProvider<FriendProvider>();
        await friendProvider.fetchAllFriendData(auth.token!);
      },
      errorMessage: 'Unable to load friends data',
    );
  }

  Future<void> _acceptFriendRequest(int friendshipId, FriendProvider friendProvider) async {
    await runAsyncAction(
      () async {
        await friendProvider.acceptFriendRequest(auth.token!, friendshipId);
      },
      successMessage: 'Friend request accepted!',
      errorMessage: 'Failed to accept friend request',
    );
  }

  Future<void> _rejectFriendRequest(int friendshipId, FriendProvider friendProvider) async {
    await runAsyncAction(
      () async {
        await friendProvider.rejectFriendRequest(auth.token!, friendshipId);
      },
      successMessage: 'Friend request rejected',
      errorMessage: 'Failed to reject friend request',
    );
  }

  void _handleFriendAction(String action, int friendId) {
    switch (action) {
      case 'share': 
        showInfo('Playlist sharing coming soon!'); 
        break;
      case 'remove': 
        _showRemoveDialog(friendId); 
        break;
    }
  }

  void _showRemoveDialog(int friendId) async {
    final confirmed = await showConfirmDialog(
      'Remove Friend', 
      'Are you sure you want to remove User ID $friendId from your friends?', isDangerous: true
    );
    if (confirmed) await _removeFriend(friendId);
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
