// lib/screens/friends/friend_request_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../core/core.dart';
import '../../widgets/app_widgets.dart';
import '../base_screen.dart';

class FriendRequestScreen extends StatefulWidget {
  const FriendRequestScreen({Key? key}) : super(key: key);

  @override
  State<FriendRequestScreen> createState() => _FriendRequestScreenState();
}

class _FriendRequestScreenState extends BaseScreen<FriendRequestScreen> {
  @override
  String get screenTitle => 'Friend Requests';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  Widget buildContent() {
    return buildConsumerContent<FriendProvider>(
      builder: (context, friendProvider) {
        if (friendProvider.isLoading) return buildLoadingState(message: 'Loading requests...');

        if (friendProvider.pendingRequests.isEmpty) {
          return buildEmptyState(
            icon: Icons.mail_outline,
            title: 'No friend requests',
            subtitle: 'When someone sends you a friend request, it will appear here',
          );
        }

        return buildListWithRefresh<Map<String, dynamic>>(
          items: friendProvider.pendingRequests,
          itemBuilder: (request, index) => _buildRequestCard(request),
          onRefresh: _loadData,
        );
      },
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
                const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User ID: ${request['from_user'] ?? 'Unknown'}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Status: ${request['status'] ?? 'pending'}',
                        style: const TextStyle(color: Colors.white70),
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
                AppWidgets.secondaryButton(
                  text: 'Reject',
                  onPressed: () => _rejectRequest(request['id']?.toString() ?? '0'),
                  fullWidth: false,
                ),
                const SizedBox(width: 12),
                AppWidgets.primaryButton(
                  text: 'Accept',
                  onPressed: () => _acceptRequest(request['id']?.toString() ?? '0'),
                  fullWidth: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadData() async {
    await runAsyncAction(
      () async {
        final friendProvider = getProvider<FriendProvider>();
        await friendProvider.fetchPendingRequests(auth.token!);
      },
      errorMessage: 'Failed to load friend requests',
    );
  }

  Future<void> _acceptRequest(String friendshipId) async {
    await runAsyncAction(
      () async {
        final friendProvider = getProvider<FriendProvider>();
        await friendProvider.acceptFriendRequest(auth.token!, int.parse(friendshipId));
        await _loadData();
      },
      successMessage: 'Friend request accepted!',
      errorMessage: 'Failed to accept request',
    );
  }

  Future<void> _rejectRequest(String friendshipId) async {
    await runAsyncAction(
      () async {
        final friendProvider = getProvider<FriendProvider>();
        await friendProvider.rejectFriendRequest(auth.token!, int.parse(friendshipId));
        await _loadData();
      },
      successMessage: 'Friend request rejected',
      errorMessage: 'Failed to reject request',
    );
  }
}
