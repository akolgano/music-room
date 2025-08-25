import 'package:flutter/material.dart';
import '../../providers/friend_providers.dart';
import '../../core/theme_core.dart';
import '../../core/provider_core.dart';
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
            _buildInvitationsTab(friendProvider, true),
            _buildInvitationsTab(friendProvider, false),
          ],
          controller: _tabController,
        );
      },
    );
  }

  Widget _buildInvitationsTab(FriendProvider provider, bool isReceived) {
    if (provider.isLoading) return buildLoadingState(message: isReceived ? 'Loading friend requests...' : 'Loading sent requests...');
    return buildListContent<Map<String, dynamic>>(
      items: isReceived ? provider.receivedInvitations : provider.sentInvitations,
      itemBuilder: (inv, idx) => isReceived ? _buildReceivedInvitationCard(inv, provider) : _buildSentInvitationCard(inv),
      onRefresh: _loadInvitations,
      emptyState: buildEmptyState(
        icon: isReceived ? Icons.inbox : Icons.send,
        title: isReceived ? 'No friend requests' : 'No sent requests',
        subtitle: isReceived ? 'You don\'t have any pending friend requests' : 'You haven\'t sent any friend requests yet',
        buttonText: isReceived ? 'Find Friends' : 'Add Friend',
        onButtonPressed: () => navigateTo(AppRoutes.addFriend),
      ),
    );
  }

  Widget _buildReceivedInvitationCard(Map<String, dynamic> invitation, FriendProvider friendProvider) {
    final fromUserId = friendProvider.getFromUserId(invitation);
    final fromUsername = friendProvider.getFromUsername(invitation) ?? 'User $fromUserId';
    final friendshipId = friendProvider.getFriendshipId(invitation);
    final status = friendProvider.getInvitationStatus(invitation);
    return _buildInvitationCard(
      userId: fromUserId,
      username: fromUsername,
      subtitle: 'Wants to be your friend',
      status: status,
      actions: status == 'pending' && friendshipId != null ? Column(
        children: [
          _buildActionButton('Accept', Colors.green, () => _acceptFriendRequest(friendshipId, friendProvider), friendProvider.isLoading),
          const SizedBox(height: 8),
          _buildActionButton('Reject', Colors.red, () => _rejectFriendRequest(friendshipId, friendProvider), friendProvider.isLoading),
        ],
      ) : null,
    );
  }

  Widget _buildSentInvitationCard(Map<String, dynamic> invitation) {
    final friendProvider = getProvider<FriendProvider>();
    final toUserId = friendProvider.getToUserId(invitation);
    final toUsername = friendProvider.getToUsername(invitation) ?? 'User $toUserId';
    final status = friendProvider.getInvitationStatus(invitation);
    return _buildInvitationCard(
      userId: toUserId,
      username: toUsername,
      subtitle: 'Friend request sent',
      status: status,
    );
  }

  Widget _buildInvitationCard({String? userId, required String username, required String subtitle, String? status, Widget? actions}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: userId != null ? ThemeUtils.getColorFromString(userId) : Colors.grey,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  if (userId != null) ...[const SizedBox(height: 2), Text('User ID: $userId', style: const TextStyle(color: Colors.grey, fontSize: 12))],
                ],
              ),
            ),
            actions ?? _buildStatusBadge(status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final color = {'pending': Colors.orange, 'accepted': Colors.green, 'rejected': Colors.red}[status?.toLowerCase()] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(status?.toUpperCase() ?? 'UNKNOWN', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
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

  Future<void> _acceptFriendRequest(String friendshipId, FriendProvider friendProvider) => runAsyncAction(
    () async => await friendProvider.acceptFriendRequest(auth.token!, friendshipId),
    successMessage: 'Friend request accepted!',
    errorMessage: 'Failed to accept friend request',
  );

  Future<void> _rejectFriendRequest(String friendshipId, FriendProvider friendProvider) async {
    if (await showConfirmDialog('Reject Friend Request', 'Are you sure you want to reject this friend request?')) {
      await runAsyncAction(
        () async => await friendProvider.rejectFriendRequest(auth.token!, friendshipId),
        successMessage: 'Friend request rejected',
        errorMessage: 'Failed to reject friend request',
      );
    }
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed, bool isLoading) => SizedBox(
    width: 80,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 4)),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    ),
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
