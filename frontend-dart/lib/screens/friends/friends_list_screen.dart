import 'package:flutter/material.dart';
import '../../core/theme_utils.dart';
import '../../core/constants.dart';
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
    return buildListContent<String>(
      items: friendProvider.friends,
      itemBuilder: (friendId, index) => _buildFriendCard(friendId),
      onRefresh: _loadFriendsData,
      emptyState: buildEmptyState(
        icon: Icons.people,
        title: 'No friends yet',
        subtitle: 'Start connecting and sharing music',
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
            margin: const EdgeInsets.all(4),
            child: ElevatedButton.icon(
              onPressed: () => navigateTo(AppRoutes.friendRequests),
              icon: const Icon(Icons.visibility),
              label: const Text('View All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 6),
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

  Widget _buildFriendCard(String friendId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: AppTheme.surface,
      child: ListTile(
        onTap: () => _navigateToUserPage(friendId),
        leading: CircleAvatar(
          backgroundColor: ThemeUtils.getColorFromString(friendId),
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          friendId, 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)
        ),
        subtitle: Text(
          'Connected', 
          style: const TextStyle(color: Colors.grey, fontSize: 12)
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleFriendAction(value, friendId),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view_profile',
              child: Row(children: [Icon(Icons.person, size: 16), SizedBox(width: 8), Text('Profile')])
            ),
            const PopupMenuItem(
              value: 'remove', 
              child: Row(children: [
                Icon(Icons.person_remove, size: 16, color: Colors.red), 
                SizedBox(width: 8), 
                Text('Remove', style: TextStyle(color: Colors.red))
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      color: AppTheme.surface,
      child: InkWell(
        onTap: fromUserId != null ? () => _navigateToUserPage(fromUserId) : null,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: fromUserId != null 
                  ? ThemeUtils.getColorFromString(fromUserId)
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
                    'Friend request',
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

  Future<void> _acceptFriendRequest(String friendshipId, FriendProvider friendProvider) async {
    await runAsyncAction(
      () async {
        await friendProvider.acceptFriendRequest(auth.token!, friendshipId);
      },
      successMessage: 'Friend request accepted!',
      errorMessage: 'Failed to accept friend request',
    );
  }

  Future<void> _rejectFriendRequest(String friendshipId, FriendProvider friendProvider) async {
    await runAsyncAction(
      () async {
        await friendProvider.rejectFriendRequest(auth.token!, friendshipId);
      },
      successMessage: 'Friend request rejected',
      errorMessage: 'Failed to reject friend request',
    );
  }

  void _handleFriendAction(String action, String friendId) {
    switch (action) {
      case 'view_profile':
        _navigateToUserPage(friendId);
        break;
      case 'remove': 
        _showRemoveDialog(friendId); 
        break;
    }
  }

  void _navigateToUserPage(String userId) {
    Navigator.pushNamed(
      context,
      AppRoutes.userPage,
      arguments: {
        'userId': userId,
        'username': null,
      },
    );
  }

  void _showRemoveDialog(String friendId) async {
    final confirmed = await showConfirmDialog(
      'Remove Friend', 
      'Are you sure you want to remove User ID $friendId from your friends?', isDangerous: true
    );
    if (confirmed) await _removeFriend(friendId);
  }

  Future<void> _removeFriend(String friendId) async {
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
