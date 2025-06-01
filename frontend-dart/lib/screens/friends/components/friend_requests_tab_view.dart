// lib/screens/friends/components/friend_requests_tab_view.dart
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../widgets/empty_state_widget.dart'; 

class FriendRequestsTabView extends StatelessWidget {
  final List<Map<String, dynamic>> pendingRequests;
  final Future<void> Function() onRefresh;
  final Function(String) onAcceptRequest;
  final Function(String) onRejectRequest;

  const FriendRequestsTabView({
    Key? key,
    required this.pendingRequests,
    required this.onRefresh,
    required this.onAcceptRequest,
    required this.onRejectRequest,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (pendingRequests.isEmpty) {
      return const EmptyState( 
        icon: Icons.mail_outline,
        title: 'No friend requests',
        subtitle: 'When someone sends you a friend request, it will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pendingRequests.length,
        itemBuilder: (context, index) {
          final request = pendingRequests[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: AppTheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                            Text(
                              'User ID: ${request['from_user'] ?? 'Unknown'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status: ${request['status'] ?? 'pending'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
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
                      OutlinedButton(
                        onPressed: () => onRejectRequest(request['id']?.toString() ?? '0'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: const Text('REJECT'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => onAcceptRequest(request['id']?.toString() ?? '0'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
}
