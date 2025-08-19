import 'package:flutter/material.dart';
import '../../providers/friend_providers.dart';
import '../../core/theme_core.dart';
import '../../core/constants_core.dart';
import '../base_screens.dart';

class FriendRequestScreen extends StatefulWidget {
  const FriendRequestScreen({super.key});

  @override
  State<FriendRequestScreen> createState() => _FriendRequestScreenState();
}

class _FriendRequestScreenState extends BaseScreen<FriendRequestScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  String get screenTitle => 'Friend Requests';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInvitations());
  }

  @override
  Widget buildContent() {
    return buildConsumerContent<FriendProvider>(
      builder: (context, friendProvider) {
        return buildTabContent(
          tabs: [
            Tab(text: 'Received (${friendProvider.receivedInvitations.length})'),
            Tab(text: 'Sent (${friendProvider.sentInvitations.length})'),
          ],
          tabViews: [
            _buildReceivedInvitationsTab(friendProvider),
            _buildSentInvitationsTab(friendProvider),
          ],
          controller: _tabController,
        );
      },
    );
  }

  Widget _buildReceivedInvitationsTab(FriendProvider friendProvider) {
    if (friendProvider.isLoading) {
      return buildLoadingState(message: 'Loading friend requests...');
    }

    return buildListContent<Map<String, dynamic>>(
      items: friendProvider.receivedInvitations,
      itemBuilder: (invitation, index) => _buildReceivedInvitationCard(invitation, friendProvider),
      onRefresh: _loadInvitations,
      emptyState: buildEmptyState(
        icon: Icons.inbox,
        title: 'No friend requests',
        subtitle: 'You don\'t have any pending friend requests',
        buttonText: 'Find Friends',
        onButtonPressed: () => navigateTo(AppRoutes.addFriend),
      ),
    );
  }

  Widget _buildSentInvitationsTab(FriendProvider friendProvider) {
    if (friendProvider.isLoading) {
      return buildLoadingState(message: 'Loading sent requests...');
    }

    return buildListContent<Map<String, dynamic>>(
      items: friendProvider.sentInvitations,
      itemBuilder: (invitation, index) => _buildSentInvitationCard(invitation),
      onRefresh: _loadInvitations,
      emptyState: buildEmptyState(
        icon: Icons.send,
        title: 'No sent requests',
        subtitle: 'You haven\'t sent any friend requests yet',
        buttonText: 'Add Friend',
        onButtonPressed: () => navigateTo(AppRoutes.addFriend),
      ),
    );
  }

  Widget _buildReceivedInvitationCard(Map<String, dynamic> invitation, FriendProvider friendProvider) {
    final fromUserId = friendProvider.getFromUserId(invitation);
    final fromUsername = friendProvider.getFromUsername(invitation) ?? 'User $fromUserId';
    final friendshipId = friendProvider.getFriendshipId(invitation);
    final status = friendProvider.getInvitationStatus(invitation);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: fromUserId != null 
                ? ThemeUtils.getColorFromString(fromUserId)
                : Colors.grey,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fromUsername,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Wants to be your friend',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  if (fromUserId != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'User ID: $fromUserId',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (status == 'pending' && friendshipId != null) ...[
              Column(
                children: [
                  SizedBox(
                    width: 80,
                    child: ElevatedButton(
                      onPressed: friendProvider.isLoading 
                        ? null 
                        : () => _acceptFriendRequest(friendshipId, friendProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      child: const Text('Accept', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 80,
                    child: ElevatedButton(
                      onPressed: friendProvider.isLoading 
                        ? null 
                        : () => _rejectFriendRequest(friendshipId, friendProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      child: const Text('Reject', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getStatusColor(status)),
                ),
                child: Text(
                  status?.toUpperCase() ?? 'UNKNOWN',
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSentInvitationCard(Map<String, dynamic> invitation) {
    final friendProvider = getProvider<FriendProvider>();
    final toUserId = friendProvider.getToUserId(invitation);
    final toUsername = friendProvider.getToUsername(invitation) ?? 'User $toUserId';
    final status = friendProvider.getInvitationStatus(invitation);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: toUserId != null 
                ? ThemeUtils.getColorFromString(toUserId)
                : Colors.grey,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    toUsername,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Friend request sent',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  if (toUserId != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'User ID: $toUserId',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStatusColor(status)),
              ),
              child: Text(
                status?.toUpperCase() ?? 'UNKNOWN',
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _loadInvitations() async {
    await runAsyncAction(
      () async {
        final friendProvider = getProvider<FriendProvider>();
        await Future.wait([
          friendProvider.fetchFriends(auth.token!),
          friendProvider.fetchReceivedInvitations(auth.token!),
          friendProvider.fetchSentInvitations(auth.token!),
        ]);
      },
      errorMessage: 'Failed to load friend requests',
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
    final confirmed = await showConfirmDialog(
      'Reject Friend Request',
      'Are you sure you want to reject this friend request?',
    );
    
    if (confirmed) {
      await runAsyncAction(
        () async => await friendProvider.rejectFriendRequest(auth.token!, friendshipId),
        successMessage: 'Friend request rejected',
        errorMessage: 'Failed to reject friend request',
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
